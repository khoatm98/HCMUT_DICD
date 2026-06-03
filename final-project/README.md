# Final Project — MIMO Sphere-Decoder (RTL → GDSII)

The capstone: design a **MIMO detector** and take it through the **entire flow**
you learned in HW1–HW5 — RTL design + verification → synthesis → power
optimization → place-and-route → **clean GDSII** — on the open-source toolchain.

## Read in order
1. [SPEC.md](SPEC.md) — the problem, scope options, I/O, numerics, deliverables. **Start here.**
2. [OBJECTIVES.md](OBJECTIVES.md)
3. [MILESTONES.md](MILESTONES.md) — the project plan, milestone by milestone.
4. [RUBRIC.md](RUBRIC.md)

## What it is
An N×N MIMO sphere decoder: QR decomposition is done in **software**; your
hardware takes **R** and **ỹ = Qᴴy** and finds the most-likely transmitted
symbols via a pruned tree search (PED). Default scope **4×4 8-PSK**; a **2×2
QPSK** scaled variant is provided for weaker laptops.

## How it's graded
A **competition** on **PSNR (detection quality) + area + time + power** — *not*
exact-match to the golden. An approximate/fast decoder that trades a little PSNR
for big PPA wins is fair game. See [SPEC.md](SPEC.md) and [RUBRIC.md](RUBRIC.md).

## Layout (CVSD-style numbered stage directories)
| Dir | What |
|-----|------|
| `00_TB/mimo_detector_tb.v` | testbench template: loads the vectors, writes your detector's detected symbols for scoring |
| `00_TB/golden/` | **committed** public dev set: `vectors.hex` (R + ỹ), `truth.txt` (ground truth), `expected.txt` (ML-optimal) |
| `00_TB/score.py` | scores your detector's output: **PSNR** + SER vs `truth.txt` (public — measure your own quality) |
| `01_RTL/` | **you write** `mimo_detector.v` (+ submodules) here, plus a `Makefile` with functional-sim targets |
| `02_SYN/{Makefile, mimo.sdc}` | SKY130 synthesis + OpenSTA timing (you tune `mimo.sdc`) |
| `03_GATE/Makefile` | gate-level sim of the netlist vs the committed vectors |
| `06_POWER/Makefile` | activity-driven power: baseline vs clock-gated, with a compare |
| `04_APR/{config.json, Makefile}` | LibreLane RTL→GDSII |

The vectors are **pre-committed** — no Python is needed to simulate; just read
`00_TB/golden/`. (The vector *generator* is instructor-private.)

You implement `01_RTL/mimo_detector.v` (and submodules).

## Quick start
```bash
cd 01_RTL
make vsim            # run YOUR detector on the committed vectors (writes build/detected.txt)
make score           # PSNR + SER vs ../00_TB/golden/truth.txt
cd ../02_SYN && make synth   # SKY130 synthesis + area
cd ../02_SYN && make sta     # OpenSTA timing (mimo.sdc)
cd ../03_GATE && make gl-sim # gate-level sim vs the committed vectors
cd ../06_POWER && make compare  # activity-driven power: baseline vs clock-gated
cd ../04_APR  && make apr    # LibreLane RTL->GDSII
```

This project deliberately reuses the **same flow scripts** as the homeworks
(`common/flow/*`), so the capstone is assembling skills, not learning new tools.
