#!/usr/bin/env bash
set -e

# AI Accelerator ASIC Project - Simulation Execution Script

echo "=================================================="
echo "        Running AI Accelerator Simulations        "
echo "=================================================="

# Ensure directories exist
mkdir -p sim
mkdir -p waves

# Run MAC simulation
echo ""
echo ">>> Running MAC Unit Simulation..."
vvp sim/sim_mac

# Run Accelerator Top-Level simulation
echo ""
echo ">>> Running AI Accelerator Top-Level Simulation..."
vvp sim/sim_accelerator

echo ""
echo "=================================================="
echo "Waveform files generated in 'waves/' directory:"
echo "  - waves/tb_mac.vcd"
echo "  - waves/tb_accelerator.vcd"
echo "=================================================="
