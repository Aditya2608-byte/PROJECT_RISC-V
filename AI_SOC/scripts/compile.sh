#!/usr/bin/env bash
set -e

# AI Accelerator ASIC Project - Compilation Script
# Target Simulator: Icarus Verilog (iverilog -g2012)

echo "=================================================="
echo "      Compiling AI Accelerator SystemVerilog      "
echo "=================================================="

mkdir -p sim
mkdir -p waves

echo "[1/2] Compiling MAC Testbench..."
iverilog -g2012 -o sim/sim_mac \
    rtl/accelerator/mac.sv \
    tb/tb_mac.sv

echo "[2/2] Compiling AI Accelerator Top-Level Testbench..."
iverilog -g2012 -o sim/sim_accelerator \
    rtl/accelerator/accelerator_pkg.sv \
    rtl/accelerator/mac.sv \
    rtl/accelerator/pe.sv \
    rtl/accelerator/systolic_array.sv \
    rtl/accelerator/accumulator.sv \
    rtl/accelerator/relu.sv \
    rtl/accelerator/controller.sv \
    rtl/accelerator/accelerator.sv \
    tb/tb_accelerator.sv

echo "==> Compilation completed successfully!"
