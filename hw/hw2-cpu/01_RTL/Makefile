# =============================================================================
# HW2 -- TinyRISC-16 CPU + MAC custom instruction (01_RTL functional sim).
#
#   make             self-checking sim over ALL programs (Icarus)   == make check
#   make sim  PROG=p run one program through Icarus
#   make vsim PROG=p run one program through Verilator (faster -- iterate with this)
#   make lint        Verilator lint of the RTL
#   make ref         run ALL programs against the REFERENCE CPU (instructor sanity)
#   make wave PROG=p open the waveform in GTKWave
#   make clean
#
# You edit cpu_core.v. The ALU (HW1) and the register file are provided in
# common/rtl. The TEST PATTERNS are pre-committed in ../00_TB/patterns/ (one
# .imem/.dmem/.golden hex per program) -- no Python or assembler needed: the
# selected program's patterns are copied into build/ before each run.
#
#   override the design under test, e.g. the reference CPU:
#     make vsim RTL="../../../common/rtl/alu/alu.v \
#                    ../../../common/rtl/cpu/regfile.v \
#                    ../../../common/rtl/cpu/cpu_core.v"
# =============================================================================
PROG    ?= ops
PROGS   := ops mac

# ---- paths (uniform stage-dir convention) ----
TB_DIR    := ../00_TB
PAT_DIR   := $(TB_DIR)/patterns
COMMON    := ../../../common
SIM_DIR   := build

# student CPU + provided building blocks (HW1 ALU + register file).
# NOTE: the local stub is passed by ABSOLUTE path on purpose -- a bare
# "cpu_core.v" would be shadowed by the reference of the same name found via the
# -I../../../common/rtl/cpu include dir (Verilator searches -I dirs for relative
# source filenames). $(CURDIR)/ forces the student's file under test.
RTL     ?= $(COMMON)/rtl/alu/alu.v $(COMMON)/rtl/cpu/regfile.v $(CURDIR)/cpu_core.v
# reference CPU (instructor / sanity)
REF_RTL := $(COMMON)/rtl/alu/alu.v $(COMMON)/rtl/cpu/regfile.v $(COMMON)/rtl/cpu/cpu_core.v
TB      := $(TB_DIR)/cpu_tb.v
TB_TOP  := cpu_tb
TOP     := cpu_$(PROG)

INCS            := -I$(COMMON)/rtl/alu -I$(COMMON)/rtl/cpu
IVERILOG_FLAGS  := -g2012 $(INCS)
VERILATOR_FLAGS := $(INCS) -Wno-TIMESCALEMOD -Wno-BLKSEQ -Wno-WIDTHEXPAND \
                   -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM

.DEFAULT_GOAL := all
.PHONY: all check prep sim vsim ref wave clean

all: check

# Stage the selected program's committed patterns into the build dir (no Python).
prep:
	@mkdir -p $(SIM_DIR)
	cp $(PAT_DIR)/$(PROG).imem.hex   $(SIM_DIR)/imem.hex
	cp $(PAT_DIR)/$(PROG).dmem.hex   $(SIM_DIR)/dmem.hex
	cp $(PAT_DIR)/$(PROG).golden.hex $(SIM_DIR)/golden.hex

# stage patterns before the reusable sim/vsim recipes run
sim:  prep
vsim: prep

# Reusable functional-sim includes (provide sim / vsim / lint).
include $(COMMON)/flow/sim_iverilog.mk
include $(COMMON)/flow/sim_verilator.mk

# Run every provided program (the graded check) via Icarus.
check:
	@for p in $(PROGS); do \
		echo "==== program: $$p ===="; \
		$(MAKE) --no-print-directory sim PROG=$$p || exit 1; \
	done
	@echo ">> ALL PROGRAMS PASS"

# Instructor / sanity: run all programs against the reference CPU.
ref:
	@for p in $(PROGS); do \
		echo "==== ref: $$p ===="; \
		$(MAKE) --no-print-directory sim PROG=$$p RTL="$(REF_RTL)" || exit 1; \
	done
	@echo ">> REFERENCE CPU PASS on all programs"

wave: prep
	gtkwave $(SIM_DIR)/cpu.vcd >/dev/null 2>&1 &

clean:
	rm -rf $(SIM_DIR) obj_dir
