module uart_rgb_stream_transmitter #(
    parameter integer CLOCK_FREQ = 12_000_000,
    parameter integer BAUD_RATE = 115_200,
    parameter integer FIFO_DEPTH = 8
) (
    input logic clk,
    input logic n_rst,
    input logic [7:0] red_data,
    input logic [7:0] green_data,
    input logic [7:0] blue_data,
    input logic pixel_valid,
    output logic pixel_ready,
    output logic serial_tx,
    output logic busy,
    output logic pixel_done,
    output logic overflow
);
    localparam integer POINTER_WIDTH = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH);
    localparam integer COUNT_WIDTH = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH + 1);

    logic [23:0] pixel_fifo [0:FIFO_DEPTH-1];
    logic [POINTER_WIDTH-1:0] write_pointer;
    logic [POINTER_WIDTH-1:0] read_pointer;
    logic [COUNT_WIDTH-1:0] fifo_count;

    logic [23:0] current_pixel;
    logic start_frame;
    logic push_pixel;
    logic pop_pixel;
    logic shift_strobe;
    logic timing_done;
    logic timing_busy;

    assign current_pixel = pixel_fifo[read_pointer];
    assign start_frame = !timing_busy && fifo_count != 0;
    assign pop_pixel = start_frame;
    assign pixel_ready = fifo_count < FIFO_DEPTH || pop_pixel;
    assign push_pixel = pixel_valid && pixel_ready;
    assign busy = timing_busy || fifo_count != 0;
    assign pixel_done = timing_done;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            write_pointer <= '0;
            read_pointer <= '0;
            fifo_count <= '0;
            overflow <= 1'b0;
        end
        else begin
            overflow <= 1'b0;

            if (pixel_valid && !pixel_ready)
                overflow <= 1'b1;

            if (push_pixel) begin
                pixel_fifo[write_pointer] <= {red_data, green_data, blue_data};

                if (write_pointer == FIFO_DEPTH - 1)
                    write_pointer <= '0;
                else
                    write_pointer <= write_pointer + 1'b1;
            end

            if (pop_pixel) begin
                if (read_pointer == FIFO_DEPTH - 1)
                    read_pointer <= '0;
                else
                    read_pointer <= read_pointer + 1'b1;
            end

            case ({push_pixel, pop_pixel})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end

    uart_rgb_tx_timing_controller #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .FRAME_BITS(30)
    ) timing_controller (
        .clk(clk),
        .n_rst(n_rst),
        .start(start_frame),
        .shift_strobe(shift_strobe),
        .frame_done(timing_done),
        .busy(timing_busy)
    );

    uart_rgb_tx_shift_register_30bit shift_register (
        .clk(clk),
        .n_rst(n_rst),
        .load(start_frame),
        .shift_strobe(shift_strobe),
        .red_data(current_pixel[23:16]),
        .green_data(current_pixel[15:8]),
        .blue_data(current_pixel[7:0]),
        .serial_tx(serial_tx)
    );
endmodule
