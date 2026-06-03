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
if [ "$PROFILE" = full ]; then
    echo "   WARNING: the FULL profile pulls the litex-hub back-end (OpenROAD/Magic/"
    echo "   KLayout/Netgen + ~1-2 GB SKY130 PDK). These pin old boost/qt/ruby and"
    echo "   OFTEN FAIL TO SOLVE. If it does, that's expected -- use the Docker path"
    echo "   for the back-end (HW3 STA, HW5 APR) instead. The front-end profile is"
    echo "   the supported conda setup."
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
echo ">> Done. Run flows with:   make smoke EDA_ENV=conda"
if [ "$PROFILE" = full ]; then
    echo ">> Pin versions for a cohort:  conda env export -n $ENV_NAME > env/conda/conda-lock.yml"
fi
