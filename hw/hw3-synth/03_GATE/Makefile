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
# Std cells (SCL/LIB) resolve via pdk.mk: in-repo pdk/ if vendored, else PDK_ROOT.
include ../../../common/flow/pdk.mk
SCL      := $(STD_CELL_DIR)
CELLS_V  := $(SCL)/verilog/sky130_fd_sc_hd.v $(SCL)/verilog/primitives.v
# The netlist instantiates the SRAM macro; supply its behavioral model so the
# gate-level sim can run (the real macro's timing model could be used instead).
SRAM_MODEL := $(CONV_INC)/sky130_sram_1kbyte_1rw1r_32x256_8.v

# ---- timing (SDF) gate sim ----
# The SDF is produced by 02_SYN (`make -C ../02_SYN sdf`); reuse it here.
SDF          := ../02_SYN/$(BUILD)/conv.sdf
# For timing sim, cell models self-power via internal supplies EXCEPT the (unused)
# lpflow_bleeder cell, whose timing model references VPWR without declaring it ->
# patch a build-copy so iverilog can elaborate. CLK_HALF widens the TB clock so the
# real SRAM->MAC delay fits (a 10 ns clock corrupts captures with real delays).
CELLS_TIMING := $(BUILD)/sky130_fd_sc_hd_timing.v
SDF_CLK_HALF ?= 25
# std-cell-only SDF for the sim: the SRAM is a BEHAVIORAL model here (no structural
# clk0->dout0[n] paths), so its CELL block is stripped -- iverilog can't annotate it
# and would abort the whole SDF parse (see common/flow/sdf_strip_macros.awk).
SIM_SDF      := $(BUILD)/conv.sim.sdf

.DEFAULT_GOAL := gl-sim
.PHONY: gl-sim gl-sim-sdf prep netlist clean

# Stage the run directory: build/ with a golden symlink + a sim subdir so the
# testbench's bare relative paths resolve when we run the sim from inside build/.
prep:
	@mkdir -p $(BUILD)/sim
	@ln -sfn ../$(GOLDEN_DIR) $(BUILD)/golden

# Always (re)synthesize via 02_SYN so gate sim uses the CURRENT netlist for this
# 01_RTL -- never a stale copy. 02_SYN re-runs Yosys only if the RTL changed.
netlist:
	@$(MAKE) --no-print-directory -C ../02_SYN synth

# ---- gate-level equivalence sim ----
gl-sim: prep netlist
	iverilog -g2012 -DGL_NETLIST -DFUNCTIONAL -DUNIT_DELAY="#1" \
	  -I$(SCL)/verilog -I$(GOLDEN_DIR) \
	  -o $(BUILD)/conv_gl.vvp \
	  $(abspath $(CELLS_V)) $(abspath $(SRAM_MODEL)) $(abspath $(NETLIST)) $(abspath $(TB))
	cd $(BUILD) && vvp conv_gl.vvp | tee sim/conv_gl.log
	@grep -q "RESULT: PASS" $(BUILD)/sim/conv_gl.log \
		&& echo ">> gate-level sim PASS (netlist == RTL)" \
		|| { echo ">> gate-level sim FAIL (netlist != golden)"; exit 1; }

# ---- timing-annotated (SDF) gate-level sim (cell-arc delays) ----
# 1) get the SDF from 02_SYN and strip the behavioral SRAM's CELL block;
# 2) patch the one malformed (unused) bleeder cell into a build-copy so the timing
#    models elaborate; 3) build with real cell delays (-gspecify -ginterconnect,
#    no UNIT_DELAY) and back-annotate the SDF via $sdf_annotate (in the TB) at a
#    slow clock (CLK_HALF, so the real SRAM->MAC delay fits).
# Pre-layout SDF carries cell-arc delays only (no wire RC -- those arrive at
# APR/HW5); iverilog applies those and ignores INTERCONNECT/TIMINGCHECK. Expect
# RESULT: PASS -- it proves the netlist still computes correctly with real delays.
$(SDF):
	$(MAKE) -C ../02_SYN sdf

# std-cell-only SDF for the sim (strip the behavioral SRAM's CELL block)
$(SIM_SDF): $(SDF) | prep
	awk -f $(COMMON)/flow/sdf_strip_macros.awk $(SDF) > $(SIM_SDF)

$(CELLS_TIMING): $(SCL)/verilog/sky130_fd_sc_hd.v | prep
	sed '/__lpflow_bleeder/,/endmodule/{/SHORT *=> *VPWR/d}' $< > $@

gl-sim-sdf: prep netlist $(SIM_SDF) $(CELLS_TIMING)
	iverilog -g2012 -gspecify -ginterconnect -DGL_NETLIST -DCLK_HALF=$(SDF_CLK_HALF) \
	  -DSDF_FILE='"$(abspath $(SIM_SDF))"' \
	  -I$(SCL)/verilog -I$(GOLDEN_DIR) -o $(BUILD)/conv_gl_sdf.vvp \
	  $(abspath $(CELLS_TIMING)) $(abspath $(SCL)/verilog/primitives.v) \
	  $(abspath $(SRAM_MODEL)) $(abspath $(NETLIST)) $(abspath $(TB))
	@# iverilog applies the cell-arc IOPATH delays; it can't model SDF INTERCONNECT
	@# (net delays -- which are ~0 pre-layout anyway) or TIMINGCHECKs, so those
	@# warnings are expected and filtered from the console (full log kept).
	cd $(BUILD) && vvp conv_gl_sdf.vvp 2>&1 | tee sim/conv_gl_sdf.log \
	  | grep -vE "port[12] =|Could not find net|intermodpath|Timing checks are not supported" || true
	@grep -q "RESULT: PASS" $(BUILD)/sim/conv_gl_sdf.log \
		&& echo ">> SDF gate-level sim PASS (cell-arc timing annotated)" \
		|| { echo ">> SDF gate-level sim FAIL -- inspect $(BUILD)/sim/conv_gl_sdf.log"; exit 1; }

clean:
	rm -rf $(BUILD)
