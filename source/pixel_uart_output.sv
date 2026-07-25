module pixel_uart_output #(
    parameter integer CLOCK_FREQ = 12_000_000,
    parameter integer BAUD_RATE = 115_200,
    parameter integer FIFO_DEPTH = 8
) (
    input logic clk,
    input logic n_rst,
    input logic [2:0] mode_value,
    input logic mode_valid,
    input logic [4:0] threshold_value,
    input logic threshold_valid,
    input logic [7:0] red_data,
    input logic [7:0] green_data,
    input logic [7:0] blue_data,
    input logic pixel_valid,
    output logic serial_tx,
    output logic pixel_ready,
    output logic tx_busy,
    output logic pixel_done,
    output logic tx_overflow,
    output logic [2:0] mode_locked,
    output logic [4:0] threshold_locked
);
    logic [7:0] processed_red;
    logic [7:0] processed_green;
    logic [7:0] processed_blue;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            mode_locked <= '0;
            threshold_locked <= '0;
        end
        else begin
            if (mode_valid)
                mode_locked <= mode_value;

            if (threshold_valid)
                threshold_locked <= threshold_value;
        end
    end

    pixel_accelerator accelerator (
        .r_in(red_data),
        .g_in(green_data),
        .b_in(blue_data),
        .mode_locked(mode_locked),
        .threshold_locked(threshold_locked),
        .r_out(processed_red),
        .g_out(processed_green),
        .b_out(processed_blue)
    );

    uart_rgb_stream_transmitter #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) transmitter (
        .clk(clk),
        .n_rst(n_rst),
        .red_data(processed_red),
        .green_data(processed_green),
        .blue_data(processed_blue),
        .pixel_valid(pixel_valid),
        .pixel_ready(pixel_ready),
        .serial_tx(serial_tx),
        .busy(tx_busy),
        .pixel_done(pixel_done),
        .overflow(tx_overflow)
    );
endmodule
