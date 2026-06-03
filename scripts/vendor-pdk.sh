#!/usr/bin/env bash
# =============================================================================
# vendor-pdk.sh -- copy the SKY130 subset the flow needs INTO the repo (pdk/),
# so synthesis / STA / gate-sim / APR libraries live here instead of in
# Docker-native (/foss/pdks) or conda-native ($CONDA_PREFIX/share/pdk) storage.
#
# Run once on a machine that HAS a SKY130 PDK (from the conda full env, ciel, or
# Docker), then `git add pdk/` to commit the vendored libs. After that, every
# stage Makefile auto-uses pdk/ (see common/flow/pdk.mk) with no PDK_ROOT needed.
#
# Usage:
#   bash scripts/vendor-pdk.sh [SRC_PDK_ROOT]
# SRC defaults to $PDK_ROOT, else $CONDA_PREFIX/share/pdk, else /foss/pdks.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."                      # repo root
REPO="$(pwd)"

SRC="${1:-${PDK_ROOT:-${CONDA_PREFIX:-}/share/pdk}}"
[ -d "${SRC:-}/sky130A" ] || SRC=/foss/pdks
if [ ! -d "$SRC/sky130A" ]; then
    echo "ERROR: no '\$SRC/sky130A' found (tried '$SRC')." >&2
    echo "       Pass your PDK root explicitly:  bash scripts/vendor-pdk.sh /path/to/pdk" >&2
    echo "       (it must contain sky130A/libs.ref/...)." >&2
    exit 1
fi
echo ">> vendoring SKY130 subset from: $SRC/sky130A  ->  pdk/sky130A/"

DST="$REPO/pdk/sky130A"
mkdir -p "$DST"
HD=libs.ref/sky130_fd_sc_hd
SR=libs.ref/sky130_sram_macros

# The course subset:
#  - std cells: 3 sign-off corners (tt typical + ff fastest + ss slowest) +
#    verilog models + LEF/techLEF (synth/STA/gate-sim/power) AND the APR views
#    gds/cdl + the "ef" LEF;
#  - the SRAM macro views (lib/lef/gds/verilog);
#  - SOURCES (PDK provenance stamp).
# Globs tolerate naming differences across PDK builds; missing files are warned.
want=(
  "$HD/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
  "$HD/lib/sky130_fd_sc_hd__ff_n40C_1v95.lib"
  "$HD/lib/sky130_fd_sc_hd__ss_100C_1v60.lib"
  "$HD/verilog/sky130_fd_sc_hd.v"
  "$HD/verilog/primitives.v"
  "$HD/lef/sky130_fd_sc_hd.lef"
  "$HD/lef/sky130_ef_sc_hd.lef"
  "$HD/techlef/"*.tlef
  "$HD/gds/sky130_fd_sc_hd.gds"
  "$HD/cdl/sky130_fd_sc_hd.cdl"
  "$SR/lib/sky130_sram_1kbyte_1rw1r_32x256_8"*.lib
  "$SR/lef/sky130_sram_1kbyte_1rw1r_32x256_8.lef"
  "$SR/gds/sky130_sram_1kbyte_1rw1r_32x256_8.gds"
  "$SR/verilog/sky130_sram_1kbyte_1rw1r_32x256_8"*.v
  "SOURCES"
)
n=0
( cd "$SRC/sky130A"
  for pat in "${want[@]}"; do
    for f in $pat; do
      if [ -e "$f" ]; then
        mkdir -p "$DST/$(dirname "$f")"
        cp -f "$f" "$DST/$f"
        echo "   + $f"
        n=$((n+1))
      else
        echo "   (skip, not found: $f)"
      fi
    done
  done
  echo "$n" > /tmp/.vendor_pdk_n )

# libs.tech: the tool decks APR needs (magic/klayout/netgen/openlane/combined).
# Skip the analog/schematic ones (ngspice/xschem/irsim/qflow/xcircuit). These use
# $PDK_ROOT internally, so they are path-portable once vendored.
echo ">> libs.tech (APR tool decks):"
for t in magic klayout netgen openlane combined; do
  if [ -d "$SRC/sky130A/libs.tech/$t" ]; then
    mkdir -p "$DST/libs.tech"; cp -a "$SRC/sky130A/libs.tech/$t" "$DST/libs.tech/"
    echo "   + libs.tech/$t"
  else
    echo "   (skip, not found: libs.tech/$t)"
  fi
done

echo ">> done. Vendored size:"; du -sh "$REPO/pdk" 2>/dev/null || true
echo ">> commit it:  git add pdk/ && git commit -m 'vendor SKY130 lib subset'"
echo "   (the stage Makefiles auto-detect pdk/ via common/flow/pdk.mk)."
