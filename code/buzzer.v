// 改为带复位的端口
module Buzzer(distance, iCLK_1Mhz, rst_n, buzzer);
input[23:0] distance;
input iCLK_1Mhz;
input rst_n;          // 新增复位
output reg buzzer;

// 1MHz分频 → 1kHz蜂鸣器音频（人耳可闻）
reg [9:0] buzzer_cnt = 10'd0;  // 10位计数器 0~1023
wire clk_buzzer;

// 【修复1】必须用时序逻辑计数，核心！！！
always @(posedge iCLK_1Mhz) begin
    if(!rst_n)
        buzzer_cnt <= 10'd0;
    else if (buzzer_cnt >= 10'd999)  // 1MHz / 1000 = 1kHz
        buzzer_cnt <= 10'd0;
    else
        buzzer_cnt <= buzzer_cnt + 1'd1;
end

// 分频得到1kHz方波
assign clk_buzzer = (buzzer_cnt < 10'd500) ? 1'b0 : 1'b1;

// 报警使能：小于100(10厘米)报警
wire ena = (distance < 24'd100) ? 1'b1 : 1'b0;

// 蜂鸣器输出
always @(posedge iCLK_1Mhz) begin
    buzzer <= ena & clk_buzzer;
end

endmodule
