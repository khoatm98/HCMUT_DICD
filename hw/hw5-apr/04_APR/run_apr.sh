#!/usr/bin/env bash
# =============================================================================
# run_apr.sh -- run the FULL back-end APR from scratch, in one command:
#     make clean  ->  Yosys synth  ->  OpenROAD floorplan/place/CTS/route
#                 ->  Magic stream to GDS
# Produces build/{conv_netlist.v, conv.def, conv.odb, conv.gds, conv.drc.rpt}.
#
# The actual flow logic is the readable step scripts in this lab's
# apr_steps/ (00_load .. 07_finish); this just drives the Makefile.
#
# REQUIREMENTS on PATH: yosys, magic (the conda EDA env) and openroad. The conda
# 'openroad' has NO GUI but routes fine headlessly; for the interactive GUI
# targets use a Qt-enabled build via OPENROAD=. On this machine:
#     conda activate hcmut-eda
#     OPENROAD=$HOME/openroad-install/bin/openroad ./run_apr.sh
# (If OPENROAD is unset, this script auto-picks $HOME/openroad-install/bin/openroad
#  when it exists, else falls back to 'openroad' on PATH.)
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"

# Pick the OpenROAD binary: explicit OPENROAD wins; else the source build; else PATH.
if [ -z "${OPENROAD:-}" ] && [ -x "$HOME/openroad-install/bin/openroad" ]; then
  export OPENROAD="$HOME/openroad-install/bin/openroad"
fi
: "${OPENROAD:=openroad}"

echo ">> tools:"
echo "     yosys    = $(command -v yosys    || echo MISSING)"
echo "     magic    = $(command -v magic    || echo MISSING)"
echo "     openroad = $OPENROAD"
for t in yosys magic "$OPENROAD"; do
  command -v "$t" >/dev/null 2>&1 || {
    echo "!! '$t' not found -- activate the EDA conda env first (e.g. 'conda activate hcmut-eda')."
    exit 1; }
done

echo ">> cleaning previous run"
make clean

echo ">> running APR from scratch (this takes ~15-20 min: detailed routing is the long part)"
time make apr-conda

echo ""
echo ">> done. artifacts:"
ls -lh build/conv_netlist.v build/conv.def build/conv.odb build/conv.gds 2>/dev/null || true
echo ">> post-route timing (want WNS/TNS = 0):"
grep -iE "wns|tns" build/apr_conda.log 2>/dev/null | tail -2 || true
echo ">> view the layout:  make gui-view OPENROAD=$OPENROAD   (needs a Qt-enabled OpenROAD + display)"
