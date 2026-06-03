# =============================================================================
# Final Project / 03_GATE -- gate-level simulation of the synthesized netlist.
#
# Simulates the netlist produced by ../02_SYN (build/) with the SKY130 cell
# models, driven by the SAME ../00_TB testbench and the COMMITTED public vectors
# in ../00_TB/golden. Confirms gate-level equivalence by checking RESULT: PASS.
# Runs inside the EDA container (Icarus + SKY130 PDK).
#
#   make gl-sim   gate-level sim of ../02_SYN/build netlist vs the public vectors
#   make clean
# =============================================================================
DESIGN  := mimo_detector
TB_TOP  := mimo_detector_tb
BUILD   := build

TB         := ../00_TB/mimo_detector_tb.v
GOLDEN_DIR := ../00_TB/golden
NETLIST    := ../02_SYN/build/$(DESIGN)_netlist.v

# ---- SKY130 cell models (EDA container) ----
# Std cells (SCL/LIB) resolve via pdk.mk: in-repo pdk/ if vendored, else PDK_ROOT.
include ../../common/flow/pdk.mk
SCL      := $(STD_CELL_DIR)
CELLS_V  := $(SCL)/verilog/sky130_fd_sc_hd.v $(SCL)/verilog/primitives.v

.DEFAULT_GOAL := gl-sim
.PHONY: gl-sim clean

gl-sim: $(NETLIST)
	@mkdir -p $(BUILD)
	iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY="#1" -I$(SCL)/verilog -I$(GOLDEN_DIR) \
	  -o $(BUILD)/gl.vvp $(CELLS_V) $(NETLIST) $(TB)
	vvp $(BUILD)/gl.vvp | tee $(BUILD)/gl.log
	@grep -q "RESULT: PASS" $(BUILD)/gl.log \
		|| { echo ">> gate-level sim FAILED"; exit 1; }
	@echo ">> gate-level sim PASS"

clean:
	rm -rf $(BUILD)
