module tick_gen (
    input           clk,
    input           rst_n,
    input  [1:0]    speed,      // 速度档位0~3
    output reg      start       // 单周期脉冲
);

    // 速度档位（100MHz下）
    // 0: 1 代/秒   → 计数 100_000_000
    // 1: 4 代/秒   → 计数  25_000_000
    // 2: 16 代/秒  → 计数   6_250_000
    // 3: 64 代/秒  → 计数   1_562_500
    reg [31:0] counter;
    reg [31:0] threshold;

    always @(*) begin
        case (speed)
            2'd0: threshold = 32'd100_000_000;
            2'd1: threshold = 32'd25_000_000;
            2'd2: threshold = 32'd6_250_000;
            2'd3: threshold = 32'd1_562_500;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin   //分频器逻辑
        if (!rst_n) begin
            counter <= 32'd0;
            start   <= 1'b0;
        end else begin
            start <= 1'b0;
            if (counter >= threshold - 1) begin
                counter <= 32'd0;
                start   <= 1'b1;
            end else begin
                counter <= counter + 32'd1;
            end
        end
    end

endmodule