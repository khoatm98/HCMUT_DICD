# =============================================================================
# pdk.mk  --  resolve PDK_ROOT (+ the SRAM macro dir), preferring IN-REPO libs.
#
# Include this from a stage Makefile (it replaces a `PDK_ROOT ?= /foss/pdks`
# line). It sets:
#
#   PDK_ROOT        the SKY130 PDK root. Prefers the in-repo pdk/ ONLY when it
#                   actually holds the STANDARD CELLS (sky130_fd_sc_hd) -- a
#                   partial vendoring (e.g. the SRAM macro alone) must NOT hijack
#                   the std-cell path. Otherwise: env PDK_ROOT, else /foss/pdks.
#
#   SRAM_MACRO_DIR  the sky130_sram_macros dir (lib/lef/gds for the HW3/HW5 SRAM),
#                   resolved INDEPENDENTLY: prefers the in-repo vendored copy
#                   (pdk/sky130A/libs.ref/sky130_sram_macros, see pdk/NOTICE) even
#                   when the std cells come from an external PDK; else it derives
#                   from PDK_ROOT.
#   SRAM_LIB        the macro's typical-corner liberty, derived from SRAM_MACRO_DIR.
#
# All three honor an env/command-line override (they use ?=). Depth-independent:
# this file is common/flow/pdk.mk, so the repo root is two levels up -- found via
# $(MAKEFILE_LIST) + $(abspath ...) regardless of which stage dir includes it.
# =============================================================================
_REPO_PDK := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../pdk)

# --- std-cell PDK root: use the in-repo pdk/ only if the std cells are there ---
ifneq ($(wildcard $(_REPO_PDK)/sky130A/libs.ref/sky130_fd_sc_hd),)
  PDK_ROOT := $(_REPO_PDK)
  $(info >> using in-repo PDK std cells: $(PDK_ROOT))
else
  PDK_ROOT ?= /foss/pdks
endif

# --- SRAM macro dir: prefer the in-repo vendored copy, independent of PDK_ROOT --
_REPO_SRAM := $(_REPO_PDK)/sky130A/libs.ref/sky130_sram_macros
ifneq ($(wildcard $(_REPO_SRAM)),)
  SRAM_MACRO_DIR ?= $(_REPO_SRAM)
  $(info >> using in-repo SRAM macros: $(SRAM_MACRO_DIR))
else
  SRAM_MACRO_DIR ?= $(PDK_ROOT)/sky130A/libs.ref/sky130_sram_macros
endif
SRAM_LIB ?= $(SRAM_MACRO_DIR)/lib/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
