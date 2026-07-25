module uart_rgb_tx_shift_register_30bit (
    input logic clk,
    input logic n_rst,
    input logic load,
    input logic shift_strobe,
    input logic [7:0] red_data,
    input logic [7:0] green_data,
    input logic [7:0] blue_data,
    output logic serial_tx
);
    logic [29:0] shift_register;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            shift_register <= '1;
        else if (load)
            shift_register <= {1'b1, blue_data, 1'b0, 1'b1, green_data, 1'b0, 1'b1, red_data, 1'b0};
        else if (shift_strobe)
            shift_register <= {1'b1, shift_register[29:1]};
    end

    assign serial_tx = shift_register[0];
endmodule
