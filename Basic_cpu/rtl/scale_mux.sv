`timescale  1ns/1ps
module  scale_mux #(parameter WIDTH = 1)
    (
    input   wire    [WIDTH-1:0] in_a,
    input   wire    [WIDTH-1:0] in_b,
    input   wire    sel_a,
    output   reg    [WIDTH-1:0] out
    );

    always_comb begin
        unique case (sel_a)
        1'b0    :   out = in_b;
        1'b1    :   out = in_a;
        default :   out = 'x;
        endcase
    end

endmodule
