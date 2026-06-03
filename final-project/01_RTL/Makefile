# =============================================================================
# Final Project / 01_RTL -- functional-sim scaffolding for the MIMO detector.
#
# You implement the RTL in THIS directory (mimo_detector.v + submodules); these
# targets run it against the COMMITTED public dev vectors in ../00_TB/golden/
# (no Python needed to simulate -- the patterns are pre-generated and committed).
#
#   make vsim     Verilator self-checking sim vs the committed vectors  <- iterate
#   make sim      Icarus self-checking sim (same vectors)
#   make lint     Verilator lint of your RTL
#   make wave     open the dumped waveform in GTKWave
#   make score    PSNR + SER of build/detected.txt vs ../00_TB/golden/truth.txt
#   make ref      run the SAME testbench against a reference RTL: make ref RTL=<path>
#   make clean
#
# All run artifacts go under build/ (git-ignored). The default RTL is *.v in this
# directory; point a different design in with RTL=, e.g.
#   make vsim RTL=../../instructor/solutions/final-project/rtl/mimo_detector.v
# =============================================================================
DESIGN  := mimo_detector
TOP     := mimo_detector_tb
TB_TOP  := mimo_detector_tb

# student RTL lives in THIS directory (override with RTL=<path> for a reference)
RTL     ?= $(wildcard *.v)
TB      := ../00_TB/mimo_detector_tb.v

# committed PUBLIC dev set (generated once by the private generator)
GOLDEN_DIR := ../00_TB/golden
TRUTH      := $(GOLDEN_DIR)/truth.txt

# all run artifacts under build/ (ignored)
SIM_DIR := build
BUILD   := build

COMMON  := ../../common/flow
COMMON_RTL := ../../common/rtl

IVERILOG_FLAGS  := -g2012 -I. -I$(COMMON_RTL)/alu -I$(GOLDEN_DIR)
VERILATOR_FLAGS := -I. -I$(COMMON_RTL)/alu -I$(GOLDEN_DIR) \
                   -Wno-TIMESCALEMOD -Wno-BLKSEQ -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC \
                   -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM

include $(COMMON)/sim_iverilog.mk
include $(COMMON)/sim_verilator.mk

.DEFAULT_GOAL := vsim
.PHONY: ref score wave clean

# Run the SAME testbench against a reference design (must PASS):
#   make ref RTL=../../instructor/solutions/final-project/rtl/mimo_detector.v
ref:
	$(MAKE) vsim RTL="$(RTL)"

# Quality score: PSNR + SER of your detector's output vs the ground truth.
# (score.py is PUBLIC -- students measure their own PSNR.)
score:
	python3 ../00_TB/score.py --detected $(BUILD)/detected.txt --truth $(TRUTH) --m 8

wave:
	gtkwave $(BUILD)/$(DESIGN).vcd &

clean:
	rm -rf $(BUILD) obj_dir
