
import fifo_pkg::*;

class fifo_generator #(parameter DATA_WIDTH = fifo_pkg::DATA_WIDTH);
	//Declare the elements that be used in this class
	typedef fifo_pkg::data_w data_w;
	mailbox #(fifo_transaction) gen2drv;
	virtual fifo_if #(DATA_WIDTH) vif;

	//Constructor to initialize the class
	function new(mailbox #(fifo_transaction) gen2drv,
		virtual fifo_if #(DATA_WIDTH) vif);
		this.gen2drv = gen2drv;
		this.vif = vif;
	endfunction

	//Task to run the class
	task run();
		fifo_transaction tr;

		// --- Step 1: Write a few samples
		$display ("[%0t] Step 1: Write a few samples", $time);
		for (int i = 0; i < 3; i++) begin
			tr = new(1, 0, data_w'($urandom_range(0,255)));
			gen2drv.put(tr);
			tr.print();
			#20;
		end

		// --- Step 2: Idle
		$display ("[%0t] Step 2: Idle for 2 cycles", $time);
		for (int i = 0; i < 3; i++) begin
			tr = new(0, 0, data_w'(0));
			gen2drv.put(tr);
			#20;
		end

		// --- Step 3: Read a few samples
		$display ("[%0t] Step 3: Read a few samples", $time);
		for (int i = 0; i < 3; i++) begin
			tr = new(0,1, data_w'(0));
			gen2drv.put(tr);
			tr.print();
			#20;
		end

		// --- Step 4: Write untill full
		$display ("[%0t] Step 4: Write untill full", $time);
		while (vif.full !== 1) begin
			tr = new(1, 0, data_w'($urandom_range(0,255)));
			gen2drv.put(tr);
			tr.print();
			#20;
		end
		$display("[GEN] FIFO FULL detected, stop writing");

		// --- Step 5: Read a few
		$display ("[%0t] Step 5: Read a few samples", $time);
		for (int i = 0; i < 4; i++) begin
			tr = new(0, 1, data_w'(0));
			gen2drv.put(tr);
			tr.print();
			#20;
		end

		// --- Step 6: Idle
		$display ("[%0t] Step 6: Idle for 2 steps", $time);
		for (int i = 0; i < 3; i++) begin
			tr = new(0, 0, data_w'(0));
			gen2drv.put(tr);
			#20;
		end

		// --- Step 7: Read until empty
		$display ("[%0t] Step 7: Read until empty", $time);
		while (vif.empty !== 1) begin
			tr = new(0, 1, data_w'(0));
			gen2drv.put(tr);
			tr.print();
			#20;
		end

		$display("[GEN] FIFO EMPTY detected, stop reading");
	endtask
endclass


