module buzzer (
    input           clk,            // 100MHz
    input           rst_n,
    input           gen_done,       // 一代完成脉冲（来自 game_core）
    output reg      beep
);

    // 1kHz 方波 = 周期 1ms → 100MHz / 100k = 1000 计数
    // 半个周期 = 50000 计数
    reg [15:0] tone_cnt;
    reg [23:0] dur_cnt;             // 持续时间：100ms → 10M 计数
    reg        playing;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            playing  <= 1'b0;
            dur_cnt  <= 24'd0;          //计数器，决定声音持续时长
            tone_cnt <= 16'd0;          //计数器，决定声音的音调
            beep     <= 1'b0;           //表示蜂鸣器是否发声
        end else begin
            if (gen_done) begin       //game_core每迭代一个周期传来的信号
                playing  <= 1'b1;     //蜂鸣器开始工作
                dur_cnt  <= 24'd0;
                tone_cnt <= 16'd0;
            end else if (playing) begin
                if (dur_cnt < 24'd10_000_000) begin  // 100ms
                    dur_cnt <= dur_cnt + 24'd1;
                    if (tone_cnt < 16'd50000) begin
                        tone_cnt <= tone_cnt + 16'd1;
                    end else begin
                        tone_cnt <= 16'd0;
                        beep <= ~beep;          //tone_cnt决定beep的频率
                    end
                end else begin
                    playing <= 1'b0;
                    beep    <= 1'b0;
                end
            end
        end
    end

endmodule
