import  typedefs::*;

module  cpu (
    input   logic   clk,
    input   logic   alu_clk,
    input   logic   rst_,
    input   logic   fetch,
    output  logic   halt,
    output  logic   load_ir
    );

    timeunit    1ns;
    timeprecision   100ps;
   
    logic   mem_rd, mem_wr, load_ac, load_pc, inc_pc, zero;
    logic   [7:0]   data_out, accum, alu_out;
    opcode_t    opcode;
    logic   [7:0]   ir_out;
    logic   [4:0]   ir_addr, pc_addr, addr;

    assign  opcode  =   opcode_t'(ir_out  [7:5]);
    assign  ir_addr =   ir_out  [4:0];

    control controller1  (
        .opcode,
        .zero,
        .clk,
        .rst_,
        .mem_rd,
        .load_ir,
        .halt,
        .inc_pc,
        .load_ac,
        .load_pc,
        .mem_wr
    );

    alu alu1 (
        .accum  (accum),
        .data   (data_out),
        .opcode (opcode),
        .clk    (alu_clk),
        .out    (alu_out),
        .zero   (zero)
    );

    register accum1  (
        .clk    (clk),
        .rst_   (rst_),
        .enable (load_ac),
        .data   (alu_out),
        .out    (accum)
    );

    register instruction1 (
        .clk    (clk),
        .rst_   (rst_),
        .enable (load_ir),
        .data   (data_out),
        .out    (ir_out)
    );

    counter counter1 (
        .clk    (~clk),
        .load   (load_pc),
        .enable (inc_pc),
        .rst_   (rst_),
        .data   (ir_addr),
        .count  (pc_addr)
    );

    scale_mux #(.WIDTH(5))  mux1  (
        .in_b   (ir_addr),
        .in_a   (pc_addr),
        .sel_a  (fetch),
        .out    (addr)
    );

    mem memory1 (
        .clk    (~clk),
        .read   (mem_rd),
        .write  (mem_wr),
        .addr   (addr),
        .data_in    (alu_out),
        .data_out   (data_out)
    );

endmodule
