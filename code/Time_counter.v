`timescale 1ns / 1ps

module Time_counter (
    input wire clk,             // 1MHz 系统时钟
    input wire rst_n,           // 异步复位，低电平有效
    input wire en,              // 计数使能信号
    input wire pulse_T,         // 启动信号 (上升沿启动)
    input wire pulse_R,         // 停止信号 (上升沿停止)
    
    output reg [19:0] count_val,// 计数值输出 (启停间的计数值)
    output reg done_pulse       // 计数结束指示脉冲 (1个时钟周期宽)
);

    // --------------------------------------------------------
    // 参数定义
    // 100ms @ 1MHz = 100,000 cycles.
    // 2^17 = 131072, 使用 20 位确保不溢出
    // --------------------------------------------------------
    localparam MAX_CNT_WIDTH = 20;
    localparam MAX_COUNT_VAL = 20'd100000; 

    // --------------------------------------------------------
    // 内部寄存器定义
    // --------------------------------------------------------
    reg [MAX_CNT_WIDTH-1:0] cnt_reg;      // 内部计数寄存器
    
    // 输入信号同步与边沿检测 (2级打拍)
    reg pulse_T_d1, pulse_T_d2;
    reg pulse_R_d1, pulse_R_d2;
    
    wire pulse_T_rise;
    wire pulse_R_rise;

    // 状态定义
    // ST_IDLE:      初始状态，等待 T
    // ST_COUNT:     计数进行中
    // ST_DONE_PULSE:收到 R，输出 done_pulse=1，保持计数值
    // ST_DONE_WAIT: done_pulse 已变低 (下降沿后)，此周期执行清零
    // ST_HOLD:      清零完成，保持停止，等待新的 T
    localparam ST_IDLE      = 3'b000;
    localparam ST_COUNT     = 3'b001;
    localparam ST_DONE_PULSE= 3'b010; 
    localparam ST_DONE_WAIT = 3'b011; 
    localparam ST_HOLD      = 3'b100; 

    reg [2:0] state, next_state;

    // ========================================================
    // 1. 信号同步与边沿检测
    // ========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_T_d1 <= 1'b0;
            pulse_T_d2 <= 1'b0;
            pulse_R_d1 <= 1'b0;
            pulse_R_d2 <= 1'b0;
        end else begin
            pulse_T_d1 <= pulse_T;
            pulse_T_d2 <= pulse_T_d1;
            pulse_R_d1 <= pulse_R;
            pulse_R_d2 <= pulse_R_d1;
        end
    end

    assign pulse_T_rise = (pulse_T_d1 == 1'b1) && (pulse_T_d2 == 1'b0);
    assign pulse_R_rise = (pulse_R_d1 == 1'b1) && (pulse_R_d2 == 1'b0);

    // ========================================================
    // 2. 状态机跳转逻辑 (组合逻辑)
    // ========================================================
    always @(*) begin
        next_state = state; //default
        case (state)
            ST_IDLE: begin
                if (pulse_T_rise)
                    next_state = ST_COUNT;
                else
                    next_state = ST_IDLE;
            end

            ST_COUNT: begin
                if (pulse_T_rise) begin
                    // 计数中再次收到 T -> 重置，保持在 COUNT 状态
                    next_state = ST_COUNT;
                end else if (pulse_R_rise) begin
                    // 收到 R -> 进入脉冲输出状态
                    next_state = ST_DONE_PULSE;
                end else if (cnt_reg >= MAX_COUNT_VAL) begin
                    // 达到 100ms 上限 -> 自动停止
                    //next_state = ST_DONE_PULSE;
                    next_state = ST_COUNT;
                end else begin
                    next_state = ST_COUNT;
                end
            end

            ST_DONE_PULSE: begin
                // 脉冲输出一个周期后，自动进入等待清零状态
                next_state = ST_DONE_WAIT;
            end

            ST_DONE_WAIT: begin
                // 清零动作完成后，进入保持状态
                next_state = ST_HOLD;
            end

            ST_HOLD: begin
                if (pulse_T_rise) begin
                    // 收到新的 T -> 重启
                    next_state = ST_COUNT;
                end else begin
                    // 收到 R 或其他 -> 保持停止 (忽略多余的 R)
                    next_state = ST_HOLD;
                end
            end

            default: next_state = ST_IDLE;
        endcase
    end

    // ========================================================
    // 3. 时序逻辑 (状态更新 + 计数器 + 输出)
    // ========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            cnt_reg <= 20'd0;
            count_val <= 20'd0;
            done_pulse <= 1'b0;
        end else 
        // if (!en) 
        // begin
            // state <= ST_IDLE;
            // cnt_reg <= 20'd0;
            // count_val <= 20'd0;
            // done_pulse <= 1'b0;
        // end else 
        
        begin
            state <= next_state;
            
            // 默认输出低电平
            done_pulse <= 1'b0;

            case (state)
                ST_IDLE: begin
                    cnt_reg <= 20'd0;
                    count_val <= 20'd0;
                    done_pulse <= 1'b0;
                end

                ST_COUNT: begin
                    if (pulse_T_rise) begin
                        // 计数中收到 T：清零重计
                        cnt_reg <= 20'd0;
                        count_val <= 20'd0;
                        done_pulse <= 1'b0;
                    end else if (en) begin
                        if (cnt_reg < MAX_COUNT_VAL) begin
                            cnt_reg <= cnt_reg + 1'b1;
                        end
                        count_val <= cnt_reg; // 实时更新输出
                        done_pulse <= 1'b0;
                    end else begin
                        // en 为 0，暂停计数，保持值
                        count_val <= cnt_reg;
                        done_pulse <= 1'b0;
                    end
                end

                ST_DONE_PULSE: begin
                    // 关键逻辑 1: 输出 1 个周期的结束脉冲
                    done_pulse <= 1'b1;
                    // 此时 count_val 保持为停止时的值 (来自上一个状态的 cnt_reg)
                    // 注意：由于是时序逻辑，这里赋值的 cnt_reg 还是停止那一刻的值
                    count_val <= cnt_reg; 
                end

                ST_DONE_WAIT: begin
                    // 关键逻辑 2: 结束信号下降沿之后延迟一个时钟周期，清零计数值
                    // 此时 done_pulse 已经在上一周期结束 (变为 0)，即经历了下降沿
                    // 本周期执行清零
                    cnt_reg <= 20'd0;
                    count_val <= 20'd0; // 输出也随之清零
                    done_pulse <= 1'b0;
                end

                ST_HOLD: begin
                    cnt_reg <= 20'd0; // 保持为 0
                    count_val <= 20'd0; // 输出为 0
                    done_pulse <= 1'b0;
                end
            endcase
        end
    end

endmodule
