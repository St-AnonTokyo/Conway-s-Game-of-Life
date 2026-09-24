module ctrl_fsm (
    input           clk,
    input           rst_n,

    input  [9:0]    key_code,      //0~7位用于按键扫描码，第8位表示通/断码（0→按下，1→松开），第9位表示扩展（0→普通键，1→扩展键）
    input           key_ready,

    input           run_mode,       // SW[2] 备用
    output          running,

    output          title_on,       // TITLE 态
    output          cursor_on,
    output          mute,           // 蜂鸣器静音
    output [5:0]    cursor_row,
    output [5:0]    cursor_col,

    // 编辑 / 清空 写入 Port B
    output          edit_we,
    output reg      edit_data,
    output [5:0]    edit_row,
    output [5:0]    edit_col,
    input           bram_dout,

    // 预设图案
    output reg [2:0] pattern_sel,
    output reg       pattern_load,
    input            pattern_done
);

    // 键码定义
    localparam [7:0]
        K_UP    = 8'h75,  K_DOWN  = 8'h72,  K_LEFT  = 8'h6B,  K_RIGHT = 8'h74,
        K_SPACE = 8'h29,  K_ENTER = 8'h5A,  K_ESC   = 8'h76,  K_BS    = 8'h66,
        K_SHIFT = 8'h12,  K_M     = 8'h3A;

    // 按键解码
    wire key_make = key_ready && !key_code[8];    // 仅通码

    wire is_up    = key_make && key_code[7:0] == K_UP    && key_code[9];
    wire is_down  = key_make && key_code[7:0] == K_DOWN  && key_code[9];
    wire is_left  = key_make && key_code[7:0] == K_LEFT  && key_code[9];
    wire is_right = key_make && key_code[7:0] == K_RIGHT && key_code[9];
    wire is_space = key_make && key_code[7:0] == K_SPACE;
    wire is_enter = key_make && key_code[7:0] == K_ENTER;
    wire is_esc   = key_make && key_code[7:0] == K_ESC;
    wire is_bs    = key_make && key_code[7:0] == K_BS;
    wire is_shift = key_make && key_code[7:0] == K_SHIFT;
    wire is_m     = key_make && key_code[7:0] == K_M;
    wire is_k1 = key_make && key_code[7:0] == 8'h16;
    wire is_k2 = key_make && key_code[7:0] == 8'h1E;
    wire is_k3 = key_make && key_code[7:0] == 8'h26;
    wire is_k4 = key_make && key_code[7:0] == 8'h25;
    wire is_k5 = key_make && key_code[7:0] == 8'h2E;
    wire is_k6 = key_make && key_code[7:0] == 8'h36;
    wire is_k7 = key_make && key_code[7:0] == 8'h3D;
    wire is_k8 = key_make && key_code[7:0] == 8'h3E;

    // TITLE → EDIT → RUN
    localparam [1:0] TITLE = 2'd0, EDIT = 2'd1, RUN = 2'd2;
    reg [1:0] mode;

    assign running   = (mode == RUN);
    assign title_on  = (mode == TITLE);
    assign cursor_on = (mode == EDIT);

    reg mute_r;
    assign mute = mute_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) mute_r <= 1'b0;
        else if (is_m) mute_r <= ~mute_r;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mode <= TITLE;      // 启动显示封面
        else case (mode)
            TITLE: if (is_shift || is_enter) mode <= EDIT;
            EDIT:  if (is_shift)              mode <= TITLE;
                   else if (is_enter)         mode <= RUN;
            RUN:   if (is_esc)                mode <= EDIT;
        endcase
    end

    // 光标移动（仅 EDIT）
    reg [5:0] cur_r, cur_c;

    assign cursor_row = cur_r;
    assign cursor_col = cur_c;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cur_r <= 6'd24;
            cur_c <= 6'd32;
        end else if (mode == EDIT) begin
            if (is_up    && cur_r > 0)     cur_r <= cur_r - 6'd1;
            if (is_down  && cur_r < 6'd47) cur_r <= cur_r + 6'd1;
            if (is_left  && cur_c > 0)     cur_c <= cur_c - 6'd1;
            if (is_right && cur_c < 6'd63) cur_c <= cur_c + 6'd1;
        end
    end

    // 翻转 / 清空（共用 edit_data）
    reg toggle_pending;
    reg toggle_write;
    reg        clearing;
    reg [11:0] clear_idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_pending <= 1'b0;
            toggle_write   <= 1'b0;
            edit_data      <= 1'b0;
            clearing       <= 1'b0;
            clear_idx      <= 12'd0;
        end else if (is_bs && mode == EDIT) begin
            clearing  <= 1'b1;
            clear_idx <= 12'd0;
            edit_data <= 1'b0;
            toggle_pending <= 1'b0;
            toggle_write   <= 1'b0;
        end else if (clearing) begin
            if (clear_idx < 12'd3072) begin
                clear_idx <= clear_idx + 12'd1;
                edit_data <= 1'b0;
            end else
                clearing <= 1'b0;
        end else if (is_space && mode == EDIT && !toggle_pending) begin
            toggle_pending <= 1'b1;
        end else if (toggle_pending) begin
            toggle_pending <= 1'b0;
            toggle_write   <= 1'b1;
            edit_data      <= !bram_dout;
        end else begin
            toggle_write   <= 1'b0;
        end
    end

    // 清空期间的地址：clear_idx → (row, col)
    wire [5:0] clear_row = clear_idx[11:6];   // /64
    wire [5:0] clear_col = clear_idx[5:0];    // %64

    // Port B 写输出（翻转/清空 二选一）
    assign edit_we  = clearing ? 1'b1 : toggle_write;
    assign edit_row = clearing ? clear_row : cur_r;
    assign edit_col = clearing ? clear_col : cur_c;
    // edit_data 已在上面 always 块中赋值（翻转时=!bram_dout），清空时保持 0

    // 预设图案（EDIT + 数字键）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_sel  <= 3'd0;
            pattern_load <= 1'b0;
        end else if (mode == EDIT) begin
            pattern_load <= 1'b0;
            if      (is_k1) begin pattern_sel <= 3'd1; pattern_load <= 1'b1; end
            else if (is_k2) begin pattern_sel <= 3'd2; pattern_load <= 1'b1; end
            else if (is_k3) begin pattern_sel <= 3'd3; pattern_load <= 1'b1; end
            else if (is_k4) begin pattern_sel <= 3'd4; pattern_load <= 1'b1; end
            else if (is_k5) begin pattern_sel <= 3'd5; pattern_load <= 1'b1; end
            else if (is_k6) begin pattern_sel <= 3'd6; pattern_load <= 1'b1; end
            else if (is_k7) begin pattern_sel <= 3'd7; pattern_load <= 1'b1; end
            else if (is_k8) begin pattern_sel <= 3'd8; pattern_load <= 1'b1; end
        end
    end

endmodule