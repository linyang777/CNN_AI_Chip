module read (
    input  wire              clk,
    input  wire              rstn,
    input  wire              done,//卷积回访信号
    input  wire              mode,//模式切换信号
    input  wire              flag,   
    input  wire signed input_pin_0,
    input  wire signed input_pin_1,
    input  wire signed input_pin_2,
    input  wire signed input_pin_3,
    input  wire signed input_pin_4,
    input  wire signed input_pin_5,
    input  wire signed input_pin_6,
    input  wire signed input_pin_7,
    input  wire signed input_pin_8,
    output reg  signed [7:0] WEIGHT_conv_out   [0:8],
    output reg  signed [7:0] WEIGHT_conv_b_out ,
    output reg  signed [7:0] WEIGHT_fc_out     [0:8],
    output reg  signed [7:0] WEIGHT_fc_b,
    output reg  signed [8:0] image [0:38],
    output reg               weight_done_out,
    output reg               image_done
);
    integer i;
    integer idx;


    reg [5:0] weight_cnt;   // 0~57
    reg [5:0] image_cnt;    // 0~39
    //声明本来的变量
    reg  signed [7:0] WEIGHT_conv   [0:26];
    reg  signed [7:0] WEIGHT_fc   [0:26];
    reg  signed [7:0] WEIGHT_conv_b [0:2];
    reg               weight_done;

    reg  [5:0] count;
    reg  [5:0] count2;
    reg  [2:0] count3;

    
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            weight_cnt  <= 0;
            image_cnt   <= 0;
            weight_done <= 0;
            image_done  <= 0;
            weight_done_out <= 0;
            count <= 1;
            count2 <= 0;
            count3 <= 0;

        end
        else begin
            if (done&&(count3 < 5)) begin
                for(i = 0;i < 13;i = i + 1)begin
                    image[i] <= image[i + 26];
                end
		count3 <= count3 + 1;
                image_cnt   <= 13;
                image_done  <= 0;
            end


           else if (flag) begin
                image_cnt   <= 0;
                image_done  <= 0;
		count3 <=0;
                case(count)
                    0: begin
                        for(i = 0; i < 9; i = i + 1) begin
                            WEIGHT_conv_out[i] <= WEIGHT_conv[i];
                            WEIGHT_fc_out[i] <= WEIGHT_fc[i];
                        end
                    end
                    1: begin
                        for(i = 0; i < 9; i = i + 1) begin
                            WEIGHT_conv_out[i] <= WEIGHT_conv[i + 9];
                            WEIGHT_fc_out[i] <= WEIGHT_fc[i + 9];
                        end
                    end             
                    2: begin
                        for(i = 0; i < 9; i = i + 1) begin
                            WEIGHT_conv_out[i] <= WEIGHT_conv[i + 18];
                            WEIGHT_fc_out[i] <= WEIGHT_fc[i + 18];
                        end
                    end
                endcase               
                count <= (count == 2) ? 0 : count + 1;
                WEIGHT_conv_b_out <= WEIGHT_conv_b[count];
            end
	     else  if (done) begin
			image_done <= 0;
	     end

             else   if (mode == 1'b0 && !weight_done) begin
                    if (weight_cnt < 27) begin
                        WEIGHT_conv[weight_cnt] <= {input_pin_7,input_pin_6,input_pin_5,input_pin_4,input_pin_3,input_pin_2,input_pin_1,input_pin_0};
                    end
                    else if (weight_cnt < 30) begin
                        WEIGHT_conv_b[weight_cnt - 27] <= {input_pin_7,input_pin_6,input_pin_5,input_pin_4,input_pin_3,input_pin_2,input_pin_1,input_pin_0};
                    end
                    else if (weight_cnt < 57) begin
                        WEIGHT_fc[weight_cnt - 30] <= {input_pin_7,input_pin_6,input_pin_5,input_pin_4,input_pin_3,input_pin_2,input_pin_1,input_pin_0};
                    end
                    else if (weight_cnt == 57) begin
                        WEIGHT_fc_b <= {input_pin_7,input_pin_6,input_pin_5,input_pin_4,input_pin_3,input_pin_2,input_pin_1,input_pin_0};
                        weight_done <= 1'b1;
                    end

                    if (!weight_done)
                        weight_cnt <= weight_cnt + 1'b1;
                end


                else if (mode == 1'b1 && !image_done) begin
                    if (image_cnt < 40) begin
                        image[image_cnt] <= {input_pin_8,input_pin_7,input_pin_6,input_pin_5,input_pin_4,input_pin_3,input_pin_2,input_pin_1,input_pin_0};
                        image_cnt <= image_cnt + 1'b1;
                    end

                    if (image_cnt == 6'd39)
                        image_done <= 1'b1;
                end
                
               else if (weight_done&&!count2) begin
                    count2 <= 1;
                    for(i = 0;i < 9;i = i + 1)
                        WEIGHT_conv_out[i] <= WEIGHT_conv[i];
                        
                    for(i = 0;i < 9;i = i + 1)
                        WEIGHT_fc_out[i] <= WEIGHT_fc[i];
                        
                    WEIGHT_conv_b_out <= WEIGHT_conv_b[0];


                    weight_done_out <= 1;                       
                end

            end
        end
    

endmodule
