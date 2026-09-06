module quanti_fc(
	input clk,
	input RSTN,
	input signed [20:0] conv,
	input start,
	output reg signed [7:0] quanti,
	output reg done
);
reg signed [13:0] quanti_ext;
reg signed [7:0] quanti_temp;
reg cnt;

always@(posedge clk or negedge RSTN) begin
	if (!RSTN) begin
		quanti <= 0;
		done <= 0;
		cnt <= 0;
	end
	
	else begin
		if (start && (cnt == 0)) begin
			cnt <= cnt + 1;
			done <= 0;
		end
		
		else if (cnt == 0) begin
			done <= 0;
		end
		
		else if (cnt == 1) begin
			cnt <= 0;
			quanti <= quanti_temp;
			done <= 1;
		end
	end
end

always@(*) begin
	if (!RSTN) begin
		quanti_temp = 0;
		quanti_ext = 0;
	end
	
	else if (start) begin
		quanti_ext = conv[20:7];
		if (quanti_ext > 127) begin
			quanti_temp = 127;
		end
		
		else if (quanti_ext < -128) begin
			quanti_temp = -128;
		end
		
		else begin
			quanti_temp = {{quanti_ext[13]},{quanti_ext[6:0]}};
		end
		
		if (quanti_temp < 0) begin
			quanti_temp = 0;
		end
	end
end

endmodule