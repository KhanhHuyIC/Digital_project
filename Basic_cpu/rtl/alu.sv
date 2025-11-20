import typedefs::*;

module  alu (
    input   logic   [7:0]   accum,
    input   logic   [7:0]   data,
    input   opcode_t        opcode,
    input   logic   clk,
    output  logic   [7:0]   out,
    output  logic   zero
    );

    timeunit        1ns;
    timeprecision   100ps;

    always_comb begin
        if (accum == 8'b00) zero = 1;
        else    zero = 0;
    end

    always_ff @(negedge clk) begin
        case (opcode)
        HLT:    out =   accum;
        SKZ:    out =   accum;
        ADD:    out =   data + accum;
        AND:    out =   data & accum;
        XOR:    out =   data ^ accum;
        LDA:    out =   data;
        STO:    out =   accum;
        JMP:    out =   accum;
        default:    out = 8'b00;
        endcase
    end

endmodule
