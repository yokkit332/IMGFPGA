`timescale 1ns/1ps

module uart_stream_decoder_tb;
    localparam integer CLOCK_PERIOD = 10;
    localparam integer NUM_PIXELS = 2;

    logic clk;
    logic n_rst;
    logic [7:0] rx_data;
    logic data_ready;
    logic framing_error;
    logic overrun_error;
    logic data_read;
    logic [2:0] mode_value;
    logic mode_valid;
    logic [4:0] threshold_value;
    logic threshold_valid;
    logic [7:0] red_data;
    logic [7:0] green_data;
    logic [7:0] blue_data;
    logic pixel_valid;
    logic frame_start;
    logic frame_done;
    logic stream_error;
    integer mode_count;
    integer threshold_count;
    integer pixel_count;
    integer frame_start_count;
    integer frame_done_count;
    integer error_count;

    uart_stream_decoder #(
        .NUM_PIXELS(NUM_PIXELS)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .rx_data(rx_data),
        .data_ready(data_ready),
        .framing_error(framing_error),
        .overrun_error(overrun_error),
        .data_read(data_read),
        .mode_value(mode_value),
        .mode_valid(mode_valid),
        .threshold_value(threshold_value),
        .threshold_valid(threshold_valid),
        .red_data(red_data),
        .green_data(green_data),
        .blue_data(blue_data),
        .pixel_valid(pixel_valid),
        .frame_start(frame_start),
        .frame_done(frame_done),
        .stream_error(stream_error)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    always_ff @(posedge clk) begin
        if (!n_rst) begin
            mode_count <= 0;
            threshold_count <= 0;
            pixel_count <= 0;
            frame_start_count <= 0;
            frame_done_count <= 0;
            error_count <= 0;
        end else begin
            if (mode_valid)
                mode_count <= mode_count + 1;
            if (threshold_valid)
                threshold_count <= threshold_count + 1;
            if (pixel_valid)
                pixel_count <= pixel_count + 1;
            if (frame_start)
                frame_start_count <= frame_start_count + 1;
            if (frame_done)
                frame_done_count <= frame_done_count + 1;
            if (stream_error)
                error_count <= error_count + 1;
        end
    end

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task automatic send_byte(input logic [7:0] value, input logic frame_error_value, input logic overrun_value);
        begin
            @(negedge clk);
            rx_data = value;
            framing_error = frame_error_value;
            overrun_error = overrun_value;
            data_ready = 1'b1;

            while (!data_read)
                tick();

            @(negedge clk);
            data_ready = 1'b0;
            framing_error = 1'b0;
            overrun_error = 1'b0;
            tick();
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_stream_decoder.fst");
        $dumpvars(0, uart_stream_decoder_tb);

        clk = 1'b0;
        n_rst = 1'b0;
        rx_data = 8'h00;
        data_ready = 1'b0;
        framing_error = 1'b0;
        overrun_error = 1'b0;

        repeat (3) tick();
        n_rst = 1'b1;
        tick();

        send_byte(8'hA0, 1'b0, 1'b0);
        send_byte(8'h04, 1'b0, 1'b0);
        send_byte(8'hA1, 1'b0, 1'b0);
        send_byte(8'h11, 1'b0, 1'b0);
        send_byte(8'hA2, 1'b0, 1'b0);

        send_byte(8'hA0, 1'b0, 1'b0);
        send_byte(8'hA1, 1'b0, 1'b0);
        send_byte(8'hA2, 1'b0, 1'b0);
        send_byte(8'h12, 1'b0, 1'b0);
        send_byte(8'h34, 1'b0, 1'b0);
        send_byte(8'h56, 1'b0, 1'b0);

        repeat (3) tick();

        assert(mode_value == 3'd4) else $fatal(1, "The mode command was decoded incorrectly");
        assert(threshold_value == 5'd17) else $fatal(1, "The threshold command was decoded incorrectly");
        assert(mode_count == 1) else $fatal(1, "mode_valid should pulse once");
        assert(threshold_count == 1) else $fatal(1, "threshold_valid should pulse once");
        assert(frame_start_count == 1) else $fatal(1, "frame_start should pulse once");
        assert(pixel_count == 2) else $fatal(1, "Two RGB pixels should produce two pixel_valid pulses");
        assert(frame_done_count == 1) else $fatal(1, "The frame should finish after NUM_PIXELS pixels");
        assert(red_data == 8'h12) else $fatal(1, "The final red byte was decoded incorrectly");
        assert(green_data == 8'h34) else $fatal(1, "The final green byte was decoded incorrectly");
        assert(blue_data == 8'h56) else $fatal(1, "The final blue byte was decoded incorrectly");

        send_byte(8'hA2, 1'b0, 1'b0);
        send_byte(8'hAA, 1'b0, 1'b0);
        send_byte(8'hBB, 1'b1, 1'b0);
        repeat (2) tick();
        assert(error_count == 1) else $fatal(1, "A UART error should create one stream_error pulse");

        send_byte(8'hA0, 1'b0, 1'b0);
        send_byte(8'h01, 1'b0, 1'b0);
        repeat (2) tick();
        assert(mode_value == 3'd1) else $fatal(1, "The decoder should recover after a stream error");
        assert(mode_count == 2) else $fatal(1, "The recovery mode command should pulse mode_valid");

        $display("PASS: uart_stream_decoder_tb");
        $finish;
    end
endmodule
