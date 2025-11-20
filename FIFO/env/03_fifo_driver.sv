
import fifo_pkg::*;

class fifo_driver #(parameter DATA_WIDTH = fifo_pkg::DATA_WIDTH);
	//Declare the elements that be used in this class
	typedef fifo_pkg::data_w data_w;
	virtual fifo_if vif;
	mailbox #(fifo_transaction) gen2drv;

	//Contructor to initialize the class
	function new (virtual fifo_if vif,
		mailbox #(fifo_transaction) gen2drv);
		this.vif = vif;
		this.gen2drv = gen2drv;
	endfunction

	//Task to run the class
	task run();
		fifo_transaction tr;
		forever begin
			gen2drv.get(tr);

			@(posedge vif.clk);
			vif.wr <= tr.wr;
			vif.rd <= tr.rd;
			vif.data_in <= tr.data;

			@(posedge vif.clk);
			vif.wr <= 0;
			vif.rd <= 0;
			#10;

		end
	endtask
endclass


