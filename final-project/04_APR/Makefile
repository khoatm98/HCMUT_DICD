# =============================================================================
# Final Project / 04_APR -- LibreLane RTL->GDSII for the MIMO detector.
#
# Drives the shared LibreLane runner (common/flow/openlane_run.sh) with the
# config.json here, which points at the RTL you wrote in ../01_RTL. Produces a
# DRC-clean, LVS-matching GDSII under runs/<tag>/. Runs in the EDA container.
#
#   make apr      LibreLane RTL->GDSII (config.json)
#   make clean
# =============================================================================
BUILD   := build
COMMON  := ../../common/flow
CONFIG  := config.json

.DEFAULT_GOAL := apr
.PHONY: apr clean

apr:
	@mkdir -p $(BUILD)
	bash $(COMMON)/openlane_run.sh ./$(CONFIG) 2>&1 | tee $(BUILD)/apr.log

clean:
	rm -rf $(BUILD) runs
