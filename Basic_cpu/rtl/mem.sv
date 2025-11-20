
module  mem (
    input   logic   clk,
    input   logic   read,
    input   logic   write,
    input   logic   [4:0]   addr,
    input   logic   [7:0]   data_in,
    output  logic   [7:0]   data_out
    );
    
    logic   [7:0]   memory  [0:31];

    always_ff @(posedge clk) begin
        if  (write == 1) begin
            memory [addr]  <=   data_in;
        end

        if  (read == 1) begin
            data_out    <=   memory [addr];
        end
    end

endmodule
