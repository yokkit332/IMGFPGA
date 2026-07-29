`timescale 1ns/1ps

module uart_rgb_tx_timing_controller_tb;
    localparam integer CLOCK_PERIOD = 10;
    localparam integer CLOCK_FREQ = 40;
    localparam integer BAUD_RATE = 10;
    localparam integer FRAME_BITS = 6;

    logic clk;
    logic n_rst;
    logic start;
    logic shift_strobe;
    logic frame_done;
    logic busy;
    integer strobe_count;
    integer timeout_count;

    uart_rgb_tx_timing_controller #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .FRAME_BITS(FRAME_BITS)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .start(start),
        .shift_strobe(shift_strobe),
        .frame_done(frame_done),
        .busy(busy)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_rgb_tx_timing_controller.fst");
        $dumpvars(0, uart_rgb_tx_timing_controller_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        start = 1'b0;
        strobe_count = 0;
        timeout_count = 0;

        repeat (2) tick();
        n_rst = 1'b1;
        tick();

        start = 1'b1;
        tick();
        start = 1'b0;
        assert(busy == 1'b1) else $fatal(1, "start should set busy");

        while (!frame_done && timeout_count < 100) begin
            tick();
            if (shift_strobe)
                strobe_count = strobe_count + 1;
            timeout_count = timeout_count + 1;
        end

        assert(frame_done == 1'b1) else $fatal(1, "The transmit timer did not finish");
        assert(strobe_count == FRAME_BITS - 1) else $fatal(1, "The timer should shift between transmitted bits");
        assert(busy == 1'b0) else $fatal(1, "busy should clear when the frame finishes");

        tick();
        assert(frame_done == 1'b0) else $fatal(1, "frame_done should be a one-cycle pulse");

        $display("PASS: uart_rgb_tx_timing_controller_tb");
        $finish;
    end
endmodule
