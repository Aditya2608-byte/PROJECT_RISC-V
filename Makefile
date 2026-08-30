# ==============================================================================
# AI Accelerator ASIC Prototype - Makefile
# Simulator: Icarus Verilog (iverilog -g2012 / vvp)
# Waveform Viewer: GTKWave
# ==============================================================================

SIM_DIR   = sim
WAVES_DIR = waves
RTL_DIR   = rtl/accelerator
TB_DIR    = tb
PYTHON    = python

IVFLAGS   = -g2012 -Wall

RTL_SRCS  = $(RTL_DIR)/accelerator_pkg.sv \
            $(RTL_DIR)/mac.sv \
            $(RTL_DIR)/pe.sv \
            $(RTL_DIR)/systolic_array.sv \
            $(RTL_DIR)/accumulator.sv \
            $(RTL_DIR)/relu.sv \
            $(RTL_DIR)/controller.sv \
            $(RTL_DIR)/accelerator.sv

MAC_SRCS  = $(RTL_DIR)/mac.sv $(TB_DIR)/tb_mac.sv
ACC_SRCS  = $(RTL_SRCS) $(TB_DIR)/tb_accelerator.sv

all: test

# ------------------------------------------------------------------------------
# Compilation Targets
# ------------------------------------------------------------------------------
$(SIM_DIR):
	mkdir -p $(SIM_DIR)

$(WAVES_DIR):
	mkdir -p $(WAVES_DIR)

compile_mac: $(SIM_DIR)
	iverilog $(IVFLAGS) -o $(SIM_DIR)/sim_mac $(MAC_SRCS)

compile_accel: $(SIM_DIR)
	iverilog $(IVFLAGS) -o $(SIM_DIR)/sim_accelerator $(ACC_SRCS)

compile: compile_mac compile_accel

# ------------------------------------------------------------------------------
# Simulation / Testing Targets
# ------------------------------------------------------------------------------
test_mac: compile_mac $(WAVES_DIR)
	vvp $(SIM_DIR)/sim_mac

test_accel: compile_accel $(WAVES_DIR)
	vvp $(SIM_DIR)/sim_accelerator

test: test_mac test_accel

# ------------------------------------------------------------------------------
# Python Golden Model Target
# ------------------------------------------------------------------------------
golden:
	$(PYTHON) python/golden_model.py

# ------------------------------------------------------------------------------
# Waveform Viewer Target
# ------------------------------------------------------------------------------
wave:
	gtkwave $(WAVES_DIR)/tb_accelerator.vcd &

wave_mac:
	gtkwave $(WAVES_DIR)/tb_mac.vcd &

# ------------------------------------------------------------------------------
# Clean Target
# ------------------------------------------------------------------------------
clean:
	rm -rf $(SIM_DIR) $(WAVES_DIR)/*.vcd

.PHONY: all compile compile_mac compile_accel test test_mac test_accel golden wave wave_mac clean help
