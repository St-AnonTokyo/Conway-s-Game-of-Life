// ctrl_fsm_tb.v — 键盘光标编辑：方向键、空格、回车、ESC、Backspace
`timescale 1ns / 1ps

module ctrl_fsm_tb;

    reg         clk, rst_n;
    reg  [9:0]  key_code;
    reg         key_ready;
    reg         run_mode;

    wire        running, cursor_on;
    wire [5:0]  cursor_row, cursor_col;
    wire        edit_we, edit_data;
    wire [5:0]  edit_row, edit_col;
    wire [2:0]  pat_sel;
    wire        pat_load;

    // Mock BRAM
    reg         mock_bram [0:47][0:63];
    reg         mock_dout;
    wire        bram_dout = mock_dout;

    always @(posedge clk) begin
        mock_dout <= mock_bram[edit_row][edit_col];
        if (edit_we) mock_bram[edit_row][edit_col] <= edit_data;
    end

    ctrl_fsm uut (
        .clk(clk), .rst_n(rst_n), .key_code(key_code), .key_ready(key_ready),
        .run_mode(run_mode), .running(running), .cursor_on(cursor_on),
        .cursor_row(cursor_row), .cursor_col(cursor_col),
        .edit_we(edit_we), .edit_data(edit_data),
        .edit_row(edit_row), .edit_col(edit_col), .bram_dout(bram_dout),
        .pattern_sel(pat_sel), .pattern_load(pat_load), .pattern_done(1'b0)
    );

    always #5 clk = ~clk;

    task send_key;
        input [7:0] scan; input expand, brk;
        begin key_code = {expand, brk, scan}; key_ready = 1; #10; key_ready = 0; #100; end
    endtask

    task press_ext;  // 扩展键（方向键）
        input [7:0] scan;
        begin send_key(scan, 1'b1, 1'b0); end
    endtask

    task press;      // 普通键
        input [7:0] scan;
        begin send_key(scan, 1'b0, 1'b0); end
    endtask

    integer r, c;
    initial begin
        clk = 0; rst_n = 0; key_code = 0; key_ready = 0; run_mode = 0;
        for (r = 0; r < 48; r = r + 1) for (c = 0; c < 64; c = c + 1) mock_bram[r][c] = 1'b0;
        #40 rst_n = 1; #200;

        // ===== 0: 启动 TITLE =====
        if (!cursor_on) $display("✓ 0: 启动TITLE 无光标");
        else $display("✗ 0: cursor_on=%b", cursor_on);

        // ===== 1: Shift → EDIT =====
        press(8'h12);  // Shift
        if (cursor_on) $display("✓ 1: Shift→EDIT 光标出现");
        else $display("✗ 1: cursor_on=%b", cursor_on);

        // ===== 2: 方向键 =====
        press_ext(8'h75);  // ↑
        if (cursor_row == 23 && cursor_col == 32) $display("✓ 1: ↑→(%0d,%0d)", cursor_row, cursor_col);
        else $display("✗ 1: (%0d,%0d)", cursor_row, cursor_col);

        press_ext(8'h6B); press_ext(8'h72); press_ext(8'h72);
        press_ext(8'h74); press_ext(8'h74); press_ext(8'h74);
        if (cursor_row == 25 && cursor_col == 34) $display("✓ 2: 方向键组合→(%0d,%0d)", cursor_row, cursor_col);
        else $display("✗ 2: (%0d,%0d)", cursor_row, cursor_col);

        // ===== 3: 边界 =====
        repeat (25) press_ext(8'h75); press_ext(8'h75);
        if (cursor_row == 0) $display("✓ 3: 上边界不越界");
        else $display("✗ 3: row=%0d", cursor_row);

        // ===== 4-5: 空格翻转 =====
        press(8'h29); repeat (100) @(posedge clk);
        if (mock_bram[0][cursor_col] == 1) $display("✓ 4: 空格→活");
        else $display("✗ 4: %b", mock_bram[0][cursor_col]);
        press(8'h29); repeat (100) @(posedge clk);
        if (mock_bram[0][cursor_col] == 0) $display("✓ 5: 空格→死");
        else $display("✗ 5: %b", mock_bram[0][cursor_col]);

        // ===== 6-7: ENTER→RUN, ESC→EDIT =====
        press(8'h5A);
        if (running) $display("✓ 6: ENTER→RUN");
        else $display("✗ 6: running=%b", running);
        press(8'h76);
        if (!running && cursor_on) $display("✓ 7: ESC→EDIT");
        else $display("✗ 7: running=%b cursor_on=%b", running, cursor_on);

        // ===== 8: Backspace 清空 =====
        mock_bram[10][20] = 1;  // 放一个细胞
        press(8'h66);  // Backspace
        repeat (5000) @(posedge clk);  // 等清空完成
        if (mock_bram[10][20] == 0) $display("✓ 8: Backspace 清空网格");
        else $display("✗ 8: mock[10][20]=%b", mock_bram[10][20]);

        $display("\n========== 全部测试完成 ==========");
        $finish;
    end

    initial begin $dumpfile("ctrl_fsm_tb.vcd"); $dumpvars(0, ctrl_fsm_tb); end
endmodule
