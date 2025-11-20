import  typedefs::*;

module  cpu_test;

timeunit    1ns;
timeprecision   100ps;

//Signals
logic       rst_;
opcode_t    topcode;
logic       clk, alu_clk;
logic       load_ir, halt, fetch;
logic       [31:0]      test_number;
logic       [12*8:1]    testfile;
logic       [3:0]       count;

//DUT
cpu cpu1 (
    .clk        (clk),
    .alu_clk    (alu_clk),
    .rst_       (rst_),
    .fetch      (fetch),
    .halt       (halt),
    .load_ir    (load_ir)
);

//Clock generator
initial begin
    clk =   1'b0;
    forever #5  clk = ~clk;
end

always_ff  @(posedge clk or negedge rst_)
    if  (!rst_)
        count   <=  '0;
    else
        count   <=  count + 1'b1;

assign  alu_clk = ~(count == 4'hc);

initial begin
    int cycles;
    $timeformat (-9, 1, " ns", 2);

    cycles = 0;

    for (int fetch_num = 0; fetch_num <= 1; fetch_num ++) begin
        fetch = fetch_num;
        $display ("CPU test with FETCH = %0d", fetch);

        for (test_number = 1; test_number <= 3; test_number = test_number + 1) begin
            rst_ = 0;
            @(negedge clk);
            rst_ = 1;

            cycles  = 0;

            testfile = {"CPUtest", 8'h30+test_number[7:0], ".dat"};
            $display    ("Loading %0s (test %0d, fetch = %0d)",
                        testfile, test_number, fetch);

            $readmemb   (testfile, cpu1.memory1.memory);

            repeat (2) @(negedge clk);

            while (!halt && cycles < 1000) begin
                @(posedge clk);
                cycles++;

                if (load_ir) begin
                    @(posedge clk);
                    topcode = cpu1.opcode;
                    $display("%t fetch=%0b, test=%0d, PC=%02h - %03s, opcode = %0h, acc = %02h, alu_out = %02h, mem_data = %02h",
                            $time, fetch, test_number, cpu1.pc_addr, topcode.name(), cpu1.opcode, cpu1.accum, cpu1.alu_out, cpu1.data_out);
                    if ((test_number == 3) && (topcode == JMP)) begin
                        $display ("Next Fibonacci number is %0d",
                                cpu1.memory1.memory[5'h1B]);
                    end
                end
            end
            if (halt) begin
                $display("[END TEST] Test %0d with fetch=%0d finished at time %t",
                    test_number, fetch, $time);
            end else begin
                $display("[END TEST] Test %0d with fetch=%0d time out at time %t",
                    test_number, fetch, $time);
            end
        end
    end
    $display ("CPU TEST COMPLETED");
    $finish;
    end
endmodule
