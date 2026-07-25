module ice40hx8k (
    input logic hwclk,
    input logic [20:0] pb,
    output logic [7:0] ss7,
    output logic [7:0] ss6,
    output logic [7:0] ss5,
    output logic [7:0] ss4,
    output logic [7:0] ss3,
    output logic [7:0] ss2,
    output logic [7:0] ss1,
    output logic [7:0] ss0,
    output logic [7:0] left,
    output logic [7:0] right,
    output logic red,
    output logic green,
    output logic blue,
    input logic Rx,
    output logic Tx,
    output logic CTSn,
    output logic DCDn
);

    top top_inst (
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

endmodule