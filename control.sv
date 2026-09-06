module control(
    input clk,
    input RSTN,
    input weight_done,
    input image_done,
    input done_convu_0,
    input [2:0] total_count_0,
    input done_quanti_0,
    input pool_finish_0,
    input done_fc_0,
	input fc_reg_done,
    input done_fc_result,
    output reg start_read,
    output reg start_convu,
    output reg start_quanti,
    output reg ready_pool,
    output reg start_fc,
	output reg start_fc_reg,
    output reg start_fc_result,
    output reg start_quanti_fc
);
reg [2:0] total_count_0_reg;

always@(*) begin

    if(!RSTN) begin
            start_read = 0;
            start_quanti = 0;
            ready_pool = 0;
            start_fc = 0;
            start_fc_result = 0;
            start_quanti_fc = 0;
			start_fc_reg = 0;
    end
    
    else begin 
        start_read = done_convu_0;
        start_quanti =(total_count_0 > total_count_0_reg);
        ready_pool = done_quanti_0;
        start_fc = pool_finish_0;
		start_fc_reg = done_fc_0;
        start_fc_result = fc_reg_done;
        start_quanti_fc = done_fc_result;
    end
end

reg start_convu_i ;
always@(posedge clk or negedge RSTN)begin
    if(!RSTN)begin
        start_convu_i <= 1'b0;
    end
    else begin
        start_convu_i <=  weight_done & image_done;
    end
end
wire start_convu_up = (!start_convu_i)&&weight_done & image_done;
always@(*)begin
    if(!RSTN)begin
        start_convu = 1'b0;
    end
    if(start_convu_up)begin
        start_convu = 1'b1;
    end
    else begin
        start_convu = 1'b0;
    end
end

always@(posedge clk or negedge RSTN) begin
    if (!RSTN) begin
        total_count_0_reg <= 0;
    end
    
    else begin
        total_count_0_reg <= total_count_0;
    end 
end

endmodule