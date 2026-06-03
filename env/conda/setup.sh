#!/usr/bin/env bash
# =============================================================================
# Create the conda environment for the course (Linux x86_64).
#
# Prerequisite: miniconda/conda or mamba installed and on PATH.
# Run from the repo root:   bash env/conda/setup.sh   [env-name]
# =============================================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ENV_NAME="${1:-hcmut-eda}"

if ! command -v conda >/dev/null 2>&1; then
    echo "ERROR: 'conda' not found. Install Miniconda first:" >&2
    echo "  https://docs.conda.io/projects/miniconda/" >&2
    exit 1
fi

echo ">> Creating/updating conda env '$ENV_NAME' from environment.yml ..."
if conda env list | grep -qE "^\s*$ENV_NAME\s"; then
    conda env update -n "$ENV_NAME" -f "$HERE/environment.yml"
else
    conda env create -n "$ENV_NAME" -f "$HERE/environment.yml"
fi

# Export PDK_ROOT (and friends) whenever the env is activated, so the homework
# Makefiles find the SKY130 liberty exactly as they do inside the Docker image.
PREFIX="$(conda run -n "$ENV_NAME" bash -lc 'printf %s "$CONDA_PREFIX"')"
ACT_DIR="$PREFIX/etc/conda/activate.d"
mkdir -p "$ACT_DIR"
cat > "$ACT_DIR/hcmut_pdk.sh" <<'EOS'
# Point the flow at the SKY130 PDK installed inside this conda env.
# (The litex-hub open_pdks.sky130a package installs under $CONDA_PREFIX/share/pdk.)
export PDK_ROOT="${CONDA_PREFIX}/share/pdk"
export PDK="sky130A"
export STD_CELL_LIBRARY="sky130_fd_sc_hd"
EOS

echo
echo ">> Verifying the SKY130 liberty is present ..."
conda run -n "$ENV_NAME" bash -lc '
  LIB="$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
  if [ -f "$LIB" ]; then echo "   OK: $LIB";
  else echo "   WARNING: liberty not found at $LIB";
       echo "   Adjust PDK_ROOT in $0 or fetch the PDK with: ciel enable <commit>"; fi'

cat <<EOF

>> Done. Use the env with either:
     conda activate $ENV_NAME && make smoke EDA_ENV=conda
   or (no activate needed):
     make smoke EDA_ENV=conda          # uses 'conda run -n $ENV_NAME'

>> For a reproducible cohort, freeze exact versions and ship the lock file:
     conda env export -n $ENV_NAME > env/conda/conda-lock.yml
EOF
