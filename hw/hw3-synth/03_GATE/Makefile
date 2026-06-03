# =============================================================================
# HW3 03_GATE -- gate-level (post-synthesis) simulation / equivalence check.
#
#   make gl-sim      gate-level sim of the 02_SYN netlist vs the SAME golden
#   make clean
#
# Runs the SAME self-checking testbench (../00_TB/conv_engine_tb.v) against the
# synthesized netlist (../02_SYN/build/conv_netlist.v) + the SKY130 cell models,
# compared to the SAME committed golden (../00_TB/golden) -> proving the gate
# netlist is functionally EQUIVALENT to the RTL. (-DFUNCTIONAL -DUNIT_DELAY for
# zero-/unit-delay cell models so the clocked TB lines up.)
#
# Needs Icarus + the SKY130 PDK from the EDA container (`make shell`). All run
# artifacts (the .vvp, the log, the VCD, and the golden symlink the testbench
# reads) land under build/ (git-ignored); the sim runs from inside build/ so the
# testbench's bare relative paths (golden/..., sim/...) resolve.
# =============================================================================
TOP    := conv_engine_tb
DESIGN := conv_engine

# shared trees (relative to this stage directory)
COMMON   := ../../../common
CONV_INC := $(COMMON)/rtl/conv

# the synthesized netlist from 02_SYN and the committed TB + golden in 00_TB
NETLIST    := ../02_SYN/build/conv_netlist.v
TB         := ../00_TB/conv_engine_tb.v
GOLDEN_DIR := ../00_TB/golden

BUILD := build

# ---- SKY130 cell models (live in the EDA container) ----
PDK_ROOT ?= /foss/pdks
SCL      := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd
CELLS_V  := $(SCL)/verilog/sky130_fd_sc_hd.v $(SCL)/verilog/primitives.v
# The netlist instantiates the SRAM macro; supply its behavioral model so the
# gate-level sim can run (the real macro's timing model could be used instead).
SRAM_MODEL := $(CONV_INC)/sky130_sram_1kbyte_1rw1r_32x256_8.v

.DEFAULT_GOAL := gl-sim
.PHONY: gl-sim prep clean

# Stage the run directory: build/ with a golden symlink + a sim subdir so the
# testbench's bare relative paths resolve when we run the sim from inside build/.
prep:
	@mkdir -p $(BUILD)/sim
	@ln -sfn ../$(GOLDEN_DIR) $(BUILD)/golden

# ---- gate-level equivalence sim ----
gl-sim: prep
	iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY="#1" \
	  -I$(SCL)/verilog -I$(GOLDEN_DIR) \
	  -o $(BUILD)/conv_gl.vvp \
	  $(abspath $(CELLS_V)) $(abspath $(SRAM_MODEL)) $(abspath $(NETLIST)) $(abspath $(TB))
	cd $(BUILD) && vvp conv_gl.vvp | tee sim/conv_gl.log
	@grep -q "RESULT: PASS" $(BUILD)/sim/conv_gl.log \
		&& echo ">> gate-level sim PASS (netlist == RTL)" \
		|| { echo ">> gate-level sim FAIL (netlist != golden)"; exit 1; }

clean:
	rm -rf $(BUILD)
