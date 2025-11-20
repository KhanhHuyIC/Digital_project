`timescale 1ns/1ns
module register (
    input   wire    clk,
    input   wire    rst_,
    input   wire    enable,
    input   wire   [7:0] data,     

    output  reg    [7:0]   out
    );

    always_ff @(posedge clk or negedge rst_) begin
        if (!rst_) begin
            out    <=  '0;
        end else begin
            if (enable) begin
                out <= data;
            end else begin
                out <= out;
            end
        end
    end

endmodule
