module counter_pulse
(
	input CLK_1M 	,		// 输入为1MHz的时钟
	input rst_n 	,		// 复位信号	
	input pulse_T 	,		// 输入待测信号
	input pulse_R 	,		// 输入待测信号
	output reg Mea_pulse,
	output	reg [15:0] cnt_high_level		// 一个待测信号的高电平宽度
);
  initial  Mea_pulse=0;
	// 获取待测脉冲信号上升沿
	reg[1:0]	pulse_temp_T;	// 分别用于存储这一时刻和上一时刻的待测脉冲信号电平
   reg[1:0]	pulse_temp_R;	// 分别用于存储这一时刻和上一时刻的待测脉冲信号电平
	reg	[5:0]	pulse_cnt	;		// 用于存储脉冲周期数
	reg	[20:0]	cnt_temp	;		// 用于临时存储高电平时钟周期数，存储32个周期，需要19位位宽，这里为了省事直接设置位21位
	reg	cnt_en		;		// 在检测到p_pulse时置位，这样可以在每次重新计数时保证从第一个脉冲上升沿时开始计数
		
	always @ ( posedge CLK_1M ) begin
		pulse_temp_T[0] <= pulse_T;			// 保存当前时刻电平
		pulse_temp_T[1] <= pulse_temp_T[0];
		pulse_temp_R[0] <= pulse_R;			// 保存当前时刻电平
		pulse_temp_R[1] <= pulse_temp_R[0];
		if((Mea_pulse == 1'b0)&&(pulse_temp_T==2'b01))
         begin
			  Mea_pulse <= 1'b1;
			  cnt_en <= 1'b0;
			end
		else if((Mea_pulse == 1'b1)&&(pulse_temp_R==2'b01))
       begin
	   	 Mea_pulse <= 1'b0;
			 cnt_en <= 1'b1;
		 end
		 else cnt_en <= 1'b0;
	end
	
	
	always @ ( posedge CLK_1M or negedge rst_n ) begin
		if ( !rst_n )
		    begin
			pulse_cnt 	<= 6'd0	;
			cnt_temp	<= 21'd0	;
			cnt_high_level <= 16'd0	;			
		  end
		else
	  	begin
			if ( pulse_cnt < 6'd32 )
		   begin	// 脉冲计数32个，
				if (Mea_pulse )
			   	begin		// 检测到脉冲的上升沿时
					cnt_temp <= cnt_temp + 21'd1	;					
				   end
				if ( cnt_en ) 
				  begin	// 在脉冲高电平和cnt_en信号被置位后开始对高电平时间计数
					 pulse_cnt 	<= pulse_cnt + 6'd1	;	// 脉冲数计数器加一
				  end
			end
			else
		   	begin
				pulse_cnt <= 6'd0	;	
				cnt_high_level <= cnt_temp[20:5]	;	// temp是cnt_temp右移5位的值，这里取低16位赋值给输出的单个脉冲宽度计数器
				cnt_temp	<= 21'd0	;				
			end
		end
	end

endmodule 
