module uart_stream_decoder #(
    parameter integer NUM_PIXELS = 4800
) (
    input logic clk,
    input logic n_rst,
    input logic [7:0] rx_data,
    input logic data_ready,
    input logic framing_error,
    input logic overrun_error,
    output logic data_read,
    output logic [2:0] mode_value,
    output logic mode_valid,
    output logic [4:0] threshold_value,
    output logic threshold_valid,
    output logic [7:0] red_data,
    output logic [7:0] green_data,
    output logic [7:0] blue_data,
    output logic pixel_valid,
    output logic frame_start,
    output logic frame_done,
    output logic stream_error
);

    localparam logic [7:0] CMD_MODE = 8'hA0;
    localparam logic [7:0] CMD_THRESHOLD = 8'hA1;
    localparam logic [7:0] CMD_FRAME_START = 8'hA2;
    localparam integer PIXEL_COUNT_WIDTH = (NUM_PIXELS > 1) ? $clog2(NUM_PIXELS) : 1;

    typedef enum logic [2:0] {
        WAIT_COMMAND,
        READ_MODE,
        READ_THRESHOLD,
        READ_RED,
        READ_GREEN,
        READ_BLUE,
        PIXEL_READY
    } state_t;

    state_t state;
    logic byte_consumed;
    logic [PIXEL_COUNT_WIDTH-1:0] pixel_count;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            state <= WAIT_COMMAND;
            byte_consumed <= 1'b0;
            pixel_count <= '0;
            data_read <= 1'b0;
            mode_value <= '0;
            mode_valid <= 1'b0;
            threshold_value <= '0;
            threshold_valid <= 1'b0;
            red_data <= '0;
            green_data <= '0;
            blue_data <= '0;
            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            frame_done <= 1'b0;
            stream_error <= 1'b0;
        end else begin
            data_read <= 1'b0;
            mode_valid <= 1'b0;
            threshold_valid <= 1'b0;
            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            frame_done <= 1'b0;
            stream_error <= 1'b0;

            if (!data_ready) begin
                byte_consumed <= 1'b0;
            end

            if (state == PIXEL_READY) begin
                pixel_valid <= 1'b1;

                if (pixel_count == NUM_PIXELS - 1) begin
                    pixel_count <= '0;
                    frame_done <= 1'b1;
                    state <= WAIT_COMMAND;
                end else begin
                    pixel_count <= pixel_count + 1'b1;
                    state <= READ_RED;
                end
            end else if (data_ready && !byte_consumed) begin
                data_read <= 1'b1;
                byte_consumed <= 1'b1;

                if (framing_error || overrun_error) begin
                    state <= WAIT_COMMAND;
                    pixel_count <= '0;
                    stream_error <= 1'b1;
                end else begin
                    case (state)
                        WAIT_COMMAND: begin
                            case (rx_data)
                                CMD_MODE: begin
                                    state <= READ_MODE;
                                end

                                CMD_THRESHOLD: begin
                                    state <= READ_THRESHOLD;
                                end

                                CMD_FRAME_START: begin
                                    pixel_count <= '0;
                                    frame_start <= 1'b1;
                                    state <= READ_RED;
                                end

                                default: begin
                                    state <= WAIT_COMMAND;
                                end
                            endcase
                        end

                        READ_MODE: begin
                            mode_value <= rx_data[2:0];
                            mode_valid <= 1'b1;
                            state <= WAIT_COMMAND;
                        end

                        READ_THRESHOLD: begin
                            threshold_value <= rx_data[4:0];
                            threshold_valid <= 1'b1;
                            state <= WAIT_COMMAND;
                        end

                        READ_RED: begin
                            red_data <= rx_data;
                            state <= READ_GREEN;
                        end

                        READ_GREEN: begin
                            green_data <= rx_data;
                            state <= READ_BLUE;
                        end

                        READ_BLUE: begin
                            blue_data <= rx_data;
                            state <= PIXEL_READY;
                        end

                        default: begin
                            state <= WAIT_COMMAND;
                            pixel_count <= '0;
                            stream_error <= 1'b1;
                        end
                    endcase
                end
            end
        end
    end

endmodule