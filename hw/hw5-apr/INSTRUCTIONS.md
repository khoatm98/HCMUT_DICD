# HW5 — Step-by-step instructions

> APR is heavy → use **Docker**: from the repo root `make shell`, then
> `cd hw/hw5-apr` (or just `make hw5` to run the default flow in the container).

## 1. Run the flow

```bash
make apr
```
`make prep` first symlinks the conv-engine RTL into `src/`, then LibreLane runs
the whole flow into a timestamped `runs/<tag>/` directory. First run is slower
(tool/PDK warm-up); the design itself is small.

## 2. Inspect each stage (the point of this lab)

```bash
make inspect        # prints where the per-stage artifacts live
```
Open and look at, in `runs/<tag>/`:
- **Floorplan** — die/core, rows, I/O placement.
- **Placement / congestion** — where cells landed; congestion heatmap (hot spots
  predict routing trouble).
- **CTS** — the clock tree fanning out to all storage flops.
- **Routed layout** — metal layers.

## 3. Signoff

```bash
make summary        # post-route timing + DRC/LVS status
```
Confirm: **DRC = 0 violations**, **LVS = match**, and post-route **worst slack ≥ 0**.
If timing fails, loosen `CLOCK_PERIOD` in `config.json`; if routing is congested,
lower `FP_CORE_UTIL` / `PL_TARGET_DENSITY_PCT` and re-run.

## 4. View the layout

```bash
make klayout        # opens the final GDS
```
Find the **SRAM macro** (the big rectangular block — the feature-map buffer),
the multiplier, and the kernel/result flops placed around it; note how the macro
dominates the floorplan and how routing reaches its pins.

## 5. Submit (see [RUBRIC.md](RUBRIC.md))
In `artifacts/`: screenshots (floorplan, congestion, routed layout), the DRC/LVS
status, the post-route timing summary, your final `config.json`, and a short
write-up relating the layout to the design.

## Conda alternative (no Docker)
LibreLane isn't reliably installable on conda. For a conda-only setup, run APR
with **OpenROAD-flow-scripts** (ORFS): point an ORFS `config.mk` at
`common/rtl/conv/conv_engine.v` (+ the `conv_defs.vh` include dir), `sky130hd`,
`clk`, and your clock period, then `make` in ORFS. The learning objectives are
identical; only the orchestrator differs.

## Common pitfalls
- **Resource/time** — APR is RAM-hungry; close other apps, ensure ≥ 8 GB.
- **Include dir** — `conv_engine.v` needs `conv_defs.vh`; `make prep` symlinks
  both into `src/` and `config.json` sets `VERILOG_INCLUDE_DIRS: dir::src`.
- **Timing fail** — start from your HW3 closing period; single-stage logic here
  is simple, so it should close comfortably.
- **DRC/LVS fail on first try** — usually utilization too high → congestion;
  lower density and re-run.
