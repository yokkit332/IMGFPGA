module uart_start_bit_detector (
    input logic clk,
    input logic n_rst,
    input logic detector_enable,
    input logic serial_in,
    output logic start_detected
);
    logic previous_serial;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            previous_serial <= 1'b1;
        else
            previous_serial <= serial_in;
    end

    always_comb begin
        start_detected = detector_enable && previous_serial && !serial_in;
    end
endmodule
