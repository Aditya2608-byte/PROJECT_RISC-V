`timescale 1ns/1ps

module pe #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input  logic                             clk,
    input  logic                             rst_n,
    input  logic                             enable,
    input  logic                             clear,
    input  logic signed [DATA_WIDTH-1:0]     a_in,
    input  logic signed [DATA_WIDTH-1:0]     b_in,
    output logic signed [ACC_WIDTH-1:0]      acc_out
);

    // Instantiate MAC unit inside Processing Element
    mac #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_mac (
        .clk    (clk),
        .rst_n  (rst_n),
        .enable (enable),
        .clear  (clear),
        .a      (a_in),
        .b      (b_in),
        .acc    (acc_out)
    );

endmodule
