# =============================================================================
# HW3 01_RTL -- functional simulation of the 3x3 convolution engine.
#
#   make vsim        Verilator self-checking sim (fast)   <- iterate with this
#   make sim         Icarus self-checking sim
#   make lint        Verilator lint of your RTL
#   make wave        open the waveform in GTKWave
#   make ref         run the SAME testbench against the REFERENCE engine (PASS)
#   make clean
#
# You edit conv_engine.v (this directory). The testbench and the committed
# public golden patterns live in ../00_TB; the conv defines and the reference
# engine live in the shared ../../../common tree. All run artifacts (the
# Verilator obj_dir, the Icarus .vvp, logs, the VCD, and the golden symlink the
# testbench reads at run time) are created under build/ and are git-ignored.
#
# The testbench reads its patterns with bare relative paths:
#   `include "conv_count.vh"          (resolved via the -I../00_TB/golden incdir)
#   $readmemh("golden/conv_stim.hex") $readmemh("golden/conv_exp.hex")
#   $dumpfile("sim/conv_engine.vcd")
# so every sim runs from inside build/, where we provide a golden/ symlink (to
# ../00_TB/golden) and a sim/ directory. The simulators never reach into the DUT,
# so the same testbench runs identically under Verilator and Icarus.
# =============================================================================
TOP     := conv_engine_tb
TB_TOP  := conv_engine_tb
DESIGN  := conv_engine

# student RTL (override with RTL=<path> to point at the reference, see `ref`)
RTL      ?= conv_engine.v

# shared trees (relative to this stage directory)
COMMON   := ../../../common
CONV_INC := $(COMMON)/rtl/conv
REF_RTL  := $(CONV_INC)/conv_engine.v
# Behavioral model of the SKY130 OpenRAM macro -- SIMULATION ONLY (synthesis
# blackboxes the macro; APR places the real .lef/.gds). Always compiled for sim.
SRAM_MODEL := $(CONV_INC)/sky130_sram_1kbyte_1rw1r_32x256_8.v

# committed public testbench + golden patterns
TB         := ../00_TB/conv_engine_tb.v
GOLDEN_DIR := ../00_TB/golden

# everything regenerable lives here
BUILD := build

IVERILOG_FLAGS  := -g2012 -I$(CONV_INC) -I$(GOLDEN_DIR)
VERILATOR_FLAGS := -I$(CONV_INC) -I$(GOLDEN_DIR) \
                   -Wno-TIMESCALEMOD -Wno-BLKSEQ -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC \
                   -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM

.DEFAULT_GOAL := vsim
.PHONY: vsim sim lint wave ref prep clean

# Stage the run directory: build/ with a golden symlink + a sim subdir so the
# testbench's bare relative paths resolve when we run the sim from inside build/.
prep:
	@mkdir -p $(BUILD)/sim
	@ln -sfn ../$(GOLDEN_DIR) $(BUILD)/golden

# ---- Verilator self-checking sim (fast) ----
vsim: prep
	verilator --binary --timing -Wall -Wno-fatal $(VERILATOR_FLAGS) \
		--Mdir $(BUILD)/obj_dir --top-module $(TB_TOP) -o V$(TB_TOP) \
		$(abspath $(RTL)) $(abspath $(SRAM_MODEL)) $(abspath $(TB))
	cd $(BUILD) && ./obj_dir/V$(TB_TOP) | tee sim/$(TOP)_vl.log
	@grep -q "RESULT: PASS" $(BUILD)/sim/$(TOP)_vl.log \
		&& echo ">> verilator sim PASS" \
		|| { echo ">> verilator sim FAIL (no 'RESULT: PASS' in log)"; exit 1; }

# ---- Icarus self-checking sim ----
sim: prep
	iverilog $(IVERILOG_FLAGS) -o $(BUILD)/$(TOP).vvp $(abspath $(RTL)) $(abspath $(SRAM_MODEL)) $(abspath $(TB))
	cd $(BUILD) && vvp $(TOP).vvp | tee sim/$(TOP).log
	@grep -q "RESULT: PASS" $(BUILD)/sim/$(TOP).log \
		&& echo ">> iverilog sim PASS" \
		|| { echo ">> iverilog sim FAIL (no 'RESULT: PASS' in log)"; exit 1; }

# ---- Verilator lint of the RTL ----
lint:
	verilator --lint-only -Wall $(VERILATOR_FLAGS) $(abspath $(RTL)) $(abspath $(SRAM_MODEL))
	@echo ">> verilator lint clean"

# ---- open the waveform ----
wave: vsim
	gtkwave $(BUILD)/sim/conv_engine.vcd >/dev/null 2>&1 &

# ---- instructor / sanity: run the SAME testbench against the reference engine ----
# Equivalent to `make vsim RTL=$(REF_RTL)`; must print RESULT: PASS.
ref:
	$(MAKE) vsim RTL=$(REF_RTL)

clean:
	rm -rf $(BUILD)
