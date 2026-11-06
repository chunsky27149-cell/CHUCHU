module GrayScaleConverter (
    input  wire       clk,
    input  wire       rst,
    input  wire       valid_in,
    input  wire [7:0] red,
    input  wire [7:0] green,
    input  wire [7:0] blue,
    output reg  [7:0] gray,
    output reg        valid_out
);

    // RGB 轉灰階：約 gray = 0.299R + 0.587G + 0.114B
    wire [15:0] r_part = red   * 8'd77;
    wire [15:0] g_part = green * 8'd150;
    wire [15:0] b_part = blue  * 8'd29;
    wire [17:0] sum = r_part + g_part + b_part;

    always @(posedge clk) begin
        if (rst) begin
            gray      <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;

            if (valid_in)
                gray <= sum[15:8];
        end
    end

endmodule