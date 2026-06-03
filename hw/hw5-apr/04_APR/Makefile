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
CONV_DIR := ../../../../common/rtl/conv      # relative to src/ (04_APR/src -> repo root)

# The conv engine instantiates one SRAM hard macro; APR needs its .lef/.gds/.lib.
# The sky130 OpenRAM macros ship with OpenLane; ADJUST this to your image if the
# path differs (config.json reads them from dir::macros/).
# PDK_ROOT: in-repo pdk/ if vendored (scripts/vendor-pdk.sh), else /foss/pdks.
include ../../../common/flow/pdk.mk
SRAM_MACRO_DIR ?= $(PDK_ROOT)/sky130A/libs.ref/sky130_sram_macros
SRAM           := sky130_sram_1kbyte_1rw1r_32x256_8

.DEFAULT_GOAL := apr
.PHONY: prep apr inspect klayout summary clean

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
	bash $(COMMON)/openlane_run.sh ./config.json 2>&1 | tee build/apr.log
	@echo ">> APR done. Inspect intermediate stages with 'make inspect'."

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
