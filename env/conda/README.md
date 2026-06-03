# Conda environment (`env/conda/`)

A **no-Docker, no-root** toolchain for **Linux x86_64**. Two profiles:

- **front-end** (default, rock-solid): `iverilog`, `verilator`, `gtkwave`,
  `yosys` — pure `conda-forge`, solves in a minute. Covers HW1/HW2 sim + (with a
  PDK) HW3 synthesis.
- **full** (`PROFILE=full`, **all-conda back-end**): adds `openroad`, `magic`,
  `netgen`, and the SKY130 PDK from the `litex-hub` (conda-eda) channel — so the
  *whole* flow runs without Docker.

> **Why the full profile pins `python=3.7`.** The only `litex-hub` OpenROAD build
> whose low-level deps still resolve against today's `conda-forge` is the
> **2.0_3175 (2022)** build, which is pinned to **python 3.7**; newer OpenROAD
> builds need a pruned `libboost 1.73` / `_openmp_mutex >=5.1` combo that no
> longer resolves. So the entire back-end hangs off `python=3.7` (verified
> resolvable 2026-06 with `CONDA_CHANNEL_PRIORITY=flexible`). `iverilog`,
> `yosys`, `verilator`, `magic`, `netgen`, and `open_pdks` all have
> py3.7-compatible builds. **KLayout and `ciel` are excluded** — both need
> python ≥ 3.8 and would break the solve (see *GDS viewing* below).

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
| HW3 synthesis | yosys + **in-repo `pdk/`** | ✅ std cells committed — no PDK install |
| HW3 STA, HW4 power | **openroad** (embeds OpenSTA) + in-repo `pdk/` | ✅ the Makefiles auto-pick `sta` if present, else `openroad` (`STA_BIN`) |
| HW3/HW4 DRC/LVS | magic / netgen | ✅ |
| GDS viewing | KLayout | ➕ separate install (not in env) — see *GDS viewing* |
| APR (HW5, Final) | OpenROAD-flow-scripts (ORFS) + **full** PDK | ⚠️ needs a COMPLETE PDK (`open_pdks`), not the in-repo subset; LibreLane's non-Docker path is Nix, so on conda we use ORFS |

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

## GDS viewing (KLayout — optional, separate)
KLayout isn't in the `hcmut-eda` env (it needs python ≥ 3.8 and clashes with the
py3.7 OpenROAD). For viewing GDS, install it on its own — none of the flow's
*checks* need it:
```bash
conda create -n klayout -c conda-forge klayout    # its own env, no conflict
#   or your distro package:  apt install klayout
klayout path/to/design.gds
```

## PDK
The full profile installs `open_pdks.sky130a` (PDK under `$CONDA_PREFIX/share/pdk`;
the activate hook sets `PDK_ROOT`). To make the libraries **independent of this
conda prefix**, vendor the subset the flow needs into the repo once — then the
stage Makefiles use `pdk/` directly (see [`../../pdk/README.md`](../../pdk/README.md)):
```bash
conda activate hcmut-eda && bash scripts/vendor-pdk.sh   # PDK_ROOT comes from the activate hook
git add pdk/ && git commit -m "vendor SKY130 lib subset"
```

## It's slow / it failed to solve
- **Slow solve:** use `mamba` (Miniforge) or `conda install -n base -y
  conda-libmamba-solver && conda config --set solver libmamba`.
- **`LibMambaUnsatisfiableError` on the full profile:** the env file is verified
  resolvable (python 3.7 + OpenROAD 2.0_3175 + open_pdks, flexible priority). If
  you hit this, you almost certainly changed `python=3.7` or re-added KLayout/`ciel`
  (python ≥ 3.8) — revert that. Confirm `setup.sh` used `CONDA_CHANNEL_PRIORITY=flexible`
  (it does).
- **HW1 needs nothing but Verilator + Python** if you just want to start.

## Offline / air-gapped
```bash
conda install -n hcmut-eda conda-pack -c conda-forge
conda pack -n hcmut-eda -o hcmut-eda.tar.gz       # ship; students unpack + conda-unpack
```
See [../../docs/03-offline-deployment.md](../../docs/03-offline-deployment.md).
