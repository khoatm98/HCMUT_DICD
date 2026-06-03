# Getting started

This guide takes you from **nothing installed** to a verified toolchain. The
only thing you install on your computer is **Docker** — every EDA tool lives
inside one container image.

> Minimum laptop: 4 cores, **8 GB RAM** (4 GB will struggle during routing),
> and **≥ 30 GB free disk** (the image is ~20 GB on disk, plus your run files).

---

## 1. Install Docker

- **Linux:** install Docker Engine (`docker` + the Compose plugin) from your
  distro or docker.com. Add yourself to the `docker` group so you don't need `sudo`.
- **macOS (Intel or Apple Silicon):** install **Docker Desktop**. The image is
  ARM64-native, so Apple Silicon runs it without emulation.
- **Windows:** install **Docker Desktop** with the **WSL2** backend.

Verify the host has what it needs:

```bash
bash scripts/check-tools.sh
```

You should see `docker`, `git`, and `make` all `OK` and the daemon running.

---

## 2. Get the toolchain image

```bash
make image-pull
```

This pulls `hpretl/iic-osic-tools:2026.05` (~4 GB download, ~20 GB on disk). It
contains Icarus Verilog, Verilator, GTKWave, Yosys+ABC, OpenROAD, OpenSTA,
KLayout, Magic, Netgen, **and** the SKY130 PDK — nothing else to install.

> **Offline / slow campus network?** Don't have every student pull 4 GB. Mirror
> the image once on the LAN — see [03-offline-deployment.md](03-offline-deployment.md).

Pin the exact image for reproducibility (optional but recommended for a cohort):

```bash
docker inspect --format='{{index .RepoDigests 0}}' hpretl/iic-osic-tools:2026.05
# paste the sha256 into VERSIONS.lock
```

---

## 3. Verify the setup

```bash
make healthcheck     # prints every tool's version from inside the container
make smoke           # pushes a tiny counter through sim -> synth -> STA -> APR -> GDS
```

`make smoke` should end with:

```
SMOKE TEST PASSED -- the toolchain is ready for HW1.
```

If it doesn't, the failing stage names the tool to debug — see
[08-troubleshooting.md](08-troubleshooting.md).

---

## 4. How you'll work

Edit files on your **host** with your normal editor; the repo is mounted live
into the container at `/foss/designs/HCMUT_DICD`, so changes are visible
immediately on both sides.

Two ways to run tools:

**A. One-shot, from the host** (most common):

```bash
make smoke          # or: make hw1, make hw2, ...
```

**B. Interactive shell inside the container:**

```bash
make shell
# you are now at /foss/designs/HCMUT_DICD inside the container
cd hw/hw1-alu
make sim
```

### GUI tools (GTKWave, KLayout) via the browser

You do **not** need XQuartz or VcXsrv. Start the built-in desktop:

```bash
make env-up
# open http://localhost:8888  (VNC password: hcmut)
```

Inside that browser desktop you have a full Linux desktop with GTKWave and
KLayout. When done:

```bash
make env-down
```

(Linux users who prefer native X11 can run `xhost +local:docker` once and launch
GUI tools directly from `make shell`.)

---

## Alternative: conda instead of Docker (Linux, no root)

If Docker is unavailable or not allowed on your machines (locked-down lab, HPC,
no admin rights), use the conda path instead — same tools, same PDK, installed
in your user space. **Linux x86_64 only** (on Windows, use WSL2 then follow
this; on macOS prefer Docker).

```bash
# install Miniforge once (ships the fast 'mamba'): https://github.com/conda-forge/miniforge
bash env/conda/setup.sh                 # creates the 'hcmut-eda' env (front-end tools)
make healthcheck EDA_ENV=conda
make smoke       EDA_ENV=conda          # simulation smoke (Icarus + Verilator)
```

The default conda env covers the **front-end** (HW1/HW2 sim, Yosys synthesis).
For a fully no-Docker setup, `PROFILE=full bash env/conda/setup.sh` adds the
**back-end** (OpenROAD/Magic/Netgen/KLayout + PDK; STA/power via OpenROAD, APR via
OpenROAD-flow-scripts) — best-effort (the litex-hub solve is version-sensitive).
Details: [env/conda/README.md](../env/conda/README.md).

## 5. Where to go next

- **HW1** — [hw/hw1-alu/](../hw/hw1-alu/): build the Q6.10 ALU and learn the
  self-checking-testbench habit the whole course relies on.
- The flow, end to end — [02-rtl-to-gdsii-flow.md](02-rtl-to-gdsii-flow.md).
- What each tool does — [01-toolchain-overview.md](01-toolchain-overview.md).
