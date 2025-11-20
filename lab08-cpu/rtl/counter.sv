module  counter (
    input   wire    clk,
    input   wire    load,
    input   wire    enable,
    input   wire    rst_,
    input   reg     [4:0]   data,

    output  reg     [4:0]   count
    );

    timeunit        1ns;
    timeprecision   1ns;

    always_ff @(posedge clk or negedge rst_) begin
        if  (!rst_) begin
            count <= '0;
        end else begin
            if (load) begin
                count   <=  data;
            end else begin
            if (enable) begin
                count   <=  count + 1'b1;
            end
            end
        end
    end

endmodule
