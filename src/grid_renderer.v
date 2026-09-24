module grid_renderer (
    input  [8:0]    row_addr,
    input  [9:0]    col_addr,
    input           rdn,

    output [5:0]    grid_row,
    output [5:0]    grid_col,
    input           grid_cell,

    input           title_on,       // 封面模式
    input  [5:0]    cursor_row,
    input  [5:0]    cursor_col,

    output [11:0]   d_out
);

    assign grid_row = row_addr / 6'd10;
    assign grid_col = col_addr / 6'd10;

    wire on_grid_line = !title_on && ((row_addr % 5'd10 == 0) || (col_addr % 5'd10 == 0));
    wire is_cursor    = (grid_row == cursor_row) && (grid_col == cursor_col);

    assign d_out = rdn         ? 12'h000 :   // 消隐 → 黑
                   is_cursor   ? 12'hF88 :   // 光标 → 粉红
                   title_on    ? (grid_cell ? 12'hFFF : 12'h000) :  // 封面：白字黑底
                   on_grid_line ? 12'h666 :  // 网格线 → 灰
                   grid_cell    ? 12'h0F0 :  // 活细胞 → 绿
                                  12'h111;   // 死细胞 → 灰黑

endmodule
