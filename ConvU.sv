`timescale 1ns/1ps
module ConvU(
    input clk, rst_n, start,
    input signed[8:0] img[0:38],
    input signed[7:0] wht_conv[0:8],
    input signed[7:0] wht_conv_b,
    output reg signed[19:0] conv,
    output reg done,//一张图片处理完成的标志信号
    //output reg valid_out,
    output reg [2:0] total_count,
	output reg done_num
);
parameter CONV_STEP = 2;
parameter DATA_WIDTH = 9;
    function signed [19:0] conv_pe_func;
        input signed[8:0] img[0:8];
        input signed[7:0] core[0:8];
        input signed[7:0] b;
        
        integer i;
        reg signed[16:0] product;
        reg signed[19:0] sum;       
        begin
            sum = 0;            
            // 累加9个乘积
            for (i = 0; i < 9; i = i + 1) begin
                product = img[i] * core[i];                // 17位乘积
                sum = sum + {{3{product[16]}}, product};  // 扩展到20位并累加
            end            
            // 加上偏置（扩展到20位）
            conv_pe_func = sum + {{12{b[7]}}, b};
        end
    endfunction

    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam FINISHED = 2'b10;
    reg [1:0]state,next_state;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end
    always@(*)begin
        if(!rst_n)begin
            next_state = 2'b0;
        end
        else begin
            case(state)
                IDLE:next_state = (start)?PROCESSING:IDLE;
                PROCESSING:next_state = (total_count >= 3'd6)?FINISHED:PROCESSING;
                FINISHED: next_state = IDLE;
                default:next_state = IDLE;
            endcase
        end
    end
    
    wire[2:0]next_col;
    reg [2:0]out_col;  // 输出特征图坐标
    wire [3:0]win_col;  // 窗口在输入中的起始坐标
    assign next_col = (out_col == 5) ? 0 : (out_col + 1);
    assign win_col  = out_col * CONV_STEP;
    wire signed[DATA_WIDTH-1:0]win[0:8];
    assign win[0] = img[win_col];
    assign win[1] = img[win_col+1];
    assign win[2] = img[win_col+2];
    assign win[3] = img[13+win_col];
    assign win[4] = img[13+win_col+1];
    assign win[5] = img[13+win_col+2];
    assign win[6] = img[26+win_col];
    assign win[7] = img[26+win_col+1];
    assign win[8] = img[26+win_col+2];
    
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            out_col <= 3'b0;
            total_count <= 3'b0;
            done <= 1'b0;
			done_num <= 0;
        end
        else begin
            if(state==IDLE)begin
                out_col <= 3'b0;
                total_count <= 3'b0;
                done <= 1'b0;
				done_num <= 0;
            end
            else if(state==PROCESSING)begin
                out_col <= next_col;
                total_count <= (total_count >= 3'd6)?3'd6:total_count + 3'd1;
				done_num <= 1;
            end
            else if(state==FINISHED)begin
                done <= 1'b1;
				done_num <= 0;
            end
        end
    end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        conv <= 20'b0;
    end
    else begin
        if(state == PROCESSING && total_count < 6)begin
            conv <=  conv_pe_func(win[0:8],wht_conv,wht_conv_b);
        end
        else;
    end
end

endmodule

