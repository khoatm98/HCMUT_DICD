# HW2 — Grading rubric (100 points)

| # | Criterion | Pts | How it's checked |
|---|-----------|-----|------------------|
| 1 | **Base ISA correctness** — `programs/ops.s` passes (all integer/fixed-point/branch/jump/load-store) | 35 | `make sim PROG=ops` → `RESULT: PASS` |
| 2 | **MAC custom instruction** — `programs/mac.s` passes; MAC implemented as a saturating accumulate reusing FXMUL | 25 | `make sim PROG=mac` → `RESULT: PASS` + code review |
| 3 | **Hidden program(s)** — instructor programs pass (no hard-coding) | 15 | autograder with extra `.s` programs |
| 4 | **ALU reuse / clean integration** — HW1 ALU instantiated unchanged; register file used correctly | 10 | code review |
| 5 | **Datapath/control quality** — readable single-cycle design, no latches, correct next-PC logic | 10 | code review + `make lint`-style check |
| 6 | **Verification effort** — at least one student-written test program + a MAC waveform | 5 | submitted artifacts |
| | **Total** | **100** | |

## Notes
- **Functional gate:** items 4–6 require item 1 to reach `RESULT: PASS`.
- **Hidden tests:** the autograder adds new `programs/*.s`; because the golden is
  computed by the ISS, any program is a valid self-checking test — hard-coding
  outputs cannot pass.
- **Interface integrity:** the `cpu_core` ports/params are fixed; changing them
  breaks the testbench and HW3 → no functional credit.
- The completed `cpu_core.v` is the design carried into HW3–HW5, so correctness
  here matters downstream.

## Autograde
- `make ref` → reference CPU passes all provided programs.
- Per student: `make` (runs `ops` + `mac` via Icarus) and any hidden programs
  via `make sim PROG=<hidden>`. See `instructor/solutions/hw2-cpu/`.
