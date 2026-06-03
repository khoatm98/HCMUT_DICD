# The RTL-to-GDSII flow (and how the homeworks map onto it)

"RTL-to-GDSII" is the journey from human-written Verilog (**RTL**, register
transfer level) to the **GDSII** file a foundry uses to make masks. This course
walks that journey one stage per homework, on a single design.

```
 ┌──────────────────────────────────────────────────────────────────────────┐
 │  FRONT-END (logic)                                                        │
 │                                                                            │
 │  ① RTL design ─▶ ② RTL simulation ─▶ (waveforms)                          │
 │     Verilog          Icarus/Verilator    GTKWave                          │
 │                                                                            │
 │            HW1 (ALU)         HW2 (CPU + MAC custom instruction)            │
 └───────────────────────────────────────┬────────────────────────────────────┘
                                          │ verified RTL
 ┌────────────────────────────────────────▼───────────────────────────────────┐
 │  SYNTHESIS & TIMING                                                         │
 │                                                                            │
 │  ③ constraints (SDC) ─▶ ④ synthesis ─▶ ⑤ gate-level sim ─▶ ⑥ STA          │
 │       hand-written          Yosys+ABC      Icarus+SKY130       OpenSTA      │
 │                          (RTL → gates)     (equivalence)    (slack/paths)   │
 │                                                                            │
 │                                  HW3                                        │
 └───────────────────────────────────────┬────────────────────────────────────┘
                                          │ gate-level netlist + SDC
 ┌────────────────────────────────────────▼───────────────────────────────────┐
 │  POWER                                                                     │
 │                                                                            │
 │  ⑦ run a workload ─▶ ⑧ capture activity ─▶ ⑨ power + optimize             │
 │     gate-level sim       VCD / SAIF            OpenSTA report_power;        │
 │                                               clock gating, operand iso.    │
 │                                  HW4                                        │
 └───────────────────────────────────────┬────────────────────────────────────┘
                                          │ power-optimized netlist
 ┌────────────────────────────────────────▼───────────────────────────────────┐
 │  BACK-END (physical) — OpenLane / LibreLane (OpenROAD)                     │
 │                                                                            │
 │  ⑩ floorplan ─▶ ⑪ power plan ─▶ ⑫ placement ─▶ ⑬ CTS ─▶ ⑭ routing        │
 │  ─▶ ⑮ DRC (Magic) + LVS (Netgen) ─▶ ⑯ GDSII ─▶ view in KLayout            │
 │                                                                            │
 │                                  HW5                                        │
 └───────────────────────────────────────┬────────────────────────────────────┘
                                          │ clean GDSII
                                 ┌────────▼────────┐
                                 │  FINAL PROJECT  │  all stages, one design,
                                 │  RTL → GDSII    │  one reproducible runbook
                                 └─────────────────┘
```

## Stage-by-stage

1. **RTL design** — describe behavior in Verilog. *(HW1, HW2)*
2. **RTL simulation** — prove it's functionally correct with a self-checking
   testbench before spending effort on anything downstream. *(HW1, HW2)*
3. **Constraints (SDC)** — tell the tools your clock period and I/O timing. *(HW3)*
4. **Synthesis** — Yosys maps RTL to actual SKY130 standard cells (a netlist). *(HW3)*
5. **Gate-level simulation** — re-run your tests on the netlist to confirm
   synthesis preserved behavior (equivalence). *(HW3)*
6. **Static Timing Analysis** — OpenSTA checks every path meets the clock
   (positive *slack*). *(HW3, and again post-route in HW5)*
7–9. **Power** — drive a realistic workload, capture switching activity
   (VCD/SAIF), estimate power, then reduce it (clock gating, operand isolation)
   and prove the savings. *(HW4)*
10–16. **Place & route** — turn the netlist into geometry: floorplan, power grid,
   place cells, build the clock tree (CTS), route wires, check physical rules
   (DRC) and that layout matches netlist (LVS), and stream out **GDSII**. *(HW5)*

Each numbered artifact is something you **open and read** — that's the point.
You are never asked to trust a black box.

## Why iterate (the back-arrows)

Real design loops: if STA fails in HW3 you tighten the RTL or constraints; if
HW4 power work or HW5 routing reveals a problem, you may re-synthesize. The flow
is mostly forward, but learning *where the loops are* is part of the course.
