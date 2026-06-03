# STA runs via standalone OpenSTA if present, else OpenROAD (which embeds OpenSTA -- conda path).
STA_BIN ?= $(shell command -v sta >/dev/null 2>&1 && echo sta || echo openroad)
# =============================================================================
# Smoke test -- take a tiny counter through the WHOLE flow to prove the toolchain
# is correctly installed before a student touches HW1.
#
# Run inside the EDA container:   make all
# Or from the repo root:          make smoke
# =============================================================================
TOP        := counter
TB_TOP     := counter_tb
RTL        := rtl/counter.v
TB         := tb/counter_tb.v
SIM_DIR    := sim

# SKY130 typical-corner liberty from the PDK baked into the container.
# PDK_ROOT: in-repo pdk/ if vendored (scripts/vendor-pdk.sh), else /foss/pdks.
include ../common/flow/pdk.mk
LIB        ?= $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

COMMON     := ../common/flow
NETLIST    := $(SIM_DIR)/$(TOP).netlist.v
SDC        := smoke.sdc

# Silence two harmless testbench-only Verilator style warnings.
VERILATOR_FLAGS := -Wno-TIMESCALEMOD -Wno-BLKSEQ

include $(COMMON)/sim_iverilog.mk
include $(COMMON)/sim_verilator.mk

.PHONY: all front noapr summary-noapr banner stage-iv stage-vl stage-synth stage-sta stage-apr stage-gds \
        summary summary-front synth sta apr clean

# Full flow (Docker default): sim -> synth -> STA -> APR -> GDS
all: banner stage-iv stage-vl stage-synth stage-sta stage-apr stage-gds summary

# Simulation only (conda front-end env): Icarus + Verilator.
# Synthesis/STA/APR need the SKY130 PDK + back-end tools -> use the Docker path.
front: banner stage-iv stage-vl summary-front

# Conda all-conda path: sim -> synth -> STA (no LibreLane APR; that uses ORFS/Docker).
noapr: banner stage-iv stage-vl stage-synth stage-sta summary-noapr

banner:
	@echo "============================================================"
	@echo " HCMUT_DICD smoke test:  counter -> sim / synth / STA / APR / GDS"
	@echo "============================================================"

stage-iv:
	@echo "[1/6] iverilog sim ........"
	@$(MAKE) --no-print-directory sim

stage-vl:
	@echo "[2/6] verilator sim ......."
	@$(MAKE) --no-print-directory vsim

stage-synth: synth
	@echo "[3/6] yosys synth ......... done (see $(SIM_DIR)/$(TOP).area.rpt)"

stage-sta: sta
	@echo "[4/6] opensta STA ......... done (see $(SIM_DIR)/$(TOP).sta.rpt)"

stage-apr: apr
	@echo "[5/6] librelane APR ....... done"

stage-gds:
	@echo "[6/6] GDS check ..........."
	@gds=$$(find runs -name '*.gds' 2>/dev/null | head -1); \
	 if [ -n "$$gds" ] && [ -s "$$gds" ]; then echo "      GDS produced: $$gds"; \
	 else echo "      ERROR: no GDS produced under runs/"; exit 1; fi

summary:
	@echo ""
	@echo "============================================================"
	@echo " SMOKE TEST PASSED -- the toolchain is ready for HW1."
	@echo "============================================================"

summary-noapr:
	@echo ""
	@echo "============================================================"
	@echo " SIM + SYNTH + STA PASSED (conda)."
	@echo " APR (LibreLane) needs Docker, or run APR on conda via"
	@echo " OpenROAD-flow-scripts (see env/conda/README.md)."
	@echo "============================================================"

summary-front:
	@echo ""
	@echo "============================================================"
	@echo " SIM SMOKE PASSED (Icarus + Verilator)."
	@echo " Synthesis / STA / APR need the SKY130 PDK + back-end tools;"
	@echo " run the full flow under Docker:   make smoke"
	@echo "============================================================"

synth: $(NETLIST)
$(NETLIST): $(RTL)
	@mkdir -p $(SIM_DIR)
	TOP=$(TOP) RTL_FILES="$(RTL)" LIB="$(LIB)" \
	  NETLIST_OUT=$(NETLIST) STAT_OUT=$(SIM_DIR)/$(TOP).area.rpt \
	  yosys -c $(COMMON)/synth_sky130.tcl

sta: $(NETLIST) $(SDC)
	TOP=$(TOP) LIB="$(LIB)" NETLIST=$(NETLIST) SDC=$(SDC) \
	  $(STA_BIN) -no_init -exit $(COMMON)/sta.tcl | tee $(SIM_DIR)/$(TOP).sta.rpt

apr: config.json
	bash $(COMMON)/openlane_run.sh ./config.json

clean:
	rm -rf $(SIM_DIR) obj_dir runs
