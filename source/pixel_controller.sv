module pixel_controller (
    input logic clk,
    input logic n_rst,

    input logic [2:0] mode_value,
    input logic mode_valid,
    input logic [4:0] threshold_value,
    input logic threshold_valid,

    input logic [7:0] decoded_red,
    input logic [7:0] decoded_green,
    input logic [7:0] decoded_blue,
    input logic pixel_valid,
    input logic frame_start,

    input logic transmitter_ready,

    output logic [7:0] red_locked,
    output logic [7:0] green_locked,
    output logic [7:0] blue_locked,
    output logic [2:0] mode_locked,
    output logic [4:0] threshold_locked,
    output logic transmit_pixel,
    output logic pixel_overrun
);
    localparam logic [1:0] WAIT_PIXEL = 2'd0;
    localparam logic [1:0] START_TX = 2'd1;
    localparam logic [1:0] WAIT_BUSY = 2'd2;
    localparam logic [1:0] WAIT_DONE = 2'd3;

    logic [1:0] state;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            state <= WAIT_PIXEL;
            red_locked <= 8'd0;
            green_locked <= 8'd0;
            blue_locked <= 8'd0;
            mode_locked <= 3'd0;
            threshold_locked <= 5'd0;
            transmit_pixel <= 1'b0;
            pixel_overrun <= 1'b0;
        end
        else begin
            transmit_pixel <= 1'b0;

            if (mode_valid)
                mode_locked <= mode_value;

            if (threshold_valid)
                threshold_locked <= threshold_value;

            if (frame_start)
                pixel_overrun <= 1'b0;

            case (state)
                WAIT_PIXEL: begin
                    if (pixel_valid) begin
                        red_locked <= decoded_red;
                        green_locked <= decoded_green;
                        blue_locked <= decoded_blue;
                        state <= START_TX;
                    end
                end

                START_TX: begin

                    if (transmitter_ready) begin
                        transmit_pixel <= 1'b1;
                        state <= WAIT_BUSY;
                    end

                    if (pixel_valid)
                        pixel_overrun <= 1'b1;
                end

                WAIT_BUSY: begin
                    if (!transmitter_ready)
                        state <= WAIT_DONE;

                    if (pixel_valid)
                        pixel_overrun <= 1'b1;
                end

                WAIT_DONE: begin
                    if (transmitter_ready)
                        state <= WAIT_PIXEL;

                    if (pixel_valid)
                        pixel_overrun <= 1'b1;
                end

                default: begin
                    state <= WAIT_PIXEL;
                end
            endcase
        end
    end
endmodule
