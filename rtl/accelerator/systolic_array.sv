`timescale 1ns/1ps

module systolic_array #(
    parameter int DATA_WIDTH  = 8,
    parameter int ACC_WIDTH   = 32,
    parameter int MATRIX_SIZE = 4
)(
    input  logic                                            clk,
    input  logic                                            rst_n,
    input  logic                                            enable,
    input  logic                                            clear,
    input  logic [1:0]                                      step_k,
    input  logic signed [DATA_WIDTH-1:0]                    a_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    input  logic signed [DATA_WIDTH-1:0]                    b_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    output logic signed [ACC_WIDTH-1:0]                     c_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1]
);

    // Generate 4x4 array of Processing Elements (16 PEs total)
    genvar r, c;
    generate
        for (r = 0; r < MATRIX_SIZE; r = r + 1) begin : pe_row
            for (c = 0; c < MATRIX_SIZE; c = c + 1) begin : pe_col
                // Operand muxing for row r and col c based on inner-product index step_k
                logic signed [DATA_WIDTH-1:0] pe_a_in;
                logic signed [DATA_WIDTH-1:0] pe_b_in;
                logic signed [ACC_WIDTH-1:0]  pe_acc_out;

                assign pe_a_in = a_matrix[r][step_k];
                assign pe_b_in = b_matrix[step_k][c];
                assign c_matrix[r][c] = pe_acc_out;

                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) u_pe (
                    .clk    (clk),
                    .rst_n  (rst_n),
                    .enable (enable),
                    .clear  (clear),
                    .a_in   (pe_a_in),
                    .b_in   (pe_b_in),
                    .acc_out(pe_acc_out)
                );
            end
        end
    endgenerate

endmodule
