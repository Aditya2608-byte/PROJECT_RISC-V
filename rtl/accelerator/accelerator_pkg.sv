`ifndef ACCELERATOR_PKG_SV
`define ACCELERATOR_PKG_SV

package accelerator_pkg;

    // =========================================================================
    // Architectural Parameters
    // =========================================================================
    parameter int DATA_WIDTH    = 8;   // Signed INT8 inputs (Matrix A, Matrix B)
    parameter int ACC_WIDTH     = 32;  // Signed INT32 accumulation / output
    parameter int MATRIX_SIZE   = 4;   // 4x4 matrix dimensions (N=4)
    parameter int NUM_ELEMENTS  = MATRIX_SIZE * MATRIX_SIZE; // 16 elements total

    // =========================================================================
    // Controller FSM States
    // =========================================================================
    typedef enum logic [2:0] {
        STATE_IDLE      = 3'b000,
        STATE_LOAD      = 3'b001,
        STATE_COMPUTE   = 3'b010,
        STATE_ACTIVATE  = 3'b011,
        STATE_WRITEBACK = 3'b100,
        STATE_DONE      = 3'b101
    } state_t;

    // =========================================================================
    // Symbolic Register Memory Map (For Future RISC-V SoC Interconnect)
    // =========================================================================
    localparam logic [31:0] REG_CTRL     = 32'h4000_0000; // Control Register
    localparam logic [31:0] REG_STATUS   = 32'h4000_0004; // Status Register
    localparam logic [31:0] REG_CFG_SIZE = 32'h4000_0008; // Matrix Size Configuration (4)
    localparam logic [31:0] REG_CFG_K    = 32'h4000_000C; // Inner Dimension K (4)
    localparam logic [31:0] REG_ADDR_A   = 32'h4000_0010; // Base Address for Matrix A
    localparam logic [31:0] REG_ADDR_B   = 32'h4000_0014; // Base Address for Matrix B
    localparam logic [31:0] REG_ADDR_C   = 32'h4000_0018; // Base Address for Matrix C
    localparam logic [31:0] REG_CFG_ACT  = 32'h4000_001C; // Activation Config (0=Bypass, 1=ReLU)

    // Bit definitions within registers
    localparam int CTRL_START_BIT    = 0; // Write 1 to start computation
    localparam int STATUS_DONE_BIT   = 0; // Read 1 when matrix multiplication complete
    localparam int STATUS_BUSY_BIT   = 1; // Read 1 during processing
    localparam int STATUS_ERROR_BIT  = 2; // Read 1 if illegal state/configuration
    localparam int CFG_ACT_RELU_BIT  = 0; // 0: Linear/Bypass, 1: ReLU

endpackage : accelerator_pkg

`endif // ACCELERATOR_PKG_SV
