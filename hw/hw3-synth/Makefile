# =============================================================================
# HW3 -- 3x3 convolution engine.  Design it, synthesize it, prove gate
# equivalence, analyze area/timing.  This is the SYNTHESIS homework.
#
#   make                 functional self-checking sim (the graded RTL check)
#   make golden          (re)generate stimulus/expected with the Python model
#   make sim             Icarus self-checking simulation        (RTL)
#   make vsim            Verilator self-checking simulation      (RTL, faster)
#   make lint            Verilator lint of your RTL
#   make wave            open the waveform in GTKWave
#   make ref             run the SAME testbench against the reference engine
#   make synth           Yosys -> SKY130 gate netlist + area report
#   make sta             OpenSTA timing using constraints/conv.sdc (you write it)
#   make gl-sim          gate-level sim of the netlist vs the SAME golden
#   make all             synth + sta + gl-sim
#   make clean
#
# You edit rtl/conv_engine.v AND constraints/conv.sdc. The testbench, golden
# model, and synthesis/STA flow wrappers are provided.
# =============================================================================
TOP     := conv_engine_tb
TB_TOP  := conv_engine_tb
DESIGN  := conv_engine
TB      := tb/conv_engine_tb.v
SIM_DIR := sim
BUILD   := build

# student RTL + the conv defs include dir
RTL      := rtl/conv_engine.v
CONV_INC := ../../common/rtl/conv
# reference engine (instructor / sanity / gl-sim equivalence baseline)
REF_RTL  := $(CONV_INC)/conv_engine.v

GOLDEN := golden/conv_stim.hex golden/conv_exp.hex golden/conv_count.vh

IVERILOG_FLAGS  := -g2012 -I$(CONV_INC) -Igolden
VERILATOR_FLAGS := -I$(CONV_INC) -Igolden \
                   -Wno-TIMESCALEMOD -Wno-BLKSEQ -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC \
                   -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM

include ../../common/flow/sim_iverilog.mk
include ../../common/flow/sim_verilator.mk

# ---- back-end (SKY130) paths: live in the EDA container ----
PDK_ROOT ?= /foss/pdks
SCL      := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd
LIB      := $(SCL)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
CELLS_V  := $(SCL)/verilog/sky130_fd_sc_hd.v $(SCL)/verilog/primitives.v
COMMON   := ../../common/flow

NETLIST  := $(BUILD)/conv_netlist.v
AREA_RPT := $(BUILD)/conv_area.rpt
STA_RPT  := $(BUILD)/conv_sta.rpt
SDC      := constraints/conv.sdc

.DEFAULT_GOAL := all-sim
.PHONY: all all-sim golden wave check ref synth sta gl-sim clean

# Default convenience: the functional RTL check (use `make all` for the
# full synth+STA+gl-sim back-end flow inside the container).
all-sim: sim

# Golden stimulus/expected come from the Python reference model.
golden $(GOLDEN): tools/gen_golden.py
	python3 tools/gen_golden.py

# Vectors must exist before the testbench is compiled/run.
$(SIM_DIR)/$(TOP).vvp: $(GOLDEN)

check: sim

wave: sim
	gtkwave $(SIM_DIR)/$(DESIGN).vcd >/dev/null 2>&1 &

# Instructor / sanity: run the testbench against the reference engine in common/.
ref: $(GOLDEN)
	@mkdir -p $(SIM_DIR)
	iverilog $(IVERILOG_FLAGS) -o $(SIM_DIR)/conv_ref.vvp $(REF_RTL) $(TB)
	vvp $(SIM_DIR)/conv_ref.vvp | tee $(SIM_DIR)/conv_ref.log
	@grep -q "RESULT: PASS" $(SIM_DIR)/conv_ref.log \
		&& echo ">> reference engine PASS" || { echo ">> reference engine FAIL"; exit 1; }

# ----------------------------- BACK-END (container) -----------------------------
# Yosys synthesis to a SKY130 gate-level netlist + area/cell report.
synth: $(NETLIST)
$(NETLIST): $(RTL)
	@mkdir -p $(BUILD)
	TOP=$(DESIGN) RTL_FILES="$(RTL)" INCDIRS="$(CONV_INC)" LIB="$(LIB)" \
	  NETLIST_OUT=$(NETLIST) STAT_OUT=$(AREA_RPT) \
	  yosys -c $(COMMON)/synth_sky130.tcl
	@echo ">> synthesized $(DESIGN) -> $(NETLIST)  (area: $(AREA_RPT))"

# OpenSTA static timing of the synthesized netlist using YOUR constraints.
sta: $(NETLIST) $(SDC)
	TOP=$(DESIGN) LIB="$(LIB)" NETLIST=$(NETLIST) SDC=$(SDC) \
	  sta -no_init -exit $(COMMON)/sta.tcl | tee $(STA_RPT)
	@echo ">> STA report: $(STA_RPT)"

# Gate-level sim: the SAME self-checking testbench drives the synthesized
# netlist + SKY130 cell models, compared against the SAME golden -> proves the
# netlist is functionally EQUIVALENT to the RTL. (-DFUNCTIONAL -DUNIT_DELAY for
# zero-/unit-delay cell models so the clocked TB lines up.)
gl-sim: $(NETLIST) $(GOLDEN)
	@mkdir -p $(SIM_DIR)
	iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY="#1" \
	  -I$(SCL)/verilog -Igolden \
	  -o $(SIM_DIR)/conv_gl.vvp $(CELLS_V) $(NETLIST) $(TB)
	vvp $(SIM_DIR)/conv_gl.vvp | tee $(SIM_DIR)/conv_gl.log
	@grep -q "RESULT: PASS" $(SIM_DIR)/conv_gl.log \
		&& echo ">> gate-level sim PASS (netlist == RTL)" \
		|| { echo ">> gate-level sim FAIL (netlist != golden)"; exit 1; }

# The full back-end flow.
all: synth sta gl-sim
	@echo ">> HW3 back-end flow complete: synth + STA + gate-level equivalence"

clean:
	rm -rf $(SIM_DIR) obj_dir $(BUILD) $(GOLDEN)
