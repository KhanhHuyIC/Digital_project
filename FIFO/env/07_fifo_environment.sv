
import fifo_pkg::*;
`include "02_fifo_generator.sv"
`include "03_fifo_driver.sv"
`include "04_fifo_monitor.sv"
`include "05_fifo_scoreboard.sv"

class fifo_env #(parameter DATA_WIDTH = fifo_pkg::DATA_WIDTH);
	//Declare the elements ued in this class
	typedef fifo_pkg::data_w data_w;
	fifo_generator gen;
	fifo_driver drv;
	fifo_monitor mon;
	fifo_scoreboard sb;

	mailbox #(fifo_transaction) gen2drv;
	mailbox #(fifo_transaction) mon2sb;

	virtual fifo_if vif;

	//Constructor to initialize the class
	function new (virtual fifo_if vif);
		this.vif = vif;

		gen2drv = new();
		mon2sb = new();

		sb = new(.mon2sb(mon2sb));
		gen = new(.gen2drv(gen2drv), .vif(vif));
		drv = new(.vif(vif), .gen2drv(gen2drv));
		mon = new(.vif(vif), .mon2sb(mon2sb));

	endfunction

	//Task to run the testbench
	task run ();
		fork
			gen.run();
			drv.run();
			mon.run();
			sb.run();
		join_any
	endtask
endclass


