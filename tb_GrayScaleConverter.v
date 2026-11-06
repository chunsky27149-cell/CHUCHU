
`timescale 1ns/1ps

module tb_GrayScaleConverter;

    reg clk;
    reg rst;
    reg valid_in;
    reg [7:0] red;
    reg [7:0] green;
    reg [7:0] blue;

    wire [7:0] gray;
    wire valid_out;

    integer pixel_file;
    integer output_file;
    integer scan_result;
    integer width;
    integer height;
    integer r;
    integer g;
    integer b;
    integer count;

    GrayScaleConverter dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .red(red),
        .green(green),
        .blue(blue),
        .gray(gray),
        .valid_out(valid_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        valid_in = 0;
        red = 0;
        green = 0;
        blue = 0;
        count = 0;

        pixel_file = $fopen("pixels.txt", "r");
        output_file = $fopen("gray_pixels.txt", "w");

        if (pixel_file == 0 || output_file == 0) begin
            $display("ERROR: Cannot open input/output file.");
            $finish;
        end

        scan_result = $fscanf(pixel_file, "%d %d", width, height);

        if (scan_result != 2) begin
            $display("ERROR: Cannot read image size.");
            $finish;
        end

        $fwrite(output_file, "%0d %0d\n", width, height);

        repeat (2) @(negedge clk);
        rst = 0;

        // 逐一讀取並送出所有 RGB 像素
        scan_result = $fscanf(pixel_file, "%d %d %d", r, g, b);

        while (scan_result == 3) begin

            @(negedge clk);
            red = r;
            green = g;
            blue = b;
            valid_in = 1;

            @(posedge clk);
            #1;

            if (valid_out) begin
                $fwrite(output_file, "%0d\n", gray);
                count = count + 1;
            end

            scan_result = $fscanf(pixel_file, "%d %d %d", r, g, b);
        end

        @(negedge clk);
        valid_in = 0;

        $display("Grayscale conversion completed!");
        $display("Image size: %0d x %0d", width, height);
        $display("Output pixels: %0d", count);

        if (count == width * height)
            $display("PASS: All pixels converted!");
        else
            $display("FAIL: Pixel count mismatch!");

        $fclose(pixel_file);
        $fclose(output_file);

        $finish;
    end

endmodule
