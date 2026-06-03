# HW5 — APR specification

## Goal
Place-and-route the synthesizable `conv_engine` (HW3) to a **DRC-clean,
LVS-matching GDSII** on SKY130 with LibreLane/OpenROAD, inspecting every physical
stage and confirming post-route timing.

## Flow stages (LibreLane orchestrates OpenROAD)
1. **Synthesis** — RTL → gates (same as HW3, run inside the flow).
2. **Floorplan** — die/core area, rows, I/O.
3. **Power planning (PDN)** — VDD/VSS rings + straps.
4. **Placement** — legalized standard-cell placement; inspect **congestion**.
5. **Clock-tree synthesis (CTS)** — build the clock distribution.
6. **Routing** — global + detailed routing.
7. **Signoff** — post-route **STA** (OpenSTA), **DRC** (Magic), **LVS** (Netgen).
8. **Stream-out** — GDSII; view in **KLayout**.

## Configuration (`config.json`, beside the design)
- `DESIGN_NAME: conv_engine`, `VERILOG_FILES: dir::src/*.v` (symlinked from
  `common/rtl/conv`), `VERILOG_INCLUDE_DIRS: dir::src`.
- `CLOCK_PORT: clk`, `CLOCK_PERIOD` (ns) — start from your HW3 closing period.
- `PDK: sky130A`, `FP_CORE_UTIL`, `PL_TARGET_DENSITY_PCT` — you may tune these to
  trade area vs routability (and observe the effect on congestion/timing).

## Why this design
`conv_engine` is **macro-free** (image/kernel/result are flop arrays, one shared
multiplier) → an all-standard-cell block that places and routes quickly on a
laptop, and whose floorplan you can *read*: the flop arrays and the multiplier
are visible, and the clock tree fans out to all the storage flops.

## Definition of done
- Flow completes to a routed layout and a streamed **GDSII**.
- **DRC clean** (0 violations) and **LVS match** (layout ≡ netlist).
- Post-route **STA** meets the clock (worst slack ≥ 0).
- You inspected and can explain: the floorplan, a congestion view, the clock
  tree, and where the multiplier / flop arrays ended up.

## Reports / artifacts to inspect (under `runs/<tag>/`)
floorplan & placement DEFs, congestion heatmap, CTS report, routed DEF, DRC and
LVS reports, post-route timing summary, and the final `*.gds`.
