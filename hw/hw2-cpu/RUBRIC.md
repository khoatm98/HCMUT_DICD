# HW2 — Grading rubric (100 points)

| # | Criterion | Pts | How it's checked |
|---|-----------|-----|------------------|
| 1 | **Base ISA correctness** — the `ops` program passes (all integer/fixed-point/branch/jump/load-store) | 35 | `cd 01_RTL && make sim PROG=ops` → `RESULT: PASS` |
| 2 | **MAC custom instruction** — the `mac` program passes; MAC implemented as a saturating accumulate reusing FXMUL | 25 | `cd 01_RTL && make sim PROG=mac` → `RESULT: PASS` + code review |
| 3 | **Hidden program(s)** — instructor patterns pass (no hard-coding) | 15 | autograder with extra hidden patterns |
| 4 | **ALU reuse / clean integration** — HW1 ALU instantiated unchanged; register file used correctly | 10 | code review |
| 5 | **Datapath/control quality** — readable single-cycle design, no latches, correct next-PC logic | 10 | code review + `make lint` |
| 6 | **Verification effort** — a MAC waveform + a short analysis note | 5 | submitted artifacts |
| | **Total** | **100** | |

## Notes
- **Functional gate:** items 4–6 require item 1 to reach `RESULT: PASS`.
- **Hidden tests:** the autograder drops additional pre-assembled patterns into
  `00_TB/patterns/`; because each golden is computed by the reference ISS, any
  program is a valid self-checking test — hard-coding outputs cannot pass.
- **Interface integrity:** the `cpu_core` ports/params are fixed; changing them
  breaks the testbench and HW3 → no functional credit.
- The completed `cpu_core.v` is the design carried into HW3–HW5, so correctness
  here matters downstream.

## Autograde (from `01_RTL/`)
- `make ref` → reference CPU passes all provided programs.
- Per student: `make` (runs `ops` + `mac` via Icarus) and any hidden programs
  via `make sim PROG=<hidden>` (after the instructor stages the hidden patterns).
  See `instructor/solutions/hw2-cpu/`.
