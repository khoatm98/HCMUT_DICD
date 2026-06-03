# HW1 — Grading rubric (100 points)

| # | Criterion | Pts | How it's checked |
|---|-----------|-----|------------------|
| 1 | **Functional correctness** — all golden vectors pass (`RESULT: PASS`) | 50 | `make sim` / `make vsim` exit 0; autograder reruns with fresh + hidden vectors |
| 2 | **Fixed-point correctness** — FXADD/FXSUB saturation and FXMUL rounding+saturation, with correct `overflow` | 20 | included in the vector check; specific FX corner vectors weighted |
| 3 | **Parameterization & style** — uses `WIDTH`/`FRAC`, opcode macros, no hard-coded widths, no latches | 10 | code review + `make lint` |
| 4 | **Clean Verilator lint** of the finished design | 10 | `make lint` reports no warnings |
| 5 | **Waveform understanding** — annotated GTKWave screenshot + short rounding/saturation note | 10 | inspect submitted artifact |
| | **Total** | **100** | |

## Notes
- **Functional gate:** items 3–5 are only awarded if item 1 reaches `RESULT: PASS`
  (a non-simulating design scores 0 on 1–2 and is capped low overall).
- **Hidden vectors:** the autograder regenerates vectors with a different seed and
  adds extra fixed-point corner cases, so hard-coding the released vectors will
  not pass.
- **Interface integrity:** changing the module ports/parameters breaks the
  testbench (and HW2) → no credit for item 1. Keep the interface exactly as in
  [SPEC.md](SPEC.md).
- **Academic honesty:** the ALU must be your own RTL; the reference solution is
  released only after grading.

## Autograde

Instructors (from `01_RTL/`): `make ref` runs the testbench against the reference
ALU (expects `RESULT: PASS`); the per-student check is `make sim` (or `make vsim`)
against the student's `01_RTL/alu.v`. See `instructor/solutions/hw1-alu/`.
