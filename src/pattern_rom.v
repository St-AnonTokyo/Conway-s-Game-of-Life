// pattern_rom.v — 预设图案 ROM
//   按键 1~6 在光标位置加载经典图案
//   通过 ctrl_fsm 的 Port B 写入 grid_bram

module pattern_rom (
    input           clk,
    input           rst_n,
    input  [2:0]    pattern_sel,    // 图案选择 1~6
    input           load,           // 开始加载脉冲
    input  [5:0]    base_row,       // 光标行（锚点）
    input  [5:0]    base_col,       // 光标列（锚点）

    // Port B 写入接口
    output reg      write_we,
    output reg      write_data,
    output reg [5:0] write_row,
    output reg [5:0] write_col,
    output reg      done
);

    // 图案定义：每个图案由最多 40 个 (dr, dc) 坐标对组成
    // dr = 行偏移，dc = 列偏移
    reg [5:0] pat_dr [0:49];
    reg [5:0] pat_dc [0:49];
    reg [5:0] pat_len;               // 图案实际长度

    reg [5:0] idx;
    reg       busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy       <= 1'b0;
            idx        <= 6'd0;
            write_we   <= 1'b0;
            write_data <= 1'b0;
            write_row  <= 6'd0;
            write_col  <= 6'd0;
            done       <= 1'b0;
        end else begin
            done <= 1'b0;

            if (load && !busy) begin
                // 选中图案，载入坐标表
                busy <= 1'b1;
                idx  <= 6'd0;
                case (pattern_sel)
                    3'd1: begin  // Glider
                        pat_dr[0]=0; pat_dc[0]=1; pat_dr[1]=1; pat_dc[1]=2;
                        pat_dr[2]=2; pat_dc[2]=0; pat_dr[3]=2; pat_dc[3]=1; pat_dr[4]=2; pat_dc[4]=2;
                        pat_len = 6'd5;
                    end
                    3'd2: begin  // Blinker
                        pat_dr[0]=0; pat_dc[0]=0; pat_dr[1]=0; pat_dc[1]=1; pat_dr[2]=0; pat_dc[2]=2;
                        pat_len = 6'd3;
                    end
                    3'd3: begin  // LWSS
                        pat_dr[0]=0; pat_dc[0]=1;
                        pat_dr[1]=1; pat_dc[1]=0; pat_dr[2]=1; pat_dc[2]=3;
                        pat_dr[3]=2; pat_dc[3]=0;
                        pat_dr[4]=3; pat_dc[4]=0; pat_dr[5]=3; pat_dc[5]=1; pat_dr[6]=3; pat_dc[6]=2; pat_dr[7]=3; pat_dc[7]=3;
                        pat_len = 6'd8;
                    end
                    3'd4: begin  // R-pentomino
                        pat_dr[0]=0; pat_dc[0]=1; pat_dr[1]=0; pat_dc[1]=2;
                        pat_dr[2]=1; pat_dc[2]=0; pat_dr[3]=1; pat_dc[3]=1;
                        pat_dr[4]=2; pat_dc[4]=1;
                        pat_len = 6'd5;
                    end
                    3'd5: begin  // Acorn
                        pat_dr[0]=0; pat_dc[0]=1;
                        pat_dr[1]=1; pat_dc[1]=3;
                        pat_dr[2]=2; pat_dc[2]=0; pat_dr[3]=2; pat_dc[3]=1; pat_dr[4]=2; pat_dc[4]=4; pat_dr[5]=2; pat_dc[5]=5; pat_dr[6]=2; pat_dc[6]=6;
                        pat_len = 6'd7;
                    end
                    3'd6: begin  // Block
                        pat_dr[0]=0; pat_dc[0]=0; pat_dr[1]=0; pat_dc[1]=1;
                        pat_dr[2]=1; pat_dc[2]=0; pat_dr[3]=1; pat_dc[3]=1;
                        pat_len = 6'd4;
                    end
                    3'd7: begin  // Pulsar (13x13, period 3, 48 cells)
                        // Row 0: cols 2,3,4,8,9,10
                        pat_dr[0]=0;pat_dc[0]=2;pat_dr[1]=0;pat_dc[1]=3;pat_dr[2]=0;pat_dc[2]=4;pat_dr[3]=0;pat_dc[3]=8;pat_dr[4]=0;pat_dc[4]=9;pat_dr[5]=0;pat_dc[5]=10;
                        // Row 2: cols 1,6,8,12
                        pat_dr[6]=2;pat_dc[6]=1;pat_dr[7]=2;pat_dc[7]=6;pat_dr[8]=2;pat_dc[8]=8;pat_dr[9]=2;pat_dc[9]=12;
                        // Row 3: cols 1,6,8,12
                        pat_dr[10]=3;pat_dc[10]=1;pat_dr[11]=3;pat_dc[11]=6;pat_dr[12]=3;pat_dc[12]=8;pat_dr[13]=3;pat_dc[13]=12;
                        // Row 4: cols 1,6,8,12
                        pat_dr[14]=4;pat_dc[14]=1;pat_dr[15]=4;pat_dc[15]=6;pat_dr[16]=4;pat_dc[16]=8;pat_dr[17]=4;pat_dc[17]=12;
                        // Row 5: cols 2,3,4,8,9,10
                        pat_dr[18]=5;pat_dc[18]=2;pat_dr[19]=5;pat_dc[19]=3;pat_dr[20]=5;pat_dc[20]=4;pat_dr[21]=5;pat_dc[21]=8;pat_dr[22]=5;pat_dc[22]=9;pat_dr[23]=5;pat_dc[23]=10;
                        // Row 7: cols 2,3,4,8,9,10
                        pat_dr[24]=7;pat_dc[24]=2;pat_dr[25]=7;pat_dc[25]=3;pat_dr[26]=7;pat_dc[26]=4;pat_dr[27]=7;pat_dc[27]=8;pat_dr[28]=7;pat_dc[28]=9;pat_dr[29]=7;pat_dc[29]=10;
                        // Row 8: cols 1,6,8,12
                        pat_dr[30]=8;pat_dc[30]=1;pat_dr[31]=8;pat_dc[31]=6;pat_dr[32]=8;pat_dc[32]=8;pat_dr[33]=8;pat_dc[33]=12;
                        // Row 9: cols 1,6,8,12
                        pat_dr[34]=9;pat_dc[34]=1;pat_dr[35]=9;pat_dc[35]=6;pat_dr[36]=9;pat_dc[36]=8;pat_dr[37]=9;pat_dc[37]=12;
                        // Row 10: cols 1,6,8,12
                        pat_dr[38]=10;pat_dc[38]=1;pat_dr[39]=10;pat_dc[39]=6;pat_dr[40]=10;pat_dc[40]=8;pat_dr[41]=10;pat_dc[41]=12;
                        // Row 12: cols 2,3,4,8,9,10
                        pat_dr[42]=12;pat_dc[42]=2;pat_dr[43]=12;pat_dc[43]=3;pat_dr[44]=12;pat_dc[44]=4;pat_dr[45]=12;pat_dc[45]=8;pat_dr[46]=12;pat_dc[46]=9;pat_dr[47]=12;pat_dc[47]=10;
                        pat_len = 6'd48;
                    end
                    3'd8: begin  // Gosper Glider Gun (36 cells, period 30)
                        pat_dr[0]=0;pat_dc[0]=24;
                        pat_dr[1]=1;pat_dc[1]=22;pat_dr[2]=1;pat_dc[2]=24;
                        pat_dr[3]=2;pat_dc[3]=12;pat_dr[4]=2;pat_dc[4]=13;pat_dr[5]=2;pat_dc[5]=20;pat_dr[6]=2;pat_dc[6]=21;pat_dr[7]=2;pat_dc[7]=34;pat_dr[8]=2;pat_dc[8]=35;
                        pat_dr[9]=3;pat_dc[9]=11;pat_dr[10]=3;pat_dc[10]=15;pat_dr[11]=3;pat_dc[11]=20;pat_dr[12]=3;pat_dc[12]=21;pat_dr[13]=3;pat_dc[13]=34;pat_dr[14]=3;pat_dc[14]=35;
                        pat_dr[15]=4;pat_dc[15]=0;pat_dr[16]=4;pat_dc[16]=1;pat_dr[17]=4;pat_dc[17]=10;pat_dr[18]=4;pat_dc[18]=16;pat_dr[19]=4;pat_dc[19]=20;pat_dr[20]=4;pat_dc[20]=21;
                        pat_dr[21]=5;pat_dc[21]=0;pat_dr[22]=5;pat_dc[22]=1;pat_dr[23]=5;pat_dc[23]=10;pat_dr[24]=5;pat_dc[24]=14;pat_dr[25]=5;pat_dc[25]=16;pat_dr[26]=5;pat_dc[26]=17;pat_dr[27]=5;pat_dc[27]=22;pat_dr[28]=5;pat_dc[28]=24;
                        pat_dr[29]=6;pat_dc[29]=10;pat_dr[30]=6;pat_dc[30]=16;pat_dr[31]=6;pat_dc[31]=24;
                        pat_dr[32]=7;pat_dc[32]=11;pat_dr[33]=7;pat_dc[33]=15;
                        pat_dr[34]=8;pat_dc[34]=12;pat_dr[35]=8;pat_dc[35]=13;
                        pat_len = 6'd36;
                    end
                    default: begin
                        pat_len = 6'd0;
                    end
                endcase
            end else if (busy) begin
                if (idx < pat_len) begin
                    // 在锚点位置写入活细胞
                    write_we   <= 1'b1;
                    write_data <= 1'b1;
                    write_row  <= base_row + pat_dr[idx];
                    write_col  <= base_col + pat_dc[idx];
                    idx        <= idx + 6'd1;
                end else begin
                    write_we <= 1'b0;
                    busy     <= 1'b0;
                    done     <= 1'b1;
                    idx      <= 6'd0;
                end
            end
        end
    end

endmodule
