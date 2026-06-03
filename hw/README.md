# Homeworks — the running design, one stage at a time

All five homeworks build **one** design — the 16-bit **TinyRISC-16** CPU — and
push it through successive stages of the RTL-to-GDSII flow. Each homework's
output feeds the next, so the final project is a culmination, not a restart.

```
 HW1 ──────────▶ HW2 ──────────▶ HW3 ──────────▶ HW4 ──────────▶ HW5
 Q6.10 ALU       CPU + MAC        synthesis        power           APR
 (design+verify) (reuses ALU)     (Yosys→SKY130)   (activity/opt)  (→ GDSII)
```

| HW | Folder | You build / do | Main tools | Builds on |
|----|--------|----------------|-----------|-----------|
| **HW1** | [hw1-alu/](hw1-alu/) | the parameterized Q6.10 ALU + self-checking TB | Icarus, Verilator, GTKWave | — |
| **HW2** | hw2-cpu/ | the TinyRISC-16 CPU; add the **MAC** custom instruction (reuses the HW1 ALU) | Icarus, Verilator, GTKWave | HW1 ALU |
| **HW3** | hw3-synth/ | synthesize the CPU to SKY130 gates; write SDC; gate-level equivalence; STA | Yosys+ABC, OpenSTA | HW2 RTL |
| **HW4** | hw4-power/ | capture switching activity; estimate + reduce power; report PPA | OpenSTA, Yosys | HW3 netlist |
| **HW5** | hw5-apr/ | place & route to a clean GDSII; inspect each physical stage | OpenLane/OpenROAD, KLayout, Magic, Netgen | HW4 netlist |

Continuity is mechanical: HW2+ **include** the canonical RTL from
[`common/rtl/`](../common/rtl/) rather than copying it, so your verified ALU is
literally the CPU's execution unit, and the same CPU flows through synthesis,
power, and APR.

Start with [hw1-alu/](hw1-alu/). Each folder has its own `OBJECTIVES`, `SPEC`,
`INSTRUCTIONS`, `RUBRIC`, and a `Makefile` with one-command targets.
