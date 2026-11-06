
`timescale 1ns/1ps

module tb_ColorPacketGenerator;

    reg clk;
    reg rst;
    reg start;

    reg [31:0] frame_id;
    reg [15:0] width;
    reg [15:0] height;
    reg [7:0] pixel_format;
    reg [31:0] payload_size;

    reg [7:0] payload_data;
    reg payload_valid;

    wire [7:0] packet_data;
    wire packet_valid;
    wire packet_last;
    wire busy;

    integer pixel_file;
    integer output_file;
    integer scan_result;
    integer red_value;
    integer green_value;
    integer blue_value;
    integer image_width;
    integer image_height;
    integer count;
    integer byte_count;

    PacketGenerator dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .frame_id(frame_id),
        .width(width),
        .height(height),
        .pixel_format(pixel_format),
        .payload_size(payload_size),
        .payload_data(payload_data),
        .payload_valid(payload_valid),
        .packet_data(packet_data),
        .packet_valid(packet_valid),
        .packet_last(packet_last),
        .busy(busy)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 在下降沿寫入封包
    always @(negedge clk) begin
        if (packet_valid) begin
            $fwrite(output_file, "%c", packet_data);
            byte_count = byte_count + 1;
        end
    end

    initial begin
        rst = 1;
        start = 0;
        payload_valid = 0;
        payload_data = 0;

        frame_id = 1;
        width = 64;
        height = 64;
        pixel_format = 3;       // RGB24
        payload_size = 12288;   // 64 * 64 * 3

        count = 0;
        byte_count = 0;

        pixel_file = $fopen("pixels.txt", "r");
        output_file = $fopen("color_packet.bin", "wb");

        if (pixel_file == 0 || output_file == 0) begin
            $display("ERROR: Cannot open files!");
            $finish;
        end

        scan_result = $fscanf(
            pixel_file, "%d %d",
            image_width, image_height
        );

        if (scan_result != 2 ||
            image_width != 64 ||
            image_height != 64) begin
            $display("ERROR: Image size mismatch!");
            $finish;
        end

        repeat (2) @(negedge clk);
        rst = 0;

        @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        wait (busy == 1'b1);
        wait (dut.state == 3'd2);

        // 依序輸入 R、G、B 三個通道
        scan_result = $fscanf(
            pixel_file, "%d %d %d",
            red_value, green_value, blue_value
        );

        while (scan_result == 3) begin

            @(negedge clk);
            payload_data = red_value[7:0];
            payload_valid = 1;

            @(negedge clk);
            payload_data = green_value[7:0];

            @(negedge clk);
            payload_data = blue_value[7:0];

            @(negedge clk);
            payload_valid = 0;

            count = count + 1;

            scan_result = $fscanf(
                pixel_file, "%d %d %d",
                red_value, green_value, blue_value
            );
        end

        wait (packet_last == 1'b1);
        @(negedge clk);

        $fclose(pixel_file);
        $fclose(output_file);

        $display("Color packet generation completed!");
        $display("Image size: %0d x %0d",
                 image_width, image_height);
        $display("Payload pixels: %0d", count);
        $display("Packet bytes: %0d", byte_count);

        if (byte_count == 12311 && count == 4096)
            $display("PASS: Color packet size is correct!");
        else
            $display("FAIL: Packet size mismatch!");

        $finish;
    end

endmodule
