module top #(
    parameter integer CLOCK_FREQ = 12_000_000,
    parameter integer BAUD_RATE = 115_200,
    parameter integer NUM_PIXELS = 4800,
    parameter integer FIFO_DEPTH = 8
) (
    input logic hwclk,
    input logic [20:0] pb,
    output logic [7:0] ss7,
    output logic [7:0] ss6,
    output logic [7:0] ss5,
    output logic [7:0] ss4,
    output logic [7:0] ss3,
    output logic [7:0] ss2,
    output logic [7:0] ss1,
    output logic [7:0] ss0,
    output logic [7:0] left,
    output logic [7:0] right,
    output logic red,
    output logic green,
    output logic blue,
    input logic Rx,
    output logic Tx,
    output logic CTSn,
    output logic DCDn
);

    logic raw_n_rst;
    logic [1:0] reset_sync = 2'b00;
    logic n_rst;

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

    logic tx_pixel_ready;
    logic tx_busy;
    logic tx_pixel_done;
    logic tx_overflow;
    logic [2:0] mode_locked;
    logic [4:0] threshold_locked;

    logic error_latched;
    logic frame_done_latched;

    assign raw_n_rst = ~pb[0];
    assign n_rst = reset_sync[1];

    always_ff @(posedge hwclk, negedge raw_n_rst) begin
        if (!raw_n_rst)
            reset_sync <= 2'b00;
        else
            reset_sync <= {reset_sync[0], 1'b1};
    end

    always_ff @(posedge hwclk, negedge n_rst) begin
        if (!n_rst) begin
            error_latched <= 1'b0;
            frame_done_latched <= 1'b0;
        end else begin
            if (uart_framing_error || uart_overrun_error || decoder_stream_error || tx_overflow)
                error_latched <= 1'b1;

            if (decoded_frame_start)
                frame_done_latched <= 1'b0;
            else if (decoded_frame_done)
                frame_done_latched <= 1'b1;
        end
    end

    uart_receiver #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) input_uart (
        .clk(hwclk),
        .n_rst(n_rst),
        .serial_rx(Rx),
        .data_read(received_byte_read),
        .rx_data(received_byte),
        .data_ready(received_byte_ready),
        .framing_error(uart_framing_error),
        .overrun_error(uart_overrun_error)
    );

    uart_stream_decoder #(
        .NUM_PIXELS(NUM_PIXELS)
    ) input_decoder (
        .clk(hwclk),
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

    pixel_uart_output #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) output_path (
        .clk(hwclk),
        .n_rst(n_rst),
        .mode_value(decoded_mode),
        .mode_valid(decoded_mode_valid),
        .threshold_value(decoded_threshold),
        .threshold_valid(decoded_threshold_valid),
        .red_data(decoded_red),
        .green_data(decoded_green),
        .blue_data(decoded_blue),
        .pixel_valid(decoded_pixel_valid),
        .serial_tx(Tx),
        .pixel_ready(tx_pixel_ready),
        .tx_busy(tx_busy),
        .pixel_done(tx_pixel_done),
        .tx_overflow(tx_overflow),
        .mode_locked(mode_locked),
        .threshold_locked(threshold_locked)
    );

    always_comb begin
        ss7 = 8'h00;
        ss6 = 8'h00;
        ss5 = 8'h00;
        ss4 = 8'h00;
        ss3 = 8'h00;
        ss2 = 8'h00;
        ss1 = 8'h00;
        ss0 = 8'h00;

        left[0] = received_byte_ready;
        left[1] = uart_framing_error;
        left[2] = uart_overrun_error;
        left[3] = decoder_stream_error;
        left[4] = tx_busy;
        left[5] = tx_overflow;
        left[6] = tx_pixel_done;
        left[7] = frame_done_latched;

        right = {mode_locked, threshold_locked};

        red = error_latched;
        green = frame_done_latched;
        blue = tx_busy;

        CTSn = 1'b0;
        DCDn = 1'b0;
    end

endmodule