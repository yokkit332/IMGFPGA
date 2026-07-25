module uart_rx_shift_register_9bit (
    input logic clk,
    input logic n_rst,
    input logic clear,
    input logic shift_strobe,
    input logic serial_in,
    output logic [7:0] packet_data,
    output logic stop_bit
);
    logic [8:0] shift_register;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            shift_register <= 9'd0;
        else if (clear)
            shift_register <= 9'd0;
        else if (shift_strobe)
            shift_register <= {serial_in, shift_register[8:1]};
    end

    assign packet_data = shift_register[7:0];
    assign stop_bit = shift_register[8];
endmodule
