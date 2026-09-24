// ps2_keyboard.v — PS/2 键盘解码器
//
// 协议：每帧 11 位（1 起始 + 8 数据 + 1 奇偶 + 1 停止）
//   PS2_CLK 下降沿采样 PS2_DATA
//   第 2~9 个下降沿为 8 位通/断码（LSB first）
//
// 特殊码：
//   8'hE0 — 扩展键前缀（方向键等）
//   8'hF0 — 断码前缀（按键释放）
//
// 输出：{expand, break, scan_code}，ready 脉冲指示有效数据

module ps2_keyboard (
    input           clk,            // 100MHz 系统时钟
    input           rst_n,          // 复位，低有效
    input           ps2_clk,        // PS/2 时钟（kHz 级，外部上拉）
    input           ps2_data,       // PS/2 数据

    output [9:0]    key_code,       // {expand(1), break(1), scan_code(8)}
    output          key_ready       // 单周期脉冲，key_code 有效
);

    // =================== PS2_CLK 下降沿检测（2 级同步 + 边沿） ===================
    reg [1:0] clk_sync;
    wire negedge_clk;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_sync <= 2'd0;
        else
            clk_sync <= {clk_sync[0], ps2_clk};
    end

    assign negedge_clk = clk_sync[1] && !clk_sync[0];  // 打一拍前是高，拍后是低 = 下降沿

    // =================== 位计数器（11 位/帧，0→10） ===================
    reg [3:0] bit_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_cnt <= 4'd0;
        else if (bit_cnt == 4'd11)
            bit_cnt <= 4'd0;            // 一帧结束，复位
        else if (negedge_clk)
            bit_cnt <= bit_cnt + 4'd1;  // 每个下降沿 +1
    end

    // =================== 采样数据位（bit_cnt=2~9 为 8 位有效数据） ===================
    reg negedge_d1;
    reg [7:0] scan_byte;

    always @(posedge clk) begin
        negedge_d1 <= negedge_clk;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            scan_byte <= 8'd0;
        else if (negedge_d1) begin          // negedge_clk 延迟一拍，保证 ps2_data 稳定
            case (bit_cnt)
                4'd2: scan_byte[0] <= ps2_data;
                4'd3: scan_byte[1] <= ps2_data;
                4'd4: scan_byte[2] <= ps2_data;
                4'd5: scan_byte[3] <= ps2_data;
                4'd6: scan_byte[4] <= ps2_data;
                4'd7: scan_byte[5] <= ps2_data;
                4'd8: scan_byte[6] <= ps2_data;
                4'd9: scan_byte[7] <= ps2_data;
                default: ;
            endcase
        end
    end

    // =================== 输出组装（处理 E0/F0 前缀） ===================
    reg expand;     // 扩展键标记（收到 E0 后置 1）
    reg brk;        // 断码标记（收到 F0 后置 1）

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expand <= 1'b0;
            brk    <= 1'b0;
        end else if (bit_cnt == 4'd11) begin
            if (scan_byte == 8'hE0) begin
                expand <= 1'b1;
                brk    <= 1'b0;
            end else if (scan_byte == 8'hF0) begin
                brk    <= 1'b1;
                expand <= 1'b0;
            end else begin
                expand <= 1'b0;
                brk    <= 1'b0;
            end
        end
    end

    assign key_code  = {expand, brk, scan_byte};
    assign key_ready = (bit_cnt == 4'd11) && (scan_byte != 8'hE0) && (scan_byte != 8'hF0);

endmodule
