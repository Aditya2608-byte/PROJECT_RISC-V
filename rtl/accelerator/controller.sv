`timescale 1ns/1ps

import accelerator_pkg::*;

module controller #(
    parameter int MATRIX_SIZE = 4
)(
    input  logic                             clk,
    input  logic                             rst_n,
    input  logic                             start,
    output logic                             busy,
    output logic                             done,
    output logic                             error,
    output logic                             load_en,
    output logic                             mac_clear,
    output logic                             mac_enable,
    output logic [1:0]                       compute_step,
    output logic                             wb_en,
    output state_t                           state_out
);

    state_t state_reg, state_next;
    logic [1:0] step_cnt_reg, step_cnt_next;

    assign state_out    = state_reg;
    assign compute_step = step_cnt_reg;

    // Sequential state and counter updates
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg    <= STATE_IDLE;
            step_cnt_reg <= 2'b00;
        end else begin
            state_reg    <= state_next;
            step_cnt_reg <= step_cnt_next;
        end
    end

    // Next-state logic and control outputs
    always_comb begin
        state_next    = state_reg;
        step_cnt_next = step_cnt_reg;

        // Default control outputs
        busy       = 1'b0;
        done       = 1'b0;
        error      = 1'b0;
        load_en    = 1'b0;
        mac_clear  = 1'b0;
        mac_enable = 1'b0;
        wb_en      = 1'b0;

        case (state_reg)
            STATE_IDLE: begin
                busy = 1'b0;
                done = 1'b0;
                if (start) begin
                    state_next    = STATE_LOAD;
                    step_cnt_next = 2'b00;
                end
            end

            STATE_LOAD: begin
                busy          = 1'b1;
                load_en       = 1'b1;
                mac_clear     = 1'b1; // Clear systolic array MAC accumulators
                step_cnt_next = 2'b00;
                state_next    = STATE_COMPUTE;
            end

            STATE_COMPUTE: begin
                busy       = 1'b1;
                mac_enable = 1'b1;
                if (step_cnt_reg == MATRIX_SIZE - 1) begin
                    state_next    = STATE_ACTIVATE;
                    step_cnt_next = 2'b00;
                end else begin
                    step_cnt_next = step_cnt_reg + 1'b1;
                end
            end

            STATE_ACTIVATE: begin
                busy       = 1'b1;
                state_next = STATE_WRITEBACK;
            end

            STATE_WRITEBACK: begin
                busy       = 1'b1;
                wb_en      = 1'b1; // Latch computed matrix into accumulator storage
                state_next = STATE_DONE;
            end

            STATE_DONE: begin
                busy = 1'b0;
                done = 1'b1;
                if (!start) begin
                    state_next = STATE_IDLE;
                end
            end

            default: begin
                error      = 1'b1;
                state_next = STATE_IDLE;
            end
        endcase
    end

endmodule
