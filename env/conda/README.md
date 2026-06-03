# Conda environment (`env/conda/`)

A **no-Docker, no-root** toolchain for **Linux x86_64**. Two profiles:

- **front-end** (default, rock-solid): `iverilog`, `verilator`, `gtkwave`,
  `yosys` — pure `conda-forge`, solves in a minute. Covers HW1/HW2 sim + (with a
  PDK) HW3 synthesis.
- **full** (`PROFILE=full`, **all-conda back-end, best-effort**): adds
  `openroad`, `magic`, `netgen`, `klayout`, and the SKY130 PDK from the
  `litex-hub` (conda-eda) channel — so the *whole* flow runs without Docker.

> **All-conda is best-effort.** The `litex-hub` back-end builds are
> version-sensitive. `setup.sh` solves with **`CONDA_CHANNEL_PRIORITY=flexible`**,
> which is what lets the newest OpenROAD build pull its low-level deps
> (`_openmp_mutex`, `libboost`) from `conda-forge` instead of failing. If the
> solve still fails, use `mamba`, pin a recent resolvable build, and tell us the
> error — the front-end profile always works as a fallback.

## Setup

```bash
# install Miniforge (ships the fast 'mamba'): https://github.com/conda-forge/miniforge
PROFILE=full bash env/conda/setup.sh      # all-conda toolchain + SKY130 PDK
conda activate hcmut-eda
make smoke EDA_ENV=conda                   # sim -> synth -> STA  (no APR; see below)
```
(`bash env/conda/setup.sh` with no `PROFILE` builds just the fast front-end.)

## What the all-conda (full) profile covers

| Stage | conda tool | Notes |
|-------|-----------|-------|
| HW1/HW2 sim, waveforms | iverilog / verilator / gtkwave | ✅ |
| HW3 synthesis | yosys + SKY130 PDK | ✅ |
| HW3 STA, HW4 power | **openroad** (embeds OpenSTA) | ✅ the Makefiles auto-pick `sta` if present, else `openroad` (`STA_BIN`) |
| HW3/HW4 DRC/LVS, layout | magic / netgen / klayout | ✅ |
| APR (HW5, Final) | OpenROAD-flow-scripts (ORFS) | ⚠️ see below — LibreLane's non-Docker path is Nix, so on conda we use ORFS |

Run back-end stages by activating the env and using the per-stage dirs, e.g.:
```bash
conda activate hcmut-eda
cd hw/hw3-synth/02_SYN && make synth && make sta     # STA runs via openroad
cd ../03_GATE && make gl-sim
cd ../../hw4-power/06_POWER && make compare
```

## APR on conda — OpenROAD-flow-scripts (ORFS)

LibreLane (what `make apr` calls) only runs non-Docker via **Nix**, so on a pure
conda box drive APR with **[OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)**,
which uses the same conda `openroad`/`yosys`/`magic`/`netgen`/`klayout`:

```bash
git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts
# point an ORFS config.mk at the design: PLATFORM=sky130hd,
#   VERILOG_FILES=common/rtl/conv/conv_engine.v, SDC_FILE=hw/hw3-synth/02_SYN/conv.sdc,
#   and the SRAM macro (ADDITIONAL_LEFS/GDS/LIBS) for the HW3/HW5 conv engine.
make DESIGN_CONFIG=.../config.mk            # floorplan -> ... -> route -> GDS
```
The learning objectives are identical to the LibreLane path; only the
orchestrator differs.

## PDK
The full profile installs `open_pdks.sky130a` (PDK under `$CONDA_PREFIX/share/pdk`;
the activate hook sets `PDK_ROOT`). If you prefer, fetch it with `ciel` instead:
```bash
conda run -n hcmut-eda ciel enable --pdk-root "$CONDA_PREFIX/share/pdk" <open_pdks-commit>
```

## It's slow / it failed to solve
- **Slow solve:** use `mamba` (Miniforge) or `conda install -n base -y
  conda-libmamba-solver && conda config --set solver libmamba`.
- **`LibMambaUnsatisfiableError` on the full profile:** confirm `setup.sh` used
  `CONDA_CHANNEL_PRIORITY=flexible` (it does). If it still fails, pin specific
  recent `litex-hub` builds or update the channel; report the exact error.
- **HW1 needs nothing but Verilator + Python** if you just want to start.

## Offline / air-gapped
```bash
conda install -n hcmut-eda conda-pack -c conda-forge
conda pack -n hcmut-eda -o hcmut-eda.tar.gz       # ship; students unpack + conda-unpack
```
See [../../docs/03-offline-deployment.md](../../docs/03-offline-deployment.md).
