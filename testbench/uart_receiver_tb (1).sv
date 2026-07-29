`timescale 1ns/1ps

module uart_receiver_tb;
    localparam integer CLOCK_PERIOD = 10;
    localparam integer CLOCK_FREQ = 160;
    localparam integer BAUD_RATE = 10;
    localparam integer CLKS_PER_BIT = 16;

    logic clk;
    logic n_rst;
    logic serial_rx;
    logic data_read;
    logic [7:0] rx_data;
    logic data_ready;
    logic framing_error;
    logic overrun_error;
    integer index;

    uart_receiver #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .serial_rx(serial_rx),
        .data_read(data_read),
        .rx_data(rx_data),
        .data_ready(data_ready),
        .framing_error(framing_error),
        .overrun_error(overrun_error)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task automatic drive_uart_bit(input logic value);
        begin
            serial_rx = value;
            repeat (CLKS_PER_BIT) tick();
        end
    endtask

    task automatic send_uart_byte(input logic [7:0] value, input logic valid_stop);
        integer bit_index;
        begin
            drive_uart_bit(1'b0);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
                drive_uart_bit(value[bit_index]);
            drive_uart_bit(valid_stop);
            serial_rx = 1'b1;
            repeat (CLKS_PER_BIT) tick();
        end
    endtask

    task automatic consume_byte;
        begin
            data_read = 1'b1;
            tick();
            data_read = 1'b0;
            tick();
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_receiver.fst");
        $dumpvars(0, uart_receiver_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        serial_rx = 1'b1;
        data_read = 1'b0;

        repeat (4) tick();
        n_rst = 1'b1;
        repeat (4) tick();

        send_uart_byte(8'hA5, 1'b1);
        assert(data_ready == 1'b1) else $fatal(1, "A valid UART byte should set data_ready");
        assert(rx_data == 8'hA5) else $fatal(1, "The receiver decoded the wrong byte");
        assert(framing_error == 1'b0) else $fatal(1, "A valid stop bit should not set framing_error");
        consume_byte();

        send_uart_byte(8'h3C, 1'b0);
        assert(data_ready == 1'b1) else $fatal(1, "A framed byte should still reach the receive buffer");
        assert(rx_data == 8'h3C) else $fatal(1, "The receiver should preserve data during a framing error");
        assert(framing_error == 1'b1) else $fatal(1, "A low stop bit should set framing_error");
        consume_byte();

        send_uart_byte(8'h11, 1'b1);
        assert(data_ready == 1'b1) else $fatal(1, "The first unread byte should remain ready");
        send_uart_byte(8'h22, 1'b1);
        assert(rx_data == 8'h22) else $fatal(1, "The second byte should replace the unread byte");
        assert(overrun_error == 1'b1) else $fatal(1, "A second unread byte should set overrun_error");
        consume_byte();

        for (index = 0; index < 4; index = index + 1)
            tick();
        assert(data_ready == 1'b0) else $fatal(1, "The buffer should remain empty after the read pulse");

        $display("PASS: uart_receiver_tb");
        $finish;
    end
endmodule
