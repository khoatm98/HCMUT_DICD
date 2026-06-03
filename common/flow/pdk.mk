# =============================================================================
# pdk.mk  --  resolve PDK_ROOT, preferring an IN-REPO vendored PDK subset.
#
# Include this from a stage Makefile (it replaces a `PDK_ROOT ?= /foss/pdks`
# line). Resolution order:
#   1. the in-repo  pdk/  directory (populated by scripts/vendor-pdk.sh) -- so the
#      synthesis / STA / APR libraries live in THIS repo, not in Docker-native
#      storage;
#   2. otherwise an external PDK: the env PDK_ROOT (e.g. a conda env's
#      $CONDA_PREFIX/share/pdk), or Docker's /foss/pdks.
#
# Depth-independent: it locates the repo `pdk/` from its OWN path (this file is
# at common/flow/pdk.mk, so the repo root is two levels up), via $(MAKEFILE_LIST)
# + $(abspath ...), regardless of which stage dir includes it.
# =============================================================================
_REPO_PDK := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../pdk)
ifneq ($(wildcard $(_REPO_PDK)/sky130A),)
  PDK_ROOT := $(_REPO_PDK)
  $(info >> using in-repo PDK: $(PDK_ROOT))
else
  PDK_ROOT ?= /foss/pdks
endif
