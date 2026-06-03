# Conda environment (`env/conda/`)

A **no-Docker, no-root** way to get the **front-end** tools, for **Linux x86_64**
machines where Docker is unavailable or not permitted. Everything installs in
your user space via conda.

> The conda path is **reliable for the front-end** (simulation + waveforms, and
> Yosys). The open-source **back-end** tools (OpenSTA, OpenROAD, Magic, Netgen,
> KLayout) are painful on conda — the `litex-hub` builds pin old `boost`/`qt`/
> `ruby` that conflict with modern `conda-forge` — so for HW3 STA, HW4 power, and
> HW5 APR, **use the Docker path**.

## Setup

```bash
# 1. (recommended) install Miniforge -- ships the fast 'mamba' solver:
#    https://github.com/conda-forge/miniforge
# 2. create the env (DEFAULT = the reliable front-end profile):
bash env/conda/setup.sh
# 3. run the simulation smoke test:
make smoke EDA_ENV=conda
```

This creates the `hcmut-eda` env (pure `conda-forge`, solves in a minute or two)
with: `iverilog`, `verilator`, `gtkwave`, `yosys`, plus `make`/`python`.

## What the conda path covers

| Stage | conda (this env) | Docker |
|-------|------------------|--------|
| HW1, HW2 — simulation + waveforms | ✅ iverilog / verilator / gtkwave | ✅ |
| HW3 — synthesis (Yosys) | ⚠️ needs the SKY130 liberty: add the PDK with `pip install ciel && ciel enable <sky130-commit>`, or use Docker | ✅ |
| HW3 STA · HW4 power · HW5 APR | ❌ → use Docker | ✅ |

`make smoke EDA_ENV=conda` runs the **simulation** smoke (Icarus + Verilator).
For the full sim→synth→STA→APR→GDS flow, use `make smoke` (Docker).

`setup.sh` writes a conda *activate hook* exporting `PDK_ROOT` so that, once a
PDK is present, the homework Makefiles find the SKY130 liberty just like Docker.

## The EXPERIMENTAL full back-end profile

There is a best-effort attempt to install the back-end on conda:

```bash
PROFILE=full bash env/conda/setup.sh
```

It pulls OpenROAD/Magic/Netgen/KLayout + the SKY130 PDK from `litex-hub`. **It
frequently fails to solve** (the conflicts described above). If it does, that is
expected — don't fight it; run the back-end under Docker.

## It's slow / it failed to solve

- **Slow solve:** use `mamba` (Miniforge) or, on Miniconda,
  `conda install -n base -y conda-libmamba-solver && conda config --set solver libmamba`.
- **`LibMambaUnsatisfiableError`:** you almost certainly ran the *full* profile.
  Use the default front-end profile (`bash env/conda/setup.sh`) and Docker for
  the back-end.
- **For HW1 specifically** you don't even need conda if Verilator + Python are on
  your machine: `cd hw/hw1-alu && make vectors && make vsim`.

## Offline / air-gapped

```bash
# pack the solved front-end env into a relocatable tarball:
conda install -n hcmut-eda conda-pack -c conda-forge
conda pack -n hcmut-eda -o hcmut-eda.tar.gz       # ship this; students unpack & source
```
See [../../docs/03-offline-deployment.md](../../docs/03-offline-deployment.md).
