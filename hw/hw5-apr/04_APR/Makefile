# =============================================================================
# HW5 -- Automated Place & Route (RTL -> GDSII) of the HW3 convolution engine.
#
#   make prep        populate src/ with the design RTL (symlinks to common/rtl/conv)
#   make apr         run the full LibreLane flow (floorplan->...->route->GDS)
#   make inspect     show where the run's intermediate artifacts live
#   make klayout     open the final GDS in KLayout
#   make summary     post-route timing + DRC/LVS status from the latest run
#   make clean
#
# Back-end APR -> use the DOCKER environment (LibreLane). For conda, see the
# OpenROAD-flow-scripts note in INSTRUCTIONS.md.
# =============================================================================
COMMON   := ../../../common/flow
# relative to src/ (04_APR/src -> repo root). NOTE: no trailing inline comment on
# this `:=` line -- trailing spaces would become part of the value and split the
# `ln` args (the symlink target path must be a single shell token).
CONV_DIR := ../../../../common/rtl/conv

# The conv engine instantiates one SRAM hard macro; APR needs its .lef/.gds/.lib.
# pdk.mk resolves SRAM_MACRO_DIR -- it prefers the in-repo vendored macro under
# pdk/.../sky130_sram_macros (see pdk/NOTICE), else the external PDK. Override
# SRAM_MACRO_DIR=<dir> if your macro views live elsewhere (config.json reads the
# staged copies from dir::macros/).
include ../../../common/flow/pdk.mk
SRAM           := sky130_sram_1kbyte_1rw1r_32x256_8

# ---- conda back-end (no Docker): Yosys -> OpenROAD APR -> Magic GDS ----
SCL        := $(STD_CELL_DIR)
LIB        := $(SCL)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
TECH_LEF   := $(SCL)/techlef/sky130_fd_sc_hd__nom.tlef
SC_LEF     := $(SCL)/lef/sky130_fd_sc_hd.lef
MACRO_LEF  := $(SRAM_MACRO_DIR)/lef/$(SRAM).lef
MACRO_GDS  := $(SRAM_MACRO_DIR)/gds/$(SRAM).gds
MAGIC_TECH := $(PDK_ROOT)/sky130A/libs.tech/magic/sky130A.tech
SDC        := ../../hw3-synth/02_SYN/conv.sdc
CONV_RTL   := ../../../common/rtl/conv
SRAM_MODEL := $(CONV_RTL)/sky130_sram_1kbyte_1rw1r_32x256_8.v
NETLIST    := build/conv_netlist.v
DEF        := build/conv.def
GDS        := build/conv.gds

.DEFAULT_GOAL := apr
.PHONY: prep apr apr-conda gui inspect klayout summary clean

# Populate src/ from the canonical conv RTL (symlinks -> single source of truth:
# APR runs the SAME engine verified in HW3) and stage the SRAM macro views.
prep:
	@mkdir -p src macros
	@ln -sf $(CONV_DIR)/conv_engine.v src/conv_engine.v
	@ln -sf $(CONV_DIR)/conv_defs.vh  src/conv_defs.vh
	@echo ">> src/ populated:"; ls -l src/*.v src/*.vh
	@# Stage the SRAM macro views (best-effort: paths are image-dependent).
	@for ext in gds lef; do \
	  f=$$(find $(SRAM_MACRO_DIR) -name "$(SRAM).$$ext" 2>/dev/null | head -1); \
	  [ -n "$$f" ] && ln -sf "$$f" macros/$(SRAM).$$ext || \
	    echo "   NOTE: $(SRAM).$$ext not found under $(SRAM_MACRO_DIR) -- set SRAM_MACRO_DIR"; \
	done
	@f=$$(find $(SRAM_MACRO_DIR) -name "$(SRAM)_TT*1p8V*25C.lib" 2>/dev/null | head -1); \
	  [ -n "$$f" ] && ln -sf "$$f" macros/$(SRAM)_TT_1p8V_25C.lib || \
	    echo "   NOTE: $(SRAM) .lib not found -- set SRAM_MACRO_DIR; config.json expects macros/$(SRAM)_TT_1p8V_25C.lib"
	@echo ">> macros/ (for APR macro placement):"; ls -l macros/ 2>/dev/null || true

apr: prep
	@mkdir -p build
	PDK_ROOT="$(PDK_ROOT)" bash $(COMMON)/openlane_run.sh ./config.json 2>&1 | tee build/apr.log
	@echo ">> APR done. Inspect intermediate stages with 'make inspect'."

# ---- conda back-end: RTL -> GDS with Yosys + OpenROAD + Magic (no Docker) ----
#   make apr-conda      synth -> floorplan/place/CTS/route (OpenROAD) -> GDS (Magic)
#   make gui            open the routed layout in Magic (needs X: ssh -Y / VNC)
apr-conda: $(GDS)
	@echo ">> conda APR complete:  netlist=$(NETLIST)  def=$(DEF)  gds=$(GDS)"

$(NETLIST): prep
	@mkdir -p build
	TOP=conv_engine RTL_FILES="src/conv_engine.v" INCDIRS="$(CONV_RTL)" LIB="$(LIB)" \
	  MACRO_LIBS="$(SRAM_LIB)" NETLIST_OUT=$(NETLIST) STAT_OUT=build/conv_area.rpt \
	  yosys -c $(COMMON)/synth_sky130.tcl

$(DEF): $(NETLIST) $(SDC)
	TECH_LEF="$(TECH_LEF)" SC_LEF="$(SC_LEF)" MACRO_LEFS="$(MACRO_LEF)" \
	  LIB="$(LIB)" MACRO_LIBS="$(SRAM_LIB)" NETLIST="$(NETLIST)" TOP=conv_engine \
	  SDC=$(SDC) OUT_DEF=$(DEF) OUT_NETLIST=build/conv.apr.v MACRO_INSTS=u_img \
	  openroad -no_init -exit $(COMMON)/apr_openroad.tcl 2>&1 | tee build/apr_conda.log

$(GDS): $(DEF)
	SC_LEF="$(SC_LEF)" MACRO_LEF="$(MACRO_LEF)" MACRO_GDS="$(MACRO_GDS)" \
	  DEF="$(DEF)" TOP=conv_engine GDS_OUT=$(GDS) \
	  magic -dnull -noconsole -T $(MAGIC_TECH) $(COMMON)/def2gds.tcl 2>&1 | tee build/def2gds.log

gui:
	@[ -f $(DEF) ] || { echo "No routed DEF -- run 'make apr-conda' first."; exit 1; }
	SC_LEF="$(SC_LEF)" MACRO_LEF="$(MACRO_LEF)" DEF="$(DEF)" TOP=conv_engine \
	  magic -T $(MAGIC_TECH) $(COMMON)/magic_view.tcl

inspect:
	@run=$$(ls -dt runs/*/ 2>/dev/null | head -1); \
	 if [ -z "$$run" ]; then echo "No run yet -- 'make apr' first."; exit 1; fi; \
	 echo "Latest run: $$run"; \
	 echo "  per-stage logs/DEFs (floorplan, PDN, placement, CTS, routing): $$run"; \
	 echo "  reports (timing, DRC, LVS): under $$run"; \
	 echo "  final GDS:"; find "$$run" -name '*.gds' 2>/dev/null

klayout:
	@gds=$$(find runs -name '*.gds' 2>/dev/null | head -1); \
	 if [ -z "$$gds" ]; then echo "No GDS -- 'make apr' first."; exit 1; fi; \
	 echo "Opening $$gds"; klayout "$$gds" >/dev/null 2>&1 &

summary:
	@run=$$(ls -dt runs/*/ 2>/dev/null | head -1); \
	 echo "Latest run: $$run"; \
	 echo "--- post-route timing / DRC / LVS (search the run) ---"; \
	 find "$$run" \( -iname '*sta*summary*' -o -iname '*drc*' -o -iname '*lvs*' \) 2>/dev/null | head -20

clean:
	rm -rf runs build src/*.v src/*.vh
