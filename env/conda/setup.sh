#!/usr/bin/env bash
# =============================================================================
# Create the conda environment for the course (Linux x86_64).
#
# Prerequisite: conda (Miniconda) or mamba (Miniforge) on PATH.
# Run from the repo root:
#   bash env/conda/setup.sh                 # FULL env (tools + SKY130 PDK; several GB)
#   PROFILE=frontend bash env/conda/setup.sh  # small/fast: just HW1/HW2 sim tools
#   bash env/conda/setup.sh my-env-name     # custom env name (default: hcmut-eda)
# =============================================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ENV_NAME="${1:-hcmut-eda}"
PROFILE="${PROFILE:-frontend}"       # frontend (small/fast, default) | full (all-conda back-end, py3.7)

case "$PROFILE" in
    frontend) YML="$HERE/environment-frontend.yml" ;;
    full)     YML="$HERE/environment.yml" ;;
    *) echo "ERROR: PROFILE must be 'full' or 'frontend' (got '$PROFILE')" >&2; exit 1 ;;
esac

# Prefer mamba (a MUCH faster solver). Fall back to conda + a libmamba hint.
if command -v mamba >/dev/null 2>&1; then
    SOLVER=mamba
elif command -v conda >/dev/null 2>&1; then
    SOLVER=conda
else
    echo "ERROR: neither 'mamba' nor 'conda' found. Install Miniforge (recommended," >&2
    echo "       ships mamba) or Miniconda: https://github.com/conda-forge/miniforge" >&2
    exit 1
fi

echo ">> Building env '$ENV_NAME' with '$SOLVER' (profile: $PROFILE)"
if [ "$SOLVER" = conda ]; then
    echo "   NOTE: the classic conda solver is slow. Speed it up a LOT first:"
    echo "       conda install -n base -y conda-libmamba-solver && conda config --set solver libmamba"
    echo "   (or install Miniforge, which ships the fast 'mamba')."
fi
# FLEXIBLE channel priority is the key to resolving the litex-hub back-end:
# it lets the newest OpenROAD build pull low-level deps (_openmp_mutex, libboost)
# from conda-forge instead of failing. Applied per-invocation (no global change).
export CONDA_CHANNEL_PRIORITY=flexible

if [ "$PROFILE" = full ]; then
    echo "   FULL profile: the all-conda toolchain (OpenROAD/Magic/Netgen + the"
    echo "   SKY130 PDK via open_pdks), solved with CONDA_CHANNEL_PRIORITY=flexible."
    echo "   NOTE: this pins python=3.7 (the resolvable OpenROAD build needs it) and"
    echo "   omits KLayout/ciel (python>=3.8). Install KLayout separately for GDS"
    echo "   viewing; see env/conda/README.md. The front-end profile is the fallback."
fi

if [ "${CONDA_DEFAULT_ENV:-}" = "$ENV_NAME" ]; then
    echo "ERROR: '$ENV_NAME' is the ACTIVE conda env, so it can't be recreated." >&2
    echo "       Run 'conda deactivate' first, then re-run this script." >&2
    exit 1
fi

if conda env list | grep -qE "^[[:space:]]*$ENV_NAME[[:space:]]"; then
    echo ">> env '$ENV_NAME' exists -- removing + recreating for a clean solve"
    echo "   (a plain 'env update' won't downgrade a stale python or swap profiles;"
    echo "    this env is course-dedicated, so recreating is safe)."
    conda env remove -n "$ENV_NAME" -y
fi
"$SOLVER" env create -n "$ENV_NAME" -f "$YML"

# Export PDK_ROOT whenever the env activates, so the homework Makefiles find the
# SKY130 liberty exactly as they do inside Docker. (Harmless for the frontend
# profile -- the PDK simply isn't there yet.)
PREFIX="$(conda run -n "$ENV_NAME" bash -lc 'printf %s "$CONDA_PREFIX"')"
ACT_DIR="$PREFIX/etc/conda/activate.d"
mkdir -p "$ACT_DIR"
cat > "$ACT_DIR/hcmut_pdk.sh" <<'EOS'
export PDK_ROOT="${CONDA_PREFIX}/share/pdk"
export PDK="sky130A"
export STD_CELL_LIBRARY="sky130_fd_sc_hd"
EOS

echo
echo ">> Done. Run sim flows with:   make smoke EDA_ENV=conda"
if [ "$PROFILE" = full ]; then
    echo
    echo ">> FULL env ready: sim + synth + STA + DRC/LVS run on conda; the SKY130 PDK"
    echo "   (open_pdks) is at $PREFIX/share/pdk and the activate hook sets PDK_ROOT."
    echo "   Try:   conda activate $ENV_NAME && make smoke EDA_ENV=conda   (sim->synth->STA)"
    echo "   APR (HW5/Final) runs via OpenROAD-flow-scripts -- see env/conda/README.md."
    echo "   Optional: vendor the libs into the repo so they're prefix-independent:"
    echo "       bash scripts/vendor-pdk.sh && git add pdk/   (see pdk/README.md)"
    echo ">> Pin versions for a cohort:  conda env export -n $ENV_NAME > env/conda/conda-lock.yml"
else
    echo
    echo ">> FRONT-END env (sim + waveforms + yosys). For the all-conda back-end"
    echo "   (OpenROAD/Magic/Netgen + SKY130 PDK), rebuild with:  PROFILE=full bash env/conda/setup.sh"
fi
