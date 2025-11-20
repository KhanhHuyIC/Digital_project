
import fifo_pkg::*;
class fifo_monitor #(parameter DATA_WIDTH = fifo_pkg::DATA_WIDTH);
	//Declare the elements 
	typedef fifo_pkg::data_w data_w;
	virtual fifo_if vif;
	mailbox #(fifo_transaction) mon2sb;

	//Constructor to initialize the class
	function new(virtual fifo_if vif,
		mailbox #(fifo_transaction) mon2sb);

		this.vif = vif;
		this.mon2sb = mon2sb;
	endfunction

	//Task to run the class
	task run();
		fifo_transaction tr;

		forever begin
			@(posedge vif.clk);

			//Monitor write data
			if (vif.wr) begin
				tr = new(1, 0, data_w'(vif.data_in));
				mon2sb.put(tr);
			end

			//Monitor read data
			if (vif.data_out_valid) begin
				tr = new(0, 1, data_w'(vif.data_out));
				mon2sb.put(tr);
			end
		end
	endtask
endclass


