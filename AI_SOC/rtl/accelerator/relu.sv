`timescale 1ns/1ps

module relu #(
    parameter int ACC_WIDTH = 32
)(
    input  logic signed [ACC_WIDTH-1:0] data_in,
    output logic signed [ACC_WIDTH-1:0] data_out
);

    // Combinational Rectified Linear Unit: max(0, data_in)
    always_comb begin
        if (data_in < 0) begin
            data_out = '0;
        end else begin
            data_out = data_in;
        end
    end

endmodule
