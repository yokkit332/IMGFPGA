module uart_receiver #(
    parameter integer CLOCK_FREQ = 12_000_000,
    parameter integer BAUD_RATE = 115_200
) (
    input logic clk,
    input logic n_rst,
    input logic serial_rx,
    input logic data_read,
    output logic [7:0] rx_data,
    output logic data_ready,
    output logic framing_error,
    output logic overrun_error
);

    logic synchronized_rx;
    logic start_detected;
    logic detector_enable;
    logic start_timer;
    logic timer_enable;
    logic shift_strobe;
    logic packet_done;
    logic clear_shift_register;
    logic [7:0] packet_data;
    logic stop_bit;
    logic stop_check_enable;
    logic stop_check_clear;
    logic checked_framing_error;
    logic load_data_buffer;

    uart_rx_synchronizer synchronizer (
        .clk(clk),
        .n_rst(n_rst),
        .asynchronous_rx(serial_rx),
        .synchronized_rx(synchronized_rx)
    );

    uart_start_bit_detector start_detector (
        .clk(clk),
        .n_rst(n_rst),
        .detector_enable(detector_enable),
        .serial_in(synchronized_rx),
        .start_detected(start_detected)
    );

    uart_rx_control_unit control_unit (
        .clk(clk),
        .n_rst(n_rst),
        .start_detected(start_detected),
        .packet_done(packet_done),
        .detector_enable(detector_enable),
        .start_timer(start_timer),
        .timer_enable(timer_enable),
        .clear_shift_register(clear_shift_register),
        .stop_check_enable(stop_check_enable),
        .stop_check_clear(stop_check_clear),
        .load_data_buffer(load_data_buffer)
    );

    uart_rx_timing_controller #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) timing_controller (
        .clk(clk),
        .n_rst(n_rst),
        .start_timer(start_timer),
        .timer_enable(timer_enable),
        .shift_strobe(shift_strobe),
        .packet_done(packet_done)
    );

    uart_rx_shift_register_9bit shift_register (
        .clk(clk),
        .n_rst(n_rst),
        .clear(clear_shift_register),
        .shift_strobe(shift_strobe),
        .serial_in(synchronized_rx),
        .packet_data(packet_data),
        .stop_bit(stop_bit)
    );

    uart_stop_bit_checker stop_checker (
        .clk(clk),
        .n_rst(n_rst),
        .check_enable(stop_check_enable),
        .clear_error(stop_check_clear),
        .stop_bit(stop_bit),
        .framing_error(checked_framing_error)
    );

    uart_rx_data_buffer data_buffer (
        .clk(clk),
        .n_rst(n_rst),
        .load_buffer(load_data_buffer),
        .data_read(data_read),
        .packet_data(packet_data),
        .framing_error_in(checked_framing_error),
        .rx_data(rx_data),
        .data_ready(data_ready),
        .framing_error(framing_error),
        .overrun_error(overrun_error)
    );

endmodule