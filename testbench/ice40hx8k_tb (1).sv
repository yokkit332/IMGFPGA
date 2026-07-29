`timescale 1ns/1ps

module ice40hx8k_tb;
    localparam integer CLOCK_PERIOD = 10;
    localparam integer CLKS_PER_BIT = 104;

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

    ice40hx8k dut (
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

    initial begin
        $dumpfile("waveforms/ice40hx8k.fst");
        $dumpvars(0, ice40hx8k_tb);

        hwclk = 1'b0;
        pb = '0;
        Rx = 1'b1;

        pb[0] = 1'b1;
        repeat (4) tick();
        pb[0] = 1'b0;
        repeat (5) tick();

        send_uart_byte(8'hA0);
        send_uart_byte(8'h04);
        send_uart_byte(8'hA1);
        send_uart_byte(8'h11);
        Rx = 1'b1;
        repeat (CLKS_PER_BIT) tick();

        assert(right == 8'h91) else $fatal(1, "The wrapper should pass mode 4 and threshold 17 into top");
        assert(CTSn == 1'b0) else $fatal(1, "CTSn should be tied low through the wrapper");
        assert(DCDn == 1'b0) else $fatal(1, "DCDn should be tied low through the wrapper");
        assert(red == 1'b0) else $fatal(1, "A valid command sequence should not latch an error");

        $display("PASS: ice40hx8k_tb");
        $finish;
    end
endmodule
