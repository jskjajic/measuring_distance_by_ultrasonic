module distance
(
	input clk,
	input rst_n,

	input pulse_R,
	input [7:0] Key_In,
	input [7:0] Sw_In,
	output Mea_pulse,
	output [7:0]Digitron_Out,
	output o_ultrasonic_signal_carrier_TP,
   output o_ultrasonic_signal_carrier_TN,
   output CLK_out,
   output [15:0] LED_Out,
	output buzzer,
	output [5:0]DigitronCS_Out
);
wire pulse_T;


wire CLK_1M	;

pll	pll_inst (
	.inclk0 ( clk ),
	.c0 ( CLK_1M )
	);
		
wire [15:0] cnt_high_level	;
//counter_pulse counter_pulse_inst
//(
//	.CLK_1M( CLK_1M ) ,	 // input 
//	.rst_n(rst_n)	,
//	.pulse_T(pulse_T) ,
//	.pulse_R(pulse_R) ,
//   .Mea_pulse(Mea_pulse),	
//	.cnt_high_level( cnt_high_level )
//);
/*
FSM_counter_pulse
(
    input  wire         CLK_1M,        // 1MHz时钟输入
    input  wire         rst_n,         // 复位信号（低有效）
    input  wire         pulse_T,       // 待测脉冲信号T
    input  wire         pulse_R,       // 待测脉冲信号R
    output reg          Mea_pulse,     // 测量使能信号
    output reg          ready,         // 单次测量结束，数据准备好
    output reg  [19:0]  cnt_high_level // 待测信号高电平宽度计数（20位）
);
*/
wire  ready ;
FSM_counter_pulse
(
	.CLK_1M( CLK_1M ) ,	 // input 
	.rst_n(rst_n)	,
	.pulse_T(pulse_T) ,
	.pulse_R(pulse_R) ,
   .Mea_pulse(Mea_pulse),
.ready(), 	
	.cnt_high_level( cnt_high_level )

//   .CLK_1M(),       // 1MHz时钟输入
//   .rst_n(),        // 复位信号（低有效）
//   .pulse_T(),      // 待测脉冲信号T
//   .pulse_R(),      // 待测脉冲信号R
//    .Mea_pulse(),    // 测量使能信号
//    .ready(),        // 单次测量结束，数据准备好
//    .cnt_high_level() // 待测信号高电平宽度计数（20位）
);
Digitron_NumDisplay_module U2
(
	.CLK( CLK_1M ) ,	 // input 
	.rst_n(rst_n)	,
	.cnt_high_level( cnt_high_level ) ,	 // input [7:0] - from U1	
	.Digitron_Out( Digitron_Out ) ,	 // output [7:0] - to top	
	.DigitronCS_Out( DigitronCS_Out ), 	// output [5:0] - to top
   .LED_Out(LED_Out),//LED灯	
	.buzzer(buzzer)
);	

assign o_ultrasonic_signal_carrier_TP = ultrasonic_signal_carrier_TP;

assign CLK_out = CLK_101hz;
//assign LED_Out = 16'b0;
wire CLK_40khz,CLK_101hz;

wire RSTn;
Rst_Delay dut_RSTn(.iCLK(clk),.iKey(Key_In[0]),.oRESET(RSTn));
assign pulse_T = CLK_101hz ;
ultrasonic_signal_carrier dut_US(.iRST(RSTn),.iCLK_50Mhz(clk),
.oCLK_40khz(CLK_40khz),.oCLK_100hz(CLK_101hz),
.o_ultrasonic_signal_carrier_TP(ultrasonic_signal_carrier_TP),
.o_ultrasonic_signal_carrier_TN(o_ultrasonic_signal_carrier_TN));

endmodule
