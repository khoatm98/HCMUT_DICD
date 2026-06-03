# =============================================================================
# HW1 -- TinyRISC-16 Q6.10 ALU.  Build + verify the ALU.
#
#   make            self-checking sim  (the graded check)
#   make vectors    (re)generate golden vectors with the Python model
#   make sim        Icarus self-checking simulation
#   make vsim       Verilator self-checking simulation (faster)
#   make lint       Verilator lint of your RTL
#   make wave       open the waveform in GTKWave
#   make ref        run the SAME testbench against the reference ALU (sanity)
#   make clean
# =============================================================================
TOP     := alu_tb
TB_TOP  := alu_tb
RTL     := rtl/alu.v
TB      := tb/alu_tb.v
SIM_DIR := sim

ALU_INC := ../../common/rtl/alu
GOLDEN  := golden/alu_vectors.hex golden/alu_count.vh

IVERILOG_FLAGS  := -g2012 -I$(ALU_INC) -Igolden
VERILATOR_FLAGS := -I$(ALU_INC) -Igolden \
                   -Wno-TIMESCALEMOD -Wno-BLKSEQ -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC

include ../../common/flow/sim_iverilog.mk
include ../../common/flow/sim_verilator.mk

.DEFAULT_GOAL := all
.PHONY: all vectors wave check ref clean

# The graded check is the self-checking sim. `lint` is a separate good-habit
# target (the starter will warn about not-yet-used signals -- that's expected;
# aim for a clean `make lint` once your ALU is complete).
all: sim

# Golden vectors come from the Python reference model.
vectors $(GOLDEN): tools/gen_vectors.py
	python3 tools/gen_vectors.py

# Vectors must exist before the testbench is compiled/run.
$(SIM_DIR)/$(TOP).vvp: $(GOLDEN)

check: sim

wave: sim
	gtkwave sim/alu.vcd >/dev/null 2>&1 &

# Instructor / sanity: run the testbench against the reference ALU in common/.
ref: $(GOLDEN)
	@mkdir -p $(SIM_DIR)
	iverilog $(IVERILOG_FLAGS) -o $(SIM_DIR)/alu_ref.vvp $(ALU_INC)/alu.v $(TB)
	vvp $(SIM_DIR)/alu_ref.vvp | tee $(SIM_DIR)/alu_ref.log
	@grep -q "RESULT: PASS" $(SIM_DIR)/alu_ref.log \
		&& echo ">> reference ALU PASS" || { echo ">> reference ALU FAIL"; exit 1; }

clean:
	rm -rf $(SIM_DIR) obj_dir $(GOLDEN)
