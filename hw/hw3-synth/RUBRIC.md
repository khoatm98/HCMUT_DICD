# HW3 — Grading rubric (100 points)

| # | Criterion | Pts | How it's checked |
|---|-----------|-----|------------------|
| 1 | **Functional correctness (RTL)** — all golden cases pass (`RESULT: PASS`) | 35 | `cd 01_RTL && make sim` / `make vsim` exit 0; autograder reruns with fresh + hidden cases |
| 2 | **Fixed-point correctness** — full-precision accumulate, round-half-up, and per-pixel saturation (incl. zero-padding edges) | 15 | included in the case check; blur/Sobel/saturate cases weighted |
| 3 | **Microarchitecture** — single shared multiplier + sequential MAC, 4-state FSM, flop arrays (macro-free), no latches | 10 | code review + `make lint` + area report shape |
| 4 | **Synthesis** — `02_SYN/make synth` produces a SKY130 netlist + area report | 10 | `02_SYN/build/conv_netlist.v` and `02_SYN/build/conv_area.rpt` exist; Yosys clean |
| 5 | **Gate-level equivalence** — `03_GATE/make gl-sim` passes against the same golden | 15 | `make gl-sim` → `RESULT: PASS` (netlist == RTL) |
| 6 | **Timing constraints + STA** — completed `02_SYN/conv.sdc`; `make sta` shows positive setup/hold slack; you can identify the critical path | 10 | `02_SYN/build/conv_sta.rpt` + the submitted note |
| 7 | **Analysis note** — clock period + worst slack, dominant area cells, area-vs-cycles trade-off of the sequential MAC | 5 | inspect submitted artifact |
| | **Total** | **100** | |

## Notes
- **Functional gate:** items 3–7 are only awarded if item 1 reaches
  `RESULT: PASS` (a non-simulating design scores 0 on 1–2 and is capped low).
  Gate-level equivalence (item 5) requires a synthesizable, latch-free design.
- **Hidden cases:** the public patterns under `00_TB/golden/` are committed; the
  autograder regenerates stimulus with a different `--seed` using the **private**
  generator (`instructor/solutions/hw3-synth/tools/gen_golden.py`) and adds extra
  kernels/edge/saturation cases, so hard-coding the released outputs will not pass.
- **Interface integrity:** changing the `conv_engine` ports/params breaks the
  testbench, the gate-level netlist port list, and HW5 → no functional credit.
  Keep the interface exactly as in [SPEC.md](SPEC.md).
- **Academic honesty:** the engine RTL and the SDC must be your own; the
  reference solution is released only after grading.

## Autograde

Instructors: `cd 01_RTL && make ref` runs the testbench against the reference
engine (expects `RESULT: PASS`); the per-student functional check is `make sim`
(in `01_RTL/`) against the student's `01_RTL/conv_engine.v`; `cd 03_GATE && make
gl-sim` checks equivalence; `cd 02_SYN && make sta` with the student SDC (or the
reference SDC) checks timing. See `instructor/solutions/hw3-synth/`.
