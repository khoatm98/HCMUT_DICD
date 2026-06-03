# =============================================================================
# HW1 -- TinyRISC-16 Q6.10 ALU.  Functional simulation (run from 01_RTL/).
#
#   make            self-checking sim  (the graded check; alias of `sim`)
#   make sim        Icarus self-checking simulation
#   make vsim       Verilator self-checking simulation (faster)  <- iterate here
#   make lint       Verilator lint of your RTL
#   make wave       open the waveform in GTKWave
#   make ref        run the SAME testbench against the reference ALU (sanity)
#   make clean
#
# The golden test patterns in ../00_TB/golden/ are PRE-COMMITTED -- there is no
# `make vectors`/`make golden` step and no Python needed. Override RTL=<file> to
# point the sim at a different ALU (e.g. the reference) without editing this file.
#
# All run artifacts go under build/ (git-ignored).
# =============================================================================
TOP     := alu_tb
TB_TOP  := alu_tb
RTL     ?= alu.v
TB      := ../00_TB/alu_tb.v
SIM_DIR := build

# Common RTL include dir holds the canonical opcode macros (alu_defs.vh), shared
# with HW2+. NOTE: that directory ALSO holds the reference alu.v -- and Verilator
# treats an include dir as a module-library search path, so pointing -I straight
# at it makes Verilator silently compile the REFERENCE instead of your alu.v.
# To get a faithful include WITHOUT that module pickup, we stage just the .vh
# into build/inc/ and include from there. (iverilog's -I is include-only, so it
# could use ALU_INC directly, but we keep one uniform include path for clarity.)
ALU_INC     := ../../../common/rtl/alu
GOLDEN_INC  := ../00_TB/golden
COMMON_FLOW := ../../../common/flow
INC_DIR     := $(SIM_DIR)/inc

IVERILOG_FLAGS  := -g2012 -I$(INC_DIR) -I$(GOLDEN_INC)
VERILATOR_FLAGS := -I$(INC_DIR) -I$(GOLDEN_INC) \
                   -Wno-TIMESCALEMOD -Wno-BLKSEQ -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC

include $(COMMON_FLOW)/sim_iverilog.mk
include $(COMMON_FLOW)/sim_verilator.mk

.DEFAULT_GOAL := all
.PHONY: all defs wave check ref clean

# The graded check is the self-checking sim. `lint` is a separate good-habit
# target (the starter stub will warn about not-yet-used signals -- that's
# expected; aim for a clean `make lint` once your ALU is complete).
all: sim

check: sim

# Stage the shared opcode macros into an include-only dir (see note above).
defs: $(INC_DIR)/alu_defs.vh
$(INC_DIR)/alu_defs.vh: $(ALU_INC)/alu_defs.vh
	@mkdir -p $(INC_DIR)
	cp $< $@

# Make sim/vsim/lint depend on the staged defs being present first.
$(SIM_DIR)/$(TOP).vvp: $(INC_DIR)/alu_defs.vh
sim vsim lint: $(INC_DIR)/alu_defs.vh

wave: sim
	gtkwave $(SIM_DIR)/alu.vcd >/dev/null 2>&1 &

# Instructor / sanity: run the SAME testbench against the reference ALU in
# common/rtl/alu/. Expect RESULT: PASS. (Uses Icarus per course convention.)
ref: $(INC_DIR)/alu_defs.vh
	@mkdir -p $(SIM_DIR)
	iverilog $(IVERILOG_FLAGS) -o $(SIM_DIR)/alu_ref.vvp $(ALU_INC)/alu.v $(TB)
	vvp $(SIM_DIR)/alu_ref.vvp | tee $(SIM_DIR)/alu_ref.log
	@grep -q "RESULT: PASS" $(SIM_DIR)/alu_ref.log \
		&& echo ">> reference ALU PASS" || { echo ">> reference ALU FAIL"; exit 1; }

clean:
	rm -rf $(SIM_DIR)/* obj_dir
