
import fifo_pkg::*;

interface fifo_if ();

	typedef fifo_pkg::data_w data_w;

	logic clk, rst_n, wr, rd, clear;
	data_w data_in;
	data_w data_out;
	logic data_out_valid, empty, full;
endinterface


