`timescale 1ns/1ps

module uart_rx_data_buffer_tb;
    localparam integer CLOCK_PERIOD = 10;

    logic clk;
    logic n_rst;
    logic load_buffer;
    logic data_read;
    logic [7:0] packet_data;
    logic framing_error_in;
    logic [7:0] rx_data;
    logic data_ready;
    logic framing_error;
    logic overrun_error;

    uart_rx_data_buffer dut (
        .clk(clk),
        .n_rst(n_rst),
        .load_buffer(load_buffer),
        .data_read(data_read),
        .packet_data(packet_data),
        .framing_error_in(framing_error_in),
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

    task automatic load_byte(input logic [7:0] value, input logic frame_error);
        begin
            packet_data = value;
            framing_error_in = frame_error;
            load_buffer = 1'b1;
            tick();
            load_buffer = 1'b0;
        end
    endtask

    task automatic read_byte;
        begin
            data_read = 1'b1;
            tick();
            data_read = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_rx_data_buffer.fst");
        $dumpvars(0, uart_rx_data_buffer_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        load_buffer = 1'b0;
        data_read = 1'b0;
        packet_data = 8'h00;
        framing_error_in = 1'b0;

        repeat (2) tick();
        n_rst = 1'b1;
        tick();

        load_byte(8'h3C, 1'b0);
        assert(rx_data == 8'h3C) else $fatal(1, "The receive buffer stored the wrong byte");
        assert(data_ready == 1'b1) else $fatal(1, "Loading a byte should assert data_ready");
        assert(overrun_error == 1'b0) else $fatal(1, "The first byte should not cause an overrun");

        load_byte(8'hA7, 1'b1);
        assert(rx_data == 8'hA7) else $fatal(1, "A new load should replace the old byte");
        assert(framing_error == 1'b1) else $fatal(1, "The framing status should be stored with the byte");
        assert(overrun_error == 1'b1) else $fatal(1, "Loading over unread data should set overrun_error");

        read_byte();
        assert(data_ready == 1'b0) else $fatal(1, "data_read should clear data_ready");
        assert(framing_error == 1'b0) else $fatal(1, "data_read should clear framing_error");
        assert(overrun_error == 1'b0) else $fatal(1, "data_read should clear overrun_error");

        packet_data = 8'h55;
        framing_error_in = 1'b0;
        load_buffer = 1'b1;
        data_read = 1'b1;
        tick();
        load_buffer = 1'b0;
        data_read = 1'b0;
        assert(data_ready == 1'b1) else $fatal(1, "A simultaneous load and read should keep the new byte ready");
        assert(overrun_error == 1'b0) else $fatal(1, "A simultaneous read should prevent an overrun");

        $display("PASS: uart_rx_data_buffer_tb");
        $finish;
    end
endmodule
