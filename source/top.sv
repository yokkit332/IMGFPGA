module top #(
    parameter int CLOCK_FREQ = 66_000_000,
    parameter int BAUD_RATE = 115_200
)(
    input logic clk,
    input logic n_rst,

    input logic rx_r,
    input logic rx_g,
    input logic rx_b,
    input logic rx_config,

    output logic tx_r,
    output logic tx_g,
    output logic tx_b
    
);
    /*
    input logic [20:0] pb,
    output logic [7:0] left,
    output logic [7:0] right,
    output logic [7:0] ss7,
    output logic [7:0] ss6,
    output logic [7:0] ss5,
    output logic [7:0] ss4,
    output logic [7:0] ss3,
    output logic [7:0] ss2,
    output logic [7:0] ss1,
    output logic [7:0] ss0,
    output logic red,
    output logic green,
    output logic blue,
    output logic [7:0] txdata,
    input logic [7:0] rxdata,
    output logic txclk,
    output logic rxclk,
    input logic txready,
    input logic rxready
    */
    // internal signals
    logic r_ready, g_ready, b_ready, config_ready, output_ready, output_ready_for_rx;
    logic [7:0] config_byte, r_in, b_in, g_in, r_out, g_out, b_out;
    logic [2:0] mode_locked;
    logic [4:0] threshold_locked;

    // uart rx rgb instantiations
    uart_rx_top #(
        .CLOCK_FREQ(CLOCK_FREQ), .BAUD_RATE(BAUD_RATE)
    )rgb_rx (
        .clk(clk), .n_rst(n_rst),
        .serial_rx_r(rx_r), .serial_rx_g(rx_g), .serial_rx_b(rx_b),
        .baud_tick_shared(1'b0), .output_ready(output_ready_for_rx),
        .r_px(r_in), .r_ready(r_ready), 
        .g_px(g_in), .g_ready(g_ready), 
        .b_px(b_in), .b_ready(b_ready)
    );

    // uart rx config instantiation
    uart_rx_config #(
        .CLOCK_FREQ(CLOCK_FREQ), .BAUD_RATE(BAUD_RATE)
    ) uart_config(
        .clk(clk), .n_rst(n_rst),
        .serial_rx_config(rx_config), .config_ack(config_ready),
        .config_byte(config_byte), .config_ready(config_ready)
    );

    
    // uart tx rgb instantiation
    uart_tx_top #(
        .CLOCK_FREQ(CLOCK_FREQ), .BAUD_RATE(BAUD_RATE)
    ) rgb_tx(
        .clk(clk), .n_rst(n_rst),
        .r_out(r_out), .g_out(g_out), .b_out(b_out),
        .output_ready(output_ready),
        .serial_tx_r(tx_r), .serial_tx_g(tx_g), .serial_tx_b(tx_b),
        .tx_ready(), .baud_tick()
    );
    

    // control instantiation
    pixel_controller control (
        .clk(clk), .n_rst(n_rst),
        .r_ready(r_ready), .g_ready(g_ready), .b_ready(b_ready), 
        .config_ready(config_ready), .config_byte(config_byte),
        .mode_locked(mode_locked), .threshold_locked(threshold_locked),
        .output_ready(output_ready), .output_ready_for_rx(output_ready_for_rx)
    );

    // pixel accelerator instantiation
    pixel_accelerator accelerator(
        .r_in(r_in), .g_in(g_in), .b_in(b_in),
        .mode_locked(mode_locked), .threshold_locked(threshold_locked),
        .r_out(r_out), .g_out(g_out), .b_out(b_out)
    );

endmodule
