# =============================================================================
# HW4 -- IoT Data Filter (the POWER homework).
#
# FUNCTIONAL (runs locally with Icarus / Verilator):
#   make            self-checking sim of all four functions (the graded check)
#   make vectors    (re)generate golden + workload from the Python model
#   make sim        Icarus self-checking simulation
#   make vsim       Verilator self-checking simulation (faster) <- iterate here
#   make lint       Verilator lint of your RTL
#   make wave       open sim/iotdf.vcd in GTKWave
#   make ref        run the SAME testbench against the reference iotdf (sanity)
#
# POWER (needs the EDA container: Yosys + Icarus + OpenSTA + SKY130 PDK):
#   make power-base synth baseline -> gate-level sim on the workload -> report_power
#                   (build/power_base.rpt)
#   make power-cg   same but synth with CLOCKGATE=1     (build/power_cg.rpt)
#   make compare    baseline vs clock-gated power + area; writes
#                   artifacts/ppa_compare.md from the two reports
#   make clean
#
# You edit rtl/iotdf.v. The testbench, golden model, and flow are provided.
# =============================================================================
TOP        := iotdf
TB_TOP     := iotdf_tb
WL_TOP     := iotdf_workload_tb
RTL        := rtl/iotdf.v
REF_RTL    := ../../common/rtl/iotdf/iotdf.v
TB         := tb/iotdf_tb.v
WL_TB      := tb/iotdf_workload_tb.v
SIM_DIR    := sim
BUILD      := build

IOTDF_INC  := ../../common/rtl/iotdf
GOLDEN     := golden/iotdf_vectors.hex golden/iotdf_count.vh
WORKLOAD   := workload/workload.hex workload/workload_count.vh

# ---- SKY130 PDK (baked into the EDA container) ----
PDK_ROOT   ?= /foss/pdks
SCL        := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd
LIB        := $(SCL)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
CELLS      := $(SCL)/verilog/sky130_fd_sc_hd.v
PRIMS      := $(SCL)/verilog/primitives.v

COMMON     := ../../common/flow
SDC        := iotdf.sdc

IVERILOG_FLAGS  := -g2012 -I$(IOTDF_INC) -Igolden -Iworkload
VERILATOR_FLAGS := -I$(IOTDF_INC) -Igolden \
                   -Wno-TIMESCALEMOD -Wno-BLKSEQ -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC \
                   -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM

include $(COMMON)/sim_iverilog.mk
include $(COMMON)/sim_verilator.mk

.DEFAULT_GOAL := all
.PHONY: all vectors wave check ref clean \
        power-base power-cg compare _power_pass

all: sim

# ---------------------------------------------------------------------------
# Functional verification (local).
# ---------------------------------------------------------------------------
# Golden vectors + power workload come from the Python reference model.
vectors $(GOLDEN) $(WORKLOAD): tools/gen_golden.py
	python3 tools/gen_golden.py

# Vectors must exist before the testbench is compiled/run.
$(SIM_DIR)/$(TOP).vvp: $(GOLDEN)

check: sim

wave: sim
	gtkwave sim/iotdf.vcd >/dev/null 2>&1 &

# Instructor / sanity: run the testbench against the REFERENCE iotdf in common/.
ref: $(GOLDEN)
	@mkdir -p $(SIM_DIR)
	iverilog $(IVERILOG_FLAGS) -o $(SIM_DIR)/iotdf_ref.vvp $(REF_RTL) $(TB)
	vvp $(SIM_DIR)/iotdf_ref.vvp | tee $(SIM_DIR)/iotdf_ref.log
	@grep -q "RESULT: PASS" $(SIM_DIR)/iotdf_ref.log \
		&& echo ">> reference iotdf PASS" || { echo ">> reference iotdf FAIL"; exit 1; }

# ---------------------------------------------------------------------------
# POWER FLOW (container).  Two passes; recursion gives each its own variables
# (sharing one PHONY node would build it only once -- so we re-enter make).
#   power-base : build/iotdf_base.v   (no clock gating)
#   power-cg   : build/iotdf_cg.v     (clockgate -liberty, CLOCKGATE=1)
# Each pass: Yosys synth -> gate-level Icarus sim on the workload (writes a VCD)
# -> OpenSTA report_power using that VCD for switching activity.
# ---------------------------------------------------------------------------
power-base:
	@$(MAKE) --no-print-directory _power_pass TAG=base CGFLAG=

power-cg:
	@$(MAKE) --no-print-directory _power_pass TAG=cg CGFLAG=1

# One full pass for a given TAG/CGFLAG: synth -> gate-level sim -> report_power.
_power_pass: $(WORKLOAD)
	@mkdir -p $(BUILD) $(SIM_DIR)
	# 1) Synthesize the STUDENT RTL to SKY130 cells (optionally with clock gating).
	TOP=$(TOP) RTL_FILES="$(RTL)" INCDIRS="$(IOTDF_INC)" LIB="$(LIB)" \
	  NETLIST_OUT=$(BUILD)/iotdf_$(TAG).v STAT_OUT=$(BUILD)/area_$(TAG).rpt \
	  CLOCKGATE="$(CGFLAG)" \
	  yosys -c $(COMMON)/synth_sky130.tcl
	# 2) Gate-level sim of the netlist on the workload -> activity VCD.
	#    SKY130 cell models are simulated functionally with a unit delay.
	iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY="#1" -I$(SCL)/verilog -Iworkload \
	  -o $(SIM_DIR)/iotdf_gl_$(TAG).vvp \
	  $(PRIMS) $(CELLS) $(BUILD)/iotdf_$(TAG).v $(WL_TB)
	vvp $(SIM_DIR)/iotdf_gl_$(TAG).vvp        # run from hw root: workload/ + sim/ paths resolve
	@mv $(SIM_DIR)/iotdf_workload.vcd $(SIM_DIR)/iotdf_workload_$(TAG).vcd
	# 3) OpenSTA timing + activity-driven power report.
	TOP=$(TOP) LIB="$(LIB)" NETLIST=$(BUILD)/iotdf_$(TAG).v SDC=$(SDC) \
	  VCD=$(SIM_DIR)/iotdf_workload_$(TAG).vcd VCD_SCOPE=$(WL_TOP)/dut \
	  sta -no_init -exit $(COMMON)/sta.tcl | tee $(BUILD)/power_$(TAG).rpt
	@echo ">> wrote $(BUILD)/power_$(TAG).rpt and $(BUILD)/area_$(TAG).rpt"

# ---------------------------------------------------------------------------
# Compare baseline vs clock-gated: print key numbers and template a report.
# ---------------------------------------------------------------------------
compare: power-base power-cg
	@echo "============================================================"
	@echo " IoT Data Filter -- PPA: baseline vs clock-gated"
	@echo "============================================================"
	@echo "--- BASELINE area ($(BUILD)/area_base.rpt) ---";  grep -iE "Chip area|Number of cells" $(BUILD)/area_base.rpt || true
	@echo "--- CLOCK-GATED area ($(BUILD)/area_cg.rpt) ---"; grep -iE "Chip area|Number of cells" $(BUILD)/area_cg.rpt   || true
	@echo "--- BASELINE power ($(BUILD)/power_base.rpt) ---";  grep -iE "^Total|Internal|Switching|Leakage|Group" $(BUILD)/power_base.rpt || true
	@echo "--- CLOCK-GATED power ($(BUILD)/power_cg.rpt) ---"; grep -iE "^Total|Internal|Switching|Leakage|Group" $(BUILD)/power_cg.rpt   || true
	@python3 tools/make_ppa.py $(BUILD)/area_base.rpt $(BUILD)/power_base.rpt \
	         $(BUILD)/area_cg.rpt $(BUILD)/power_cg.rpt artifacts/ppa_compare.md \
	  && echo ">> wrote artifacts/ppa_compare.md" \
	  || echo ">> (fill in artifacts/ppa_compare.md by hand from the reports above)"

clean:
	rm -rf $(SIM_DIR) obj_dir $(BUILD) $(GOLDEN) $(WORKLOAD)
