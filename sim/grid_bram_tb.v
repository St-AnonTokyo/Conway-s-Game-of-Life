// grid_bram_tb.v — 验证双端口读写
`timescale 1ns / 1ps

module grid_bram_tb;

    // Port A (VGA)
    reg         clk_a;
    reg  [5:0]  addr_a_row, addr_a_col;
    wire        dout_a;

    // Port B (Game Core)
    reg         clk_b;
    reg  [5:0]  addr_b_row, addr_b_col;
    reg         we_b;
    reg         din_b;
    wire        dout_b;

    grid_bram uut (
        .clk_a      (clk_a),
        .addr_a_row (addr_a_row),
        .addr_a_col (addr_a_col),
        .dout_a     (dout_a),
        .clk_b      (clk_b),
        .addr_b_row (addr_b_row),
        .addr_b_col (addr_b_col),
        .we_b       (we_b),
        .din_b      (din_b),
        .dout_b     (dout_b)
    );

    // 25MHz VGA 时钟
    always #20 clk_a = ~clk_a;
    // 100MHz 系统时钟
    always #5  clk_b = ~clk_b;

    initial begin
        clk_a = 0;
        clk_b = 0;
        we_b = 0;
        din_b = 0;
        addr_a_row = 0;
        addr_a_col = 0;
        addr_b_row = 0;
        addr_b_col = 0;

        // 先等几个周期让初始化生效
        #60;

        // 测试 1: Port A 读初始值（预设的活细胞在 (2,2)）
        addr_a_row = 6'd2;
        addr_a_col = 6'd2;
        #40;  // 等一个 VGA 周期
        $display("Test 1 - Read preset: grid[2][2] = %b (expect 1)", dout_a);

        // 测试 2: Port A 读死细胞
        addr_a_row = 6'd10;
        addr_a_col = 6'd10;
        #40;
        $display("Test 2 - Read dead:   grid[10][10] = %b (expect 0)", dout_a);

        // 测试 3: Port B 写入新活细胞
        addr_b_row = 6'd5;
        addr_b_col = 6'd5;
        din_b = 1'b1;
        we_b = 1'b1;
        #10;  // 一个 100MHz 周期
        we_b = 1'b0;
        // 等两个周期后从 Port A 读回验证
        #80;
        addr_a_row = 6'd5;
        addr_a_col = 6'd5;
        #40;
        $display("Test 3 - Write+Read: grid[5][5] = %b (expect 1)", dout_a);

        $display("All tests done.");
        $finish;
    end

    initial begin
        $dumpfile("grid_bram_tb.vcd");
        $dumpvars(0, grid_bram_tb);
    end

endmodule
