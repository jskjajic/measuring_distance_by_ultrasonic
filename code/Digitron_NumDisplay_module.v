module Digitron_NumDisplay_module
(
	CLK, rst_n	,cnt_high_level, Digitron_Out, DigitronCS_Out,LED_Out,buzzer
);
	 input  CLK;
	 input  rst_n	;
	 input  [15:0] cnt_high_level	;
	 output [7:0]Digitron_Out;
	 output [5:0]DigitronCS_Out;	 
	 output [15:0] LED_Out;//LED灯
	 output buzzer;//蜂鸣器报警
	
	wire [23:0] distance = cnt_high_level * 8'd170 / 24'd1000-30	;	// 算距离	
	wire [3:0] show_data_1 = distance/24'd1000				;		// 取显示的百位
	wire [3:0] show_data_2 = distance%24'd1000/24'd100		;		// 取显示的十位	
	wire [3:0] show_data_3 = distance%24'd100/24'd10		; 		// 取显示的个位
	wire [3:0] show_data_4 = distance%24'd10		; 		         // 取显示的一位小数
	wire [15:0] Result = {show_data_1,show_data_2,show_data_3,show_data_4} ;
	
   Buzzer  my_buzzer(.distance(distance),.iCLK_1Mhz(CLK),.rst_n(rst_n),.buzzer(buzzer));
   
    parameter Timex = 8'd200;	
	 reg [7:0]Count;
	 reg [3:0]SingleNum;
	 reg [7:0]W_Digitron_Out;
	 reg [5:0]W_DigitronCS_Out;
	 reg [15:0]W_LED_Out;//LED灯
	 
	 parameter _0 = 8'b0011_1111, _1 = 8'b0000_0110, _2 = 8'b0101_1011,
			 	  _3 = 8'b0100_1111, _4 = 8'b0110_0110, _5 = 8'b0110_1101,
			 	  _6 = 8'b0111_1101, _7 = 8'b0000_0111, _8 = 8'b0111_1111,
				  _9 = 8'b0110_1111;
				  
	 parameter _0_ = 8'b1011_1111, _1_ = 8'b1000_0110, _2_ = 8'b1101_1011,
			 	  _3_ = 8'b1100_1111, _4_ = 8'b1110_0110, _5_ = 8'b1110_1101,
			 	  _6_ = 8'b1111_1101, _7_ = 8'b1000_0111, _8_ = 8'b1111_1111,
				  _9_ = 8'b1110_1111;
	
	integer cs_two=0;//标志是否选中第二个片选信号
	
	always @(posedge CLK or negedge rst_n) begin
    if(!rst_n)
        W_LED_Out <= 16'b1111_1111_1111_1111;  // 复位全灭
    else begin
        // 全部分支都赋值 → 不会产生锁存器！
        if(distance < 24'd100)        // <10cm  只有LED0亮
            W_LED_Out <= 16'b1111_1111_1111_1110;
        else if(distance < 24'd500)   // 10-50cm 只有LED1亮
            W_LED_Out <= 16'b1111_1111_1111_1101;
        else if(distance < 24'd1000)  // 50-100cm 只有LED2亮
            W_LED_Out <= 16'b1111_1111_1111_1011;
        else if(distance < 24'd1500)  // 100-150cm 只有LED3亮
            W_LED_Out <= 16'b1111_1111_1111_0111;
        else if(distance < 24'd2000)  // 150-200cm 只有LED4亮
            W_LED_Out <= 16'b1111_1111_1110_1111;
        else if(distance < 24'd2500)  // 200-250cm 只有LED5亮
            W_LED_Out <= 16'b1111_1111_1101_1111;
        else                          // >250cm 只有LED6亮
            W_LED_Out <= 16'b1111_1111_1111_1111;
    end
    end
	
	
	
	always @ ( posedge CLK or negedge rst_n) 
		begin
			if ( !rst_n ) begin
				W_DigitronCS_Out = 6'b11_1110	;
			end
			else begin
				if( Count == Timex ) begin				
						Count <= 8'd0;
						W_DigitronCS_Out = {W_DigitronCS_Out[5:4],W_DigitronCS_Out[2],W_DigitronCS_Out[1],W_DigitronCS_Out[0],W_DigitronCS_Out[3]};
						if(W_DigitronCS_Out == 6'b11_1100) 
							W_DigitronCS_Out = 6'b11_1110;
							
						case(W_DigitronCS_Out)		
							6'b11_1110: SingleNum = Result[3:0];	//Display ResultL
							6'b11_1101: begin cs_two=1;SingleNum = Result[7:4];end	//Display ResultH		
							6'b11_1011: SingleNum = Result[11:8];	//Display Result
	                  6'b11_0111: SingleNum = Result[15:12];	//Display Result							
						endcase
						
						case(SingleNum)					
							4'd0:  begin if(cs_two==1)W_Digitron_Out = _0_;else W_Digitron_Out = _0;cs_two=0;end//重置
							4'd1:  begin if(cs_two==1)W_Digitron_Out = _1_;else W_Digitron_Out = _1;cs_two=0;end
							4'd2:  begin if(cs_two==1)W_Digitron_Out = _2_;else W_Digitron_Out = _2;cs_two=0;end
							4'd3:  begin if(cs_two==1)W_Digitron_Out = _3_;else W_Digitron_Out = _3;cs_two=0;end
							4'd4:  begin if(cs_two==1)W_Digitron_Out = _4_;else W_Digitron_Out = _4;cs_two=0;end
							4'd5:  begin if(cs_two==1)W_Digitron_Out = _5_;else W_Digitron_Out = _5;cs_two=0;end
							4'd6:  begin if(cs_two==1)W_Digitron_Out = _6_;else W_Digitron_Out = _6;cs_two=0;end
							4'd7:  begin if(cs_two==1)W_Digitron_Out = _7_;else W_Digitron_Out = _7;cs_two=0;end
							4'd8:  begin if(cs_two==1)W_Digitron_Out = _8_;else W_Digitron_Out = _8;cs_two=0;end
							4'd9:  begin if(cs_two==1)W_Digitron_Out = _9_;else W_Digitron_Out = _9;cs_two=0;end
							default: W_Digitron_Out <= 8'b1111_1111;	
						endcase
					end
				else
					Count <= Count + 1'b1;
			end
		end
	
	 assign Digitron_Out = W_Digitron_Out;
	 assign DigitronCS_Out = W_DigitronCS_Out;
	 assign LED_Out=W_LED_Out;//LED灯 
	
endmodule 
