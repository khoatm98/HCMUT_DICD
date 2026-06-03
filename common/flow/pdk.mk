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
#   PDK_ROOT        a COMPLETE external PDK root, for APR (LibreLane/OpenROAD-flow,
#                   which need the full PDK -- tech LEF, magic/klayout tech, all
#                   cells). This is DELIBERATELY *not* redirected to the in-repo
#                   pdk/, because pdk/ holds only a SUBSET (the tt std-cell lib +
#                   the SRAM macro) -- enough for synth/STA/gate-sim, NOT for APR.
#                   Defaults to the env PDK_ROOT, else Docker's /foss/pdks.
#
# All vars honor an env/command-line override (?=). Depth-independent: this file
# is common/flow/pdk.mk, so the repo root is two levels up -- found via
# $(MAKEFILE_LIST) + $(abspath ...) regardless of which stage dir includes it.
# =============================================================================
_REPO_PDK := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../pdk)
_REPO_REF := $(_REPO_PDK)/sky130A/libs.ref

# External full PDK root -- APR only. NOT flipped to the in-repo subset.
PDK_ROOT ?= /foss/pdks

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
