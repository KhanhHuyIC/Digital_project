
import fifo_pkg::*;

class fifo_scoreboard #(parameter DATA_WIDTH = fifo_pkg::DATA_WIDTH);
	typedef fifo_pkg::data_w data_w;
	mailbox #(fifo_transaction) mon2sb;
	data_w model[$];

	function new(mailbox #(fifo_transaction) mon2sb);
		this.mon2sb = mon2sb;
	endfunction

	task run();
		fifo_transaction tr;
		forever begin
			mon2sb.get(tr);
			if (tr.wr && !tr.rd) begin
				model.push_back(tr.data);
			end else if (tr.rd && !tr.wr) begin
				data_w expected = model.size() ? model.pop_front() : 'x;
				$display("[SB] POP expect = 0x%0h", expected);
				if (model.size() == 0)
					$display("[SB] ERROR: Read when FIFO empty");
			end
		end
	endtask

endclass
