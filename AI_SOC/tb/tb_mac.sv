`timescale 1ns/1ps

module tb_mac;

    parameter int DATA_WIDTH = 8;
    parameter int ACC_WIDTH  = 32;

    logic                             clk;
    logic                             rst_n;
    logic                             enable;
    logic                             clear;
    logic signed [DATA_WIDTH-1:0]     a;
    logic signed [DATA_WIDTH-1:0]     b;
    logic signed [ACC_WIDTH-1:0]      acc;

    int pass_count = 0;
    int fail_count = 0;

    // Instantiate MAC module under test
    mac #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .enable (enable),
        .clear  (clear),
        .a      (a),
        .b      (b),
        .acc    (acc)
    );

    // Clock Generation: 10ns period (100MHz)
    always #5 clk = ~clk;

    // Helper task to check results
    task check_result(input string test_name, input logic signed [ACC_WIDTH-1:0] expected);
        @(posedge clk);
        #1; // Sample after clock edge
        if (acc === expected) begin
            $display("[PASS] %s | Expected: %0d, Got: %0d", test_name, expected, acc);
            pass_count++;
        end else begin
            $display("[FAIL] %s | Expected: %0d, Got: %0d", test_name, expected, acc);
            fail_count++;
        end
    endtask

    initial begin
        // Setup VCD waveform dump
        $dumpfile("waves/tb_mac.vcd");
        $dumpvars(0, tb_mac);

        $display("==================================================");
        $display("          RUNNING MAC MODULE TESTBENCH            ");
        $display("==================================================");

        // Initialize signals
        clk    = 0;
        rst_n  = 0;
        enable = 0;
        clear  = 0;
        a      = 0;
        b      = 0;

        // TEST 1: Reset Behavior
        #20;
        rst_n = 1;
        check_result("TEST 1: Reset -> Acc is 0", 32'sd0);

        // TEST 2: Positive * Positive
        @(negedge clk);
        enable = 1;
        a = 8'sd5;
        b = 8'sd6;
        check_result("TEST 2: 5 * 6 = 30", 32'sd30);

        // TEST 3: Positive * Negative
        @(negedge clk);
        enable = 1;
        a = 8'sd4;
        b = -8'sd10; // 30 + (4 * -10) = 30 - 40 = -10
        check_result("TEST 3: Acc(-10) via 4 * -10", -32'sd10);

        // TEST 4: Negative * Negative
        @(negedge clk);
        enable = 1;
        a = -8'sd7;
        b = -8'sd8; // -10 + (-7 * -8) = -10 + 56 = 46
        check_result("TEST 4: Acc(46) via -7 * -8", 32'sd46);

        // TEST 5: Clear Operation
        @(negedge clk);
        enable = 0;
        clear  = 1;
        check_result("TEST 5: Clear signal -> Acc is 0", 32'sd0);

        // TEST 6: Multiple accumulated MAC operations
        @(negedge clk);
        clear  = 0;
        enable = 1;
        a = 8'sd12; b = 8'sd3;  // +36 (acc = 36)
        @(posedge clk); #1;
        a = 8'sd10; b = 8'sd10; // +100 (acc = 136)
        @(posedge clk); #1;
        a = -8'sd5; b = 8'sd6;  // -30 (acc = 106)
        check_result("TEST 6: Accumulated 3 steps -> 106", 32'sd106);

        // TEST 7: Extreme signed limits (INT8 max / min)
        @(negedge clk);
        clear = 1;
        @(negedge clk);
        clear = 0;
        enable = 1;
        a = -8'sd128; // Min signed 8-bit
        b = -8'sd128; // Min signed 8-bit -> Product is +16384
        check_result("TEST 7: Signed INT8 min * min = +16384", 32'sd16384);

        // TEST 8: Enable = 0 holds accumulator value
        @(negedge clk);
        enable = 0;
        a = 8'sd100;
        b = 8'sd100;
        check_result("TEST 8: Enable=0 holds value (16384)", 32'sd16384);

        #20;
        $display("==================================================");
        $display("MAC TEST RESULTS: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("==================================================");

        if (fail_count == 0) begin
            $display("[ALL MAC TESTS PASSED]");
        end else begin
            $display("[MAC TESTS FAILED]");
        end

        $finish;
    end

endmodule
