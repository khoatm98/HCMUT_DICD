# STA runs via standalone OpenSTA if present, else OpenROAD (which embeds OpenSTA -- conda path).
STA_BIN ?= $(shell command -v sta >/dev/null 2>&1 && echo sta || echo openroad)
# =============================================================================
# Final Project / 06_POWER -- activity-driven power (baseline vs clock-gated).
#
# Synthesizes the ../01_RTL detector two ways -- baseline and with clock gating
# (the tree-search units idle when pruned) -- runs a representative workload
# through gate-level sim to capture a VCD, then OpenSTA reports power for each.
# Compare the two to quantify the power optimization. Runs in the EDA container.
#
#   make baseline    synth + gate-sim + OpenSTA power, NO clock gating
#   make clockgate   synth + gate-sim + OpenSTA power, WITH clock gating
#   make compare     run both and print the baseline-vs-clockgate power deltas
#   make clean
# =============================================================================
DESIGN  := mimo_detector
TB_TOP  := mimo_detector_tb
BUILD   := build
COMMON  := ../../common/flow

RTL        ?= $(wildcard ../01_RTL/*.v)
INCDIRS    := ../01_RTL ../../common/rtl/alu
TB         := ../00_TB/mimo_detector_tb.v
GOLDEN_DIR := ../00_TB/golden
SDC        := ../02_SYN/mimo.sdc

# ---- back-end (SKY130) paths: live in the EDA container ----
# PDK_ROOT: in-repo pdk/ if vendored (scripts/vendor-pdk.sh), else /foss/pdks.
include ../../common/flow/pdk.mk
SCL      := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd
LIB      := $(SCL)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
CELLS_V  := $(SCL)/verilog/sky130_fd_sc_hd.v $(SCL)/verilog/primitives.v

.DEFAULT_GOAL := compare
.PHONY: baseline clockgate compare clean

# $(1) = tag (baseline|clockgate), $(2) = CLOCKGATE value ("" or "1")
define POWER_RUN
	@mkdir -p $(BUILD)
	TOP=$(DESIGN) RTL_FILES="$(RTL)" INCDIRS="$(INCDIRS)" LIB="$(LIB)" CLOCKGATE="$(2)" \
	  NETLIST_OUT=$(BUILD)/$(DESIGN)_$(1).v STAT_OUT=$(BUILD)/$(DESIGN)_$(1)_area.rpt \
	  yosys -c $(COMMON)/synth_sky130.tcl
	iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY="#1" -I$(SCL)/verilog -I$(GOLDEN_DIR) \
	  -o $(BUILD)/$(1).vvp $(CELLS_V) $(BUILD)/$(DESIGN)_$(1).v $(TB)
	vvp $(BUILD)/$(1).vvp
	mv $(BUILD)/$(DESIGN).vcd $(BUILD)/$(DESIGN)_$(1).vcd
	TOP=$(DESIGN) LIB="$(LIB)" NETLIST=$(BUILD)/$(DESIGN)_$(1).v SDC=$(SDC) \
	  VCD=$(BUILD)/$(DESIGN)_$(1).vcd VCD_SCOPE=$(TB_TOP)/dut \
	  $(STA_BIN) -no_init -exit $(COMMON)/sta.tcl | tee $(BUILD)/$(DESIGN)_$(1)_power.rpt
endef

baseline:
	$(call POWER_RUN,baseline,)
	@echo ">> baseline power: $(BUILD)/$(DESIGN)_baseline_power.rpt"

clockgate:
	$(call POWER_RUN,clockgate,1)
	@echo ">> clock-gated power: $(BUILD)/$(DESIGN)_clockgate_power.rpt"

compare: baseline clockgate
	@echo "==================== POWER COMPARE ===================="
	@echo "-- baseline --";  grep -A4 "POWER" $(BUILD)/$(DESIGN)_baseline_power.rpt  || true
	@echo "-- clockgate --"; grep -A4 "POWER" $(BUILD)/$(DESIGN)_clockgate_power.rpt || true

clean:
	rm -rf $(BUILD)
