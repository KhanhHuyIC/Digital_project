
import fifo_pkg::*;

class fifo_checker #(parameter DATA_WIDTH = fifo_pkg::DATA_WIDTH);
	//Declare the elements used in this class
	typedef fifo_pkg::data_w data_w;
	virtual fifo_if #(DATA_WIDTH) vif;
	integer wr_count = 0;
	integer rd_count = 0;

	//Constructor to initilize the class
	function new(virtual fifo_if #(DATA_WIDTH) vif);
		this.vif = vif;
	endfunction

	//Task to run the class
	task run();
		forever begin
			@(posedge vif.clk);

			if (vif.rd && vif.empty)
				$error("[ASSERT] Reading from EMPTY FIFO at time %0t", $time);
			if (vif.wr && vif.full)
				$error("[ASSERT] Writing to FULL FIFO at time %0t", $time);
			if (vif.wr && !vif.full)
				wr_count++;
			if (vif.rd && vif.data_out_valid)
				rd_count++;
		end
	endtask

	function void report();
		$display("[COV] Total write cycles: %0d", wr_count);
		$display("[COV] Total read cycles: %0d", rd_count);
	endfunction
endclass

