`timescale 1ns/1ps

module pixel_uart_output_tb;
    localparam integer CLOCK_PERIOD = 10;
    localparam integer CLOCK_FREQ = 40;
    localparam integer BAUD_RATE = 10;
    localparam integer CLKS_PER_BIT = 4;
    localparam integer FIFO_DEPTH = 4;

    logic clk;
    logic n_rst;
    logic [2:0] mode_value;
    logic mode_valid;
    logic [4:0] threshold_value;
    logic threshold_valid;
    logic [7:0] red_data;
    logic [7:0] green_data;
    logic [7:0] blue_data;
    logic pixel_valid;
    logic serial_tx;
    logic pixel_ready;
    logic tx_busy;
    logic pixel_done;
    logic tx_overflow;
    logic [2:0] mode_locked;
    logic [4:0] threshold_locked;
    logic [29:0] captured_bits;
    integer index;

    pixel_uart_output #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .mode_value(mode_value),
        .mode_valid(mode_valid),
        .threshold_value(threshold_value),
        .threshold_valid(threshold_valid),
        .red_data(red_data),
        .green_data(green_data),
        .blue_data(blue_data),
        .pixel_valid(pixel_valid),
        .serial_tx(serial_tx),
        .pixel_ready(pixel_ready),
        .tx_busy(tx_busy),
        .pixel_done(pixel_done),
        .tx_overflow(tx_overflow),
        .mode_locked(mode_locked),
        .threshold_locked(threshold_locked)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

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

    initial begin
        $dumpfile("waveforms/pixel_uart_output.fst");
        $dumpvars(0, pixel_uart_output_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        mode_value = 3'd0;
        mode_valid = 1'b0;
        threshold_value = 5'd0;
        threshold_valid = 1'b0;
        red_data = 8'h00;
        green_data = 8'h00;
        blue_data = 8'h00;
        pixel_valid = 1'b0;
        captured_bits = '0;

        repeat (3) tick();
        n_rst = 1'b1;
        repeat (2) tick();

        mode_value = 3'd2;
        threshold_value = 5'd5;
        mode_valid = 1'b1;
        threshold_valid = 1'b1;
        tick();
        mode_valid = 1'b0;
        threshold_valid = 1'b0;

        assert(mode_locked == 3'd2) else $fatal(1, "mode_valid should update mode_locked");
        assert(threshold_locked == 5'd5) else $fatal(1, "threshold_valid should update threshold_locked");

        fork
            capture_frame(captured_bits);
            push_pixel(8'd250, 8'd10, 8'd20);
        join

        for (index = 0; index < 30; index = index + 1)
            assert(captured_bits[index] == expected_bit(index, 8'd255, 8'd15, 8'd25)) else $fatal(1, "Unexpected processed UART bit %0d", index);
        assert(tx_overflow == 1'b0) else $fatal(1, "A single processed pixel should not overflow");

        $display("PASS: pixel_uart_output_tb");
        $finish;
    end
endmodule
