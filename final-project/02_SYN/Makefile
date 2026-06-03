# =============================================================================
# Final Project / 02_SYN -- Yosys synthesis to SKY130 + OpenSTA timing.
#
# Synthesizes the RTL you wrote in ../01_RTL using the shared flow script
# common/flow/synth_sky130.tcl, then runs OpenSTA with mimo.sdc (CVSD I/O).
# Runs inside the EDA container (Yosys / OpenSTA + SKY130 PDK).
#
#   make synth    SKY130 gate netlist + area report   -> build/
#   make sta      OpenSTA setup/hold timing using mimo.sdc
#   make all      synth + sta
#   make clean
# =============================================================================
DESIGN  := mimo_detector
BUILD   := build
COMMON  := ../../common/flow

# RTL comes from the student's 01_RTL (override RTL= for a reference design)
RTL     ?= $(wildcard ../01_RTL/*.v)
INCDIRS := ../01_RTL ../../common/rtl/alu
SDC     := mimo.sdc

# ---- back-end (SKY130) paths: live in the EDA container ----
PDK_ROOT ?= /foss/pdks
SCL      := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd
LIB      := $(SCL)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

NETLIST  := $(BUILD)/$(DESIGN)_netlist.v
AREA_RPT := $(BUILD)/$(DESIGN)_area.rpt
STA_RPT  := $(BUILD)/$(DESIGN)_sta.rpt

.DEFAULT_GOAL := synth
.PHONY: synth sta all clean

synth: $(NETLIST)
$(NETLIST): $(RTL)
	@mkdir -p $(BUILD)
	TOP=$(DESIGN) RTL_FILES="$(RTL)" INCDIRS="$(INCDIRS)" LIB="$(LIB)" \
	  NETLIST_OUT=$(NETLIST) STAT_OUT=$(AREA_RPT) \
	  yosys -c $(COMMON)/synth_sky130.tcl
	@echo ">> netlist: $(NETLIST)"

sta: $(NETLIST) $(SDC)
	TOP=$(DESIGN) LIB="$(LIB)" NETLIST=$(NETLIST) SDC=$(SDC) \
	  sta -no_init -exit $(COMMON)/sta.tcl | tee $(STA_RPT)

all: synth sta
	@echo ">> synth + sta complete"

clean:
	rm -rf $(BUILD)
