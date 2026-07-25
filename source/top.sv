module top #(
    parameter integer CLOCK_FREQ = 12_000_000,
    parameter integer BAUD_RATE = 115_200,
    parameter integer NUM_PIXELS = 4800
) (
    input logic clk,
    input logic n_rst,
    input logic serial_rx,
    output logic serial_tx;


);
    logic [7:0] received_byte;
    logic received_byte_ready;
    logic received_byte_read;
    logic uart_framing_error;
    logic uart_overrun_error;
    logic [2:0] decoded_mode;
    logic decoded_mode_valid;
    logic [4:0] decoded_threshold;
    logic decoded_threshold_valid;
    logic [7:0] decoded_red;
    logic [7:0] decoded_green;
    logic [7:0] decoded_blue;
    logic decoded_pixel_valid;
    logic decoded_frame_start;
    logic decoded_frame_done;
    logic decoder_stream_error;
    logic [7:0] red_locked;
    logic [7:0] green_locked;
    logic [7:0] blue_locked;
    logic [2:0] mode_locked;
    logic [4:0] threshold_locked;
    logic transmit_pixel;
    logic pixel_overrun;
    logic [7:0] processed_red;
    logic [7:0] processed_green;
    logic [7:0] processed_blue;
    logic transmitter_ready;
    logic tx_pixel_ready;
    logic tx_busy;
    logic tx_pixel_done;
    logic tx_overflow;
    logic [2:0] mode_locked;
    logic [4:0] threshold_locked;

    uart_receiver #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) input_uart (
        .clk(clk),
        .n_rst(n_rst),
        .serial_rx(serial_rx),
        .data_read(received_byte_read),
        .rx_data(received_byte),
        .data_ready(received_byte_ready),
        .framing_error(uart_framing_error),
        .overrun_error(uart_overrun_error)
    );

    uart_stream_decoder #(
        .NUM_PIXELS(NUM_PIXELS)
    ) input_decoder (
        .clk(clk),
        .n_rst(n_rst),
        .rx_data(received_byte),
        .data_ready(received_byte_ready),
        .framing_error(uart_framing_error),
        .overrun_error(uart_overrun_error),
        .data_read(received_byte_read),
        .mode_value(decoded_mode),
        .mode_valid(decoded_mode_valid),
        .threshold_value(decoded_threshold),
        .threshold_valid(decoded_threshold_valid),
        .red_data(decoded_red),
        .green_data(decoded_green),
        .blue_data(decoded_blue),
        .pixel_valid(decoded_pixel_valid),
        .frame_start(decoded_frame_start),
        .frame_done(decoded_frame_done),
        .stream_error(decoder_stream_error)
    );

    pixel_controller controller (
        .clk(clk),
        .n_rst(n_rst),
        .mode_value(decoded_mode),
        .mode_valid(decoded_mode_valid),
        .threshold_value(decoded_threshold),
        .threshold_valid(decoded_threshold_valid),
        .decoded_red(decoded_red),
        .decoded_green(decoded_green),
        .decoded_blue(decoded_blue),
        .pixel_valid(decoded_pixel_valid),
        .frame_start(decoded_frame_start),
        .transmitter_ready(transmitter_ready),
        .red_locked(red_locked),
        .green_locked(green_locked),
        .blue_locked(blue_locked),
        .mode_locked(mode_locked),
        .threshold_locked(threshold_locked),
        .transmit_pixel(transmit_pixel),
        .pixel_overrun(pixel_overrun)
    );

    pixel_accelerator accelerator (
        .r_in(red_locked),
        .g_in(green_locked),
        .b_in(blue_locked),
        .mode_locked(mode_locked),
        .threshold_locked(threshold_locked),
        .r_out(processed_red),
        .g_out(processed_green),
        .b_out(processed_blue)
    );

    rgb_uart_transmitter #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) output_uart (
        .clk(clk),
        .n_rst(n_rst),
        .start(transmit_pixel),
        .red_data(processed_red),
        .green_data(processed_green),
        .blue_data(processed_blue),
        .serial_tx_r(tx_r),
        .serial_tx_g(tx_g),
        .serial_tx_b(tx_b),
        .ready(transmitter_ready)
    );
    pixel_uart_output #(
    .CLOCK_FREQ(CLOCK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .FIFO_DEPTH(8)
    ) output_path (
    .clk(clk),
    .n_rst(n_rst),
    .mode_value(decoded_mode),
    .mode_valid(decoded_mode_valid),
    .threshold_value(decoded_threshold),
    .threshold_valid(decoded_threshold_valid),
    .red_data(decoded_red),
    .green_data(decoded_green),
    .blue_data(decoded_blue),
    .pixel_valid(decoded_pixel_valid),
    .serial_tx(serial_tx),
    .pixel_ready(tx_pixel_ready),
    .tx_busy(tx_busy),
    .pixel_done(tx_pixel_done),
    .tx_overflow(tx_overflow),
    .mode_locked(mode_locked),
    .threshold_locked(threshold_locked)
);

endmodule
