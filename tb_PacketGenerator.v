
`timescale 1ns/1ps

module tb_PacketGenerator;

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

    integer file;
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
        .packet_last(packet_last)
    );

    // 10ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Record packet bytes
    always @(negedge clk) begin
        if (packet_valid) begin
            $fwrite(file, "%c", packet_data);
            byte_count = byte_count + 1;

            if (packet_last)
                $display("Packet LAST detected!");
        end
    end

    initial begin
        file = $fopen("D:/FPGA_FramePacket/test_packet.bin", "wb");

        if (file == 0) begin
            $display("ERROR: Cannot open output file!");
            $finish;
        end

        byte_count = 0;

        rst = 1;
        start = 0;
        frame_id = 1;
        width = 2;
        height = 1;
        pixel_format = 1;
        payload_size = 2;
        payload_data = 0;
        payload_valid = 0;

        repeat (3) @(negedge clk);
        rst = 0;

        @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        // Wait until PAYLOAD state
        wait (dut.state == 3'd2);

        @(negedge clk);
        payload_data = 8'h10;
        payload_valid = 1;

        @(negedge clk);
        payload_data = 8'h20;

        @(negedge clk);
        payload_valid = 0;

        wait (packet_last == 1);

        @(negedge clk);
        #1;
        $fclose(file);

        $display("Packet output finished.");
        $display("Total bytes = %0d", byte_count);

        if (byte_count == 25)
            $display("PASS: Packet length is correct.");
        else
            $display("FAIL: Packet length is incorrect.");

        #20;
        $finish;
    end

    initial begin
        #10000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
