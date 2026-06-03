# STA runs via standalone OpenSTA if present, else OpenROAD (which embeds OpenSTA -- conda path).
STA_BIN ?= $(shell command -v sta >/dev/null 2>&1 && echo sta || echo openroad)
# =============================================================================
# HW4 -- IoT Data Filter : 06_POWER activity-driven power + before/after compare.
#
# Reuses common/flow/sta.tcl: reads a synthesized netlist (../02_SYN/build), the
# CVSD timing constraints (../02_SYN/iotdf.sdc), and the switching-activity VCD
# captured by the workload gate-level sim (../03_GATE/build/sim) to run OpenSTA
# report_power. Two passes -- baseline vs clock-gated -- then a comparison.
#
#   make power-base   report_power on the BASELINE netlist     -> build/power_base.rpt
#   make power-cg     report_power on the CLOCK-GATED netlist   -> build/power_cg.rpt
#   make compare      both + area; writes ../artifacts/ppa_compare.md (make_ppa.py)
#   make clean
#
# Needs the EDA container (OpenSTA + SKY130 PDK). Run 02_SYN then 03_GATE first
# (this Makefile reads their build/ outputs). make_ppa.py lives HERE (public --
# it only formats reports). Artifacts -> build/ (git-ignored); the filled PPA
# table goes to ../artifacts/ppa_compare.md.
# =============================================================================
TOP        := iotdf
WL_TOP     := iotdf_workload_tb
COMMON     := ../../../common/flow
SYN_BUILD  := ../02_SYN/build
GATE_SIM   := ../03_GATE/build/sim
SDC        := ../02_SYN/iotdf.sdc
BUILD      := build
ARTIFACTS  := ../artifacts

# ---- SKY130 PDK (baked into the EDA container) ----
PDK_ROOT   ?= /foss/pdks
SCL        := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd
LIB        := $(SCL)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

.PHONY: power-base power-cg compare clean

# Internal STA+power pass for a given netlist TAG (base | cg): annotate the
# tagged workload VCD as switching activity, then report_power.
define POWER_PASS
	@mkdir -p $(BUILD)
	TOP=$(TOP) LIB="$(LIB)" NETLIST=$(SYN_BUILD)/iotdf_$(1).v SDC=$(SDC) \
	  VCD=$(GATE_SIM)/iotdf_workload_$(1).vcd VCD_SCOPE=$(WL_TOP)/dut \
	  $(STA_BIN) -no_init -exit $(COMMON)/sta.tcl | tee $(BUILD)/power_$(1).rpt
	@echo ">> wrote $(BUILD)/power_$(1).rpt"
endef

# Baseline power.
power-base:
	$(call POWER_PASS,base)

# Clock-gated power.
power-cg:
	$(call POWER_PASS,cg)

# Compare baseline vs clock-gated power + area; template the PPA write-up.
compare: power-base power-cg
	@echo "============================================================"
	@echo " IoT Data Filter -- PPA: baseline vs clock-gated"
	@echo "============================================================"
	@echo "--- BASELINE area ($(SYN_BUILD)/area_base.rpt) ---";  grep -iE "Chip area|Number of cells" $(SYN_BUILD)/area_base.rpt || true
	@echo "--- CLOCK-GATED area ($(SYN_BUILD)/area_cg.rpt) ---"; grep -iE "Chip area|Number of cells" $(SYN_BUILD)/area_cg.rpt   || true
	@echo "--- BASELINE power ($(BUILD)/power_base.rpt) ---";  grep -iE "^Total|Internal|Switching|Leakage|Group" $(BUILD)/power_base.rpt || true
	@echo "--- CLOCK-GATED power ($(BUILD)/power_cg.rpt) ---"; grep -iE "^Total|Internal|Switching|Leakage|Group" $(BUILD)/power_cg.rpt   || true
	@mkdir -p $(ARTIFACTS)
	@python3 make_ppa.py $(SYN_BUILD)/area_base.rpt $(BUILD)/power_base.rpt \
	         $(SYN_BUILD)/area_cg.rpt $(BUILD)/power_cg.rpt $(ARTIFACTS)/ppa_compare.md \
	  && echo ">> wrote $(ARTIFACTS)/ppa_compare.md" \
	  || echo ">> (fill in $(ARTIFACTS)/ppa_compare.md by hand from the reports above)"

clean:
	rm -rf $(BUILD)
