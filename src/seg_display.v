// seg_display.v — 4 位七段数码管，显示活细胞数（hex）

module seg_display (
    input           clk, rst_n,
    input  [11:0]   alive_count,
    output reg [3:0] an,
    output reg [7:0] segment
);

    function [7:0] seg;
        input [3:0] d;
        case (d)
            4'h0: seg = 8'h3F; 4'h1: seg = 8'h06; 4'h2: seg = 8'h5B; 4'h3: seg = 8'h4F;
            4'h4: seg = 8'h66; 4'h5: seg = 8'h6D; 4'h6: seg = 8'h7D; 4'h7: seg = 8'h07;
            4'h8: seg = 8'h7F; 4'h9: seg = 8'h6F; 4'hA: seg = 8'h77; 4'hB: seg = 8'h7C;
            4'hC: seg = 8'h39; 4'hD: seg = 8'h5E; 4'hE: seg = 8'h79; 4'hF: seg = 8'h71;
        endcase
    endfunction

    reg [16:0] cnt;
    reg [1:0]  digit;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0; digit <= 0; an <= 4'b1111; segment <= 8'h00;
        end else begin
            if (cnt == 17'd100_000) begin
                cnt <= 0;
                digit <= digit + 2'd1;
                // 扫描：一次更新 an 和 segment
                case (digit)
                    2'd0: begin an <= 4'b1110; segment <= ~seg(alive_count[3:0]);  end
                    2'd1: begin an <= 4'b1101; segment <= ~seg(alive_count[7:4]);  end
                    2'd2: begin an <= 4'b1011; segment <= ~seg(alive_count[11:8]); end
                    2'd3: begin an <= 4'b0111; segment <= ~seg(4'h0);              end
                endcase
            end else begin
                cnt <= cnt + 17'd1;
            end
        end
    end

endmodule
