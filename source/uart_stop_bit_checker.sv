module uart_stop_bit_checker (
    input logic clk,
    input logic n_rst,
    input logic clear_error,
    input logic check_stop,
    input logic stop_bit,
    output logic framing_error
);

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            framing_error <= 1'b0;
        end else if (clear_error) begin
            framing_error <= 1'b0;
        end else if (check_stop) begin
            framing_error <= !stop_bit;
        end
    end

endmodule