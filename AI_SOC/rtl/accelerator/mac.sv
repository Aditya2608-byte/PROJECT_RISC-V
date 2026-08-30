`timescale 1ns/1ps

module mac #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input  logic                             clk,
    input  logic                             rst_n,
    input  logic                             enable,
    input  logic                             clear,
    input  logic signed [DATA_WIDTH-1:0]     a,
    input  logic signed [DATA_WIDTH-1:0]     b,
    output logic signed [ACC_WIDTH-1:0]      acc
);

    // Explicit signed multiplication product
    logic signed [(2*DATA_WIDTH)-1:0] mult_product;

    // Signed multiplication of inputs a and b
    always_comb begin
        mult_product = a * b;
    end

    // Clocked synchronous accumulation with active-low asynchronous/synchronous reset
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= '0;
        end else if (clear) begin
            acc <= '0;
        end else if (enable) begin
            // Sign-extended accumulation into 32-bit register
            acc <= acc + { {(ACC_WIDTH - 2*DATA_WIDTH){mult_product[(2*DATA_WIDTH)-1]}}, mult_product };
        end
    end

endmodule
