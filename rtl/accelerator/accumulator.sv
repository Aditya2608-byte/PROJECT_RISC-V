`timescale 1ns/1ps

module accumulator #(
    parameter int ACC_WIDTH   = 32,
    parameter int MATRIX_SIZE = 4,
    parameter int NUM_ELEMENTS = MATRIX_SIZE * MATRIX_SIZE
)(
    input  logic                                            clk,
    input  logic                                            rst_n,
    input  logic                                            clear,
    input  logic                                            write_enable,
    input  logic [$clog2(NUM_ELEMENTS)-1:0]                 addr,
    input  logic signed [ACC_WIDTH-1:0]                     data_in,
    input  logic                                            parallel_we,
    input  logic signed [ACC_WIDTH-1:0]                     parallel_data_in [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    output logic signed [ACC_WIDTH-1:0]                     data_out,
    output logic signed [ACC_WIDTH-1:0]                     matrix_out [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1]
);

    // 4x4 matrix storage registers (16 INT32 elements)
    logic signed [ACC_WIDTH-1:0] mem [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    // Combinational readout of indexed element and full matrix
    assign data_out = mem[addr / MATRIX_SIZE][addr % MATRIX_SIZE];

    genvar r, c;
    generate
        for (r = 0; r < MATRIX_SIZE; r = r + 1) begin : gen_out_r
            for (c = 0; c < MATRIX_SIZE; c = c + 1) begin : gen_out_c
                assign matrix_out[r][c] = mem[r][c];
            end
        end
    endgenerate

    // Synchronous write / clear with active-low reset
    integer i, j;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    mem[i][j] <= '0;
                end
            end
        end else if (clear) begin
            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    mem[i][j] <= '0;
                end
            end
        end else if (parallel_we) begin
            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    mem[i][j] <= parallel_data_in[i][j];
                end
            end
        end else if (write_enable) begin
            mem[addr / MATRIX_SIZE][addr % MATRIX_SIZE] <= data_in;
        end
    end

endmodule
