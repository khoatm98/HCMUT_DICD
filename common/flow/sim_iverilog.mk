# =============================================================================
# sim_iverilog.mk  --  reusable Icarus Verilog simulation include.
#
# Include from a module Makefile and set:
#   TOP   - testbench top module / output basename   (required)
#   RTL   - design source files                       (required)
#   TB    - testbench source files                    (required)
# Optional:
#   SIM_DIR        (default: sim)
#   IVERILOG_FLAGS (default: -g2012)
#
# Provides targets:  sim  (compile + run + check "RESULT: PASS")
# =============================================================================
IVERILOG        ?= iverilog
VVP             ?= vvp
SIM_DIR         ?= sim
IVERILOG_FLAGS  ?= -g2012

$(SIM_DIR)/$(TOP).vvp: $(RTL) $(TB)
	@mkdir -p $(SIM_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -o $@ $(RTL) $(TB)

.PHONY: sim
sim: $(SIM_DIR)/$(TOP).vvp
	@mkdir -p $(SIM_DIR)
	$(VVP) $< | tee $(SIM_DIR)/$(TOP).log
	@grep -q "RESULT: PASS" $(SIM_DIR)/$(TOP).log \
		|| { echo ">> iverilog sim FAILED (no 'RESULT: PASS' in log)"; exit 1; }
	@echo ">> iverilog sim PASS"
