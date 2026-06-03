# HW4 — Grading rubric (100 points)

HW4 is the **power** homework: functional correctness is the gate, but most of
the credit is for **measuring and reducing** power and reporting a quantified PPA.

| # | Criterion | Pts | How it's checked |
|---|-----------|-----|------------------|
| 1 | **Functional correctness** — all four functions pass (`RESULT: PASS`) | 30 | `make sim` / `make vsim` exit 0; autograder reruns with fresh + hidden streams |
| 2 | **Low-power RTL structure** — per-function units, operand-isolated idle inputs, CRC/LFSR registers gated (update only when selected) | 15 | code review + `make lint` |
| 3 | **Baseline power measured** — `make power-base` produces `build/power_base.rpt` from gate-level activity on the workload | 15 | report present + sane (internal/switching/leakage/total) |
| 4 | **Clock gating applied** — `make power-cg` re-synthesizes with `CLOCKGATE=1` and re-measures on the same workload | 15 | `build/power_cg.rpt` present; gating cells inserted |
| 5 | **Quantified PPA before/after** — completed `artifacts/ppa_compare.md` with baseline-vs-gated **power and area** numbers and a correct reduction % | 15 | inspect `ppa_compare.md` |
| 6 | **Discussion** — where the baseline power went; clock gating vs **operand isolation** for the idle units; the area/power trade-off | 10 | inspect write-up |
| | **Total** | **100** | |

## Notes
- **Functional gate:** items 2–6 are only awarded if item 1 reaches `RESULT:
  PASS`. A non-simulating design scores 0 on 1 and is capped low overall.
- **Hidden streams:** the autograder regenerates the stimulus with a different
  seed and adds directed CRC/LFSR/Gray corners, so hard-coding released vectors
  will not pass.
- **Power must be activity-driven.** A `report_power` with no VCD (static
  estimate) does not earn items 3–4; the workload VCD must annotate the netlist
  (`make compare` wires `VCD`/`VCD_SCOPE` for you).
- **The improvement is the point, not its size.** Different correct structures
  yield different savings; full credit for items 4–6 needs a *measured* reduction
  and a *correct explanation*, not a particular percentage.
- **Interface integrity:** changing the `iotdf` ports breaks the TB and the power
  flow → no functional credit.
- **Academic honesty:** the RTL must be your own; the reference is released only
  after grading.

## Autograde

Instructors: `make ref` runs the testbench against the reference `iotdf`
(expects `RESULT: PASS`); the per-student functional check is `make sim`. The
power flow is `make compare` (Yosys + Icarus gate-sim + OpenSTA). See
`instructor/solutions/hw4-power/`.
