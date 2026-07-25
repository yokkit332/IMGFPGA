module uart_rx_synchronizer (
    input logic clk,
    input logic n_rst,
    input logic asynchronous_rx,
    output logic synchronized_rx
);
    logic first_stage;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            first_stage <= 1'b1;
            synchronized_rx <= 1'b1;
        end
        else begin
            first_stage <= asynchronous_rx;
            synchronized_rx <= first_stage;
        end
    end
endmodule
