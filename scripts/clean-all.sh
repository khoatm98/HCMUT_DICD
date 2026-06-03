#!/usr/bin/env bash
# Remove build / run artifacts repo-wide (safe to re-run).
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Cleaning build/run artifacts under $(pwd) ..."
find . -type d \( -name sim -o -name obj_dir -o -name runs \) -prune -exec rm -rf {} + 2>/dev/null || true
find . -type f \( \
        -name '*.vvp'  -o -name '*.vcd' -o -name '*.fst' -o -name '*.saif' \
     -o -name '*.netlist.v' -o -name '*.rpt' \
   \) -delete 2>/dev/null || true
echo "Done."
