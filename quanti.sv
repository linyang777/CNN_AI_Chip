module quanti(
	input clk,
	input RSTN,
	input start,
	input reg signed [19:0] conv,
	output reg signed [7:0] quanti [0:35],
	output reg done
);

reg [5:0] quanti_cnt;
reg signed [7:0] quanti_temp;
reg signed [12:0] quanti_ext;

always@(posedge clk or negedge RSTN) begin
	integer i;
	if (!RSTN) begin
		for (i = 0; i < 36; i = i + 1) begin
			quanti[i] <= 8'b00000000;
		end
		done <= 0;
		quanti_cnt <= 0;
	end
	
	else begin
		begin
			if (start && (quanti_cnt < 36)) begin
				quanti[quanti_cnt] <= quanti_temp;
				quanti_cnt <= quanti_cnt + 1;
			end
			
			if (quanti_cnt == 36) begin
				done <= 1;
				quanti_cnt <= 0;
			end
			
			else begin
				done <= 0;
			end
				
		end
	end
end

always@(*) begin
	quanti_ext = conv[19:7];
    quanti_temp = 0;
    if (start) begin
        if (quanti_ext > 127) begin
            quanti_temp = 127;
        end
        else if (quanti_ext < -128) begin
            quanti_temp = -128;
        end
        else begin
			quanti_temp = quanti_ext[7:0];
		end
		
        if (quanti_temp < 0) begin
            quanti_temp = 0;
        end
            
    end
end

endmodule
 
