
`timescale 1ns/1ps

module tb_GrayPacketGenerator;

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

    integer gray_file;
    integer output_file;
    integer scan_result;
    integer gray_value;
    integer image_width;
    integer image_height;
    integer count;
    integer byte_count;

    // PacketGenerator
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

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Write packet bytes at the falling edge
    always @(negedge clk) begin
        if (packet_valid) begin
            $fwrite(output_file, "%c", packet_data);
            byte_count = byte_count + 1;
        end
    end

    initial begin

        // Initial values
        rst = 1;
        start = 0;
        payload_valid = 0;
        payload_data = 0;

        frame_id = 1;
        width = 64;
        height = 64;
        pixel_format = 1;
        payload_size = 4096;

        count = 0;
        byte_count = 0;

        // Open files
        gray_file = $fopen("gray_pixels.txt", "r");
        output_file = $fopen("gray_packet.bin", "wb");

        if (gray_file == 0 || output_file == 0) begin
            $display("ERROR: Cannot open files!");
            $finish;
        end

        // Read image size
        scan_result = $fscanf(
            gray_file,
            "%d %d",
            image_width,
            image_height
        );

        if (scan_result != 2) begin
            $display("ERROR: Cannot read image size!");
            $finish;
        end

        if (image_width != 64 || image_height != 64) begin
            $display("ERROR: Image size mismatch!");
            $finish;
        end

        // Reset
        repeat (2) @(negedge clk);
        rst = 0;

        // Start packet generation
        @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        // Wait for PacketGenerator to become busy
        wait (busy == 1'b1);

        // Wait until PAYLOAD state
        wait (dut.state == 3'd2);

        // Read and send grayscale pixels
        scan_result = $fscanf(gray_file, "%d", gray_value);

        while (scan_result == 1) begin

            @(negedge clk);
            payload_data = gray_value[7:0];
            payload_valid = 1;

            @(negedge clk);
            payload_valid = 0;

            count = count + 1;

            scan_result = $fscanf(
                gray_file,
                "%d",
                gray_value
            );
        end

        // Check payload count
        if (count != 4096) begin
            $display("ERROR: Payload count mismatch!");
            $display("Expected: 4096");
            $display("Actual: %0d", count);
        end

        // Wait until packet transmission finishes
        wait (packet_last == 1'b1);

        // Allow final byte to be written
        @(negedge clk);

        // Close files
        $fclose(gray_file);
        $fclose(output_file);

        // Display result
        $display("Gray packet generation completed!");
        $display("Image size: %0d x %0d",
                 image_width, image_height);
        $display("Payload pixels: %0d", count);
        $display("Packet bytes: %0d", byte_count);

        if (byte_count == 4119 && count == 4096) begin
            $display("PASS: Gray packet size is correct!");
        end
        else begin
            $display("FAIL: Packet size mismatch!");
        end

        $finish;

    end

endmodule
