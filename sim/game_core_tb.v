// game_core_tb.v — 验证 Conway 规则 + 3 行缓冲 + 延迟写入
//
// 测试用图案：Blinker（闪烁子），3 个细胞横向排列
//   位置：行 10，列 30, 31, 32
//   下一代应变为：行 9,10,11，列 31（纵向排列）
//
// 验证点：
//   1. 邻居计数正确（每个细胞数 8 个邻居）
//   2. Conway 规则正确
//   3. 3 行缓冲正确（边界行 buf_top=0 / buf_bot=0）
//   4. 延迟写入正确（不会覆盖未读的旧数据）

`timescale 1ns / 1ps

module game_core_tb;

    reg         clk;
    reg         rst_n;
    reg         start;
    wire [5:0]  bram_row;
    wire [5:0]  bram_col;
    wire        bram_we;
    wire        bram_din;
    wire        bram_dout;
    wire        gen_done;
    wire [11:0] alive_count;

    // =================== Mock BRAM（模拟 grid_bram Port B） ===================
    reg [0:0] mock_grid [0:47][0:63];
    reg [0:0] mock_dout;

    // 同步读：数据延迟一个周期
    assign bram_dout = mock_dout;

    always @(posedge clk) begin
        mock_dout <= mock_grid[bram_row][bram_col];
        if (bram_we) begin
            mock_grid[bram_row][bram_col] <= bram_din;
        end
    end

    // =================== DUT ===================
    game_core uut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .bram_row   (bram_row),
        .bram_col   (bram_col),
        .bram_we    (bram_we),
        .bram_din   (bram_din),
        .bram_dout  (bram_dout),
        .gen_done   (gen_done),
        .alive_count(alive_count)
    );

    // =================== 100MHz 时钟 ===================
    always #5 clk = ~clk;  // 周期 10ns

    // =================== 状态监控 ===================
    integer cycle_count;
    reg [2:0] prev_state;

    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        if (uut.state !== prev_state) begin
            prev_state <= uut.state;
            $display("  [t=%0t, cyc=%0d] st=%0d row=%0d col=%0d we=%b",
                $time, cycle_count,
                uut.state, uut.row, uut.col, uut.bram_we);
        end
    end

    // =================== 测试流程 ===================
    integer r, c;
    reg   [63:0] row_buf;  // 用于逐行 dump 网格，方便观察

    initial begin
        // ---- 初始化 ----
        clk = 0;
        rst_n = 0;
        start = 0;
        cycle_count = 0;
        prev_state = 3'd0;

        // 清零 mock_grid
        for (r = 0; r < 48; r = r + 1)
            for (c = 0; c < 64; c = c + 1)
                mock_grid[r][c] = 1'b0;

        // ---- 放置 Blinker：行 10，列 30,31,32 ----
        mock_grid[10][30] = 1'b1;
        mock_grid[10][31] = 1'b1;
        mock_grid[10][32] = 1'b1;

        // ---- 复位释放 ----
        #20 rst_n = 1;
        #20;

        // ---- 打印初始状态 ----
        $display("========== 初始状态（第 0 代）==========");
        print_grid_around(10, 30);

        // ---- 发出 start 脉冲 ----
        $display("\n>>> 发出 start 脉冲");
        start = 1;
        #10 start = 0;

        // ---- 等待 gen_done ----
        wait (gen_done);
        #10;  // 等 gen_done 拉低
        $display(">>> gen_done 收到，第 1 代计算完成, alive_count=%0d\n", alive_count);

        // ---- 验证第 1 代结果 ----
        // Blinker 横向 → 纵向：
        //   横向：■■■ 在 (10,30)(10,31)(10,32)
        //   纵向：  ■ 在 ( 9,31)(10,31)(11,31)
        $display("========== 验证第 1 代 ==========");
        print_grid_around(10, 31);

        check_cell( 9, 31, 1'b1, "( 9,31) 应诞生");
        check_cell(10, 31, 1'b1, "(10,31) 应存活");
        check_cell(11, 31, 1'b1, "(11,31) 应诞生");

        check_cell(10, 30, 1'b0, "(10,30) 应死亡（原Blinker左端，邻居=1）");
        check_cell(10, 32, 1'b0, "(10,32) 应死亡（原Blinker右端，邻居=1）");

        if (alive_count == 12'd3)
            $display("  ✓ alive_count=3 正确");
        else
            $display("  ✗ alive_count=%0d 期望3", alive_count);

        // ---- 第二轮：纵向 → 横向（验证振荡） ----
        $display("\n>>> 发出第 2 次 start 脉冲");
        start = 1;
        #10 start = 0;

        wait (gen_done);
        #10;
        $display(">>> gen_done 收到，第 2 代计算完成, alive_count=%0d\n", alive_count);

        $display("========== 验证第 2 代（应恢复横向）==========");
        print_grid_around(10, 31);

        check_cell(10, 30, 1'b1, "(10,30) 应恢复");
        check_cell(10, 31, 1'b1, "(10,31) 应恢复");
        check_cell(10, 32, 1'b1, "(10,32) 应恢复");

        check_cell( 9, 31, 1'b0, "( 9,31) 应回死");
        check_cell(11, 31, 1'b0, "(11,31) 应回死");

        // ---- 边界测试：左上角 (0,0) 的邻居 ----
        $display("\n========== 边界测试 ==========");
        // 在 (0,0) 放一个活细胞，(0,1) 也放一个
        mock_grid[0][0] = 1'b1;
        mock_grid[0][1] = 1'b1;

        start = 1;
        #10 start = 0;
        wait (gen_done);
        #10;
        $display("左上角 (0,0) 邻居数应为 2（只有 (0,1) 和 (1,0)(1,1) 中存活的）");
        print_grid_around(0, 0);

        $display("\n========== 全部测试完成 ==========");
        $finish;
    end

    // =================== VCD 波形 ===================
    initial begin
        $dumpfile("game_core_tb.vcd");
        $dumpvars(0, game_core_tb);
    end

    // =================== 辅助函数 ===================
    task print_grid_around;
        input [5:0] center_r, center_c;
        integer rr, cc;
        begin
            $display("       列: %0d %0d %0d %0d %0d %0d %0d",
                center_c-3, center_c-2, center_c-1,
                center_c, center_c+1, center_c+2, center_c+3);
            for (rr = center_r - 2; rr <= center_r + 2; rr = rr + 1) begin
                if (rr >= 0 && rr < 48) begin
                    $write("  行 %2d:  ", rr);
                    for (cc = center_c - 3; cc <= center_c + 3; cc = cc + 1) begin
                        if (cc >= 0 && cc < 64)
                            $write("%s ", mock_grid[rr][cc] ? "■" : "□");
                        else
                            $write("x ");
                    end
                    $display("");
                end
            end
        end
    endtask

    task check_cell;
        input [5:0]  row_chk, col_chk;
        input        expected;
        input [256*8:0] msg;
        begin
            if (mock_grid[row_chk][col_chk] !== expected) begin
                $display("  ✗ 失败: %0s (期望%b, 实际%b)", msg, expected, mock_grid[row_chk][col_chk]);
            end else begin
                $display("  ✓ 通过: %0s", msg);
            end
        end
    endtask

endmodule
