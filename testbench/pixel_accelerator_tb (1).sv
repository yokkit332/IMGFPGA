`timescale 1ns/1ps

module pixel_accelerator_tb;
    logic [7:0] r_in;
    logic [7:0] g_in;
    logic [7:0] b_in;
    logic [2:0] mode_locked;
    logic [4:0] threshold_locked;
    logic [7:0] r_out;
    logic [7:0] g_out;
    logic [7:0] b_out;

    pixel_accelerator dut (
        .r_in(r_in),
        .g_in(g_in),
        .b_in(b_in),
        .mode_locked(mode_locked),
        .threshold_locked(threshold_locked),
        .r_out(r_out),
        .g_out(g_out),
        .b_out(b_out)
    );

    task automatic check_pixel(
        input logic [2:0] mode_value,
        input logic [4:0] threshold_value,
        input logic [7:0] red_value,
        input logic [7:0] green_value,
        input logic [7:0] blue_value,
        input logic [7:0] expected_red,
        input logic [7:0] expected_green,
        input logic [7:0] expected_blue
    );
        begin
            mode_locked = mode_value;
            threshold_locked = threshold_value;
            r_in = red_value;
            g_in = green_value;
            b_in = blue_value;
            #1;
            assert(r_out == expected_red) else $fatal(1, "Unexpected red output for mode %0d", mode_value);
            assert(g_out == expected_green) else $fatal(1, "Unexpected green output for mode %0d", mode_value);
            assert(b_out == expected_blue) else $fatal(1, "Unexpected blue output for mode %0d", mode_value);
        end
    endtask

    initial begin
        $dumpfile("waveforms/pixel_accelerator.fst");
        $dumpvars(0, pixel_accelerator_tb);

        check_pixel(3'd0, 5'd0, 8'd10, 8'd20, 8'd30, 8'd10, 8'd20, 8'd30);
        check_pixel(3'd1, 5'd0, 8'd10, 8'd20, 8'd30, 8'd245, 8'd235, 8'd225);
        check_pixel(3'd2, 5'd20, 8'd10, 8'd240, 8'd250, 8'd30, 8'd255, 8'd255);
        check_pixel(3'd3, 5'd20, 8'd10, 8'd20, 8'd30, 8'd0, 8'd0, 8'd10);
        check_pixel(3'd4, 5'd0, 8'd100, 8'd150, 8'd200, 8'd127, 8'd127, 8'd127);
        check_pixel(3'd7, 5'd31, 8'd1, 8'd2, 8'd3, 8'd1, 8'd2, 8'd3);

        $display("PASS: pixel_accelerator_tb");
        $finish;
    end
endmodule
