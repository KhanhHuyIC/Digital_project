module  timer_test;

//==========DECLARATION
    //DUT   signals
    logic   pclk;
    logic   preset_n;
    logic   psel;
    logic   penable;
    logic   pwrite;
    logic   [7:0]   paddr;
    logic   [7:0]   pwdata;

    logic   pready;
    logic   pslverr;
    logic   [7:0]   prdata;

    //Timer IP
    timer_ip    dut (
        .pclk       (pclk),
        .preset_n   (preset_n),
        .psel       (psel),
        .penable    (penable),
        .pwrite     (pwrite),
        .paddr      (paddr),
        .pwdata     (pwdata),
        .pready     (pready),
        .pslverr    (pslverr),
        .prdata     (prdata)
    );

    //Address of Timer register
    localparam  addr_TDR = 8'h00,
                addr_TCR = 8'h01,
                addr_TSR = 8'h02,
                addr_TCNT= 8'h03;

//==========TASKS TRANSACTION
    //APB READ
    task automatic APB_READ (input [7:0]  addr, output [7:0] rdata);
        begin
            psel    =   1'b1;
            paddr   =   addr;
            pwrite  =   1'b0;
            penable =   1'b0;
            @(posedge   pclk);
            @(negedge   pclk);
            penable =   1'b1;
            @(posedge   pclk);
            @(negedge   pclk);
            rdata   =   prdata;
            penable =   1'b0;
            psel    =   1'b0;
        end
    endtask

    //APB WRITE
    task  APB_WRITE (input [7:0] addr, input  [7:0] wdata);
        begin
            psel    =   1'b1;
            paddr   =   addr;
            pwrite  =   1'b1;
            pwdata  =   wdata;
            penable =   1'b0;
            @(posedge   pclk);
            @(negedge   pclk);
            penable =   1'b1;
            @(posedge   pclk);
            @(negedge   pclk);
            penable =   1'b0;
            psel    =   1'b0;
            pwrite  =   1'b0;
        end
    endtask

    //Wait tick from DUT
    task automatic WAIT_TICKS (input int n);
        int w;
        begin
        unique case (n)
            0:  w = 1;
            1:  w = 3;
            2:  w = 7;
            3:  w = 15;
            default: w = 1;
        endcase
        repeat (w)  begin
            @(posedge   dut.core_tick);
        end
        end
    endtask
    
    //Expected ticks
    function automatic int EXP_CYCLES (input logic [1:0] cks);
        case (cks)
            2'b00: return 2;
            2'b01: return 4;
            2'b10: return 8;
            default: return 16;
        endcase
    endfunction

    //Counter set up
    task automatic TCNT_SET (
        input   logic   [1:0]   cks,
        input   logic           up_dw,
        input   logic   [7:0]   wdata
        );
    reg [7:0]   TCR_val;
    //Write data to TDR
    APB_WRITE   (addr_TDR, wdata);
    //TCR = {load, 0, up_dw, en, 2'b00, cks}
    TCR_val =   {1'b1, 1'b0, up_dw, 1'b0, 2'b00, cks};
    APB_WRITE   (addr_TCR, TCR_val);
    //Reset load
    TCR_val[7] = 1'b0;
    APB_WRITE   (addr_TCR, TCR_val);
    endtask

    //Check clock scaler
    task automatic CHECK_CLOCK (
        input   logic   [1:0]   cks,
        input   logic   up_dw,
        input   logic   [7:0]   wdata
        );
            reg [7:0]   rdata, pre, cur, TCR_val;
            int cnt, exp;

            TCNT_SET    (cks, up_dw, wdata);
            APB_READ    (addr_TCNT, rdata);
            if (rdata !== wdata)
                $error ("[%3t] [CKS = %0b] Load to TCNT fail: got = %02h, exp = %02h",
                $time, cks, rdata, wdata);
            else
                $display ("[%3t] [CKS = %0b] Load to TCNT pass: %02h",
                $time, cks, rdata);

            TCR_val = {1'b0, 1'b0, up_dw, 1'b1, 2'b00, cks};
            APB_WRITE   (addr_TCR, TCR_val);

            exp = EXP_CYCLES (cks);
            @(posedge dut.core_tick);
            
            cnt = 0;
            do begin
                @(posedge pclk);
                cnt ++;
            end while (!dut.core_tick);

            fork
                begin: COUNT_PCLK
                    forever @(negedge pclk) cnt++;
                end
                begin: WAIT_NEXT_TICK
                    @(posedge   dut.core_tick);
                end
            join_any
            disable COUNT_PCLK;

            if (cnt !== exp)
                $error ("[%3t] [CKS = %0b] PRESCALE FAIL: got %0d pclk, expect %0d",
                $time, cks, cnt, exp);
            else
                $display("[%3t] [CKS = %0b] PRESCALE PASS: %0d pclk/tick",
                $time, cks, exp);

            @(posedge   dut.core_tick);
            @(negedge   pclk);
            APB_READ    (addr_TCNT, pre);

            @(posedge   dut.core_tick);
            @(negedge   pclk);
            APB_READ    (addr_TCNT, cur);

            exp    = (EXP_CYCLES(cks) == 2) ? 8'd2 : 8'd1;
            
            if (!up_dw) begin
                if (cur !== (pre + exp))
                    $error ("[%3t] [CKS = %0b] COUNT UP FAIL: pre = %2h, cur = %2h",
                    $time, cks, pre, cur);
            end else begin
                if (cur !== (pre - exp))
                    $error ("[%3t] [CKS = %0b] COUNT DOWN FAIL: pre = %2h, cur = %2h",
                    $time, cks, pre, cur);
            end

    endtask

    //Check PSLVERR
    task automatic  APB_PSLVERR (
        input [7:0] addr,
        input [7:0] wdata,
        output bit err
        );
    err     = 1'b0;
    psel    = 1'b1;
    paddr   = addr;
    pwrite  = 1'b1;
    pwdata  = wdata;
    penable = 1'b0;

    @(posedge pclk);
    penable = 1'b1;
    
    @(posedge pclk);
    @(negedge pclk);
    err = pslverr;
    penable     = 1'b0;
    psel        = 1'b0;
    pwrite      = 1'b0;
    endtask
    
    //Check UDF and OVF
    task automatic  TIMER_COVER (input logic [1:0] cks, input bit up_dw);
        reg [7:0] TCR_val, rdata, start;
        bit err;
        start = (up_dw == 1'b0) ? 8'hFE : 8'h01;

        //Write the value the cover data
        TCNT_SET (cks, up_dw, start);

        TCR_val = {1'b0, 1'b0, up_dw, 1'b1, 2'b00, cks};
        APB_WRITE   (addr_TCR, TCR_val);

        @(posedge   dut.core_tick);
        @(posedge   dut.core_tick);

        APB_READ    (addr_TCNT, rdata);

        if  (up_dw == 1'b0) begin
            if (rdata !== 8'h00) $error ("TCNT overflow check fail: %02h", rdata);
            APB_READ (addr_TSR, rdata);
            if (rdata [0] !== 1'b1) $error ("OVF flag didn't raise");
            APB_WRITE   (addr_TSR, 8'b0000_0001);
            APB_READ    (addr_TSR, rdata);
            if (rdata [0] !== 1'b0) $error ("OVF flag clear fail");
        end else begin
            if (rdata !== 8'hFF) $error ("TCNT underflow check fail: %02h", rdata);
            APB_READ (addr_TSR, rdata);
            if (rdata [1] !== 1'b1) $error ("UDF flag didn't raise");
            APB_WRITE   (addr_TSR, 8'b0000_0010);
            APB_READ    (addr_TSR, rdata);
            if (rdata[1] !== 1'b0) $error ("UDF flag clear fail");
         end
    endtask
    
    //Check APB

//==========GENERATOR/SEQUENCE
    //Clock generator
    initial begin
        pclk  =   1'b0;
        forever   #5  pclk = ~pclk;
    end
    
    //Reset and init
    initial begin
        preset_n    =   1'b0;
        psel        =   1'b0;
        penable     =   1'b0;
        pwrite      =   1'b0;
        pwdata      =   '0;
        paddr       =   '0;
        repeat  (3) @(posedge   pclk);
        preset_n    =   1'b1;
    end

    //Stimulus
    initial begin
        reg [7:0]   rdata;
        reg [7:0]   wdata;
        reg [7:0]   TCR_val;
        reg [1:0]   cks;
        int         exp;
        wait (preset_n == 1'b1);
        @(posedge   pclk);

//==========Clock and Reset test (no 1 and no 2)
        $display ("[%2t] CLOCK TEST", $time);
        for (int i = 0; i < 4; i++) begin
            cks     = i[1:0];
            wdata   = $urandom_range (0, 8'hF0);

            CHECK_CLOCK (cks, 0, wdata);
            @(posedge pclk);
            CHECK_CLOCK (cks, 1, wdata);
        end
        $display("[%2t] CLOCK TEST FINISH", $time);

        $display ("[%2t] RESET TEST", $time);
        for (int i = 0; i < 20; i++) begin
            psel    = 1'b0;
            penable = 1'b0;
            pwrite  = 1'b0;

            preset_n    = 1'b0;
            @(posedge pclk);
            preset_n    = 1'b1;
            @(posedge pclk);
            if ((prdata !== 8'h00) || (pslverr !== 1'b0) || (pready !== 1'b0))
                $error ("Reset output data fail");

            APB_READ    (addr_TCR, rdata);
            if (rdata !== 8'h00) $error ("Reset TCR test fail");
            APB_READ    (addr_TDR, rdata);
            if (rdata !== 8'h00) $error ("Reset TDR test fail");
            APB_READ    (addr_TCNT, rdata);
            if (rdata !== 8'h00) $error ("Reset TCNT test fail");
            APB_READ    (addr_TSR, rdata);
            if (rdata !== 8'h00) $error ("Reset TSR test fail");
        end
        $display("[%2t] RESET TEST FINISH", $time);

//==========Register test
        $display("[%2t] REGISTER TEST", $time);

        //No 3, 4, 5 check TSR, TDR, TCR
        $display("Read/Write test");
        for (int i = 0; i < 20; i++) begin
            psel    = 1'b0;
            penable = 1'b0;
            pwrite  = 1'b0;
            
            preset_n = 1'b0;
            @(posedge pclk);
            preset_n = 1'b1;
            @(posedge pclk);

            //Check TDR
            APB_READ    (addr_TDR, rdata);
            if (rdata !== 8'h00) $error ("TDR default value check fail: got %02h", rdata);
            wdata = $urandom;
            APB_WRITE   (addr_TDR, wdata);
            APB_READ    (addr_TDR, rdata);
            if (rdata !== wdata) $error ("TDR read/write mismatch: got = %02h, exp = %02h", rdata, wdata);

            //Check TCR
            APB_READ    (addr_TCR, rdata);
            if (rdata !== 8'h00) $error ("TCR default value check fail: got=  %02h", rdata);
            wdata = $urandom;
            wdata = wdata & 8'b0110_1111;
            APB_WRITE   (addr_TCR, wdata);
            wdata = wdata & 8'b1011_0011;
            APB_READ    (addr_TCR, rdata);
            if (rdata !== wdata) $error ("TCR read/write mismatch: got = %02h, exp = %02h", rdata, wdata);

            //Check TSR
            APB_READ    (addr_TSR, rdata);
            if (rdata !== 8'h00) $error ("TSR default value check fail: got = %02h", rdata);
            wdata = $urandom;
            APB_WRITE   (addr_TSR, wdata);
            APB_READ    (addr_TSR, rdata);
            if (rdata !== 8'h00) $error ("TSR should remain 0: got = %02h", rdata);
        end

            //No 6, 7: Check null address and pslverr
            $display("Null-address test");
            for (int i = 0; i < 20; i++) begin
                bit err;
                logic   [7:0]   addr;
                addr    = $urandom;
                wdata   = $urandom;

                if (addr == addr_TDR || addr == addr_TCR || addr == addr_TSR || addr == addr_TCNT) begin
                    unique case (addr)
                        addr_TDR: begin
                            APB_WRITE   (addr_TDR, wdata);
                            APB_WRITE   (addr_TDR, rdata);
                            if (rdata !== wdata)
                                $error ("TDR read/write mismatch");
                            else
                                $display("TDR address test pass");
                        end
                        addr_TCR: begin
                            wdata = wdata & 8'b0110_1111;
                            APB_WRITE   (addr_TCR, wdata);
                            APB_READ    (addr_TCR, rdata);
                            wdata = wdata & 8'b1011_0011;
                            if (rdata !== wdata)
                                $error ("TCR read/write mismatch");
                            else
                                $display("TCR address test pass");
                        end
                        addr_TSR: begin
                            APB_READ    (addr_TSR, rdata);
                            if (rdata !== 8'h00)
                                $error ("TSR should remain 0");
                            else
                                $display ("TSR address test pass");
                        end
                        addr_TCNT: begin
                            APB_READ    (addr_TCNT, rdata);
                            $display    ("TCNT readable: %02h", rdata);
                        end
                    endcase
                end else begin
                    APB_PSLVERR (addr, wdata, err);
                    if (!err) $error ("Expected PSLVERR for invalid addr %02h", addr);
                end
            end
            $display ("[%2t] REGISTER TEST FINISH", $time);
//==========COVER TEST
            $display ("[%2t] COVER VALUE TEST", $time);
            for (int i = 0; i < 4; i++) begin
                cks = i[1:0];
                TIMER_COVER (cks, 0);
                @(posedge pclk);
                TIMER_COVER (cks, 1);
            end
            $display ("[%2t] COVER VALUE TEST", $time);
    #20;
    $display ("[%2t] TIMER TEST COMPLETE", $time);
    $finish;
    end

//==========COVERAGE
    logic   apb_xfer;
    assign  apb_xfer = psel & penable;

    covergroup  cg_simple @(posedge pclk);
        option.per_instance = 1;
        option.goal         = 100;

        //DUT SIGNALS
        //CKS
        cp_cks  : coverpoint dut.TCR[1:0] {
            bins    cks_00  =   {2'b00};
            bins    cks_01  =   {2'b01};
            bins    cks_10  =   {2'b10};
            bins    cks_11  =   {2'b11};
        }

        //Counter up/down control
        cp_updw : coverpoint dut.TCR[5] {
            bins up={1'b0};
            bins down={1'b1};
        }

        //Enable timer
        cp_en   : coverpoint dut.TCR[4] {
            bins off={1'b0};
            bins on={1'b1};
        }

        //LOAD pulse
        cp_load : coverpoint dut.load_pulse{
            bins seen = {1'b1};
        }

        //Over flag
        cp_ovf  : coverpoint dut.TSR[0] {
            bins set = {1'b1};
        }
        
        cp_udf  : coverpoint dut.TSR[1] {
            bins set = {1'b1};
        }

        //APB SIGNALS
        //Address
        cp_addr : coverpoint paddr iff (apb_xfer) {
            bins    TDR     = {8'h00};
            bins    TCR     = {8'h01};
            bins    TSR     = {8'h02};
            bins    TCNT    = {8'h03};
            bins    inv[]   = default;
        }

        //Read/Write
        cp_rw   : coverpoint pwrite iff (apb_xfer) {
            bins    rd  = {1'b0};
            bins    wr  = {1'b1};
        }

        //PSLVERR
        cp_err  : coverpoint pslverr iff (apb_xfer) {
            bins noerr={1'b0};
            bins err = {1'b1};
        }
        
        //PREADY
        cp_rdy  : coverpoint pready iff (psel) {
            bins low = {1'b0};
            bins hi = {1'b1};
        }
    endgroup: cg_simple

    cg_simple cov_simple = new();

    final begin
        $display ("=== SIMPLE FUNCTIONAL COVERAGE ===");
        $display ("cg_simple: %0.2f %%", cov_simple.get_coverage());
    end
endmodule
