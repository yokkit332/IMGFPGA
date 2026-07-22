`timescale 1ns/1ps
module top_tb;


    // 66 Mhz clk / 115200 baud rate is clks_per_bit
    localparam CLKS_PER_BIT = 572; // default 572, 10 for speed
    

    // #1 toggle = 2 time units per cycle
    localparam CLK_PERIOD   = 2;                    

    // how long we have to hold each bit so UART reads it correctly
    localparam BIT_PERIOD   = CLKS_PER_BIT * CLK_PERIOD;  // 1144

    // mode codes
    localparam MODE_PASSTHROUGH = 3'b000;
    localparam MODE_INVERTER    = 3'b001;
    localparam MODE_BRIGHTEN    = 3'b010;
    localparam MODE_DARKEN      = 3'b011;
    localparam MODE_GRAYSCALE   = 3'b100;

    logic clk, n_rst;
    logic tb_rx_r, tb_rx_g, tb_rx_b, tb_rx_config;
    logic tb_tx_r, tb_tx_g, tb_tx_b;
    logic [7:0] received_r, received_g, received_b;
    integer error_count;

    // fast version
    /*
    top #(.CLOCK_FREQ(1000), .BAUD_RATE(100)
    )DUT (
        .clk(clk), .n_rst(n_rst),
        .rx_r(tb_rx_r), .rx_g(tb_rx_g), .rx_b(tb_rx_b), .rx_config(tb_rx_config),
        .tx_r(tb_tx_r), .tx_g(tb_tx_g), .tx_b(tb_tx_b)
    );
    */

    // default 66Mhz 115200 baud
    top #(
    )DUT (
        .clk(clk), .n_rst(n_rst),
        .rx_r(tb_rx_r), .rx_g(tb_rx_g), .rx_b(tb_rx_b), .rx_config(tb_rx_config),
        .tx_r(tb_tx_r), .tx_g(tb_tx_g), .tx_b(tb_tx_b)
    );
    

    initial clk = 0;
    always #1 clk = ~clk;

    // reset task
    task reset();
    begin
        $display("\nRESETTING DUT...\n");
        n_rst = 0;
        // when idle, rx lines need to be high
        tb_rx_r = 1; tb_rx_g = 1; tb_rx_b = 1; tb_rx_config = 1;
        @(posedge clk);
        @(posedge clk);
        n_rst = 1;
        @(posedge clk);
    end
    endtask


    // tasks to send bytes to UART with start bit, 8 data bits LSB first, and one stop bit 
    task send_byte_r(input logic [7:0] data);
        integer i;
    begin

        // start bit
        tb_rx_r = 1'b0;
        #(BIT_PERIOD);

        // send data thru UART one at a time LSB first
        for (i = 0; i < 8; i = i + 1) begin
            tb_rx_r = data[i];
            #(BIT_PERIOD);
        end

        // stop bit
        tb_rx_r = 1'b1;
        #(BIT_PERIOD);
    end
    endtask

    // same thing for g
    task send_byte_g(input logic [7:0] data);
        integer i;
    begin
        tb_rx_g = 1'b0;
        #(BIT_PERIOD);
        for (i = 0; i < 8; i = i + 1) begin
            tb_rx_g = data[i];
            #(BIT_PERIOD);
        end
        tb_rx_g = 1'b1;
        #(BIT_PERIOD);
    end
    endtask

    // same thing for b
    task send_byte_b(input logic [7:0] data);
        integer i;
    begin
        tb_rx_b = 1'b0;
        #(BIT_PERIOD);
        for (i = 0; i < 8; i = i + 1) begin
            tb_rx_b = data[i];
            #(BIT_PERIOD);
        end
        tb_rx_b = 1'b1;
        #(BIT_PERIOD);
    end
    endtask

    // same thing for config
    task send_config_byte(input logic [7:0] data);
        integer i;
    begin
        tb_rx_config = 1'b0;
        #(BIT_PERIOD);
        for (i = 0; i < 8; i = i + 1) begin
            tb_rx_config = data[i];
            #(BIT_PERIOD);
        end
        tb_rx_config = 1'b1;
        #(BIT_PERIOD);
    end
    endtask

    // send mode byte then threshold byte
    task configure(input logic [2:0] mode, input logic [4:0] threshold);
    begin
        send_config_byte({5'b0, mode});
        send_config_byte({3'b0, threshold});
    end
    endtask

    // send one RGB pixel, one channel at a time
    task send_pixel(input logic [7:0] r, input logic [7:0] g, input logic [7:0] b);
    begin
        send_byte_r(r);
        send_byte_g(g);
        send_byte_b(b);
    end
    endtask

    // read RGB channels of one pixel back from chip's tx pins
    task receive_pixel();
        integer i;
    begin
        // wait for uart tx start line to drop to 0 to know when to capture the byte
        @(negedge tb_tx_r);

        // skip start bit, land in middle of bit 0
        #(BIT_PERIOD + BIT_PERIOD/2);

        // read one bit at a time, 8 times, for all 3 channels
        for (i = 0; i < 8; i = i + 1) begin
            received_r[i] = tb_tx_r;
            received_g[i] = tb_tx_g;
            received_b[i] = tb_tx_b;
            #(BIT_PERIOD);   // move to the next bit
        end
    end
    endtask

    // task to send a pixel and then receive it
    task run_pixel(input logic [7:0] r_in, input logic [7:0] g_in, input logic [7:0] b_in);
    begin
        // fork runs both send and receive simultaneously then waits for all to finish
        fork
            send_pixel(r_in, g_in, b_in);
            receive_pixel();
        join
    end
    endtask

    // check if the pixel is correctly written and read
    task check_pixel(input logic [7:0] exp_r, input logic [7:0] exp_g, input logic [7:0] exp_b,
                      input logic [7:0] act_r, input logic [7:0] act_g, input logic [7:0] act_b);
    begin
        if (act_r !== exp_r || act_g !== exp_g || act_b !== exp_b) begin
            error_count = error_count + 1;
            $error("FAILED: expected R=%0d G=%0d B=%0d, got R=%0d G=%0d B=%0d",
                    exp_r, exp_g, exp_b, act_r, act_g, act_b);
        end else begin
            $display("PASSED: R=%0d G=%0d B=%0d", act_r, act_g, act_b);
        end
    end
    endtask

    // TEST SCENARIOS
    task test_passthrough();
    begin
        $display("\n===TEST 1: PASSTHROUGH===");
        reset();
        configure(MODE_PASSTHROUGH, 5'd0);
        run_pixel(8'd120, 8'd60, 8'd200);
        check_pixel(8'd120, 8'd60, 8'd200, received_r, received_g, received_b);
    end
    endtask

    task test_invert();
    begin
        $display("\n===TEST 2: INVERT===");
        reset();
        configure(MODE_INVERTER, 5'd0);
        run_pixel(8'd100, 8'd50, 8'd10);
        check_pixel(8'd155, 8'd205, 8'd245, received_r, received_g, received_b);
    end
    endtask

    // brighten with no clipping
    task test_brighten_no_clip();
    begin
        $display("\n===TEST 3: BRIGHTEN (no clipping)===");
        reset();
        configure(MODE_BRIGHTEN, 5'd20);
        run_pixel(8'd100, 8'd100, 8'd100);
        check_pixel(8'd120, 8'd120, 8'd120, received_r, received_g, received_b);
    end
    endtask

    // brighten with clipping
    task test_brighten_clip();
    begin
        $display("\n===TEST 4: BRIGHTEN (has clip)===");
        reset();
        configure(MODE_BRIGHTEN, 5'd20);
        run_pixel(8'd250, 8'd250, 8'd250);
        check_pixel(8'd255, 8'd255, 8'd255, received_r, received_g, received_b);
    end
    endtask

    // darken with no clipping
    task test_darken_no_clip();
    begin
        $display("\n===TEST 5: DARKEN (no clip)===");
        reset();
        configure(MODE_DARKEN, 5'd20);
        run_pixel(8'd100, 8'd100, 8'd100);
        check_pixel(8'd80, 8'd80, 8'd80, received_r, received_g, received_b);
    end
    endtask

    // darken with clipping
    task test_darken_clip();
    begin
        $display("\n===TEST 6: DARKEN (clipping)===");
        reset();
        configure(MODE_DARKEN, 5'd16);
        run_pixel(8'd5, 8'd5, 8'd5);
        check_pixel(8'd0, 8'd0, 8'd0, received_r, received_g, received_b);
    end
    endtask

    task test_grayscale();
    begin
        $display("\n===TEST 7: GRAYSCALE===");
        reset();
        configure(MODE_GRAYSCALE, 5'd0);
        // gray = (r>>2)+(r>>4)+(g>>1)+(g>>4)+(b>>4)
        // r=200,g=100,b=50 -> 50+12+50+6+3 = 121
        run_pixel(8'd200, 8'd100, 8'd50);
        check_pixel(8'd121, 8'd121, 8'd121, received_r, received_g, received_b);
    end
    endtask

    // test multiple pixels back to back
    task test_back_to_back();
        integer i;
    begin
        $display("\n===TEST 8: MULTIPLE PIXELS BACK TO BACK===");
        reset();
        configure(MODE_PASSTHROUGH, 5'd0);
        for (i = 0; i < 10; i = i + 1) begin
            $display("-- pixel %0d --", i);

            // since i is a 32 bit integer, only need to send least significant 8 bits to tasks
            run_pixel(i[7:0], i[7:0]+8'd1, i[7:0]+8'd2);
            check_pixel(i[7:0], i[7:0]+8'd1, i[7:0]+8'd2, received_r, received_g, received_b);
        end
    end
    endtask

    task test_full_frame_rollover();
        integer i;
    begin
        $display("\n===TEST 9: FULL 4800-PIXEL FRAME + ROLLOVER===");
        $display("simulating...yes it takes a lot of time...");
        reset();
        configure(MODE_PASSTHROUGH, 5'd0);

        for (i = 0; i < 4800; i = i + 1) begin
            run_pixel(8'd50, 8'd60, 8'd70);
            if (received_r !== 8'd50 || received_g !== 8'd60 || received_b !== 8'd70) begin
                error_count = error_count + 1;
                $error("FAILED at pixel %0d of frame", i);
            end
            else if(i % 200 == 0) begin
                $display("byte %0d finished processing...", i);
            end
        end
        $display("Completed 4800 pixels -- FSM should have rolled over to INPUT_MODE");

        // prove rollover happened: reconfigure WITHOUT reset and confirm it takes effect
        configure(MODE_INVERTER, 5'd0);
        run_pixel(8'd10, 8'd10, 8'd10);
        check_pixel(8'd245, 8'd245, 8'd245, received_r, received_g, received_b);
    end
    endtask

    initial begin
        //$dumpfile("top_sim.vcd");
        //$dumpvars(0, top_tb);
        error_count = 0;

        test_passthrough();
        test_invert();
        test_brighten_no_clip();
        test_brighten_clip();
        test_darken_no_clip();
        test_darken_clip();
        test_grayscale();
        test_back_to_back();
        test_full_frame_rollover();   // comment out for faster iteration

        $display("\n=====================================");
        if (error_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", error_count);
        $display("=====================================\n");

        $finish;
    end

endmodule
