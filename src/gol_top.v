// gol_top.v — 康威生命游戏顶层模块 (Phase 2)
// 时钟: 32bit计数器 clkdiv[1] = 25MHz
// 模块: tick_gen → game_core → grid_bram ← grid_renderer ← vgac

module gol_top (
    input           clk,            // 100MHz (AC18)
    input           rst_n,          // 复位按钮

    // 拨码开关
    input  [1:0]    speed,         // SW[1:0]: 速度档位
    input           run_mode,      // SW[2]: 0=编辑 1=运行

    // PS/2 键盘
    input           ps2_clk,
    input           ps2_data,

    output [3:0]    vga_r,
    output [3:0]    vga_g,
    output [3:0]    vga_b,
    output          vga_hs,
    output          vga_vs,

    // 蜂鸣器 + 数码管
    output          buzzer,
    output [3:0]    AN,
    output [7:0]    SEGMENT
);

    // =================== 时钟 ===================
    reg [31:0] clkdiv;
    always @(posedge clk) begin
        clkdiv <= clkdiv + 1'b1;
    end
    wire vga_clk = clkdiv[1];   // 25MHz

    // =================== 互联信号 ===================
    wire [11:0] vga_d_in;
    wire [8:0]  row_addr;
    wire [9:0]  col_addr;
    wire        rdn;
    wire [5:0]  grid_row, grid_col;
    wire        grid_cell;

    // Game Core ↔ BRAM
    wire [5:0]  gc_row, gc_col;
    wire        gc_we, gc_din, gc_dout;

    // 光标 / 编辑
    wire        title_on, cursor_on, mute;
    wire [5:0]  cursor_row, cursor_col;
    wire        edit_we, edit_data;
    wire [5:0]  edit_row, edit_col;
    wire        running;

    // 预设图案
    wire [2:0]  pat_sel;
    wire        pat_load, pat_done;
    wire        pat_we, pat_data;
    wire [5:0]  pat_row, pat_col;

    // PS/2 解码
    wire [9:0]  ps2_key;
    wire        ps2_ready;

    // Tick → Game Core
    wire        tick_start;
    wire        gen_done;       // 一代完成
    wire [11:0] alive_count;    // 活细胞数
    reg  [19:0] gen_count;      // 代数计数（5 位 hex）

    // Port B 多路切换：图案 > Game Core > 编辑器
    wire        pat_busy = pat_load || pat_we;
    wire [5:0]  bram_b_row   = pat_busy ? pat_row : (running ? gc_row    : edit_row);
    wire [5:0]  bram_b_col   = pat_busy ? pat_col : (running ? gc_col    : edit_col);
    wire        bram_b_we    = pat_busy ? pat_we  : (running ? gc_we     : edit_we);
    wire        bram_b_din   = pat_busy ? pat_data: (running ? gc_din    : edit_data);
    wire        bram_b_dout;

    // =================== PS/2 键盘解码 ===================
    ps2_keyboard u_ps2 (
        .clk        (clk),
        .rst_n      (rst_n),
        .ps2_clk    (ps2_clk),
        .ps2_data   (ps2_data),
        .key_code   (ps2_key),
        .key_ready  (ps2_ready)
    );

    // =================== 控制状态机（光标编辑 + 运行切换） ===================
    ctrl_fsm u_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .key_code   (ps2_key),
        .key_ready  (ps2_ready),
        .run_mode   (run_mode),
        .running    (running),
        .title_on   (title_on),
        .cursor_on  (cursor_on),
        .mute       (mute),
        .cursor_row (cursor_row),
        .cursor_col (cursor_col),
        .edit_we    (edit_we),
        .edit_data  (edit_data),
        .edit_row   (edit_row),
        .edit_col   (edit_col),
        .bram_dout  (bram_b_dout),
        .pattern_sel(pat_sel),
        .pattern_load(pat_load),
        .pattern_done(pat_done)
    );

    // =================== 预设图案 ROM ===================
    pattern_rom u_pattern (
        .clk        (clk),
        .rst_n      (rst_n),
        .pattern_sel(pat_sel),
        .load       (pat_load),
        .base_row   (cursor_row),
        .base_col   (cursor_col),
        .write_we   (pat_we),
        .write_data (pat_data),
        .write_row  (pat_row),
        .write_col  (pat_col),
        .done       (pat_done)
    );

    // =================== Tick Generator（仅在 RUNNING 态工作） ===================
    tick_gen u_tick (
        .clk        (clk),
        .rst_n      (rst_n),
        .speed      (speed),
        .start      (tick_start)
    );

    // =================== Game Core ===================
    game_core u_game_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (tick_start && running),
        .bram_row   (gc_row),
        .bram_col   (gc_col),
        .bram_we    (gc_we),
        .bram_din   (gc_din),
        .bram_dout  (bram_b_dout),
        .gen_done   (gen_done),
        .alive_count(alive_count)
    );

    // =================== 代数计数器 ===================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gen_count <= 20'd0;
        else if (gen_done)
            gen_count <= gen_count + 20'd1;
    end

    // =================== 蜂鸣器 ===================
    buzzer u_buzzer (
        .clk        (clk),
        .rst_n      (rst_n),
        .gen_done   (gen_done && !mute),
        .beep       (buzzer)
    );

    // =================== 七段数码管 ===================
    seg_display u_seg (
        .clk        (clk),
        .rst_n      (rst_n),
        .alive_count(alive_count),
        .an         (AN),
        .segment    (SEGMENT)
    );

    // =================== Grid BRAM ===================
    grid_bram u_grid_bram (
        .clk_a      (vga_clk),
        .addr_a_row (grid_row),
        .addr_a_col (grid_col),
        .dout_a     (grid_cell),
        // Port B → 经多路切换器
        .clk_b      (clk),
        .addr_b_row (bram_b_row),
        .addr_b_col (bram_b_col),
        .we_b       (bram_b_we),
        .din_b      (bram_b_din),
        .dout_b     (bram_b_dout)
    );

    // =================== Grid Renderer ===================
    grid_renderer u_grid_renderer (
        .row_addr   (row_addr),
        .col_addr   (col_addr),
        .rdn        (rdn),
        .grid_row   (grid_row),
        .grid_col   (grid_col),
        .grid_cell  (grid_cell),
        .title_on   (title_on),
        .cursor_row (cursor_on ? cursor_row : 6'd48),
        .cursor_col (cursor_on ? cursor_col : 6'd63),
        .d_out      (vga_d_in)
    );

    // =================== VGA 驱动 ===================
    vgac u_vgac (
        .vga_clk    (vga_clk),
        .clrn       (rst_n),
        .d_in       (vga_d_in),
        .row_addr   (row_addr),
        .col_addr   (col_addr),
        .rdn        (rdn),
        .r          (vga_r),
        .g          (vga_g),
        .b          (vga_b),
        .hs         (vga_hs),
        .vs         (vga_vs)
    );

endmodule
