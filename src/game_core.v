module game_core (
    input           clk,
    input           rst_n,
    input           start,

    output [5:0]    bram_row,
    output [5:0]    bram_col,
    output          bram_we,
    output          bram_din,
    input           bram_dout,

    output reg      gen_done,
    output [11:0]   alive_count     // 活细胞数量
);

    //遍历过程中的各个阶段
    localparam [2:0]
        IDLE      = 3'd0,   // 初始状态
        PREREAD0  = 3'd1,   // 预读 row 0 → buf_mid
        PREREAD1  = 3'd2,   // 预读 row 1 → buf_bot
        READ_NEXT = 3'd3,   // 读 row r+2 → buf_temp（读新的行）
        COMPUTE   = 3'd4,   // 计算buf_mid的64 列细胞的下一个状态
        WRITEBACK = 3'd5,   // 写上一行 + 缓冲轮换 buf_temp → buf_bot → buf_mid → buf_top
        CLEANUP   = 3'd6;   // 清空缓存同时写最后一行

    reg [2:0] state;

    // 计数用
    reg [5:0] row;          //行进度
    reg [6:0] col;          //列进度
    reg       first;        // 每轮 BRAM 读的第一个周期

    // 行缓冲
    reg [63:0] buf_top;
    reg [63:0] buf_mid;
    reg [63:0] buf_bot;
    reg [63:0] buf_temp;    //缓存下一行
    reg [63:0] result_delay; //缓存这一行的result
    reg [63:0] result_next;  //上一行的result
    reg [11:0] alive_cnt;
    assign alive_count = alive_cnt;

    // BRAM 接口
    wire do_read  = (state == PREREAD0) || (state == PREREAD1)    //BRAM读取
                 || (state == READ_NEXT);      
    wire do_write = (state == WRITEBACK && row > 6'd0)            //BRAM写入
                 || (state == CLEANUP);
    // 读取的地址
    wire [5:0] rd_row = (state == PREREAD0) ? 6'd0
                      : (state == PREREAD1) ? 6'd1
                      : (row + 6'd2);
    // 写入的地址
    wire [5:0] wr_row = (state == CLEANUP) ? 6'd47 : (row - 6'd1);

    assign bram_row = do_read ? rd_row : wr_row;
    assign bram_col = col[5:0];
    assign bram_we  = do_write;
    assign bram_din = result_delay[col[5:0]];

    // Conway 规则
    function cell_next;
        input [63:0]  top, mid, bot;
        input [5:0]   c; //column
        reg   [3:0]   cnt;
        begin
            cnt = 4'd0;   //算九宫格中的总存活数
            if (c > 0) begin   
                         cnt = cnt + {3'b0, top[c-1]};
                         cnt = cnt + {3'b0, mid[c-1]};
                         cnt = cnt + {3'b0, bot[c-1]};
            end

            if (c < 63) begin
                         cnt = cnt + {3'b0, top[c+1]};  
                         cnt = cnt + {3'b0, mid[c+1]};
                         cnt = cnt + {3'b0, bot[c+1]};
            end
            
            
            cnt = cnt + {3'b0, top[c]};
            cnt = cnt + {3'b0, bot[c]};

            cell_next = (mid[c])?(cnt==4'd2||cnt==4'd3)?1'b1:1'b0:(cnt==4'd3)?1'b1:1'b0;
        end
    endfunction

    // 主状态机 + 时序逻辑
    always @(posedge clk or negedge rst_n) begin //rst_n is the reset button which is effective when it swifts from 1 to 0
        if (!rst_n) begin
            state        <= IDLE;
            row          <= 6'd0;
            col          <= 7'd0;
            first        <= 1'b0;
            buf_top      <= 64'd0;
            buf_mid      <= 64'd0;
            buf_bot      <= 64'd0;
            buf_temp     <= 64'd0;
            result_delay <= 64'd0;
            result_next  <= 64'd0;
            alive_cnt    <= 12'd0;
            gen_done     <= 1'b0;
        end else begin
            gen_done <= 1'b0;

            case (state)

                IDLE: begin      //初始化
                    col <= 7'd0;
                    first <= 1'b0;
                    if (start) begin
                        row        <= 6'd0;
                        buf_top    <= 64'd0;
                        buf_temp   <= 64'd0;
                        alive_cnt  <= 12'd0;      // 每代重新计数
                        state      <= PREREAD0;   //执行完毕后进入下一阶段（下同）
                    end
                end

                PREREAD0: begin      //读第0行的数据到buf_mid
                    if (!first) begin      //使用first来初始化
                        col   <= 7'd1;
                        first <= 1'b1;
                    end else if (col < 65) begin
                        buf_mid[col[5:0] - 1'b1] <= bram_dout;
                        col <= col + 7'd1;
                    end else begin
                        first <= 1'b0;
                        state <= PREREAD1;
                    end
                end

                PREREAD1: begin       //读第1行数据到buf_bot
                    if (!first) begin
                        col   <= 7'd1;
                        first <= 1'b1;
                    end else if (col < 65) begin
                        buf_bot[col[5:0] - 1'b1] <= bram_dout;
                        col <= col + 7'd1;
                    end else begin
                        col   <= 7'd0;
                        first <= 1'b0;
                        state <= READ_NEXT;
                    end
                end

                READ_NEXT: begin      //读下一行
                    if (row + 6'd2 >= 6'd48) begin
                        buf_temp <= 64'd0;
                        col   <= 7'd0;
                        first <= 1'b0;
                        state <= COMPUTE;
                    end else if (!first) begin
                        col   <= 7'd1;
                        first <= 1'b1;
                    end else if (col < 65) begin
                        buf_temp[col[5:0] - 1'b1] <= bram_dout;
                        col <= col + 7'd1;
                    end else begin
                        col   <= 7'd0;
                        first <= 1'b0;
                        state <= COMPUTE;
                    end
                end

                COMPUTE: begin           //计算细胞的下一个状态
                    if (col < 64) begin
                        result_next[col[5:0]] <= cell_next(     //存入result_next
                            buf_top, buf_mid, buf_bot, col[5:0]
                        );
                        alive_cnt <= alive_cnt + {11'b0, buf_mid[col[5:0]]};
                        col <= col + 7'd1;
                    end else begin
                        col   <= 7'd0;
                        state <= WRITEBACK;
                    end
                end

                WRITEBACK: begin        //将数据传给BRAM写入
                    if (col < 64) begin
                        // we_b=1 时 BRAM 自动写入（row>0）
                        col <= col + 7'd1;
                    end else begin
                        // 缓冲轮换
                        col          <= 7'd0;
                        buf_top      <= buf_mid;
                        buf_mid      <= buf_bot;
                        buf_bot      <= buf_temp;
                        result_delay <= result_next;
                        row          <= row + 6'd1;

                        if (row < 6'd48) begin
                            state <= READ_NEXT;    // 还有行要处理
                        end else begin
                            state <= CLEANUP;      // 全部算完
                        end
                    end
                end

                CLEANUP: begin
                    if (col < 64) begin
                        col <= col + 7'd1;
                    end else begin
                        gen_done <= 1'b1;  //结束遍历
                        state    <= IDLE;  //恢复初始状态
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule