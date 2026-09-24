// pattern_rom_tb.v — 验证预设图案加载
`timescale 1ns / 1ps

module pattern_rom_tb;

    reg         clk, rst_n;
    reg  [2:0]  pattern_sel;
    reg         load;
    reg  [5:0]  base_row, base_col;
    wire        write_we, write_data;
    wire [5:0]  write_row, write_col;
    wire        done;

    pattern_rom uut (
        .clk(clk), .rst_n(rst_n), .pattern_sel(pattern_sel), .load(load),
        .base_row(base_row), .base_col(base_col),
        .write_we(write_we), .write_data(write_data),
        .write_row(write_row), .write_col(write_col), .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; pattern_sel = 0; load = 0; base_row = 10; base_col = 20;
        #40 rst_n = 1;
        #200;

        // ====== Glider (5 cells) ======
        $display("=== Glider (图案1) ===");
        pattern_sel = 3'd1; load = 1; #10; load = 0;
        wait(done);
        #10;
        $display("✓ Glider 加载完成 (5 cells)");

        // ====== Blinker (3 cells) ======
        $display("=== Blinker (图案2) ===");
        pattern_sel = 3'd2; load = 1; #10; load = 0;
        wait(done);
        #10;
        $display("✓ Blinker 加载完成 (3 cells)");

        // ====== LWSS (8 cells) ======
        $display("=== LWSS (图案3) ===");
        pattern_sel = 3'd3; load = 1; #10; load = 0;
        wait(done);
        #10;
        $display("✓ LWSS 加载完成 (8 cells)");

        // ====== Block (4 cells) ======
        $display("=== Block (图案6) ===");
        pattern_sel = 3'd6; load = 1; #10; load = 0;
        wait(done);
        #10;
        $display("✓ Block 加载完成 (4 cells)");

        $display("\n========== 全部测试完成 ==========");
        $finish;
    end

    initial begin
        $dumpfile("pattern_rom_tb.vcd");
        $dumpvars(0, pattern_rom_tb);
    end

endmodule
