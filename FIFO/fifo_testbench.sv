
`timescale 1ns/1ps
import fifo_pkg::*;
`include "env/01_fifo_interface.sv"
`include "env/07_fifo_environment.sv"
`include "rtl/fifo.sv"

module fifo_tb;

//Interface
fifo_if intf();

//Initial block for clock generator
initial begin
	intf.clk = 0;
	forever #5 intf.clk = ~intf.clk;
end

//Initial block for initialize the signals
initial begin
	intf.wr = 0;
	intf.rd = 0;
	intf.data_in = '0;
	intf.rst_n = 0;
	intf.clear = 0;
	#12;
	intf.rst_n = 1;
end

//DUT
fifo dut (
	.clk (intf.clk),
	.rst_n (intf.rst_n),
	.wr (intf.wr),
	.rd (intf.rd),
	.clear (intf.clear),
	.data_in (intf.data_in),
	.data_out (intf.data_out),
	.data_out_valid (intf.data_out_valid),
	.empty (intf.empty),
	.full (intf.full)
	);

//Environment
fifo_env env;

//Clear
initial begin
	#525;
	$display("[TB] Trigger clear");
	intf.clear = 1;
	#20;
	intf.clear = 0;
end

//Initial to run environment and finish
initial begin
	env = new(intf);
	$monitor($time, " wr=%b, rd=%b, data_in=%h, data_out=%h, valid=%b, full=%b, empty =%b", intf.wr, intf.rd, intf.data_in, intf.data_out, intf.data_out_valid, intf.full, intf.empty);
	env.run();
	#2000;
	$finish;
end

//Dump waveform
/*initial begin
$dumpfile("FIFO_tb.vcd");
$dumpvars(0, FIFO_tb);
end
*/
endmodule


