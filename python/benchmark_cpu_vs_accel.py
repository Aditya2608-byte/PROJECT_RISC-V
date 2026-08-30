"""
Benchmark: RISC-V Scalar CPU vs. AI Accelerator Hardware
Calculates exact clock cycle counts, latency, throughput, and speedup factors.
"""

import time
import numpy as np

def simulate_riscv_cpu_matmul(N=4, with_relu=True):
    """
    Simulates instruction-by-instruction execution of a standard RISC-V (RV32IM)
    assembly loop for Matrix Multiplication (C = A * B) with optional ReLU:
    
    C Pseudo-code:
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            int sum = 0;
            for (int k = 0; k < N; k++) {
                sum += (int32_t)A[i][k] * (int32_t)B[k][j];
            }
            if (with_relu && sum < 0) sum = 0;
            C[i][j] = sum;
        }
    }
    """
    cycles = 0
    instructions = 0
    
    # Outer loop overhead: init i=0 (1 cycle)
    cycles += 1
    instructions += 1
    
    for i in range(N):
        # Middle loop overhead: init j=0 (1 cycle)
        cycles += 1
        instructions += 1
        
        for j in range(N):
            # Inner loop overhead: init k=0, sum=0 (2 cycles)
            cycles += 2
            instructions += 2
            
            for k in range(N):
                # 1. Address calculation & Load A[i][k] (2 instructions: slli/add + lb) -> 3 cycles (1 load stall)
                # 2. Address calculation & Load B[k][j] (2 instructions: slli/add + lb) -> 3 cycles (1 load stall)
                # 3. Signed Multiply (mul instruction on RV32M) -> 1 to 3 cycles (typ 2 cycles)
                # 4. Accumulate (add instruction) -> 1 cycle
                # 5. Increment k and branch (addi + blt) -> 2 cycles (branch taken)
                cycles += (3 + 3 + 2 + 1 + 2)
                instructions += 7
                
            # After inner loop:
            # Store sum to C[i][j] (sw instruction) -> 2 cycles
            cycles += 2
            instructions += 1
            
            # If ReLU: check sign + conditional branch + zero write (bge + mv) -> ~2 cycles
            if with_relu:
                cycles += 2
                instructions += 2
                
            # Increment j and branch (addi + blt) -> 2 cycles
            cycles += 2
            instructions += 2
            
        # Increment i and branch (addi + blt) -> 2 cycles
        cycles += 2
        instructions += 2
        
    return cycles, instructions

def simulate_ai_accelerator(N=4):
    """
    Hardware AI Accelerator cycle model:
    - State LOAD: 1 cycle (latch A & B, clear MACs)
    - State COMPUTE: N cycles (parallel MAC array: 16 PEs compute in parallel each cycle)
    - State ACTIVATE: 1 cycle (combinational 16-channel parallel ReLU)
    - State WRITEBACK: 1 cycle (parallel write to accumulator memory)
    - State DONE: 1 cycle (handshake acknowledgment)
    """
    cycles = 1 + N + 1 + 1 + 1 # Total = 7 cycles for N=4
    return cycles

def run_benchmark():
    clock_freq_mhz = 100 # 100 MHz (10ns period)
    clock_period_ns = 10.0
    
    print("=" * 80)
    print("      PERFORMANCE BENCHMARK: RISC-V CPU vs. AI ACCELERATOR HARDWARE      ")
    print("=" * 80)
    print(f"System Clock Frequency: {clock_freq_mhz} MHz ({clock_period_ns} ns / cycle)")
    print("-" * 80)
    
    matrix_sizes = [4, 8, 16, 32, 64]
    
    print(f"{'Matrix Size':<12} | {'Total MACs':<10} | {'RISC-V CPU (Cycles/Time)':<26} | {'AI Accelerator (Cycles/Time)':<30} | {'Speedup':<12}")
    print("-" * 80)
    
    for n in matrix_sizes:
        total_macs = n * n * n
        
        # CPU Cycles
        cpu_cycles, cpu_inst = simulate_riscv_cpu_matmul(N=n, with_relu=True)
        cpu_time_us = (cpu_cycles * clock_period_ns) / 1000.0
        
        # Accelerator Cycles (Tiled in 4x4 blocks if N > 4)
        tiles_dim = (n + 3) // 4
        num_tiles = tiles_dim * tiles_dim * tiles_dim
        accel_cycles = num_tiles * simulate_ai_accelerator(4)
        accel_time_us = (accel_cycles * clock_period_ns) / 1000.0
        
        speedup = cpu_cycles / accel_cycles
        
        cpu_str = f"{cpu_cycles:,} cycles ({cpu_time_us:.2f} us)"
        accel_str = f"{accel_cycles:,} cycles ({accel_time_us:.2f} us)"
        speedup_str = f"{speedup:.1f}x FASTER"
        
        print(f"{f'{n}x{n}':<12} | {total_macs:<10,d} | {cpu_str:<26} | {accel_str:<30} | {speedup_str:<12}")
        
    print("=" * 80)
    print("\nDetailed Breakdown for 4x4 Matrix Multiplication + ReLU:")
    print("-" * 80)
    
    c_cycles, c_inst = simulate_riscv_cpu_matmul(4, True)
    a_cycles = simulate_ai_accelerator(4)
    
    print(f"1. Standard RISC-V RV32IM CPU (Scalar, 1 MAC at a time):")
    print(f"   - Total Instructions Executed: {c_inst:,} instructions")
    print(f"   - Total CPU Clock Cycles:     {c_cycles:,} cycles")
    print(f"   - Latency @ 100MHz:            {c_cycles * 10:,} ns ({c_cycles * 10 / 1000.0:.2f} us)")
    print(f"   - Arithmetic Throughput:       {64.0 / c_cycles:.3f} MACs / cycle")
    print()
    print(f"2. Dedicated AI Accelerator (Spatial 4x4 Processing Array):")
    print(f"   - Hardware Parallelism:        16 Processing Elements executing simultaneously")
    print(f"   - Total Hardware Cycles:       {a_cycles} cycles (1 Load + 4 Compute + 1 Act + 1 WB)")
    print(f"   - Latency @ 100MHz:            {a_cycles * 10} ns ({a_cycles * 10 / 1000.0:.3f} us)")
    print(f"   - Arithmetic Throughput:       {64.0 / a_cycles:.2f} MACs / cycle (Peak: 16.0 MACs/cycle)")
    print()
    print(f">>> SPEEDUP: AI Accelerator is {c_cycles / a_cycles:.1f}x FASTER and saves {(c_cycles - a_cycles) / c_cycles * 100:.1f}% execution time! <<<")
    print("=" * 80)

if __name__ == "__main__":
    run_benchmark()
