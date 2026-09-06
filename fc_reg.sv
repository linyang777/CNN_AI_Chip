module fc_reg(
    input clk,
    input RSTN,
    input signed [20:0] fc_result_0,
    input start_fc_reg,
    output reg signed[20:0] fc_result_reg0,
    output reg signed[20:0] fc_result_reg1,
    output reg signed[20:0] fc_result_reg2,
    output reg fc_reg_done
    );

reg [1:0] cnt;

always@(posedge clk or negedge RSTN) begin
    if (!RSTN) begin
        fc_result_reg0 <= 0;
        fc_result_reg1 <= 0;
        fc_result_reg2 <= 0;
        cnt <= 0;
        fc_reg_done <= 0;
    end
    
    else begin
        if (start_fc_reg && (cnt == 0 )) begin
                         fc_result_reg0 <= fc_result_0;
                cnt <= cnt + 1;
            end
            
            else if (start_fc_reg && (cnt == 1 )) begin
                fc_result_reg1 <= fc_result_0;
                cnt <= cnt + 1;
            end 
            
            else if (start_fc_reg && (cnt == 2 )) begin
                fc_result_reg2 <= fc_result_0;
                fc_reg_done <= 1;
                cnt <= cnt + 1;
            end    
    
         if (cnt == 3) begin
            fc_reg_done <= 0;
		cnt <= 0;
	   end
        end
    end

endmodule
		