# Homeworks — how the course is built

A **front-end pair** (HW1 → HW2) builds design + verification habits on one
running design; then each **back-end** homework is a focused, **standalone**
design that spotlights one stage of the RTL-to-GDSII flow (the NTU-CVSD model).
The Final is a new capstone taken the whole way.

```
 HW1 ──────▶ HW2          HW3            HW4            HW5            Final
 ALU         CPU+MAC      conv engine    IoT filter     conv engine    MIMO sphere
 (verify)   (reuses ALU)  SYNTHESIS      POWER          APR → GDSII    decoder (all)
            └ front-end ┘  └──────── standalone, one per stage ──────┘  └ capstone ┘
```

| HW | Folder | Design | You do | Main tools | Builds on |
|----|--------|--------|--------|-----------|-----------|
| **HW1** | [hw1-alu/](hw1-alu/) | Q6.10 ALU | design + verify the ALU | Icarus, Verilator, GTKWave | — |
| **HW2** | [hw2-cpu/](hw2-cpu/) | TinyRISC-16 CPU | datapath + control; add the **MAC** custom instruction | Icarus, Verilator | **HW1 ALU** |
| **HW3** | [hw3-synth/](hw3-synth/) | 3×3 convolution engine | synthesize → SKY130; SDC; gate-equivalence; STA | Yosys+ABC, OpenSTA | standalone |
| **HW4** | [hw4-power/](hw4-power/) | IoT data filter | capture activity; reduce power; report PPA | OpenSTA, Yosys | standalone |
| **HW5** | [hw5-apr/](hw5-apr/) | the **HW3 conv engine** | place & route → clean GDSII | OpenLane/OpenROAD, KLayout, Magic, Netgen | **HW3 design** |
| **Final** | [../final-project/](../final-project/) | MIMO sphere-decoder | full RTL→GDSII; graded on PSNR + area + time + power | entire stack | all skills |

## What carries between homeworks
- **HW1 → HW2:** the ALU you build *is* the CPU's execution unit (included from
  [`common/rtl/`](../common/rtl/), not copied).
- **HW3 → HW5:** HW5 places-and-routes the *same* convolution engine you
  synthesized in HW3 ([`common/rtl/conv/`](../common/rtl/conv/)).
- **HW4 and the Final** are their own designs — the *flow and the skills* carry
  even when the design doesn't (that's the CVSD model: master each stage on a
  design suited to it).

Start with [hw1-alu/](hw1-alu/). Each folder has its own `OBJECTIVES`, `SPEC`,
`INSTRUCTIONS`, `RUBRIC`, and a `Makefile` with one-command targets.
