`timescale 1ns/1ps

module uart_start_bit_detector_tb;
    localparam integer CLOCK_PERIOD = 10;

    logic clk;
    logic n_rst;
    logic detector_enable;
    logic serial_in;
    logic start_detected;

    uart_start_bit_detector dut (
        .clk(clk),
        .n_rst(n_rst),
        .detector_enable(detector_enable),
        .serial_in(serial_in),
        .start_detected(start_detected)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_start_bit_detector.fst");
        $dumpvars(0, uart_start_bit_detector_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        detector_enable = 1'b0;
        serial_in = 1'b1;

        repeat (2) tick();
        n_rst = 1'b1;
        detector_enable = 1'b1;
        tick();

        @(negedge clk);
        serial_in = 1'b0;
        #1;
        assert(start_detected == 1'b1) else $fatal(1, "A falling edge should be detected while enabled");

        tick();
        assert(start_detected == 1'b0) else $fatal(1, "The start pulse should last for one clock interval");

        serial_in = 1'b1;
        tick();
        assert(start_detected == 1'b0) else $fatal(1, "A rising edge is not a UART start bit");

        detector_enable = 1'b0;
        @(negedge clk);
        serial_in = 1'b0;
        #1;
        assert(start_detected == 1'b0) else $fatal(1, "Detection should be disabled when detector_enable is low");

        $display("PASS: uart_start_bit_detector_tb");
        $finish;
    end
endmodule
