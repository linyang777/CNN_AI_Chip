module top_AI(
	input  wire clk,
    input  wire RSTN,
    input  wire mode,                 // 0=weight, 1=image
    input  wire input_pin_0,
    input  wire input_pin_1,
    input  wire input_pin_2,
    input  wire input_pin_3,
    input  wire input_pin_4,
    input  wire input_pin_5,
    input  wire input_pin_6,
    input  wire input_pin_7,
    input  wire input_pin_8,
	output wire signed [7:0] result,
	output wire out_data_flag
);

wire signed [7:0] WEIGHT_conv   [0:8];
wire signed [7:0] WEIGHT_conv_b;
wire signed [7:0] WEIGHT_fc     [0:8];
wire signed [7:0] WEIGHT_fc_b;
wire signed [8:0] DATA_NUM      [0:38];
wire weight_done;
wire image_done;
wire start_read;
wire done_fc_0;

read read 	(.clk(clk),
			.rstn(RSTN),
			.mode(mode),
			.flag(done_fc_0),
			.done(start_read),
			.input_pin_0(input_pin_0),
			.input_pin_1(input_pin_1),
			.input_pin_2(input_pin_2),
			.input_pin_3(input_pin_3),
			.input_pin_4(input_pin_4),
			.input_pin_5(input_pin_5),
			.input_pin_6(input_pin_6),
			.input_pin_7(input_pin_7),
			.input_pin_8(input_pin_8),
			.WEIGHT_conv_out(WEIGHT_conv),
			.WEIGHT_conv_b_out(WEIGHT_conv_b),
			.WEIGHT_fc_out(WEIGHT_fc),
			.WEIGHT_fc_b(WEIGHT_fc_b),
			.image(DATA_NUM),
			.weight_done_out(weight_done),
			.image_done(image_done)
); 

wire start_convu;
wire signed[19:0] conv_0;
wire [2:0] total_count_0;
wire done_num_0;
wire done_convu_0;//一张图片处理完成的标志信号

ConvU ConvU_0(
    .clk(clk), 
	.rst_n(RSTN),
	.start(start_convu),
    .img(DATA_NUM),
    .wht_conv(WEIGHT_conv),
    .wht_conv_b(WEIGHT_conv_b),
    .conv(conv_0),
    .done(done_convu_0),//一张图片处理完成的标志信号
	.total_count(total_count_0),
	.done_num(done_num_0)
);

wire start_quanti;
wire signed [7:0]quanti_result_0[0:35];
wire done_quanti_0;

quanti quanti_0(
	.clk(clk),
	.RSTN(RSTN),
	.start(start_quanti),
	.conv(conv_0),
	.quanti(quanti_result_0),
	.done(done_quanti_0)
);

parameter POOL_SIZE = 2;
parameter POOL_STEP= 2;
parameter DATA_WIDTH = 8;
parameter INPUT_WIDTH = 6;
parameter INPUT_TALL = 6;
parameter OUTPUT_WIDTH = 3;
parameter OUTPUT_TALL = 3;
wire ready_pool;
wire signed [DATA_WIDTH-1:0] pool_result_0 [0:OUTPUT_WIDTH*OUTPUT_TALL-1];
wire pool_finish_0;

MAX_Pool#(
	.POOL_SIZE(POOL_SIZE),
	.POOL_STEP(POOL_STEP),
	.DATA_WIDTH(DATA_WIDTH),
	.INPUT_WIDTH(INPUT_WIDTH),
	.INPUT_TALL(INPUT_TALL),
	.OUTPUT_WIDTH(OUTPUT_WIDTH),
	.OUTPUT_TALL(OUTPUT_TALL)
	)
	MAX_Pool_0(
	.clk(clk),
	.ready(ready_pool),
	.rstn(RSTN),
	.quanti(quanti_result_0),
	.pool_result(pool_result_0),
	.pool_finish(pool_finish_0)
);

wire start_fc;
wire signed [20:0] result_fc_0;

fc fc_0(
	.clk(clk),
	.RSTN(RSTN),
	.start(start_fc),
	.pool(pool_result_0),
	.wht_fc(WEIGHT_fc),
	.result(result_fc_0),
	.done(done_fc_0)
);

wire start_fc_reg;
wire fc_reg_done;
wire signed[20:0] fc_result_reg0;
wire signed[20:0] fc_result_reg1;
wire signed[20:0] fc_result_reg2;


 fc_reg fc_reg(
	.clk(clk),
	.RSTN(RSTN),
	.fc_result_0(result_fc_0),
	.start_fc_reg(start_fc_reg),
	.fc_result_reg0(fc_result_reg0),
	.fc_result_reg1(fc_result_reg1),
	.fc_result_reg2(fc_result_reg2),
	.fc_reg_done(fc_reg_done)
	);


wire start_fc_result;
wire done_fc_result;
wire signed [20:0] result_fc_result;

fc_result fc_result(
	.clk(clk),
	.RSTN(RSTN),
	.start(start_fc_result),
	.result0(fc_result_reg0),
	.result1(fc_result_reg1),
	.result2(fc_result_reg2),
	.wht_fc_b(WEIGHT_fc_b),
	.done(done_fc_result),
	.result(result_fc_result)
);

wire start_quanti_fc;
wire signed [7:0] quanti_end;
wire done_quanti_fc;

quanti_fc quanti_fc(
	.clk(clk),
	.RSTN(RSTN),
	.conv(result_fc_result),
	.start(start_quanti_fc),
	.quanti(quanti_end),
	.done(done_quanti_fc)
);

assign result = quanti_end;
assign out_data_flag = done_quanti_fc;

control control(
	.clk(clk),
	.RSTN(RSTN),
	.weight_done(weight_done),
	.image_done(image_done),
	.done_convu_0(done_convu_0),
	.total_count_0(total_count_0),
	.done_quanti_0(done_quanti_0),
	.pool_finish_0(pool_finish_0),
	.done_fc_0(done_fc_0),
	.fc_reg_done(fc_reg_done),
	.done_fc_result(done_fc_result),
	.start_read(start_read),
	.start_convu(start_convu),
	.start_quanti(start_quanti),
	.ready_pool(ready_pool),
	.start_fc(start_fc),
	.start_fc_reg(start_fc_reg),
	.start_fc_result(start_fc_result),
	.start_quanti_fc(start_quanti_fc)
);

endmodule


