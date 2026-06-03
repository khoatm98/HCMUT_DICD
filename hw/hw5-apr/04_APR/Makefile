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

.DEFAULT_GOAL := apr
.PHONY: prep apr inspect klayout summary clean

# Populate src/ from the canonical conv RTL (symlinks -> single source of truth:
# APR runs the SAME engine verified in HW3).
prep:
	@mkdir -p src
	@ln -sf $(CONV_DIR)/conv_engine.v src/conv_engine.v
	@ln -sf $(CONV_DIR)/conv_defs.vh  src/conv_defs.vh
	@echo ">> src/ populated:"; ls -l src/*.v src/*.vh

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
