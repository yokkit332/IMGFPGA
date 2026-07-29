`timescale 1ns/1ps

module uart_rx_timing_controller_tb;
    localparam integer CLOCK_PERIOD = 10;
    localparam integer CLOCK_FREQ = 100;
    localparam integer BAUD_RATE = 10;

    logic clk;
    logic n_rst;
    logic start_timer;
    logic timer_enable;
    logic shift_strobe;
    logic packet_done;
    integer strobe_count;
    integer timeout_count;

    uart_rx_timing_controller #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .start_timer(start_timer),
        .timer_enable(timer_enable),
        .shift_strobe(shift_strobe),
        .packet_done(packet_done)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_rx_timing_controller.fst");
        $dumpvars(0, uart_rx_timing_controller_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        start_timer = 1'b0;
        timer_enable = 1'b0;
        strobe_count = 0;
        timeout_count = 0;

        repeat (2) tick();
        n_rst = 1'b1;
        tick();

        start_timer = 1'b1;
        tick();
        start_timer = 1'b0;
        timer_enable = 1'b1;

        while (!packet_done && timeout_count < 200) begin
            tick();
            if (shift_strobe)
                strobe_count = strobe_count + 1;
            timeout_count = timeout_count + 1;
        end

        assert(packet_done == 1'b1) else $fatal(1, "The receive timer did not finish");
        assert(strobe_count == 9) else $fatal(1, "The receive timer should sample eight data bits and one stop bit");

        tick();
        assert(packet_done == 1'b0) else $fatal(1, "packet_done should be a one-cycle pulse");

        timer_enable = 1'b0;
        tick();
        assert(shift_strobe == 1'b0) else $fatal(1, "The timer should stop when timer_enable is low");

        $display("PASS: uart_rx_timing_controller_tb");
        $finish;
    end
endmodule
