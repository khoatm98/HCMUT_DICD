# Conda environment (`env/conda/`)

A **no-Docker, no-root** way to get the toolchain, for **Linux x86_64** machines
(lab PCs, shared servers, HPC) where Docker is unavailable or not permitted.
Everything installs in your user space via conda.

> Linux x86_64 only. On Windows use WSL2 (then this works inside the WSL Linux).
> macOS/Apple-Silicon tool coverage on conda is partial — prefer the Docker path
> there (`env/docker/`).

## Setup

```bash
# 1. install Miniforge (recommended -- ships the FAST 'mamba' solver):
#    https://github.com/conda-forge/miniforge   (or Miniconda + libmamba)
# 2. create the course env (from the repo root):
bash env/conda/setup.sh
# 3. verify + run the front-end smoke test:
make healthcheck EDA_ENV=conda
make smoke       EDA_ENV=conda
```

### It's taking forever?

The **full** install pulls several GB (OpenROAD/Magic/KLayout + the ~1–2 GB
SKY130 PDK) and the classic conda solver is slow. Two fixes:

- **Use a fast solver.** Install **Miniforge** (ships `mamba`), or for an
  existing Miniconda: `conda install -n base -y conda-libmamba-solver && conda
  config --set solver libmamba`. `setup.sh` auto-uses `mamba` if present.
- **Start small.** HW1 and HW2 only need the simulators — install the tiny
  front-end profile and begin immediately:
  ```bash
  PROFILE=frontend bash env/conda/setup.sh      # small + fast (iverilog/verilator/gtkwave)
  ```
  Run the full `bash env/conda/setup.sh` later (same env name) to add
  synth/STA/APR + the PDK before HW3.

> For **HW1 specifically** you don't even need conda if Verilator + Python are
> already on your machine: `cd hw/hw1-alu && make vectors && make vsim`.

`EDA_ENV=conda` tells the top-level Makefile to run flows via
`conda run -n hcmut-eda` instead of Docker. You can also `conda activate
hcmut-eda` and drop the `EDA_ENV=conda` (set it once: `export EDA_ENV=conda`).

## What you get

| Tool | Source channel |
|------|----------------|
| iverilog, verilator, gtkwave | conda-forge |
| yosys, openroad, opensta, magic, netgen, klayout | litex-hub (conda-eda) |
| SKY130 PDK (`sky130A`/`sky130_fd_sc_hd`) | litex-hub `open_pdks.sky130a` |

`setup.sh` also writes a conda *activate hook* that exports `PDK_ROOT` so the
homework Makefiles find the SKY130 liberty exactly as they do in Docker.

## APR (HW5) on conda

The `make smoke EDA_ENV=conda` target runs the **front-end** stages
(sim → synth → STA), which fully validate this environment for HW1–HW4. For the
**place-and-route** stage (HW5), conda does not ship the LibreLane orchestrator
on a supported path; HW5 documents two conda-friendly routes:

1. **OpenROAD-flow-scripts (ORFS)** — a scripted RTL-to-GDSII flow that uses the
   conda `openroad`/`yosys`/`magic`/`netgen`/`klayout` directly.
2. Hand-driven **OpenROAD Tcl** steps (floorplan → place → CTS → route), which
   is the most transparent and matches the course's "inspect each stage" goal.

(The Docker path runs LibreLane end-to-end if you prefer push-button APR.)

## Reproducibility

Versions in `environment.yml` are unpinned so the first solve succeeds. For a
cohort, freeze them once and distribute the lock file:

```bash
conda env export -n hcmut-eda > env/conda/conda-lock.yml
```

## Offline / air-gapped

Two options, both avoiding per-student internet:

```bash
# A) pack the whole solved env into a relocatable tarball (simplest):
conda activate hcmut-eda
conda install -n hcmut-eda conda-pack -c conda-forge
conda pack -n hcmut-eda -o hcmut-eda.tar.gz       # ship this; students unpack & source
# B) mirror the litex-hub + conda-forge channels on the LAN and point conda at them.
```

See [../../docs/03-offline-deployment.md](../../docs/03-offline-deployment.md).
