module fc(
	input clk,
	input RSTN,
	input start,
	input signed [7:0] pool [0:8],
	input signed [7:0] wht_fc [0:8],
	output signed [20:0] result,
	output reg done
);

reg signed [20:0] sum;
reg signed [15:0] temp;
reg signed [20:0] temp_21bit;
parameter [1:0] IDLE = 2'b00,
				PROCESSING = 2'b01,
				FINISHED = 2'b10;
reg [1:0] Sreg,Snext;
reg [3:0] cnt;

always@(posedge clk or negedge RSTN) begin
	if (!RSTN) begin
		Sreg <= IDLE;
	end
	
	else begin
		Sreg <= Snext;
	end
end

always@(*) begin
	case(Sreg)
		IDLE: Snext = (start)?PROCESSING:IDLE;
		PROCESSING: Snext = (cnt < 10)?PROCESSING:FINISHED;
		FINISHED: Snext = IDLE;
		default: Snext = IDLE;
	endcase
end

always@(posedge clk or negedge RSTN) begin
	if (!RSTN) begin	
		sum <= 0;
		temp <= 0;
		temp_21bit <= 0;
		cnt <= 0;
	end
	
	else begin
		if (Sreg == IDLE) begin
			cnt <= 0;
			sum <= 0;
			done <= 0;
			temp_21bit <= 0;
			temp <= 0;
		end
		
		else if(Sreg == PROCESSING) begin
			temp <= pool[cnt] * wht_fc[cnt];
		    temp_21bit <= {{5{temp[15]}},{temp}};
		    sum <= sum + temp_21bit;
			cnt <= cnt + 1;
		end
		
		else if (Sreg == FINISHED) begin
			done <= 1;
		end
	end
end

assign result = sum;

endmodule		