#!/usr/bin/env bash
# =============================================================================
# build-ws.sh -- materialize an INSTRUCTOR workspace with every reference
# solution wired in, so you can run the WHOLE flow (sim / synth / STA / gate-sim /
# power / APR) on WORKING designs instead of the student stubs.
#
#   bash instructor/solutions/build-ws.sh            # -> ./ws  (git-ignored)
#   bash instructor/solutions/build-ws.sh /path/ws   # custom location
#
# The workspace is a COPY of hw/ + final-project/ with the 01_RTL stubs replaced
# by the reference RTL, plus a symlink to common/ so the stage Makefiles' relative
# includes resolve (pdk.mk auto-finds the real repo pdk/). It is GIT-IGNORED and
# MUST NOT be committed -- it contains the solutions.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/../.."            # repo root
REPO="$(pwd)"
WS="${1:-$REPO/ws}"
SD="${SPHERE_DECODING:-/home/MingKe/hcmut/SphereDecoding}"   # reference MIMO detector

echo ">> building solutions workspace at: $WS"
rm -rf "$WS"; mkdir -p "$WS"
ln -s "$REPO/common" "$WS/common"               # relative includes resolve here
ln -s "$REPO/pdk"    "$WS/pdk"                   # pdk.mk resolves PDK_ROOT/STD_CELL_DIR
                                                 # via a repo-relative path -> needs ws/pdk
cp -r "$REPO/hw" "$REPO/final-project" "$WS/"
# Strip regenerable build artifacts copied from the repo working tree, so the ws
# synthesizes FRESH from the solution RTL. Otherwise a stale netlist (e.g. one
# synthesized from the student stub) would be reused and the flow would "fail".
find "$WS" -depth -type d \( -name build -o -name obj_dir -o -name runs \) -exec rm -rf {} + 2>/dev/null || true

# --- drop reference solutions over the student stubs (hw1-hw4 designs) ---
cp "$REPO/common/rtl/alu/alu.v"          "$WS/hw/hw1-alu/01_RTL/alu.v"
cp "$REPO/common/rtl/cpu/cpu_core.v"     "$WS/hw/hw2-cpu/01_RTL/cpu_core.v"
cp "$REPO/common/rtl/conv/conv_engine.v" "$WS/hw/hw3-synth/01_RTL/conv_engine.v"
cp "$REPO/common/rtl/iotdf/iotdf.v"      "$WS/hw/hw4-power/01_RTL/iotdf.v"
echo "   + hw1..hw4 01_RTL <- common/rtl reference solutions"
# hw5-apr reads common/rtl/conv directly (make prep) -- nothing to fill.

# --- final project: wire the reference MIMO sphere-decoder (for APR/flow tests) ---
# The course TB is an open template; for FLOW testing we just need synthesizable
# RTL with a top. The SphereDecoding reference top is `MIMO_detector` (instantiates
# complex_multiply x4), so point the flow's DESIGN_NAME at it.
if [ ! -f "$SD/MIMO_detector.v" ]; then
  echo "   NOTE: $SD/MIMO_detector.v not found -- set SPHERE_DECODING=<dir>; final 01_RTL left empty"
elif grep -qE "^(<<<<<<<|=======|>>>>>>>)" "$SD/MIMO_detector.v" "$SD/complex_multiply.v" 2>/dev/null; then
  echo "   WARNING: $SD has UNRESOLVED git merge-conflict markers in MIMO_detector.v /"
  echo "            complex_multiply.v (repo is mid-merge: 'git -C $SD status' shows AA)."
  echo "            -> NOT wiring final-project RTL (it would not compile). Resolve the"
  echo "               conflicts in $SD first, then re-run this script."
else
  cp "$SD/MIMO_detector.v" "$SD/complex_multiply.v" "$WS/final-project/01_RTL/"
  for cfg in "$WS"/final-project/04_APR/config.json; do
    [ -f "$cfg" ] && sed -i 's/"DESIGN_NAME":[[:space:]]*"mimo_detector"/"DESIGN_NAME": "MIMO_detector"/' "$cfg"
  done
  echo "   + final-project 01_RTL <- SphereDecoding (top: MIMO_detector). For synth/APR use:"
  echo "       make ... DESIGN=MIMO_detector RTL=\"01_RTL/MIMO_detector.v 01_RTL/complex_multiply.v\""
fi

cat <<EOF

>> workspace ready: $WS
   Run the flow on working designs, e.g.:
     cd $WS/hw/hw3-synth/02_SYN   && make all          # synth + STA  (in-repo PDK)
     cd $WS/hw/hw3-synth/03_GATE  && make gl-sim        # gate-level equivalence
     cd $WS/hw/hw5-apr/04_APR     && make apr EDA_ENV=conda   # APR -> GDSII (conv engine)
     cd $WS/final-project/04_APR  && make apr EDA_ENV=conda   # APR -> GDSII (MIMO detector)
   (APR on conda uses the OpenROAD runner; in Docker use 'make apr'.)
EOF
