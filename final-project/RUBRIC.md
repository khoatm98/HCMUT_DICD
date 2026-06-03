# Final Project — Grading rubric (100 points)

The capstone is a **competition**: you are graded on **detection quality (PSNR)**
and on **area, time, and power** — *not* on matching the ML golden bit-for-bit.
An approximate/fast sphere decoder that trades a little PSNR for big PPA wins is a
valid, encouraged design. (Quality is measured by `00_TB/score.py` vs
`00_TB/golden/truth.txt`; area/time/power come from your synth/STA/APR reports.)

## Fixed points (60) — you must complete the whole flow

| # | Criterion | Pts | Evidence |
|---|-----------|-----|----------|
| 1 | **Working detector** — runs the committed vectors at RTL and gate level; produces detected symbols; achieves **PSNR ≥ threshold** (instructor-set, e.g. ≥ 30 dB on the high-SNR set) | 20 | `01_RTL/make vsim` + `make score`; `03_GATE/make gl-sim` |
| 2 | **Synthesis + STA** — SKY130 netlist, SDC, timing met, gate-level equivalence to the RTL detector | 10 | `02_SYN/make synth`+`sta`, `03_GATE/make gl-sim` + reports |
| 3 | **Power measured** — activity-driven OpenSTA power on the workload | 5 | `06_POWER/make compare` report |
| 4 | **APR to clean GDSII** — DRC-clean, LVS-match, post-route timing met | 20 | `04_APR/` `runs/<tag>/` GDS + DRC/LVS/STA |
| 5 | **Reproducibility + report** — per-stage `make` runbook; report covers algorithm, microarchitecture, and the PPA/PSNR results | 5 | runbook + report |

## Competition score (40) — ranked PPA-vs-quality

Among submissions that meet the PSNR threshold (#1), rank by a combined
**figure of merit** and award the 40 points on a curve:

```
FOM = (Area x Time x Power)      # lower is better
   Area  : core area (or cell count) from APR/synth
   Time  : detection latency = cycles for the test set x clock period
   Power : average power on the workload
   subject to PSNR >= threshold  (designs below the threshold are not ranked here)
```

- Report **PSNR (and SER) vs SNR** so the quality/PPA tradeoff is explicit.
- Higher PSNR at equal PPA, or lower PPA at equal PSNR, ranks higher.
- Instructors may instead weight the four axes (e.g. PSNR 40%, area/time/power
  20% each) — set the exact formula at course start and announce it.

## Notes
- **Scope** (4×4 8-PSK vs 2×2 QPSK) doesn't change the rubric; state and justify
  your scope. Thresholds may be set per scope.
- **No exact-match requirement:** correctness = "detects well enough" (PSNR
  gate), then it's a PPA race.
- Hidden check: instructors re-score your detector on a HIDDEN vector set
  (a different seed/SNR, kept private); your PSNR should hold.
- Bonus: a Gray-mapped constellation + BER-vs-SNR curve; a throughput/area study
  (parallel vs sequential PED); configurable search radius (PSNR↔PPA knob).

## Autograde hooks
`01_RTL/make vsim` → detected symbols → `make score` (PSNR/SER vs truth) ·
`02_SYN/make synth`+`sta` · `03_GATE/make gl-sim` (gate-level equivalence) ·
`06_POWER/make compare` · `04_APR/make apr` → `runs/<tag>/` GDS, DRC=0, LVS
match, slack ≥ 0. Collect Area/Time/Power for the FOM ranking.
See `instructor/solutions/final-project/`.
