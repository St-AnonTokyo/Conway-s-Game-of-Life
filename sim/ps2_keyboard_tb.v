// ps2_keyboard_tb.v — PS/2 键盘解码验证（带调试）
`timescale 1ns / 1ps

module ps2_keyboard_tb;

    reg         clk;
    reg         rst_n;
    reg         ps2_clk;
    reg         ps2_data;
    wire [9:0]  key_code;
    wire        key_ready;

    ps2_keyboard uut (
        .clk        (clk),
        .rst_n      (rst_n),
        .ps2_clk    (ps2_clk),
        .ps2_data   (ps2_data),
        .key_code   (key_code),
        .key_ready  (key_ready)
    );

    always #5 clk = ~clk;

    // PS/2 时钟生成：手动控制（空闲=高，发帧时才翻转）
    task ps2_tick;
        begin
            ps2_clk = 1; #10000;
            ps2_clk = 0; #10000;
            ps2_clk = 1; #10000;
        end
    endtask

    // 发送一帧：11 个 ps2_tick
    task send_ps2_byte;
        input [7:0] data;
        integer i;
        reg parity;
        begin
            parity = ^data;
            $display("  [tb t=%0t] → 起始位", $time);
            ps2_data = 1'b0; ps2_tick;
            for (i = 0; i < 8; i = i + 1) begin
                ps2_data = data[i]; ps2_tick;
                $display("  [tb t=%0t] → bit%0d=%b", $time, i, data[i]);
            end
            ps2_data = ~parity; ps2_tick;
            $display("  [tb t=%0t] → 校验", $time);
            ps2_data = 1'b1;    ps2_tick;
            $display("  [tb t=%0t] → 停止位", $time);
        end
    endtask

    // 捕获 key_ready 脉冲
    reg got_ready;
    always @(posedge key_ready) got_ready <= 1'b1;

    initial begin
        clk = 0;
        rst_n = 0;
        ps2_clk = 1;
        ps2_data = 1;
        got_ready = 0;

        #200 rst_n = 1;
        #50000;

        $display("========== W 键通码 (1D) ==========");
        got_ready = 0; send_ps2_byte(8'h1D);
        wait(got_ready);
        $display("✓ W通码: %h (exp=%b brk=%b scan=%h)",
            key_code, key_code[9], key_code[8], key_code[7:0]);

        $display("========== F0 断码前缀 ==========");
        got_ready = 0; send_ps2_byte(8'hF0);
        #50000;
        if (!got_ready)
            $display("✓ F0被拦截");

        $display("========== W 键断码 (F0+1D) ==========");
        got_ready = 0; send_ps2_byte(8'h1D);
        wait(got_ready);
        $display("✓ W断码: %h (brk=%b)", key_code, key_code[8]);

        $display("========== ↑ 箭头 (E0+75) ==========");
        got_ready = 0; send_ps2_byte(8'hE0); #20000;
        send_ps2_byte(8'h75);
        wait(got_ready);
        $display("✓ ↑通码: %h (exp=%b scan=%h)", key_code, key_code[9], key_code[7:0]);

        $display("\n========== 全部测试完成 ==========");
        $finish;
    end

    initial begin
        $dumpfile("ps2_keyboard_tb.vcd");
        $dumpvars(0, ps2_keyboard_tb);
    end

endmodule
