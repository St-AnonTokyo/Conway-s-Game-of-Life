// seg_display_tb.v — 4 位七段管显示活细胞数
`timescale 1ns / 1ps

module seg_display_tb;

    reg         clk, rst_n;
    reg  [11:0] alive_count;
    wire [3:0]  an;
    wire [7:0]  segment;

    seg_display uut (
        .clk(clk), .rst_n(rst_n),
        .alive_count(alive_count),
        .an(an), .segment(segment)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; alive_count = 12'h003;
        #40 rst_n = 1;

        #2000000;  // 2ms，等扫描跑起来（每 1ms 换一位）
        $display("alive_count=3 → 数码管应显示 003（看波形验证段码）");

        alive_count = 12'h030;  // 48, Pulsar
        #2000000;
        $display("alive_count=48 → 数码管应显示 030");

        $display("\n========== 波形验证 AN 轮流亮、段码正确 ==========");
        $finish;
    end

    initial begin
        $dumpfile("seg_display_tb.vcd");
        $dumpvars(0, seg_display_tb);
    end

endmodule
