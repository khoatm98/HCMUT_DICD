# =============================================================================
# HW3 02_SYN -- synthesize the convolution engine to SKY130 gates + STA.
#
#   make synth       Yosys -> build/conv_netlist.v + build/conv_area.rpt
#   make sta         OpenSTA timing on the netlist using conv.sdc -> build/conv_sta.rpt
#   make all         synth + sta
#   make clean
#
# Synthesizes ../01_RTL/conv_engine.v (the design you completed in 01_RTL) via
# the shared Yosys wrapper. All outputs land in build/ (git-ignored). Back-end
# tools (Yosys, OpenSTA) + the SKY130 PDK live in the EDA container (`make shell`).
# =============================================================================
DESIGN := conv_engine

# shared trees (relative to this stage directory)
COMMON   := ../../../common
CONV_INC := $(COMMON)/rtl/conv
RTL      := ../01_RTL/conv_engine.v
SDC      := conv.sdc

BUILD := build

# ---- SKY130 standard-cell library (lives in the EDA container) ----
PDK_ROOT ?= /foss/pdks
SCL      := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd
LIB      := $(SCL)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# ---- SRAM hard macro: blackboxed in synthesis; its .lib gives STA the timing ----
# The behavioral model supplies the interface for the blackbox; the macro's
# liberty ships with the sky130 OpenRAM macros. ADJUST SRAM_LIB to your image
# if the path differs (the macros are not in the base std-cell PDK).
SRAM_MODEL := $(CONV_INC)/sky130_sram_1kbyte_1rw1r_32x256_8.v
SRAM_LIB   ?= $(PDK_ROOT)/sky130A/libs.ref/sky130_sram_macros/lib/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib

NETLIST  := $(BUILD)/conv_netlist.v
AREA_RPT := $(BUILD)/conv_area.rpt
STA_RPT  := $(BUILD)/conv_sta.rpt

.DEFAULT_GOAL := all
.PHONY: all synth sta clean

all: synth sta
	@echo ">> HW3 02_SYN complete: netlist + STA"

# ---- Yosys synthesis -> SKY130 gate-level netlist + area/cell report ----
synth: $(NETLIST)
$(NETLIST): $(RTL)
	@mkdir -p $(BUILD)
	TOP=$(DESIGN) RTL_FILES="$(RTL)" INCDIRS="$(CONV_INC)" LIB="$(LIB)" \
	  BLACKBOX_FILES="$(SRAM_MODEL)" \
	  NETLIST_OUT=$(NETLIST) STAT_OUT=$(AREA_RPT) \
	  yosys -c $(COMMON)/flow/synth_sky130.tcl
	@echo ">> synthesized $(DESIGN) -> $(NETLIST)  (area: $(AREA_RPT))"

# ---- OpenSTA static timing of the netlist using conv.sdc ----
sta: $(NETLIST) $(SDC)
	@mkdir -p $(BUILD)
	TOP=$(DESIGN) LIB="$(LIB)" MACRO_LIBS="$(SRAM_LIB)" NETLIST=$(NETLIST) SDC=$(SDC) \
	  sta -no_init -exit $(COMMON)/flow/sta.tcl | tee $(STA_RPT)
	@echo ">> STA report: $(STA_RPT)"

clean:
	rm -rf $(BUILD)
