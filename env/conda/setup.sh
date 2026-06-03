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
PROFILE="${PROFILE:-frontend}"       # frontend (reliable, default) | full (EXPERIMENTAL back-end)

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
    echo "   FULL profile: the all-conda toolchain (OpenROAD/Magic/Netgen/KLayout +"
    echo "   ~1-2 GB SKY130 PDK), solved with CONDA_CHANNEL_PRIORITY=flexible."
    echo "   BEST-EFFORT: litex-hub builds are version-sensitive. If the solve fails,"
    echo "   try 'mamba', or pin a recent resolvable build (see env/conda/README.md),"
    echo "   and report the error -- the front-end profile always works as a fallback."
fi

if conda env list | grep -qE "^[[:space:]]*$ENV_NAME[[:space:]]"; then
    "$SOLVER" env update -n "$ENV_NAME" -f "$YML"
else
    "$SOLVER" env create -n "$ENV_NAME" -f "$YML"
fi

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
echo
echo ">> To run HW3 SYNTHESIS on conda, fetch the SKY130 PDK once (Yosys is already"
echo "   in this env). 'ciel' (pip) is installed; enable a pinned PDK into the env:"
echo "       conda run -n $ENV_NAME ciel enable --pdk-root \"$PREFIX/share/pdk\" <open_pdks-commit>"
echo "   (see https://github.com/fossi-foundation/ciel for the commit list). The"
echo "   activate hook already points PDK_ROOT there, so 'make hw3 ... EDA_ENV=conda'"
echo "   synthesis then finds the liberty. STA / power / APR still use Docker."
if [ "$PROFILE" = full ]; then
    echo ">> Pin versions for a cohort:  conda env export -n $ENV_NAME > env/conda/conda-lock.yml"
fi
