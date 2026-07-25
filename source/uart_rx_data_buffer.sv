module uart_rx_data_buffer (
    input logic clk,
    input logic n_rst,
    input logic load_buffer,
    input logic data_read,
    input logic [7:0] packet_data,
    input logic framing_error_in,

    output logic [7:0] rx_data,
    output logic data_ready,
    output logic framing_error,
    output logic overrun_error
);

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            rx_data <= 8'd0;
            data_ready <= 1'b0;
            framing_error <= 1'b0;
            overrun_error <= 1'b0;
        end
        else begin
            if (load_buffer) begin
                overrun_error <= data_ready && !data_read;
                rx_data <= packet_data;
                data_ready <= 1'b1;
                framing_error <= framing_error_in;
            end
            else if (data_read) begin
                data_ready <= 1'b0;
                framing_error <= 1'b0;
                overrun_error <= 1'b0;
            end
        end
    end
endmodule
