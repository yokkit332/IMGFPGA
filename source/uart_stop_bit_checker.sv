module uart_stop_bit_checker (
    input logic clk,
    input logic n_rst,
    input logic check_enable,
    input logic clear_error,
    input logic stop_bit,
    output logic framing_error
);

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            framing_error <= 1'b0;
        else if (clear_error)
            framing_error <= 1'b0;
        else if (check_enable)
            framing_error <= !stop_bit;
    end

endmodule
