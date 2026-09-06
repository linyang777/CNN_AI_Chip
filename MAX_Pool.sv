`timescale 1ns / 1ps

module MAX_Pool #(
parameter POOL_SIZE =2,
parameter POOL_STEP=2,
parameter DATA_WIDTH =8,
parameter INPUT_WIDTH =6,
parameter INPUT_TALL =6,
parameter OUTPUT_WIDTH = 3,
parameter OUTPUT_TALL = 3
)(
input clk,
input ready,
input rstn,
input signed [DATA_WIDTH-1:0] quanti [0:INPUT_WIDTH*INPUT_TALL-1],
output reg signed [DATA_WIDTH-1:0] pool_result [0:OUTPUT_WIDTH*OUTPUT_TALL-1],
output reg pool_finish
);
localparam OUT_SIZE=9;
function [DATA_WIDTH-1:0] max;//取最大值函数
    input [DATA_WIDTH-1:0] a, b, c, d;
    reg [DATA_WIDTH-1:0] temp1, temp2;
    begin
        temp1 = (a > b) ? a : b;  
        temp2 = (c > d) ? c : d;  
        max = (temp1 > temp2) ? temp1 : temp2; 
    end
endfunction

wire[1:0]next_row,next_col;
reg [1:0] out_row, out_col;  // 输出特征图坐标
wire [2:0] win_row, win_col;  // 窗口在输入中的起始坐标
assign next_col = (out_col == OUTPUT_WIDTH - 1) ? 0 : (out_col + 1);
assign next_row = (out_col == OUTPUT_WIDTH - 1) ? 
                  ((out_row == OUTPUT_TALL - 1) ? 0 : (out_row + 1)) : 
                  out_row;
assign win_row = out_row * POOL_STEP;
assign win_col = out_col * POOL_STEP;
wire [DATA_WIDTH-1:0]win_0 = quanti[win_row*INPUT_WIDTH + win_col];
wire [DATA_WIDTH-1:0]win_1 = quanti[win_row*INPUT_WIDTH + win_col+1];
wire [DATA_WIDTH-1:0]win_2 = quanti[(win_row + 1) * INPUT_WIDTH + win_col];    // (row+1, col)
wire [DATA_WIDTH-1:0]win_3 = quanti[(win_row + 1) * INPUT_WIDTH + (win_col + 1)]; // (row+1, col+1) 定义2*2窗口

localparam IDLE = 2'b00;
localparam PROCESSING = 2'b01;
localparam FINISHED = 2'b10;
reg[1:0]state,next_state;
reg[3:0]counter;
integer i;
always@(posedge clk or negedge rstn)begin
    if(!rstn)begin
        state <= 2'b0;
        //next_state <= 2'b0;
    end
    else begin
        state <= next_state;
    end
end
always@(*)begin
if(!rstn)begin
    next_state = 2'b0;
end
else begin
    case(state)
        IDLE: next_state = (ready)?PROCESSING:IDLE;
        PROCESSING:next_state = (counter >= OUT_SIZE)?FINISHED:PROCESSING;
        FINISHED:next_state = IDLE;
        default:next_state = IDLE;
    endcase
    end
end
always@(posedge clk or negedge rstn)begin
    if(!rstn)begin
        counter <= 4'b0;
        out_row <= 2'b0;
        out_col <= 2'b0;
        pool_finish<= 1'b0;
    end
    else begin
        if(state == IDLE)begin
                    counter <= 4'b0;
                    out_row <= 2'b0;
                    out_col <= 2'b0;
                    pool_finish<= 1'b0;
        end
        else if(state==PROCESSING)begin
            out_row <= next_row;
            out_col <= next_col;
            counter <= (counter>=4'd9)?4'd9:counter + 4'd1;
        end
        else if(state==FINISHED)begin
            pool_finish <= 1'b1;
        end
        else;
    end
end

always@(posedge clk or negedge rstn)begin
    if(!rstn)begin
                for(i=0;i<OUT_SIZE;i=i+1)begin
                     pool_result[i]<= 8'd0;
                end
    end
    else begin
        if(state == PROCESSING && counter < OUT_SIZE)begin
            pool_result[counter] <= max(win_0,win_1,win_2,win_3);
        end
        else;
    end
end


endmodule
