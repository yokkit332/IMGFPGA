`timescale 1ns/1ps

module uart_rx_synchronizer_tb;
    localparam integer CLOCK_PERIOD = 10;

    logic clk;
    logic n_rst;
    logic asynchronous_rx;
    logic synchronized_rx;

    uart_rx_synchronizer dut (
        .clk(clk),
        .n_rst(n_rst),
        .asynchronous_rx(asynchronous_rx),
        .synchronized_rx(synchronized_rx)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_rx_synchronizer.fst");
        $dumpvars(0, uart_rx_synchronizer_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        asynchronous_rx = 1'b1;

        repeat (2) tick();
        assert(synchronized_rx == 1'b1) else $fatal(1, "Reset should force the synchronized input high");

        n_rst = 1'b1;
        tick();

        asynchronous_rx = 1'b0;
        tick();
        assert(synchronized_rx == 1'b1) else $fatal(1, "The first synchronizer stage should absorb the first clock");
        tick();
        assert(synchronized_rx == 1'b0) else $fatal(1, "A low input should appear after two clock edges");

        asynchronous_rx = 1'b1;
        tick();
        assert(synchronized_rx == 1'b0) else $fatal(1, "The first synchronizer stage should absorb the rising edge");
        tick();
        assert(synchronized_rx == 1'b1) else $fatal(1, "A high input should appear after two clock edges");

        $display("PASS: uart_rx_synchronizer_tb");
        $finish;
    end
endmodule
