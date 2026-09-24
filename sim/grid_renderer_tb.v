// grid_renderer_tb.v — 验证坐标映射和颜色输出
`timescale 1ns / 1ps

module grid_renderer_tb;

    reg  [8:0]  row_addr;
    reg  [9:0]  col_addr;
    reg         rdn;
    reg         grid_cell;
    wire [5:0]  grid_row;
    wire [5:0]  grid_col;
    wire [11:0] d_out;

    grid_renderer uut (
        .row_addr   (row_addr),
        .col_addr   (col_addr),
        .rdn        (rdn),
        .grid_row   (grid_row),
        .grid_col   (grid_col),
        .grid_cell  (grid_cell),
        .d_out      (d_out)
    );

    // grid_renderer 是纯组合逻辑，无需时钟
    initial begin
        rdn = 1;
        grid_cell = 0;

        // 测试 1: 消隐区 → 黑色
        rdn = 1;
        grid_cell = 0;
        row_addr = 9'd100;
        col_addr = 10'd200;
        #40;
        $display("Test 1 - Blanking:    rdn=%b → d_out=%h (expect 000)", rdn, d_out);

        // 测试 2: 有效区 + 活细胞 → 绿色
        rdn = 0;
        grid_cell = 1;
        row_addr = 9'd55;   // grid_row = 5，不在网格线上（55%10=5≠0）
        col_addr = 10'd123; // grid_col = 12，不在网格线上（123%10=3≠0）
        #40;
        $display("Test 2 - Alive:       r=%0d c=%0d grid=(%0d,%0d) → d_out=%h (expect 0F0)",
                 row_addr, col_addr, grid_row, grid_col, d_out);

        // 测试 3: 有效区 + 死细胞 → 黑色
        grid_cell = 0;
        #40;
        $display("Test 3 - Dead:        r=%0d c=%0d grid=(%0d,%0d) → d_out=%h (expect 000)",
                 row_addr, col_addr, grid_row, grid_col, d_out);

        // 测试 4: 网格线（列边界 col_addr=0） → 灰色，优先级高于细胞状态
        grid_cell = 1;  // 活细胞，但被网格线覆盖
        row_addr = 9'd33;  // 不在行边界上
        col_addr = 10'd0;  // col=0 是网格线
        #40;
        $display("Test 4 - Grid(col):   r=%0d c=%0d → d_out=%h (expect 666)",
                 row_addr, col_addr, d_out);

        // 测试 5: 网格线（行边界 row_addr=0） → 灰色
        row_addr = 9'd0;   // row=0 是网格线
        col_addr = 10'd57;
        #40;
        $display("Test 5 - Grid(row):   r=%0d c=%0d → d_out=%h (expect 666)",
                 row_addr, col_addr, d_out);

        // 测试 6: 边界坐标
        row_addr = 9'd479;
        col_addr = 10'd639;
        #40;
        $display("Test 6 - Edge:        r=%0d c=%0d → grid=(%0d,%0d)",
                 row_addr, col_addr, grid_row, grid_col);

        $display("All tests done.");
        $finish;
    end

    // 生成 VCD 波形文件
    initial begin
        $dumpfile("grid_renderer_tb.vcd");
        $dumpvars(0, grid_renderer_tb);
    end

endmodule
