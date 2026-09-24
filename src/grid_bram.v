module grid_bram (
    // Port A — VGA 只读
    input           clk_a,          // VGA 时钟域（25MHz）
    input  [5:0]    addr_a_row,     // 行地址 0~47
    input  [5:0]    addr_a_col,     // 列地址 0~63
    output reg      dout_a,         // 读出数据：该格细胞状态

    // Port B — Game Core 读写
    input           clk_b,          // 系统时钟域（100MHz）
    input  [5:0]    addr_b_row,     // 行地址 0~47
    input  [5:0]    addr_b_col,     // 列地址 0~63
    input           we_b,           // 写使能
    input           din_b,          // 写入数据
    output reg      dout_b          // 读出数据
);

    // 网格存储：48 行 × 64 列 × 1 bit
    reg [0:0] grid [0:47][0:63];

    // 封面 "GAME OF LIFE"（7×5 字体，居中两行）
    integer init_r, init_c;
    initial begin
        for (init_r = 0; init_r < 48; init_r = init_r + 1) begin
            for (init_c = 0; init_c < 64; init_c = init_c + 1) begin
                grid[init_r][init_c] = 1'b0;
            end
        end

        // ===== 上行 "GAME" (row 14-20, col 3-27) =====
        // G (col 3-7)
        grid[14][4]=1;grid[14][5]=1;grid[14][6]=1; grid[15][3]=1;grid[15][7]=1;
        grid[16][3]=1; grid[17][3]=1;grid[17][5]=1;grid[17][6]=1;grid[17][7]=1;
        grid[18][3]=1;grid[18][7]=1; grid[19][3]=1;grid[19][7]=1;
        grid[20][4]=1;grid[20][5]=1;grid[20][6]=1;
        // A (col 9-13)
        grid[14][10]=1;grid[14][11]=1;grid[14][12]=1; grid[15][9]=1;grid[15][13]=1;
        grid[16][9]=1;grid[16][13]=1; grid[17][9]=1;grid[17][10]=1;grid[17][11]=1;grid[17][12]=1;grid[17][13]=1;
        grid[18][9]=1;grid[18][13]=1; grid[19][9]=1;grid[19][13]=1; grid[20][9]=1;grid[20][13]=1;
        // M (col 15-20)
        grid[14][15]=1;grid[14][20]=1; grid[15][15]=1;grid[15][16]=1;grid[15][19]=1;grid[15][20]=1;
        grid[16][15]=1;grid[16][17]=1;grid[16][19]=1;grid[16][20]=1;
        grid[17][15]=1;grid[17][18]=1;grid[17][20]=1;
        grid[18][15]=1;grid[18][20]=1; grid[19][15]=1;grid[19][20]=1; grid[20][15]=1;grid[20][20]=1;
        // E (col 22-27)
        grid[14][22]=1;grid[14][23]=1;grid[14][24]=1;grid[14][25]=1;grid[14][26]=1;grid[14][27]=1;
        grid[15][22]=1; grid[16][22]=1;grid[16][23]=1;grid[16][24]=1;grid[16][25]=1;grid[16][26]=1;grid[16][27]=1;
        grid[17][22]=1; grid[18][22]=1; grid[19][22]=1;
        grid[20][22]=1;grid[20][23]=1;grid[20][24]=1;grid[20][25]=1;grid[20][26]=1;grid[20][27]=1;

        // ===== 下行 "OF LIFE" (row 24-30, col 15-56) =====
        // O (col 15-19)
        grid[24][16]=1;grid[24][17]=1;grid[24][18]=1; grid[25][15]=1;grid[25][19]=1;
        grid[26][15]=1;grid[26][19]=1; grid[27][15]=1;grid[27][19]=1;
        grid[28][15]=1;grid[28][19]=1; grid[29][15]=1;grid[29][19]=1;
        grid[30][16]=1;grid[30][17]=1;grid[30][18]=1;
        // F (col 22-27)
        grid[24][22]=1;grid[24][23]=1;grid[24][24]=1;grid[24][25]=1;grid[24][26]=1;grid[24][27]=1;
        grid[25][22]=1; grid[26][22]=1;grid[26][23]=1;grid[26][24]=1;grid[26][25]=1;grid[26][26]=1;grid[26][27]=1;
        grid[27][22]=1; grid[28][22]=1; grid[29][22]=1; grid[30][22]=1;
        // space (col 29-33) — blank
        // L (col 35-40)
        grid[24][35]=1; grid[25][35]=1; grid[26][35]=1; grid[27][35]=1;
        grid[28][35]=1; grid[29][35]=1;
        grid[30][35]=1;grid[30][36]=1;grid[30][37]=1;grid[30][38]=1;grid[30][39]=1;grid[30][40]=1;
        // I (col 42-46)
        grid[24][42]=1;grid[24][43]=1;grid[24][44]=1;grid[24][45]=1;grid[24][46]=1;
        grid[25][44]=1; grid[26][44]=1; grid[27][44]=1; grid[28][44]=1; grid[29][44]=1;
        grid[30][42]=1;grid[30][43]=1;grid[30][44]=1;grid[30][45]=1;grid[30][46]=1;
        // F (col 48-53)
        grid[24][48]=1;grid[24][49]=1;grid[24][50]=1;grid[24][51]=1;grid[24][52]=1;grid[24][53]=1;
        grid[25][48]=1; grid[26][48]=1;grid[26][49]=1;grid[26][50]=1;grid[26][51]=1;grid[26][52]=1;grid[26][53]=1;
        grid[27][48]=1; grid[28][48]=1; grid[29][48]=1; grid[30][48]=1;
        // E (col 55-60)
        grid[24][55]=1;grid[24][56]=1;grid[24][57]=1;grid[24][58]=1;grid[24][59]=1;grid[24][60]=1;
        grid[25][55]=1; grid[26][55]=1;grid[26][56]=1;grid[26][57]=1;grid[26][58]=1;grid[26][59]=1;grid[26][60]=1;
        grid[27][55]=1; grid[28][55]=1; grid[29][55]=1;
        grid[30][55]=1;grid[30][56]=1;grid[30][57]=1;grid[30][58]=1;grid[30][59]=1;grid[30][60]=1;

    end

    // Port A: VGA 读取（同步读）
    always @(posedge clk_a) begin
        dout_a <= grid[addr_a_row][addr_a_col];
    end

    // Port B: Game Core 读写（同步读写）
    always @(posedge clk_b) begin
        if (we_b) begin
            grid[addr_b_row][addr_b_col] <= din_b;
        end
        dout_b <= grid[addr_b_row][addr_b_col];
    end

endmodule