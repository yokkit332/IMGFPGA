`timescale 1ns/1ps

module top_tb;
    localparam integer CLOCK_PERIOD = 10;
    localparam integer CLOCK_FREQ = 160;
    localparam integer BAUD_RATE = 10;
    localparam integer CLKS_PER_BIT = 16;
    localparam integer NUM_PIXELS = 2;
    localparam integer FIFO_DEPTH = 4;

    logic hwclk;
    logic [20:0] pb;
    logic [7:0] ss7;
    logic [7:0] ss6;
    logic [7:0] ss5;
    logic [7:0] ss4;
    logic [7:0] ss3;
    logic [7:0] ss2;
    logic [7:0] ss1;
    logic [7:0] ss0;
    logic [7:0] left;
    logic [7:0] right;
    logic red;
    logic green;
    logic blue;
    logic Rx;
    logic Tx;
    logic CTSn;
    logic DCDn;
    logic [7:0] received0;
    logic [7:0] received1;
    logic [7:0] received2;
    logic [7:0] received3;
    logic [7:0] received4;
    logic [7:0] received5;

    top #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .NUM_PIXELS(NUM_PIXELS),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .hwclk(hwclk),
        .pb(pb),
        .ss7(ss7),
        .ss6(ss6),
        .ss5(ss5),
        .ss4(ss4),
        .ss3(ss3),
        .ss2(ss2),
        .ss1(ss1),
        .ss0(ss0),
        .left(left),
        .right(right),
        .red(red),
        .green(green),
        .blue(blue),
        .Rx(Rx),
        .Tx(Tx),
        .CTSn(CTSn),
        .DCDn(DCDn)
    );

    always #(CLOCK_PERIOD / 2) hwclk = ~hwclk;

    task automatic tick;
        begin
            @(posedge hwclk);
            #1;
        end
    endtask

    task automatic drive_uart_bit(input logic value);
        begin
            Rx = value;
            repeat (CLKS_PER_BIT) tick();
        end
    endtask

    task automatic send_uart_byte(input logic [7:0] value);
        integer bit_index;
        begin
            drive_uart_bit(1'b0);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
                drive_uart_bit(value[bit_index]);
            drive_uart_bit(1'b1);
        end
    endtask

    task automatic receive_uart_byte(output logic [7:0] value);
        integer bit_index;
        begin
            @(negedge Tx);
            repeat (CLKS_PER_BIT + (CLKS_PER_BIT / 2)) tick();
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                value[bit_index] = Tx;
                repeat (CLKS_PER_BIT) tick();
            end
            assert(Tx == 1'b1) else $fatal(1, "The transmitted UART stop bit should be high");
        end
    endtask

    initial begin
        $dumpfile("waveforms/top.fst");
        $dumpvars(0, top_tb);

        hwclk = 1'b0;
        pb = '0;
        Rx = 1'b1;
        received0 = 8'h00;
        received1 = 8'h00;
        received2 = 8'h00;
        received3 = 8'h00;
        received4 = 8'h00;
        received5 = 8'h00;

        pb[0] = 1'b1;
        repeat (4) tick();
        pb[0] = 1'b0;
        repeat (5) tick();

        fork
            begin
                receive_uart_byte(received0);
                receive_uart_byte(received1);
                receive_uart_byte(received2);
                receive_uart_byte(received3);
                receive_uart_byte(received4);
                receive_uart_byte(received5);
            end
            begin
                send_uart_byte(8'hA0);
                send_uart_byte(8'h01);
                send_uart_byte(8'hA1);
                send_uart_byte(8'h00);
                send_uart_byte(8'hA2);
                send_uart_byte(8'd10);
                send_uart_byte(8'd20);
                send_uart_byte(8'd30);
                send_uart_byte(8'hA0);
                send_uart_byte(8'hA1);
                send_uart_byte(8'hA2);
                Rx = 1'b1;
            end
        join

        repeat (10) tick();

        assert(received0 == 8'd245) else $fatal(1, "The first inverted red byte is incorrect");
        assert(received1 == 8'd235) else $fatal(1, "The first inverted green byte is incorrect");
        assert(received2 == 8'd225) else $fatal(1, "The first inverted blue byte is incorrect");
        assert(received3 == 8'h5F) else $fatal(1, "A0 should be treated as pixel data inside the frame");
        assert(received4 == 8'h5E) else $fatal(1, "A1 should be treated as pixel data inside the frame");
        assert(received5 == 8'h5D) else $fatal(1, "A2 should be treated as pixel data inside the frame");
        assert(right == 8'h20) else $fatal(1, "The board status output should show mode 1 and threshold 0");
        assert(green == 1'b1) else $fatal(1, "The frame-done LED should latch high");
        assert(red == 1'b0) else $fatal(1, "No error should be latched during the valid transfer");
        assert(CTSn == 1'b0) else $fatal(1, "CTSn should be tied low");
        assert(DCDn == 1'b0) else $fatal(1, "DCDn should be tied low");
        assert(ss7 == 8'h00 && ss6 == 8'h00 && ss5 == 8'h00 && ss4 == 8'h00) else $fatal(1, "The upper seven-segment displays should be off");
        assert(ss3 == 8'h00 && ss2 == 8'h00 && ss1 == 8'h00 && ss0 == 8'h00) else $fatal(1, "The lower seven-segment displays should be off");

        $display("PASS: top_tb");
        $finish;
    end
endmodule
