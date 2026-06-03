# =============================================================================
# HW2 -- TinyRISC-16 CPU + MAC custom instruction.
#
#   make             assemble + golden-ISS + self-checking sim over all programs
#   make sim PROG=p  run one program (programs/p.s) through Icarus
#   make vsim PROG=p run one program through Verilator (faster)
#   make prog PROG=p just assemble + generate the golden for programs/p.s
#   make ref         run all programs against the REFERENCE CPU (instructor)
#   make wave PROG=p open the waveform in GTKWave
#   make clean
#
# You edit rtl/cpu_core.v. The ALU (HW1) and the register file are provided.
# =============================================================================
PROG    ?= ops
PROGS   := ops mac
SIM_DIR := sim

# student CPU + provided building blocks
RTL     := ../../common/rtl/alu/alu.v ../../common/rtl/cpu/regfile.v rtl/cpu_core.v
# reference CPU (instructor / sanity)
REF_RTL := ../../common/rtl/alu/alu.v ../../common/rtl/cpu/regfile.v ../../common/rtl/cpu/cpu_core.v
TB      := tb/cpu_tb.v
TB_TOP  := cpu_tb

INCS            := -I../../common/rtl/alu -I../../common/rtl/cpu
IVERILOG_FLAGS  := -g2012 $(INCS)
VERILATOR_FLAGS := $(INCS) -Wno-TIMESCALEMOD -Wno-BLKSEQ -Wno-WIDTHEXPAND \
                   -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM

.DEFAULT_GOAL := all
.PHONY: all check sim vsim ref prog wave clean

all: check

# Assemble programs/$(PROG).s and produce the golden final-memory image.
prog:
	@mkdir -p $(SIM_DIR)
	python3 tools/asm.py programs/$(PROG).s $(SIM_DIR)/imem.hex $(SIM_DIR)/dmem.hex
	python3 tools/iss.py $(SIM_DIR)/imem.hex $(SIM_DIR)/dmem.hex $(SIM_DIR)/golden.hex

# Icarus self-checking sim of the CPU on one program.
sim: prog
	@mkdir -p $(SIM_DIR)
	iverilog $(IVERILOG_FLAGS) -o $(SIM_DIR)/cpu.vvp $(RTL) $(TB)
	vvp $(SIM_DIR)/cpu.vvp | tee $(SIM_DIR)/cpu_$(PROG).log
	@grep -q "RESULT: PASS" $(SIM_DIR)/cpu_$(PROG).log \
		|| { echo ">> program '$(PROG)' FAILED"; exit 1; }
	@echo ">> program '$(PROG)' PASS"

# Verilator self-checking sim (faster).
vsim: prog
	@mkdir -p $(SIM_DIR)
	verilator --binary --timing -Wall -Wno-fatal $(VERILATOR_FLAGS) \
		--top-module $(TB_TOP) -o V$(TB_TOP) $(RTL) $(TB)
	./obj_dir/V$(TB_TOP) | tee $(SIM_DIR)/cpu_$(PROG)_vl.log
	@grep -q "RESULT: PASS" $(SIM_DIR)/cpu_$(PROG)_vl.log \
		|| { echo ">> program '$(PROG)' FAILED"; exit 1; }
	@echo ">> program '$(PROG)' PASS"

# Run every provided program (the graded check).
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

wave: prog
	gtkwave $(SIM_DIR)/cpu.vcd >/dev/null 2>&1 &

clean:
	rm -rf $(SIM_DIR) obj_dir
