`timescale 1ns/1ps

module uart_rx_shift_register_9bit_tb;
    localparam integer CLOCK_PERIOD = 10;

    logic clk;
    logic n_rst;
    logic clear;
    logic shift_strobe;
    logic serial_in;
    logic [7:0] packet_data;
    logic stop_bit;
    logic [7:0] test_byte;
    integer index;

    uart_rx_shift_register_9bit dut (
        .clk(clk),
        .n_rst(n_rst),
        .clear(clear),
        .shift_strobe(shift_strobe),
        .serial_in(serial_in),
        .packet_data(packet_data),
        .stop_bit(stop_bit)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task automatic shift_bit(input logic value);
        begin
            serial_in = value;
            shift_strobe = 1'b1;
            tick();
            shift_strobe = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_rx_shift_register_9bit.fst");
        $dumpvars(0, uart_rx_shift_register_9bit_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        clear = 1'b0;
        shift_strobe = 1'b0;
        serial_in = 1'b1;
        test_byte = 8'hA5;

        repeat (2) tick();
        n_rst = 1'b1;
        clear = 1'b1;
        tick();
        clear = 1'b0;

        for (index = 0; index < 8; index = index + 1)
            shift_bit(test_byte[index]);
        shift_bit(1'b1);

        assert(packet_data == test_byte) else $fatal(1, "The shift register assembled the wrong data byte");
        assert(stop_bit == 1'b1) else $fatal(1, "The ninth sampled bit should be the stop bit");

        clear = 1'b1;
        tick();
        clear = 1'b0;
        assert(packet_data == 8'h00) else $fatal(1, "clear should reset packet_data");
        assert(stop_bit == 1'b0) else $fatal(1, "clear should reset stop_bit");

        $display("PASS: uart_rx_shift_register_9bit_tb");
        $finish;
    end
endmodule
