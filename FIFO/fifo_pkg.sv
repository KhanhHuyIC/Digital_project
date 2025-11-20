
package fifo_pkg;
	//Define the width of data
	parameter int DATA_WIDTH = 8;
	typedef logic [DATA_WIDTH-1:0] data_w;

	//Define the memory capacity
	parameter int STORAGE = 16;

	//fifo_transaction class
	class fifo_transaction;
		//Declare the elements used in this class
		bit wr, rd;
		data_w data;

		function new(bit wr, bit rd, data_w data);
			this.wr = wr;
			this.rd = rd;
			this.data = data;
		endfunction

		function void print();
			$display ("Write: %b, Read: %b, Data: %h", wr, rd, data);
		endfunction
	endclass

endpackage


