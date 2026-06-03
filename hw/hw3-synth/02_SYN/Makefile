# STA runs via standalone OpenSTA if present, else OpenROAD (which embeds OpenSTA -- conda path).
STA_BIN ?= $(shell command -v sta >/dev/null 2>&1 && echo sta || echo openroad)
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
# Std cells (SCL/LIB) resolve via pdk.mk: in-repo pdk/ if vendored, else PDK_ROOT.
include ../../../common/flow/pdk.mk
SCL      := $(STD_CELL_DIR)
LIB      := $(SCL)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# ---- SRAM hard macro: blackboxed in synthesis; its .lib gives STA the timing ----
# The behavioral model supplies the interface for the blackbox; the macro's
# liberty (SRAM_LIB) is resolved by pdk.mk -- it prefers the in-repo vendored
# copy under pdk/.../sky130_sram_macros (see pdk/NOTICE), else the external PDK.
# Override SRAM_LIB=<file> if your macro liberty lives elsewhere.
SRAM_MODEL := $(CONV_INC)/sky130_sram_1kbyte_1rw1r_32x256_8.v

NETLIST  := $(BUILD)/conv_netlist.v
AREA_RPT := $(BUILD)/conv_area.rpt
STA_RPT  := $(BUILD)/conv_sta.rpt
SDF      := $(BUILD)/conv.sdf

# LEF paths are only needed if write_sdf runs under OpenROAD; standalone OpenSTA
# builds the timing graph from liberty alone (write_sdf.tcl reads LEF only if it can).
TECH_LEF  := $(SCL)/techlef/sky130_fd_sc_hd__nom.tlef
SC_LEF    := $(SCL)/lef/sky130_fd_sc_hd.lef
MACRO_LEF := $(SRAM_MACRO_DIR)/lef/sky130_sram_1kbyte_1rw1r_32x256_8.lef

.DEFAULT_GOAL := all
.PHONY: all synth sta sdf clean

all: synth sta sdf
	@echo ">> HW3 02_SYN complete: netlist + STA + SDF"

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
	  $(STA_BIN) -no_init -exit $(COMMON)/flow/sta.tcl | tee $(STA_RPT)
	@echo ">> STA report: $(STA_RPT)"

# ---- SDF (Standard Delay Format) -- cell-arc delays from the liberty ----
# Pre-layout: no wire parasitics yet (those are added at APR/HW5). Consumed by
# 03_GATE `make gl-sim-sdf` ($sdf_annotate) and usable for SDF-annotated STA.
sdf: $(SDF)
$(SDF): $(NETLIST) $(SDC)
	@mkdir -p $(BUILD)
	TECH_LEF="$(TECH_LEF)" SC_LEF="$(SC_LEF)" MACRO_LEFS="$(MACRO_LEF)" \
	  LIB="$(LIB)" MACRO_LIBS="$(SRAM_LIB)" NETLIST=$(NETLIST) TOP=$(DESIGN) \
	  SDC=$(SDC) SDF_OUT=$(SDF) \
	  $(STA_BIN) -no_init -exit $(COMMON)/flow/write_sdf.tcl
	@echo ">> SDF (cell-arc delays) -> $(SDF)"

clean:
	rm -rf $(BUILD)
