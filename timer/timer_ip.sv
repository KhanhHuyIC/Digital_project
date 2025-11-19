module  timer_ip (
    input   logic   pclk,
    input   logic   preset_n,
    input   logic   psel,
    input   logic   penable,
    input   logic   pwrite,
    input   logic   [7:0]   paddr,
    input   logic   [7:0]   pwdata,

    output  logic   pready,
    output  logic   pslverr,
    output  logic   [7:0]   prdata
    );

    //Declaration
    logic   core_tick;
    //Register
    logic   [7:0]   TCR;
    logic   [7:0]   TDR;
    logic   [7:0]   TSR;
    logic   [7:0]   TCNT;
    //Register address
    localparam  ADDR_TDR    = 8'h00;
    localparam  ADDR_TCR    = 8'h01;
    localparam  ADDR_TSR    = 8'h02;
    localparam  ADDR_TCNT   = 8'h03;
    
    //Control signals
    logic   load_pulse, up_dw, en;
    logic   [1:0]   cks;
    logic   ovf_pulse, udf_pulse;

    //Edge - detect for loaded data
    logic   tcr7_q;
    always_ff   @(posedge pclk or negedge preset_n) begin
        if (!preset_n)  tcr7_q  <=  1'b0;
        else            tcr7_q  <=  TCR[7];
    end

    assign  load_pulse  = TCR[7] & ~tcr7_q;

    //Read/Write control - APB protocol
    always_ff   @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            pready  <=  1'b0;
            pslverr <=  1'b0;
            prdata  <=  '0;
            TCR <=  '0;
            TDR <=  '0;
            TSR <=  '0;
        end else begin
            if (psel) pready    <= 1'b1;
            else    pready      <= 1'b0;
            pslverr <=  1'b0;
            if  (psel && penable) begin
                if (pwrite) begin
                    unique case (paddr)
                        ADDR_TCR    :   TCR <=  {pwdata[7], 1'b0, pwdata[5], pwdata[4], 2'b00, pwdata[1:0]};
                        ADDR_TDR    :   TDR <=  pwdata;
                        ADDR_TSR    :   begin
                            TSR [1] <=  TSR[1] & ~pwdata[1];
                            TSR [0] <=  TSR[0] & ~pwdata[0];  
                        end
                    default:    pslverr <= 1'b1;
                    endcase
                 end else begin
                    unique  case (paddr)
                        ADDR_TCR    :   prdata  <=  {TCR[7], 1'b0, TCR[5], TCR[4], 2'b00, TCR[1:0]};
                        ADDR_TDR    :   prdata  <=  TDR;
                        ADDR_TSR    :   prdata  <=  {6'b0, TSR[1], TSR[0]};
                        ADDR_TCNT   :   prdata  <=  TCNT;
                    default:begin
                        pslverr <=  1'b1;
                        prdata  <=  '0;
                    end
                    endcase
                end
            end
        if  (udf_pulse) TSR[1]  <=  1'b1;
        if  (ovf_pulse) TSR[0]  <=  1'b1;
        end
    end

    //Timer_core
    timer core (
        .clk    (pclk),
        .rst_n  (preset_n),
        .load   (load_pulse),
        .up_dw  (TCR[5]),
        .en     (TCR[4]),
        .cks    (TCR[1:0]),
        .data   (TDR),
        .tcnt   (TCNT),
        .udf    (udf_pulse),
        .ovf    (ovf_pulse),
        .clock_tick(core_tick)
        );
  
endmodule
