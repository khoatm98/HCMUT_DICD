# =============================================================================
# pdk.mk  --  resolve the SKY130 library paths the flow needs, preferring the
# IN-REPO vendored subset (pdk/) over an external PDK install.
#
# Include this from a stage Makefile. It sets:
#
#   STD_CELL_DIR    sky130_fd_sc_hd dir (the std-cell lib/verilog/lef the
#                   file-level tools read for SYNTH / STA / GATE-SIM / POWER).
#                   Prefers the in-repo vendored subset, else the external PDK.
#   SRAM_MACRO_DIR  sky130_sram_macros dir (lib/lef/gds for the HW3/HW5 SRAM).
#                   Resolved the same way (see pdk/NOTICE).
#   SRAM_LIB        the SRAM macro's typical-corner liberty (from SRAM_MACRO_DIR).
#
#   PDK_ROOT        the PDK root used by APR (LibreLane/OpenROAD-flow). Prefers the
#                   in-repo pdk/ ONCE it is APR-complete -- i.e. it has libs.tech
#                   (magic/klayout/netgen/openlane) AND the std-cell gds/cdl + the
#                   ff/ss sign-off corners the openlane PDK config globs/loads.
#                   Until then it stays external (env PDK_ROOT, else /foss/pdks),
#                   so a synth-only subset never misleads APR into an incomplete PDK.
#
# All vars honor an env/command-line override (?=). Depth-independent: this file
# is common/flow/pdk.mk, so the repo root is two levels up -- found via
# $(MAKEFILE_LIST) + $(abspath ...) regardless of which stage dir includes it.
# =============================================================================
_REPO_PDK := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../pdk)
_REPO_REF := $(_REPO_PDK)/sky130A/libs.ref

# APR PDK root: in-repo IFF it carries libs.tech (the APR tool decks) -- else external.
ifneq ($(wildcard $(_REPO_PDK)/sky130A/libs.tech),)
  PDK_ROOT := $(_REPO_PDK)
  $(info >> using in-repo PDK for APR: $(PDK_ROOT))
else
  PDK_ROOT ?= /foss/pdks
endif

# --- std cells: prefer the in-repo vendored subset (synth/STA/gate-sim/power) ---
ifneq ($(wildcard $(_REPO_REF)/sky130_fd_sc_hd),)
  STD_CELL_DIR ?= $(_REPO_REF)/sky130_fd_sc_hd
  $(info >> using in-repo std cells: $(STD_CELL_DIR))
else
  STD_CELL_DIR ?= $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd
endif

# --- SRAM macro: prefer the in-repo vendored copy, independent of PDK_ROOT ---
ifneq ($(wildcard $(_REPO_REF)/sky130_sram_macros),)
  SRAM_MACRO_DIR ?= $(_REPO_REF)/sky130_sram_macros
  $(info >> using in-repo SRAM macros: $(SRAM_MACRO_DIR))
else
  SRAM_MACRO_DIR ?= $(PDK_ROOT)/sky130A/libs.ref/sky130_sram_macros
endif
SRAM_LIB ?= $(SRAM_MACRO_DIR)/lib/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
