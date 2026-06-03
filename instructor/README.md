# Instructor materials — **DO NOT DISTRIBUTE TO STUDENTS**

This folder holds everything students should *not* have: reference solutions,
the **private pattern generators**, grading notes, and common-pitfall guides.
Withhold the whole `instructor/` directory from the student-facing repo.

## What's here

```
instructor/solutions/
├── hw1-alu/      README (grading notes + pitfalls) + tools/gen_vectors.py  (private)
├── hw2-cpu/      README + tools/{asm.py,iss.py} + programs/{ops.s,mac.s}    (private)
├── hw3-synth/    README + tools/gen_golden.py + conv_ref.sdc               (private)
├── hw4-power/    README + tools/gen_golden.py                              (private)
├── hw5-apr/      README (APR/macro grading notes)
└── final-project/ README + tools/gen_golden.py  (score.py is PUBLIC in 00_TB/)
```

The **reference RTL** is the canonical, completed design under
[`common/rtl/`](../common/rtl/) (`alu/`, `cpu/`, `conv/`, `iotdf/`) — the same
files students reuse. Each module's `make ref` runs the reference against the
released testbench (expects `RESULT: PASS`).

## How testing / grading works

- **Public patterns** (committed under each module's `00_TB/golden|patterns/`)
  are what students develop against — input + expected output (CVSD "released
  patterns"). Students never see the generators.
- **Hidden patterns** (for grading) are regenerated with the **private**
  generators using a different `--seed`, then dropped into the module's
  `00_TB/golden|patterns/` before re-running the checks. Because each golden is
  computed by the reference model, *any* input is a valid self-checking test, so
  hard-coding the released outputs cannot pass. Restore the committed public set
  (default seed) when done. Per-module commands are in each
  `instructor/solutions/<hw>/README.md`.
- **Autograding:** each module's `01_RTL/` (or `02_SYN`/`04_APR`) Makefile exits
  non-zero on failure and prints `RESULT: PASS/FAIL`, so a grader can drive
  `make` per stage and parse the result. The **Final** is a competition scored on
  **PSNR** (`final-project/00_TB/score.py` vs `truth.txt`) plus area/time/power.

## Per-stage grading map

| HW | Graded by | Where |
|----|-----------|-------|
| HW1 | functional sim vs golden ALU vectors | `hw1-alu/01_RTL` `make sim` |
| HW2 | sim over programs (ops + mac + hidden) | `hw2-cpu/01_RTL` `make` |
| HW3 | synth (no latches) + gate-equivalence + STA | `hw3-synth/{01_RTL,02_SYN,03_GATE}` |
| HW4 | activity power + clock-gating PPA delta | `hw4-power/{01_RTL,02_SYN,03_GATE,06_POWER}` |
| HW5 | DRC-clean / LVS-match / post-route timing GDSII (with SRAM macro) | `hw5-apr/04_APR` |
| Final | PSNR + area + time + power (competition) | `final-project/*` + `score.py` |

## Tool notes
- Front-end checks (HW1/HW2, and HW3 functional) run locally with Verilator or
  Icarus; **HW3 synthesis** also runs on the conda env (Yosys + a `ciel` PDK).
- STA / power / **APR** (incl. the HW3/HW5 **SRAM macro** placement) need the
  Docker EDA image; the macro `.lib`/`.lef`/`.gds` paths are image-dependent
  (`SRAM_MACRO_DIR` in `hw3-synth/02_SYN` and `hw5-apr/04_APR`).
- Pin the toolchain at course start (`VERSIONS.lock`) and freeze the public
  patterns; don't upgrade the image mid-semester (keeps grades comparable).
