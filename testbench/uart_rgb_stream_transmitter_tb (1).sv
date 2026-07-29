`timescale 1ns/1ps

module uart_rgb_stream_transmitter_tb;
    localparam integer CLOCK_PERIOD = 10;
    localparam integer CLOCK_FREQ = 40;
    localparam integer BAUD_RATE = 10;
    localparam integer CLKS_PER_BIT = 4;
    localparam integer FIFO_DEPTH = 2;

    logic clk;
    logic n_rst;
    logic [7:0] red_data;
    logic [7:0] green_data;
    logic [7:0] blue_data;
    logic pixel_valid;
    logic pixel_ready;
    logic serial_tx;
    logic busy;
    logic pixel_done;
    logic overflow;
    logic [29:0] captured_bits;
    integer done_count;
    integer index;

    uart_rgb_stream_transmitter #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .red_data(red_data),
        .green_data(green_data),
        .blue_data(blue_data),
        .pixel_valid(pixel_valid),
        .pixel_ready(pixel_ready),
        .serial_tx(serial_tx),
        .busy(busy),
        .pixel_done(pixel_done),
        .overflow(overflow)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    always_ff @(posedge clk) begin
        if (!n_rst)
            done_count <= 0;
        else if (pixel_done)
            done_count <= done_count + 1;
    end

    function automatic logic expected_bit(
        input integer bit_index,
        input logic [7:0] red_value,
        input logic [7:0] green_value,
        input logic [7:0] blue_value
    );
        begin
            if (bit_index == 0)
                expected_bit = 1'b0;
            else if (bit_index >= 1 && bit_index <= 8)
                expected_bit = red_value[bit_index - 1];
            else if (bit_index == 9)
                expected_bit = 1'b1;
            else if (bit_index == 10)
                expected_bit = 1'b0;
            else if (bit_index >= 11 && bit_index <= 18)
                expected_bit = green_value[bit_index - 11];
            else if (bit_index == 19)
                expected_bit = 1'b1;
            else if (bit_index == 20)
                expected_bit = 1'b0;
            else if (bit_index >= 21 && bit_index <= 28)
                expected_bit = blue_value[bit_index - 21];
            else
                expected_bit = 1'b1;
        end
    endfunction

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task automatic reset_dut;
        begin
            n_rst = 1'b0;
            pixel_valid = 1'b0;
            repeat (3) tick();
            n_rst = 1'b1;
            repeat (2) tick();
        end
    endtask

    task automatic push_pixel(input logic [7:0] red_value, input logic [7:0] green_value, input logic [7:0] blue_value);
        begin
            while (!pixel_ready)
                tick();
            red_data = red_value;
            green_data = green_value;
            blue_data = blue_value;
            pixel_valid = 1'b1;
            tick();
            pixel_valid = 1'b0;
        end
    endtask

    task automatic capture_frame(output logic [29:0] bits);
        integer bit_index;
        begin
            @(negedge serial_tx);
            repeat (CLKS_PER_BIT / 2) tick();
            for (bit_index = 0; bit_index < 30; bit_index = bit_index + 1) begin
                bits[bit_index] = serial_tx;
                repeat (CLKS_PER_BIT) tick();
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_rgb_stream_transmitter.fst");
        $dumpvars(0, uart_rgb_stream_transmitter_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        red_data = 8'h00;
        green_data = 8'h00;
        blue_data = 8'h00;
        pixel_valid = 1'b0;
        captured_bits = '0;

        reset_dut();

        fork
            capture_frame(captured_bits);
            push_pixel(8'hA5, 8'h3C, 8'h81);
        join

        for (index = 0; index < 30; index = index + 1)
            assert(captured_bits[index] == expected_bit(index, 8'hA5, 8'h3C, 8'h81)) else $fatal(1, "Unexpected UART frame bit %0d", index);
        assert(done_count == 1) else $fatal(1, "One transmitted pixel should create one pixel_done pulse");
        assert(overflow == 1'b0) else $fatal(1, "A single pixel should not overflow the FIFO");

        reset_dut();
        push_pixel(8'h01, 8'h02, 8'h03);
        while (!busy)
            tick();
        push_pixel(8'h11, 8'h12, 8'h13);
        push_pixel(8'h21, 8'h22, 8'h23);

        assert(pixel_ready == 1'b0) else $fatal(1, "The two-entry FIFO should be full");
        red_data = 8'h31;
        green_data = 8'h32;
        blue_data = 8'h33;
        pixel_valid = 1'b1;
        tick();
        pixel_valid = 1'b0;
        assert(overflow == 1'b1) else $fatal(1, "Writing while the FIFO is full should pulse overflow");

        $display("PASS: uart_rgb_stream_transmitter_tb");
        $finish;
    end
endmodule
