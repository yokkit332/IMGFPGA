module rgb_uart_transmitter #(
    parameter integer CLOCK_FREQ = 12_000_000,
    parameter integer BAUD_RATE = 115_200
) (
    input logic clk,
    input logic n_rst,
    input logic start,
    input logic [7:0] red_data,
    input logic [7:0] green_data,
    input logic [7:0] blue_data,
    output logic serial_tx_r,
    output logic serial_tx_g,
    output logic serial_tx_b,
    output logic ready
);
    logic shift_strobe;
    logic frame_done;
    logic busy;
    logic load;

    assign ready = !busy;
    assign load = start && ready;

    uart_tx_timing_controller #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) timing_controller (
        .clk(clk),
        .n_rst(n_rst),
        .start(load),
        .shift_strobe(shift_strobe),
        .frame_done(frame_done),
        .busy(busy)
    );

    uart_tx_shift_register_10bit red_shift_register (
        .clk(clk),
        .n_rst(n_rst),
        .load(load),
        .shift_strobe(shift_strobe),
        .parallel_data(red_data),
        .serial_out(serial_tx_r)
    );

    uart_tx_shift_register_10bit green_shift_register (
        .clk(clk),
        .n_rst(n_rst),
        .load(load),
        .shift_strobe(shift_strobe),
        .parallel_data(green_data),
        .serial_out(serial_tx_g)
    );

    uart_tx_shift_register_10bit blue_shift_register (
        .clk(clk),
        .n_rst(n_rst),
        .load(load),
        .shift_strobe(shift_strobe),
        .parallel_data(blue_data),
        .serial_out(serial_tx_b)
    );
endmodule
