module uart_rx_timing_controller #(
    parameter integer CLOCK_FREQ = 12_000_000,
    parameter integer BAUD_RATE = 115_200
) (
    input logic clk,
    input logic n_rst,
    input logic start_timer,
    input logic timer_enable,
    output logic shift_strobe,
    output logic packet_done
);

    localparam integer CLKS_PER_BIT_RAW =
        (CLOCK_FREQ + (BAUD_RATE / 2)) / BAUD_RATE;
    localparam integer CLKS_PER_BIT =
        (CLKS_PER_BIT_RAW < 2) ? 2 : CLKS_PER_BIT_RAW;

    localparam integer FIRST_SAMPLE_CLKS =
        CLKS_PER_BIT + (CLKS_PER_BIT / 2);

    localparam integer COUNTER_WIDTH =
        (FIRST_SAMPLE_CLKS <= 1) ? 1 : $clog2(FIRST_SAMPLE_CLKS);

    logic [COUNTER_WIDTH-1:0] clock_count;
    logic [3:0] sample_count;
    logic first_sample;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            clock_count <= '0;
            sample_count <= '0;
            first_sample <= 1'b1;
            shift_strobe <= 1'b0;
            packet_done <= 1'b0;
        end
        else begin

            shift_strobe <= 1'b0;
            packet_done <= 1'b0;

            if (start_timer) begin
                clock_count <= '0;
                sample_count <= '0;
                first_sample <= 1'b1;
            end
            else if (!timer_enable) begin
                clock_count <= '0;
                sample_count <= '0;
                first_sample <= 1'b1;
            end
            else if (first_sample) begin
                if (clock_count == FIRST_SAMPLE_CLKS - 1) begin
                    clock_count <= '0;
                    sample_count <= 4'd1;
                    first_sample <= 1'b0;
                    shift_strobe <= 1'b1;
                end
                else begin
                    clock_count <= clock_count + 1'b1;
                end
            end
            else begin
                if (clock_count == CLKS_PER_BIT - 1) begin
                    clock_count <= '0;
                    shift_strobe <= 1'b1;

                    if (sample_count == 4'd8) begin

                        packet_done <= 1'b1;
                    end
                    else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end
                else begin
                    clock_count <= clock_count + 1'b1;
                end
            end
        end
    end
endmodule
