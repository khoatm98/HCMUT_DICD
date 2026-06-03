# =============================================================================
# HW4 -- IoT Data Filter : 03_GATE gate-level sim / switching-activity capture.
#
# Runs the WORKLOAD testbench (../00_TB/iotdf_workload_tb.v) against the
# synthesized netlist from ../02_SYN/build, with the SKY130 cell models, to
# record a VCD of switching activity that 06_POWER feeds to OpenSTA report_power.
# The SAME testbench drives RTL and gate-level (ports only), so it works on both
# the baseline and the clock-gated netlist.
#
#   make gate       gate-level sim of the BASELINE netlist     -> build/iotdf_workload_base.vcd
#   make gate-cg    gate-level sim of the CLOCK-GATED netlist   -> build/iotdf_workload_cg.vcd
#   make all        both
#   make clean
#
# Needs the EDA container (Icarus + SKY130 PDK). Run 02_SYN first. The workload
# testbench prints a harmless "RESULT: PASS" line (it is activity-only, not a
# functional self-check); each target greps for it. Artifacts -> build/ (ignored).
# =============================================================================
TOP          := iotdf
WL_TOP       := iotdf_workload_tb
WL_TB        := ../00_TB/iotdf_workload_tb.v
WORKLOAD_DIR := ../00_TB/workload
SYN_BUILD    := ../02_SYN/build
BUILD        := build
SIM_DIR      := $(BUILD)/sim

# ---- SKY130 PDK (baked into the EDA container) ----
# PDK_ROOT: in-repo pdk/ if vendored (scripts/vendor-pdk.sh), else /foss/pdks.
include ../../../common/flow/pdk.mk
SCL        := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd
CELLS      := $(SCL)/verilog/sky130_fd_sc_hd.v
PRIMS      := $(SCL)/verilog/primitives.v

.PHONY: all gate gate-cg prep clean
all: gate gate-cg

# The workload TB runs from build/ (cwd), so expose there the relative names it
# expects: $readmemh "workload/..." (symlink into ../00_TB) and $dumpfile
# "sim/..." (build/sim is a real dir, created here).
prep:
	@mkdir -p $(SIM_DIR)
	@ln -sfn ../$(WORKLOAD_DIR) $(BUILD)/workload

# Internal gate-level pass for a given netlist TAG (base | cg).
#   1) compile SKY130 prims+cells + netlist + workload TB (functional, unit delay)
#   2) run it from build/ so workload/ + sim/ resolve; capture the VCD
#   3) tag the VCD so 06_POWER can pick baseline vs clock-gated
define GATE_PASS
	@mkdir -p $(SIM_DIR)
	iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY="#1" \
	  -I$(SCL)/verilog -I$(WORKLOAD_DIR) \
	  -o $(SIM_DIR)/iotdf_gl_$(1).vvp \
	  $(PRIMS) $(CELLS) $(SYN_BUILD)/iotdf_$(1).v $(WL_TB)
	cd $(BUILD) && vvp sim/iotdf_gl_$(1).vvp | tee sim/iotdf_gl_$(1).log
	@grep -q "RESULT: PASS" $(SIM_DIR)/iotdf_gl_$(1).log \
	  || { echo ">> gate-level workload sim FAILED ($(1))"; exit 1; }
	@mv $(SIM_DIR)/iotdf_workload.vcd $(SIM_DIR)/iotdf_workload_$(1).vcd
	@echo ">> wrote $(SIM_DIR)/iotdf_workload_$(1).vcd"
endef

# Baseline netlist activity capture.
gate: prep
	$(call GATE_PASS,base)

# Clock-gated netlist activity capture.
gate-cg: prep
	$(call GATE_PASS,cg)

clean:
	rm -rf $(BUILD)
