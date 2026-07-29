`timescale 1ns/1ps

module uart_rx_control_unit_tb;
    localparam integer CLOCK_PERIOD = 10;

    logic clk;
    logic n_rst;
    logic start_detected;
    logic packet_done;
    logic detector_enable;
    logic start_timer;
    logic timer_enable;
    logic clear_shift_register;
    logic stop_check_enable;
    logic stop_check_clear;
    logic load_data_buffer;

    uart_rx_control_unit dut (
        .clk(clk),
        .n_rst(n_rst),
        .start_detected(start_detected),
        .packet_done(packet_done),
        .detector_enable(detector_enable),
        .start_timer(start_timer),
        .timer_enable(timer_enable),
        .clear_shift_register(clear_shift_register),
        .stop_check_enable(stop_check_enable),
        .stop_check_clear(stop_check_clear),
        .load_data_buffer(load_data_buffer)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_rx_control_unit.fst");
        $dumpvars(0, uart_rx_control_unit_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        start_detected = 1'b0;
        packet_done = 1'b0;

        repeat (2) tick();
        n_rst = 1'b1;
        tick();

        assert(detector_enable == 1'b1) else $fatal(1, "The control unit should begin in IDLE");
        assert(stop_check_clear == 1'b1) else $fatal(1, "IDLE should clear an old framing error");

        start_detected = 1'b1;
        #1;
        assert(start_timer == 1'b1) else $fatal(1, "A detected start bit should start the timer");
        assert(clear_shift_register == 1'b1) else $fatal(1, "A detected start bit should clear the shift register");

        tick();
        start_detected = 1'b0;
        assert(timer_enable == 1'b1) else $fatal(1, "RECEIVE should enable the timing controller");

        packet_done = 1'b1;
        tick();
        packet_done = 1'b0;
        assert(stop_check_enable == 1'b1) else $fatal(1, "CHECK_STOP should validate the stop bit");

        tick();
        assert(load_data_buffer == 1'b1) else $fatal(1, "LOAD_DATA should write the receive buffer");

        tick();
        assert(detector_enable == 1'b1) else $fatal(1, "The control unit should return to IDLE");

        $display("PASS: uart_rx_control_unit_tb");
        $finish;
    end
endmodule
