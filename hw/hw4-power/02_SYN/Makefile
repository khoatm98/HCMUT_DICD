# =============================================================================
# HW4 -- IoT Data Filter : 02_SYN synthesis (Yosys -> SKY130 standard cells).
#
# Synthesizes the STUDENT RTL in ../01_RTL/iotdf.v with the shared flow script
# common/flow/synth_sky130.tcl, in TWO variants:
#   make synth      baseline netlist            -> build/iotdf_base.v + area_base.rpt
#   make synth-cg   clock-gated (CLOCKGATE=1)   -> build/iotdf_cg.v   + area_cg.rpt
#   make all        both
#   make clean
#
# Needs the EDA container (Yosys + SKY130 PDK). Outputs go to build/ (git-ignored)
# and feed 03_GATE (gate-level sim) and 06_POWER (activity-driven power).
# The timing constraints (iotdf.sdc, CVSD 130nm I/O) live in THIS directory and
# are consumed by 06_POWER / OpenSTA.
# =============================================================================
TOP        := iotdf
RTL        := ../01_RTL/iotdf.v
IOTDF_INC  := ../../../common/rtl/iotdf
COMMON     := ../../../common/flow
SDC        := iotdf.sdc
BUILD      := build

# ---- SKY130 PDK (baked into the EDA container) ----
# Std cells (SCL/LIB) resolve via pdk.mk: in-repo pdk/ if vendored, else PDK_ROOT.
include ../../../common/flow/pdk.mk
SCL        := $(STD_CELL_DIR)
LIB        := $(SCL)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

.PHONY: all synth synth-cg clean
all: synth synth-cg

# Baseline synthesis (no clock gating).
synth:
	@mkdir -p $(BUILD)
	TOP=$(TOP) RTL_FILES="$(RTL)" INCDIRS="$(IOTDF_INC)" LIB="$(LIB)" \
	  NETLIST_OUT=$(BUILD)/iotdf_base.v STAT_OUT=$(BUILD)/area_base.rpt \
	  CLOCKGATE="" \
	  yosys -c $(COMMON)/synth_sky130.tcl
	@echo ">> wrote $(BUILD)/iotdf_base.v and $(BUILD)/area_base.rpt"

# Clock-gated synthesis (Yosys inserts integrated clock-gating cells).
synth-cg:
	@mkdir -p $(BUILD)
	TOP=$(TOP) RTL_FILES="$(RTL)" INCDIRS="$(IOTDF_INC)" LIB="$(LIB)" \
	  NETLIST_OUT=$(BUILD)/iotdf_cg.v STAT_OUT=$(BUILD)/area_cg.rpt \
	  CLOCKGATE="1" \
	  yosys -c $(COMMON)/synth_sky130.tcl
	@echo ">> wrote $(BUILD)/iotdf_cg.v and $(BUILD)/area_cg.rpt"

clean:
	rm -rf $(BUILD)
