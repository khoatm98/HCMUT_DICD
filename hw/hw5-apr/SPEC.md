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
`conv_engine` is small but exercises the key back-end skills: it has one shared
multiplier + a result/kernel flop register set **and one SKY130 OpenRAM SRAM hard
macro** (the feature-map buffer). So APR here is a real **mixed standard-cell +
macro** flow — you place the macro, build the power grid around it, and route to
it — yet it's still small enough to finish on a laptop. The floorplan is readable:
the SRAM macro is one big block, with standard cells (the multiplier, control,
flops) placed around it and the clock tree fanning out.

## Macro integration (the new part vs a pure std-cell block)
The conv engine instantiates `sky130_sram_1kbyte_1rw1r_32x256_8`. The flow:
- **synthesis** blackboxes the macro (its `.lib` gives the interface/timing);
- **floorplan/placement** places the macro at a fixed location (`MACROS` in
  [`04_APR/config.json`](04_APR/config.json)) with a halo for routing;
- **PDN** connects the macro's power pins to the grid (`PDN_MACRO_CONNECTIONS`);
- **routing/signoff** route to the macro pins and DRC/LVS include it.

`make prep` (in `04_APR/`) symlinks the macro's `.lef`/`.gds`/`.lib` into
`macros/` from the sky130 OpenRAM macros that ship with OpenLane — adjust
`SRAM_MACRO_DIR` in the Makefile if your image stores them elsewhere.

## Definition of done
- Flow completes to a routed layout and a streamed **GDSII**, with the **SRAM
  macro placed** and power-connected.
- **DRC clean** (0 violations) and **LVS match** (layout ≡ netlist, incl. the macro).
- Post-route **STA** meets the clock (worst slack ≥ 0).
- You inspected and can explain: the floorplan (with the macro), a congestion
  view, the clock tree, and where the multiplier / flops landed around the macro.

## Reports / artifacts to inspect (under `runs/<tag>/`)
floorplan & placement DEFs, congestion heatmap, CTS report, routed DEF, DRC and
LVS reports, post-route timing summary, and the final `*.gds`.
