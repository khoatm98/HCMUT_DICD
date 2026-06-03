# Toolchain overview

Every tool below is free and open-source, and all of them ship in the one
container image (`hpretl/iic-osic-tools`). You never install them individually.

| Tool | Role in this course | Replaces (commercial) |
|------|---------------------|-----------------------|
| **Icarus Verilog** (`iverilog`/`vvp`) | Primary RTL & gate-level simulator. Compiles Verilog and runs your testbench. | VCS / ModelSim |
| **Verilator** | Fast simulator + strict linter. Used for big regressions and to catch width/latch bugs. | VCS / SpyGlass (lint) |
| **GTKWave** | Waveform viewer for the `.vcd` files your testbenches dump. | Verdi / DVE |
| **Yosys + ABC** | Logic synthesis: turns RTL into a SKY130 gate-level netlist; ABC does technology mapping. | Design Compiler |
| **OpenSTA** | Static timing analysis (slack, critical paths) and activity-driven power estimation. | PrimeTime |
| **OpenLane / LibreLane** | Orchestrates the full RTL-to-GDSII automated place-and-route recipe. | the flow around Innovus/ICC2 |
| **OpenROAD** | The engine *underneath* OpenLane: floorplan, placement, CTS, routing. | Innovus / ICC2 |
| **Magic** | Layout tool used here for **DRC** (design-rule checking) during signoff. | Calibre / PVS (DRC) |
| **Netgen** | **LVS** (layout-vs-schematic) comparison during signoff. | Calibre / PVS (LVS) |
| **KLayout** | GDSII/layout viewer — look at your finished chip. | Virtuoso / layout viewers |
| **SKY130 PDK** | SkyWater 130 nm open process design kit: the standard cells, rules, and models everything targets. | a foundry PDK |

## Why these choices

- **LibreLane over OpenLane 1:** LibreLane (the FOSSi-Foundation successor to
  OpenLane 2) is Python-based and lets you run and inspect *individual* flow
  steps — exactly the "see the intermediate artifacts" pedagogy this course
  wants. OpenLane 1 (Tcl) is no longer recommended for new projects.
- **One image, baked-in PDK:** reproducibility and offline-friendliness. Every
  student has identical tool versions and an identical PDK, so area/timing/power
  numbers are comparable and gradeable.

See the flow itself in [02-rtl-to-gdsii-flow.md](02-rtl-to-gdsii-flow.md).
