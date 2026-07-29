`timescale 1ns/1ps

module uart_rgb_tx_shift_register_30bit_tb;
    localparam integer CLOCK_PERIOD = 10;

    logic clk;
    logic n_rst;
    logic load;
    logic shift_strobe;
    logic [7:0] red_data;
    logic [7:0] green_data;
    logic [7:0] blue_data;
    logic serial_tx;
    integer index;

    uart_rgb_tx_shift_register_30bit dut (
        .clk(clk),
        .n_rst(n_rst),
        .load(load),
        .shift_strobe(shift_strobe),
        .red_data(red_data),
        .green_data(green_data),
        .blue_data(blue_data),
        .serial_tx(serial_tx)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    function automatic logic expected_bit(input integer bit_index);
        begin
            if (bit_index == 0)
                expected_bit = 1'b0;
            else if (bit_index >= 1 && bit_index <= 8)
                expected_bit = red_data[bit_index - 1];
            else if (bit_index == 9)
                expected_bit = 1'b1;
            else if (bit_index == 10)
                expected_bit = 1'b0;
            else if (bit_index >= 11 && bit_index <= 18)
                expected_bit = green_data[bit_index - 11];
            else if (bit_index == 19)
                expected_bit = 1'b1;
            else if (bit_index == 20)
                expected_bit = 1'b0;
            else if (bit_index >= 21 && bit_index <= 28)
                expected_bit = blue_data[bit_index - 21];
            else
                expected_bit = 1'b1;
        end
    endfunction

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task automatic shift_once;
        begin
            shift_strobe = 1'b1;
            tick();
            shift_strobe = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_rgb_tx_shift_register_30bit.fst");
        $dumpvars(0, uart_rgb_tx_shift_register_30bit_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        load = 1'b0;
        shift_strobe = 1'b0;
        red_data = 8'hA5;
        green_data = 8'h3C;
        blue_data = 8'h81;

        repeat (2) tick();
        assert(serial_tx == 1'b1) else $fatal(1, "Reset should leave the UART output idle high");

        n_rst = 1'b1;
        load = 1'b1;
        tick();
        load = 1'b0;

        for (index = 0; index < 30; index = index + 1) begin
            assert(serial_tx == expected_bit(index)) else $fatal(1, "Unexpected serialized bit at position %0d", index);
            if (index < 29)
                shift_once();
        end

        shift_once();
        assert(serial_tx == 1'b1) else $fatal(1, "The shift register should fill with idle-high bits");

        $display("PASS: uart_rgb_tx_shift_register_30bit_tb");
        $finish;
    end
endmodule
