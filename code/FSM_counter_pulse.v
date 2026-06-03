module FSM_counter_pulse
(
    input  wire         CLK_1M,        // 1MHz时钟输入
    input  wire         rst_n,         // 复位信号（低有效）
    input  wire         pulse_T,       // 待测脉冲信号T
    input  wire         pulse_R,       // 待测脉冲信号R
    output reg          Mea_pulse,     // 测量使能信号
    output reg          ready,         // 单次测量结束，数据准备好
    output reg  [19:0]  cnt_high_level // 待测信号高电平宽度计数（20位）
);

// --------------------------
// 内部信号定义
// --------------------------
reg  [1:0]  pulse_T_sync;  // pulse_T 两级同步（打拍）
reg  [1:0]  pulse_R_sync;  // pulse_R 两级同步（打拍）
wire        rise_T;        // pulse_T 上升沿
wire        rise_R;        // pulse_R 上升沿

reg  [1:0]  curr_state;    // 当前状态
reg  [1:0]  next_state;    // 下一个状态

reg  [15:0] pulse_cnt;     // 脉冲周期计数（最多256个）
reg  [21:0] cnt_temp;      // 高电平周期临时计数

// 状态定义
localparam S_IDLE      = 2'b00;  // 空闲状态
localparam S_MEASURE   = 2'b01;  // 测量状态（计数高电平周期）
localparam S_CALC      = 2'b10;  // 计算状态（输出结果）

// --------------------------
// 输入信号同步与边沿检测
// --------------------------
always @(posedge CLK_1M or negedge rst_n) begin
    if (!rst_n) begin
        pulse_T_sync <= 2'b00;
        pulse_R_sync <= 2'b00;
    end else begin
        pulse_T_sync <= {pulse_T_sync[0], pulse_T};
        pulse_R_sync <= {pulse_R_sync[0], pulse_R};
    end
end

assign rise_T = (pulse_T_sync == 2'b01);  // 上升沿：0 -> 1
assign rise_R = (pulse_R_sync == 2'b01);

// --------------------------
// 有限状态机（FSM）- 状态寄存器
// --------------------------
always @(posedge CLK_1M or negedge rst_n) begin
    if (!rst_n) begin
        curr_state <= S_IDLE;
    end else begin
        curr_state <= next_state;
    end
end

// --------------------------
// 有限状态机（FSM）- 组合逻辑（状态转移）
// --------------------------
always @(*) begin
    case (curr_state)
        S_IDLE: begin
            if (rise_T) begin
                next_state = S_MEASURE;
            end else begin
                next_state = S_IDLE;
            end
        end

        S_MEASURE: begin
            if (pulse_cnt >= 16'd32) begin
			//if (pulse_cnt >= 16'd256) begin
                next_state = S_CALC;
            end else begin
                next_state = S_MEASURE;
            end
        end

        S_CALC: begin
            next_state = S_IDLE;  // 计算完成后回到空闲
        end

        default: begin
            next_state = S_IDLE;
        end
    endcase
end




// --------------------------
// 有限状态机（FSM）- 时序逻辑（输出与计数）
// --------------------------
always @(posedge CLK_1M or negedge rst_n) begin
    if (!rst_n) begin
        Mea_pulse       <= 1'b0;
        ready           <= 1'b0;
        pulse_cnt       <= 16'd0;
        cnt_temp        <= 22'd0;
        cnt_high_level  <= 20'd0;
    end else begin
        case (curr_state)
            S_IDLE: begin
                ready <= 1'b0;
                Mea_pulse   <= 1'b1;    // 检测到T上升沿，开启测量
                cnt_temp    <= 22'd0;   // 清空临时计数
                pulse_cnt   <= 16'd0;   // 清空脉冲计数
                end 


            S_MEASURE: begin
                if (done_pulse) begin               
                cnt_temp <= cnt_temp + tmp_count_val;
                    pulse_cnt <= pulse_cnt + 16'd1; // 每个R上升沿计数+1
                end
            end

            S_CALC: begin
                cnt_high_level  <= {5'b0, cnt_temp[21:5]}; // 32 右移5位 256个周期平均（右移8位）
                cnt_temp        <= 22'd0;                 // 清空临时计数
                pulse_cnt       <= 16'd0;                 // 清空脉冲计数
                ready           <= 1'b1;                  // 数据准备好
            end
        endcase
    end
end


wire [19:0] tmp_count_val;
wire done_pulse;
Time_counter freq_counter_Onetime(
    .clk(CLK_1M),             // 1MHz 系统时钟
    .rst_n(rst_n),           // 异步复位，低电平有效
    .en(1'b1),              // 计数使能信号
    .pulse_T(pulse_T_sync[1]),         // 启动信号 (上升沿启动)
    .pulse_R(pulse_R_sync[1]),         // 停止信号 (上升沿停止)
    
    .count_val(tmp_count_val),// 计数值输出 (启停间的计数值)
    .done_pulse(done_pulse)       // 计数结束指示脉冲 (1个时钟周期宽)
);


endmodule


// module Time_counter (
    // input wire clk,             // 1MHz 系统时钟
    // input wire rst_n,           // 异步复位，低电平有效
    // input wire en,              // 计数使能信号
    // input wire pulse_T,         // 启动信号 (上升沿启动)
    // input wire pulse_R,         // 停止信号 (上升沿停止)
    
    // output reg [19:0] count_val,// 计数值输出 (启停间的计数值)
    // output reg done_pulse       // 计数结束指示脉冲 (1个时钟周期宽)
// );
