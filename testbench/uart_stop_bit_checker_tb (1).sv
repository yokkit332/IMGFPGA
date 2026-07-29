`timescale 1ns/1ps

module uart_stop_bit_checker_tb;
    localparam integer CLOCK_PERIOD = 10;

    logic clk;
    logic n_rst;
    logic check_enable;
    logic clear_error;
    logic stop_bit;
    logic framing_error;

    uart_stop_bit_checker dut (
        .clk(clk),
        .n_rst(n_rst),
        .check_enable(check_enable),
        .clear_error(clear_error),
        .stop_bit(stop_bit),
        .framing_error(framing_error)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_stop_bit_checker.fst");
        $dumpvars(0, uart_stop_bit_checker_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        check_enable = 1'b0;
        clear_error = 1'b0;
        stop_bit = 1'b1;

        repeat (2) tick();
        n_rst = 1'b1;
        tick();

        check_enable = 1'b1;
        stop_bit = 1'b1;
        tick();
        check_enable = 1'b0;
        assert(framing_error == 1'b0) else $fatal(1, "A high stop bit should be valid");

        check_enable = 1'b1;
        stop_bit = 1'b0;
        tick();
        check_enable = 1'b0;
        assert(framing_error == 1'b1) else $fatal(1, "A low stop bit should set framing_error");

        stop_bit = 1'b1;
        tick();
        assert(framing_error == 1'b1) else $fatal(1, "The error should remain latched until it is cleared");

        clear_error = 1'b1;
        tick();
        clear_error = 1'b0;
        assert(framing_error == 1'b0) else $fatal(1, "clear_error should clear framing_error");

        $display("PASS: uart_stop_bit_checker_tb");
        $finish;
    end
endmodule
