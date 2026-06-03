# HW5 — Automated Place & Route (RTL → GDSII)

Take the **HW3 convolution engine** through the full physical-implementation
flow with **LibreLane/OpenROAD**: floorplan → power planning → placement →
clock-tree synthesis → routing → DRC/LVS → **GDSII**, inspecting each stage and
viewing the layout in KLayout.

> APR is the heaviest stage — run in **Docker** (`make hw5`). ~8 GB RAM
> recommended. Conda alternative (OpenROAD-flow-scripts): see [INSTRUCTIONS.md](INSTRUCTIONS.md).

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

The APR target is the **macro-free** `conv_engine` (memory is on-chip flops, no
SRAM macros), so it's a clean standard-cell block — `src/` is symlinked from
`common/rtl/conv`. The per-design `config.json` lives beside the design (the
OpenLane convention). You pass with a **DRC-clean, LVS-matching GDSII** that
meets post-route timing, plus an explanation of the floorplan/congestion and how
the multiplier + flop arrays land in the layout.
