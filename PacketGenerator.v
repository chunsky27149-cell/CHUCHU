
module PacketGenerator (
    input wire clk,
    input wire rst,

    input wire start,

    input wire [31:0] frame_id,
    input wire [15:0] width,
    input wire [15:0] height,
    input wire [7:0] pixel_format,
    input wire [31:0] payload_size,

    input wire [7:0] payload_data,
    input wire payload_valid,

    output reg [7:0] packet_data,
    output reg packet_valid,
    output reg packet_last,
    output reg busy
);

    localparam IDLE = 3'd0;
    localparam HEADER = 3'd1;
    localparam PAYLOAD = 3'd2;
    localparam CRC_WAIT = 3'd3;
    localparam CRC_SEND = 3'd4;

    reg [2:0] state;

    reg [151:0] header;
    reg [4:0] header_index;

    reg [31:0] payload_count;

    reg crc_reset;
    reg [31:0] crc_saved;
    reg [1:0] crc_index;

    wire [151:0] header_wire;

    wire [31:0] crc_out;
    wire crc_done;

    wire crc_valid;
    wire crc_last;

    PacketHeader header_unit (
        .frame_id(frame_id),
        .width(width),
        .height(height),
        .pixel_format(pixel_format),
        .payload_size(payload_size),
        .header(header_wire)
    );

    assign crc_valid = (state == PAYLOAD) && payload_valid;

    assign crc_last =
        crc_valid &&
        (payload_count == payload_size - 1'b1);

    CRC32 crc_unit (
        .clk(clk),
        .rst(rst | crc_reset),
        .valid_in(crc_valid),
        .data_in(payload_data),
        .last_in(crc_last),
        .crc_out(crc_out),
        .valid_out(crc_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;

            header <= 0;
            header_index <= 0;
            payload_count <= 0;

            packet_data <= 0;
            packet_valid <= 0;
            packet_last <= 0;
            busy <= 0;

            crc_reset <= 0;
            crc_saved <= 0;
            crc_index <= 0;
        end
        else begin

            packet_valid <= 0;
            packet_last <= 0;
            crc_reset <= 0;

            case (state)

                IDLE: begin
                    busy <= 0;

                    if (start) begin
                        header <= header_wire;

                        header_index <= 0;
                        payload_count <= 0;

                        crc_reset <= 1;

                        state <= HEADER;
                        busy <= 1;
                    end
                end

                HEADER: begin
                    busy <= 1;

                    packet_data <=
                        header[header_index * 8 +: 8];

                    packet_valid <= 1;

                    if (header_index == 18) begin

                        if (payload_size == 0) begin
                            crc_saved <= 0;
                            crc_index <= 0;
                            state <= CRC_SEND;
                        end
                        else begin
                            state <= PAYLOAD;
                        end

                    end
                    else begin
                        header_index <= header_index + 1'b1;
                    end
                end

                PAYLOAD: begin
                    busy <= 1;

                    if (payload_valid) begin

                        packet_data <= payload_data;
                        packet_valid <= 1;

                        payload_count <= payload_count + 1'b1;

                        if (payload_count == payload_size - 1'b1)
                            state <= CRC_WAIT;

                    end
                end

                CRC_WAIT: begin
                    busy <= 1;

                    if (crc_done) begin
                        crc_saved <= crc_out;
                        crc_index <= 0;
                        state <= CRC_SEND;
                    end
                end

                CRC_SEND: begin
                    busy <= 1;

                    packet_data <=
                        crc_saved[crc_index * 8 +: 8];

                    packet_valid <= 1;

                    if (crc_index == 3) begin
                        packet_last <= 1;
                        state <= IDLE;
                        busy <= 0;
                    end
                    else begin
                        crc_index <= crc_index + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    busy <= 0;
                end

            endcase
        end
    end

endmodule
