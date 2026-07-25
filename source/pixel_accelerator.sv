module pixel_accelerator (
    input logic [7:0] r_in,
    input logic [7:0] g_in,
    input logic [7:0] b_in,
    input logic [2:0] mode_locked,
    input logic [4:0] threshold_locked,
    output logic [7:0] r_out,
    output logic [7:0] g_out,
    output logic [7:0] b_out
);
    localparam logic [2:0] MODE_PASSTHROUGH = 3'b000;
    localparam logic [2:0] MODE_INVERTER = 3'b001;
    localparam logic [2:0] MODE_BRIGHTEN = 3'b010;
    localparam logic [2:0] MODE_DARKEN = 3'b011;
    localparam logic [2:0] MODE_GRAYSCALE = 3'b100;

    logic [8:0] r_brighten;
    logic [8:0] g_brighten;
    logic [8:0] b_brighten;
    logic [9:0] gray;

    always_comb begin
        r_brighten = {1'b0, r_in} + {4'b0000, threshold_locked};
        g_brighten = {1'b0, g_in} + {4'b0000, threshold_locked};
        b_brighten = {1'b0, b_in} + {4'b0000, threshold_locked};

        gray = ({2'b00, r_in} >> 2)
            + ({2'b00, r_in} >> 4)
            + ({2'b00, g_in} >> 1)
            + ({2'b00, g_in} >> 4)
            + ({2'b00, b_in} >> 4);

        case (mode_locked)
            MODE_PASSTHROUGH: begin
                r_out = r_in;
                g_out = g_in;
                b_out = b_in;
            end

            MODE_INVERTER: begin
                r_out = 8'd255 - r_in;
                g_out = 8'd255 - g_in;
                b_out = 8'd255 - b_in;
            end

            MODE_BRIGHTEN: begin
                r_out = r_brighten[8] ? 8'd255 : r_brighten[7:0];
                g_out = g_brighten[8] ? 8'd255 : g_brighten[7:0];
                b_out = b_brighten[8] ? 8'd255 : b_brighten[7:0];
            end

            MODE_DARKEN: begin
                r_out = (r_in < {3'b000, threshold_locked})
                    ? 8'd0 : r_in - {3'b000, threshold_locked};
                g_out = (g_in < {3'b000, threshold_locked})
                    ? 8'd0 : g_in - {3'b000, threshold_locked};
                b_out = (b_in < {3'b000, threshold_locked})
                    ? 8'd0 : b_in - {3'b000, threshold_locked};
            end

            MODE_GRAYSCALE: begin
                r_out = gray[7:0];
                g_out = gray[7:0];
                b_out = gray[7:0];
            end

            default: begin
                r_out = r_in;
                g_out = g_in;
                b_out = b_in;
            end
        endcase
    end
endmodule
