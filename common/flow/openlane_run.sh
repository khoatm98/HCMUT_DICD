#!/usr/bin/env bash
# =============================================================================
# openlane_run.sh  --  reusable LibreLane / OpenLane-2 runner.
#
# Usage:  openlane_run.sh <config.json> [extra flow args...]
#
# We prefer LibreLane (the FOSSi-Foundation-maintained successor to OpenLane 2)
# but fall back to the "openlane" entry point if that is what the container
# provides. Both consume the same config.json.
# =============================================================================
set -euo pipefail

CFG="${1:?usage: openlane_run.sh <config.json> [args]}"
shift || true

if command -v librelane >/dev/null 2>&1; then
    echo ">> Running LibreLane on ${CFG}"
    exec librelane "${CFG}" "$@"
elif command -v openlane >/dev/null 2>&1; then
    echo ">> Running OpenLane 2 on ${CFG}"
    exec openlane "${CFG}" "$@"
else
    echo "ERROR: neither 'librelane' nor 'openlane' is on PATH." >&2
    echo "       You are probably not inside the EDA container." >&2
    echo "       From the repo root run:  make shell" >&2
    exit 127
fi
