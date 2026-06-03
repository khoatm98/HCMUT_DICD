# HW5 — Automated Place & Route (RTL → GDSII)

Take the **HW3 convolution engine** through the full physical-implementation
flow with **LibreLane/OpenROAD**: floorplan → power planning → placement →
clock-tree synthesis → routing → DRC/LVS → **GDSII**, inspecting each stage and
viewing the layout in KLayout.

> APR is the heaviest stage — easiest in **Docker** (`make hw5`). ~8 GB RAM
> recommended. Conda alternative (OpenROAD-flow-scripts): see [INSTRUCTIONS.md](INSTRUCTIONS.md).
> No PDK install needed — the SKY130 libraries (incl. `libs.tech`) are in-repo
> under [`pdk/`](../../pdk/); you just need the APR tools.

## Read in order
[OBJECTIVES.md](OBJECTIVES.md) · [SPEC.md](SPEC.md) · [INSTRUCTIONS.md](INSTRUCTIONS.md) · [RUBRIC.md](RUBRIC.md)

## Quick commands
```bash
make apr            # full RTL->GDSII flow (LibreLane) into runs/
make inspect        # where the per-stage artifacts live
make summary        # post-route timing + DRC/LVS status
make klayout        # open the final GDS in KLayout
```

## What you produce
| Path | What |
|------|------|
| `runs/<tag>/...` | per-stage outputs (floorplan, placement, CTS, routed DEF, GDS, reports) |
| `artifacts/` | floorplan/congestion/layout screenshots + your write-up |

The APR target is the HW3 `conv_engine`: standard cells (a shared multiplier +
kernel/result flops + control) **plus one SKY130 OpenRAM SRAM macro** (the
feature-map buffer) — so this is a real **mixed std-cell + macro** flow (place
the macro, build the PDN around it, route to it), still laptop-sized. `make prep`
symlinks the design (`src/`) from `common/rtl/conv` and the macro views
(`macros/`) from the PDK; `config.json` (`MACROS`/`PDN_MACRO_CONNECTIONS`) pins
the macro. You pass with a **DRC-clean, LVS-matching GDSII** that meets post-route
timing, plus an explanation of the floorplan/congestion and where the macro,
multiplier, and flops land.
