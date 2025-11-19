module  timer(
    input   logic   clk,
    input   logic   rst_n,
    input   logic   load,
    input   logic   up_dw,
    input   logic   en,
    input   logic   [1:0]   cks,
    input   logic   [7:0]   data,

    output  logic   [7:0]   tcnt,
    output  logic   udf,
    output  logic   ovf,
    output  logic   clock_tick
    );

    logic   [3:0]   clock_scale;
    logic   [3:0]   clock_count;
    
    //Prescaler
    always_comb unique  case    (cks)
        2'b00   :   clock_scale =   4'd1;
        2'b01   :   clock_scale =   4'd3;
        2'b10   :   clock_scale =   4'd7;
        default :   clock_scale =   4'd15;
        endcase
    
    //Clock tick
    always_ff   @(posedge   clk or negedge  rst_n) begin
        if (!rst_n || load) begin
            clock_count <=  '0;
        end else if (!en) begin
            clock_count <=  '0;
        end else if (clock_count == clock_scale) begin
            clock_count <=  '0;
        end else begin
            clock_count <=  clock_count + 1'b1;
        end
    end
    
    assign  clock_tick  =   en && (clock_count == clock_scale);

     //Counter and output logic
     always_ff  @(posedge   clk or  negedge rst_n)  begin
        if (!rst_n) begin
            tcnt    <=  '0;
            ovf     <=  1'b0;
            udf     <=  1'b0;
        end else begin
            ovf     <=  1'b0;
            udf     <=  1'b0;
        
        if (load) begin
            tcnt    <=  data;
        end else if (clock_tick) begin
            if(!up_dw) begin
                ovf     <=  (tcnt == 8'hFF);
                tcnt    <=  tcnt + 8'd1;
            end else begin
                udf     <=  (tcnt == 8'h00);
                tcnt    <=  tcnt - 8'd1;
            end
        end
        end
    end

endmodule
