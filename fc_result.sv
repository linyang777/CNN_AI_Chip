module fc_result(
	input clk,
	input RSTN,
	input start,
	input signed [20:0] result0,
	input signed [20:0] result1,
	input signed [20:0] result2,
	input signed [7:0] wht_fc_b,   
	output reg done,
	output reg signed [20:0] result
);

reg [1:0] cnt;

always@(posedge clk or negedge RSTN) begin
	if (!RSTN) begin
		done <= 0;
		result <= 0;
		cnt <= 0;
	end
	
	else begin
		
		if (start && (cnt == 0)) begin
			result <=  result0 + result1 + result2 + {{13{wht_fc_b[7]}}, wht_fc_b};
			done <= 1;
			cnt <= cnt + 1;
		end
		
		else if (cnt == 1) begin
			done <= 0;
			cnt <= cnt + 1;
		end
		else if (cnt == 2) begin
			cnt <= 0;
			result <= 0;
		end
	end
end

endmodule