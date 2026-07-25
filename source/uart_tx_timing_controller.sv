module uart_tx_timing_controller #(
    parameter integer CLOCK_FREQ = 12_000_000,
    parameter integer BAUD_RATE = 115_200,
    parameter integer FRAME_BITS = 30
) (
    input logic clk,
    input logic n_rst,
    input logic start,
    output logic shift_strobe,
    output logic frame_done,
    output logic busy
);
    localparam integer CLKS_PER_BIT_RAW = (CLOCK_FREQ + (BAUD_RATE / 2)) / BAUD_RATE;
    localparam integer CLKS_PER_BIT = (CLKS_PER_BIT_RAW < 2) ? 2 : CLKS_PER_BIT_RAW;
    localparam integer CLOCK_COUNT_WIDTH = (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);
    localparam integer BIT_COUNT_WIDTH = (FRAME_BITS <= 1) ? 1 : $clog2(FRAME_BITS);

    logic [CLOCK_COUNT_WIDTH-1:0] clock_count;
    logic [BIT_COUNT_WIDTH-1:0] bit_count;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            clock_count <= '0;
            bit_count <= '0;
            shift_strobe <= 1'b0;
            frame_done <= 1'b0;
            busy <= 1'b0;
        end
        else begin
            shift_strobe <= 1'b0;
            frame_done <= 1'b0;

            if (start && !busy) begin
                clock_count <= '0;
                bit_count <= '0;
                busy <= 1'b1;
            end
            else if (busy) begin
                if (clock_count == CLKS_PER_BIT - 1) begin
                    clock_count <= '0;

                    if (bit_count == FRAME_BITS - 1) begin
                        bit_count <= '0;
                        frame_done <= 1'b1;
                        busy <= 1'b0;
                    end
                    else begin
                        bit_count <= bit_count + 1'b1;
                        shift_strobe <= 1'b1;
                    end
                end
                else begin
                    clock_count <= clock_count + 1'b1;
                end
            end
        end
    end
endmodule
