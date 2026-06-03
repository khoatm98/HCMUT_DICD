# =============================================================================
# HW4 -- IoT Data Filter : 01_RTL functional-simulation Makefile.
#
# Run from this directory (hw/hw4-power/01_RTL):
#   make vsim     Verilator self-checking sim (fast)        <- iterate here
#   make sim      Icarus self-checking sim
#   make lint     Verilator lint of your RTL
#   make wave     open the VCD in GTKWave
#   make ref      run the SAME testbench against the REFERENCE iotdf (sanity)
#   make clean    remove build artifacts
#
# You edit iotdf.v. The testbench + the committed public test patterns live in
# ../00_TB (../00_TB/golden); the shared iotdf_defs.vh lives in common/rtl/iotdf.
# All run artifacts go under build/ (git-ignored). The public golden patterns are
# pre-committed -- there is NO 'make vectors' / generator step for students.
# =============================================================================
TOP        := iotdf
TB_TOP     := iotdf_tb
RTL        := iotdf.v
REF_RTL    := ../../../common/rtl/iotdf/iotdf.v
TB         := ../00_TB/iotdf_tb.v

# ---- stage-dir layout (uniform convention) ----
TB_DIR       := ../00_TB
GOLDEN_DIR   := ../00_TB/golden
WORKLOAD_DIR := ../00_TB/workload
IOTDF_RTL    := ../../../common/rtl/iotdf
COMMON       := ../../../common/flow
BUILD        := build
# header-only incdir (exposes just iotdf_defs.vh, never the reference iotdf.v)
SIM_DIR      := $(BUILD)/sim
INC_DIR      := $(BUILD)/inc

# The testbench reads its patterns with RELATIVE paths ($readmemh "golden/...",
# $dumpfile "sim/...") and `includes count headers + iotdf_defs.vh. `prep` exposes
# those names under build/ (golden/, workload/, sim/, inc/) without copying. The
# defs header is exposed via a HEADER-ONLY incdir so Verilator does not also pull
# the reference common/rtl/iotdf/iotdf.v in as a library module.
IVERILOG_FLAGS  := -g2012 -I$(INC_DIR) -I$(GOLDEN_DIR) -I$(WORKLOAD_DIR)
VERILATOR_FLAGS := -I$(INC_DIR) -I$(GOLDEN_DIR) \
                   -Wno-TIMESCALEMOD -Wno-BLKSEQ -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC \
                   -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM

# Reusable simulation recipes (sim / vsim / lint) -- shared across the course.
include $(COMMON)/sim_iverilog.mk
include $(COMMON)/sim_verilator.mk

.DEFAULT_GOAL := vsim
.PHONY: prep wave ref clean

# Expose, under build/, the relative names the byte-identical testbench expects
# (golden/, workload/, sim/) plus a header-only incdir with just iotdf_defs.vh.
# Nothing is copied; build/ is git-ignored.
prep:
	@mkdir -p $(SIM_DIR) $(INC_DIR)
	@ln -sfn $(GOLDEN_DIR)   golden
	@ln -sfn $(WORKLOAD_DIR) workload
	@ln -sfn $(SIM_DIR)      sim
	@ln -sfn ../../$(IOTDF_RTL)/iotdf_defs.vh $(INC_DIR)/iotdf_defs.vh

# The reused recipes run from here, so they need the patterns + headers prepped.
lint: prep
sim:  prep
vsim: prep

wave: sim
	gtkwave $(SIM_DIR)/iotdf.vcd >/dev/null 2>&1 &

# Instructor / sanity: run the SAME testbench against the REFERENCE iotdf.
#   - Icarus path:    make ref
#   - Verilator path: make vsim RTL=$(REF_RTL)   (front-end machines)
# Either must print "RESULT: PASS".
ref: prep
	@mkdir -p $(SIM_DIR)
	iverilog $(IVERILOG_FLAGS) -o $(SIM_DIR)/iotdf_ref.vvp $(REF_RTL) $(TB)
	vvp $(SIM_DIR)/iotdf_ref.vvp | tee $(SIM_DIR)/iotdf_ref.log
	@grep -q "RESULT: PASS" $(SIM_DIR)/iotdf_ref.log \
		&& echo ">> reference iotdf PASS" || { echo ">> reference iotdf FAIL"; exit 1; }

clean:
	rm -rf $(BUILD) obj_dir golden workload sim
