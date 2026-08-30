`timescale 1ns/1ps

import accelerator_pkg::*;

module tb_accelerator;

    parameter int DATA_WIDTH   = 8;
    parameter int ACC_WIDTH    = 32;
    parameter int MATRIX_SIZE  = 4;

    logic                                            clk;
    logic                                            rst_n;
    logic                                            start;
    logic                                            activation_enable;
    logic signed [DATA_WIDTH-1:0]                    a_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [DATA_WIDTH-1:0]                    b_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [ACC_WIDTH-1:0]                     c_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic                                            busy;
    logic                                            done;
    logic                                            error;

    logic                                            reg_we;
    logic [31:0]                                     reg_addr;
    logic [31:0]                                     reg_wdata;
    logic [31:0]                                     reg_rdata;

    int total_tests = 0;
    int passed_tests = 0;
    int failed_tests = 0;

    // Instantiate AI Accelerator DUT
    ai_accelerator #(
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .start            (start),
        .activation_enable(activation_enable),
        .a_matrix         (a_matrix),
        .b_matrix         (b_matrix),
        .c_matrix         (c_matrix),
        .busy             (busy),
        .done             (done),
        .error            (error),
        .reg_we           (reg_we),
        .reg_addr         (reg_addr),
        .reg_wdata        (reg_wdata),
        .reg_rdata        (reg_rdata)
    );

    // 100MHz clock generation (10ns period)
    always #5 clk = ~clk;

    // Test matrix definitions
    logic signed [DATA_WIDTH-1:0] test_a [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [DATA_WIDTH-1:0] test_b [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    // Task to run and verify a 4x4 matrix multiplication test case
    task run_matrix_test(
        input string test_title,
        input logic act_en
    );
        logic signed [ACC_WIDTH-1:0] expected [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
        int r, c, k;
        bit test_pass;
        int timeout_counter;

        total_tests++;
        test_pass = 1'b1;

        // 1. Calculate golden reference model inside testbench
        for (r = 0; r < MATRIX_SIZE; r = r + 1) begin
            for (c = 0; c < MATRIX_SIZE; c = c + 1) begin
                expected[r][c] = 0;
                for (k = 0; k < MATRIX_SIZE; k = k + 1) begin
                    expected[r][c] = expected[r][c] + (signed'(32'(test_a[r][k])) * signed'(32'(test_b[k][c])));
                end
                // Apply ReLU activation if enabled
                if (act_en) begin
                    if (expected[r][c] < 0) begin
                        expected[r][c] = 0;
                    end
                end
            end
        end

        // 2. Apply inputs to DUT
        @(negedge clk);
        for (r = 0; r < MATRIX_SIZE; r = r + 1) begin
            for (c = 0; c < MATRIX_SIZE; c = c + 1) begin
                a_matrix[r][c] = test_a[r][c];
                b_matrix[r][c] = test_b[r][c];
            end
        end
        activation_enable = act_en;
        start = 1'b1;

        // 3. Deassert start after one clock cycle
        @(posedge clk);
        #1;
        start = 1'b0;

        // 4. Wait for done signal with watchdog timeout
        timeout_counter = 0;
        while (!done && timeout_counter < 50) begin
            @(posedge clk);
            timeout_counter++;
        end

        if (timeout_counter >= 50) begin
            $display("\n==================================================");
            $display("[FAIL] %s - TIMEOUT WAITING FOR DONE SIGNAL", test_title);
            $display("==================================================");
            test_pass = 0;
        end else begin
            // 5. Compare DUT output against expected golden result
            for (r = 0; r < MATRIX_SIZE; r = r + 1) begin
                for (c = 0; c < MATRIX_SIZE; c = c + 1) begin
                    if (c_matrix[r][c] !== expected[r][c]) begin
                        test_pass = 0;
                    end
                end
            end

            // 6. Pretty print test results
            $display("\n--------------------------------------------------");
            $display("## %s (Activation: %s)", test_title, (act_en ? "ReLU" : "Linear/Bypass"));
            $display("--------------------------------------------------");
            $display("Matrix A:");
            for (r = 0; r < MATRIX_SIZE; r = r + 1) begin
                $display("  [%4d, %4d, %4d, %4d]", test_a[r][0], test_a[r][1], test_a[r][2], test_a[r][3]);
            end
            $display("Matrix B:");
            for (r = 0; r < MATRIX_SIZE; r = r + 1) begin
                $display("  [%4d, %4d, %4d, %4d]", test_b[r][0], test_b[r][1], test_b[r][2], test_b[r][3]);
            end
            $display("Expected Matrix C:");
            for (r = 0; r < MATRIX_SIZE; r = r + 1) begin
                $display("  [%6d, %6d, %6d, %6d]", expected[r][0], expected[r][1], expected[r][2], expected[r][3]);
            end
            $display("RTL Output Matrix C:");
            for (r = 0; r < MATRIX_SIZE; r = r + 1) begin
                $display("  [%6d, %6d, %6d, %6d]", c_matrix[r][0], c_matrix[r][1], c_matrix[r][2], c_matrix[r][3]);
            end

            if (test_pass) begin
                $display("RESULT: [PASS]");
                passed_tests++;
            end else begin
                $display("RESULT: [FAIL]");
                failed_tests++;
            end
        end

        // Idle delay between tests
        @(posedge clk);
        #10;
    endtask

    initial begin
        // Setup GTKWave dump
        $dumpfile("waves/tb_accelerator.vcd");
        $dumpvars(0, tb_accelerator);

        $display("==================================================");
        $display("     AI ACCELERATOR SYSTEMVERILOG TESTBENCH       ");
        $display("==================================================");

        // Initialize signals
        clk               = 0;
        rst_n             = 0;
        start             = 0;
        activation_enable = 0;
        reg_we            = 0;
        reg_addr          = 0;
        reg_wdata         = 0;

        for (int i = 0; i < MATRIX_SIZE; i++) begin
            for (int j = 0; j < MATRIX_SIZE; j++) begin
                a_matrix[i][j] = '0;
                b_matrix[i][j] = '0;
            end
        end

        // Apply reset
        #25;
        rst_n = 1;
        #20;

        // =====================================================================
        // TEST 1: Specified standard matrix test case (Linear / Bypass)
        // =====================================================================
        test_a[0][0] = 8'sd1; test_a[0][1] = 8'sd2; test_a[0][2] = 8'sd3; test_a[0][3] = 8'sd4;
        test_a[1][0] = 8'sd5; test_a[1][1] = 8'sd6; test_a[1][2] = 8'sd7; test_a[1][3] = 8'sd8;
        test_a[2][0] = 8'sd1; test_a[2][1] = 8'sd2; test_a[2][2] = 8'sd1; test_a[2][3] = 8'sd2;
        test_a[3][0] = 8'sd3; test_a[3][1] = 8'sd4; test_a[3][2] = 8'sd3; test_a[3][3] = 8'sd4;

        test_b[0][0] = 8'sd1; test_b[0][1] = 8'sd0; test_b[0][2] = 8'sd2; test_b[0][3] = 8'sd1;
        test_b[1][0] = 8'sd0; test_b[1][1] = 8'sd1; test_b[1][2] = 8'sd1; test_b[1][3] = 8'sd2;
        test_b[2][0] = 8'sd2; test_b[2][1] = 8'sd1; test_b[2][2] = 8'sd0; test_b[2][3] = 8'sd1;
        test_b[3][0] = 8'sd1; test_b[3][1] = 8'sd2; test_b[3][2] = 8'sd1; test_b[3][3] = 8'sd0;

        run_matrix_test("TEST 1: Standard 4x4 Matrix Multiplication", 1'b0);

        // =====================================================================
        // TEST 2: Negative signed values with ReLU Activation
        // =====================================================================
        test_a[0][0] = -8'sd2; test_a[0][1] =  8'sd3; test_a[0][2] = -8'sd1; test_a[0][3] =  8'sd4;
        test_a[1][0] =  8'sd1; test_a[1][1] = -8'sd5; test_a[1][2] =  8'sd2; test_a[1][3] = -8'sd3;
        test_a[2][0] = -8'sd4; test_a[2][1] =  8'sd1; test_a[2][2] = -8'sd2; test_a[2][3] =  8'sd0;
        test_a[3][0] =  8'sd3; test_a[3][1] = -8'sd2; test_a[3][2] =  8'sd1; test_a[3][3] = -8'sd1;

        test_b[0][0] =  8'sd2; test_b[0][1] = -8'sd1; test_b[0][2] =  8'sd3; test_b[0][3] = -8'sd2;
        test_b[1][0] = -8'sd3; test_b[1][1] =  8'sd2; test_b[1][2] = -8'sd1; test_b[1][3] =  8'sd4;
        test_b[2][0] =  8'sd1; test_b[2][1] = -8'sd4; test_b[2][2] =  8'sd2; test_b[2][3] = -8'sd1;
        test_b[3][0] = -8'sd2; test_b[3][1] =  8'sd1; test_b[3][2] = -8'sd3; test_b[3][3] =  8'sd2;

        run_matrix_test("TEST 2: Signed Negative Operands with ReLU", 1'b1);

        // =====================================================================
        // TEST 3: Zero Matrices
        // =====================================================================
        for (int i = 0; i < MATRIX_SIZE; i++) begin
            for (int j = 0; j < MATRIX_SIZE; j++) begin
                test_a[i][j] = 8'sd0;
                test_b[i][j] = 8'sd0;
            end
        end
        run_matrix_test("TEST 3: Zero Matrices", 1'b0);

        // =====================================================================
        // TEST 4: Identity Matrix (A * I = A)
        // =====================================================================
        test_a[0][0] = 8'sd7;  test_a[0][1] = -8'sd12; test_a[0][2] = 8'sd35; test_a[0][3] = 8'sd4;
        test_a[1][0] = 8'sd19; test_a[1][1] =  8'sd0;  test_a[1][2] = 8'sd8;  test_a[1][3] = -8'sd22;
        test_a[2][0] = -8'sd3; test_a[2][1] =  8'sd14; test_a[2][2] = 8'sd1;  test_a[2][3] = 8'sd15;
        test_a[3][0] = 8'sd2;  test_a[3][1] = -8'sd9;  test_a[3][2] = 8'sd6;  test_a[3][3] = 8'sd10;

        for (int i = 0; i < MATRIX_SIZE; i++) begin
            for (int j = 0; j < MATRIX_SIZE; j++) begin
                test_b[i][j] = (i == j) ? 8'sd1 : 8'sd0;
            end
        end
        run_matrix_test("TEST 4: Multiplication with Identity Matrix", 1'b0);

        // =====================================================================
        // TEST 5: Random Small INT8 Values (Pseudorandom generation)
        // =====================================================================
        for (int i = 0; i < MATRIX_SIZE; i++) begin
            for (int j = 0; j < MATRIX_SIZE; j++) begin
                test_a[i][j] = signed'($urandom_range(0, 30) - 15);
                test_b[i][j] = signed'($urandom_range(0, 30) - 15);
            end
        end
        run_matrix_test("TEST 5: Random INT8 Matrices with ReLU", 1'b1);

        // =====================================================================
        // Final Summary
        // =====================================================================
        $display("\n==================================================");
        $display("               SIMULATION SUMMARY                 ");
        $display("==================================================");
        $display("TOTAL TESTS : %0d", total_tests);
        $display("PASSED      : %0d", passed_tests);
        $display("FAILED      : %0d", failed_tests);
        $display("==================================================");

        if (failed_tests == 0) begin
            $display(">>> ALL AI ACCELERATOR TESTS PASSED SUCCESSFULLY! <<<");
        end else begin
            $display(">>> SOME TESTS FAILED! <<<");
        end

        $finish;
    end

endmodule
