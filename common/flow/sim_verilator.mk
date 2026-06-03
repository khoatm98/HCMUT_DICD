# =============================================================================
# sim_verilator.mk  --  reusable Verilator include (fast lint + optional sim).
#
# Verilator 5 can run a plain Verilog testbench directly with --binary --timing,
# so students get a much faster simulation path for big pattern sweeps, plus a
# strict lint that catches width/latch bugs Icarus silently accepts.
#
# Include from a module Makefile and set:
#   TOP       - basename for logs                         (required)
#   RTL       - design source files                       (required)
#   TB        - testbench source files                    (required for vsim)
#   TB_TOP    - testbench top module name                 (required for vsim)
# Optional:
#   SIM_DIR          (default: sim)
#   VERILATOR_FLAGS
#
# Provides targets:  lint   vsim
# =============================================================================
VERILATOR       ?= verilator
SIM_DIR         ?= sim
VERILATOR_FLAGS ?=
# litex-hub's conda Verilator ships a verilated.mk with a hardcoded build-machine
# PYTHON3 (/root/conda-eda/.../python3) that breaks `--binary` here. -MAKEFLAGS
# overrides PYTHON3 in the build sub-make (harmless elsewhere; python3 is on PATH).
VERILATOR_BUILD_FLAGS ?= -MAKEFLAGS PYTHON3=python3

.PHONY: lint
lint:
	$(VERILATOR) --lint-only -Wall $(VERILATOR_FLAGS) $(RTL)
	@echo ">> verilator lint clean"

.PHONY: vsim
vsim:
	@mkdir -p $(SIM_DIR)
	$(VERILATOR) --binary --timing -Wall -Wno-fatal $(VERILATOR_BUILD_FLAGS) $(VERILATOR_FLAGS) \
		--top-module $(TB_TOP) -o V$(TB_TOP) $(RTL) $(TB)
	./obj_dir/V$(TB_TOP) | tee $(SIM_DIR)/$(TOP)_vl.log
	@grep -q "RESULT: PASS" $(SIM_DIR)/$(TOP)_vl.log \
		|| { echo ">> verilator sim FAILED (no 'RESULT: PASS' in log)"; exit 1; }
	@echo ">> verilator sim PASS"
