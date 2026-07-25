module uart_rx_control_unit (
    input logic clk,
    input logic n_rst,
    input logic start_detected,
    input logic packet_done,

    output logic detector_enable,
    output logic start_timer,
    output logic timer_enable,
    output logic clear_shift_register,
    output logic stop_check_enable,
    output logic stop_check_clear,
    output logic load_data_buffer
);
    localparam logic [1:0] IDLE = 2'd0;
    localparam logic [1:0] RECEIVE = 2'd1;
    localparam logic [1:0] CHECK_STOP = 2'd2;
    localparam logic [1:0] LOAD_DATA = 2'd3;

    logic [1:0] state;
    logic [1:0] next_state;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start_detected)
                    next_state = RECEIVE;
            end

            RECEIVE: begin
                if (packet_done)
                    next_state = CHECK_STOP;
            end

            CHECK_STOP: begin
                next_state = LOAD_DATA;
            end

            LOAD_DATA: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always_comb begin
        detector_enable = 1'b0;
        start_timer = 1'b0;
        timer_enable = 1'b0;
        clear_shift_register = 1'b0;
        stop_check_enable = 1'b0;
        stop_check_clear = 1'b0;
        load_data_buffer = 1'b0;

        case (state)
            IDLE: begin
                detector_enable = 1'b1;
                stop_check_clear = 1'b1;

                if (start_detected) begin
                    start_timer = 1'b1;
                    clear_shift_register = 1'b1;
                end
            end

            RECEIVE: begin
                timer_enable = 1'b1;
            end

            CHECK_STOP: begin
                stop_check_enable = 1'b1;
            end

            LOAD_DATA: begin
                load_data_buffer = 1'b1;
            end

            default: begin
                detector_enable = 1'b1;
            end
        endcase
    end
endmodule
