# Final Project — Milestones

A suggested plan. Each milestone reuses a skill from a specific homework.

## M1 — Algorithm & golden (reuses HW1 verification habits)
- Choose scope (4×4 8-PSK or 2×2 QPSK).
- Study the committed dev set in `00_TB/golden/`: the vectors
  (`vectors.hex` — R upper-triangle + ỹ), the ground truth (`truth.txt`), and the
  expected ML symbols (`expected.txt`). The patterns are pre-generated and
  committed — you do not run any generator.
- Write a Python or paper model of your intended datapath (PED accumulation,
  tree order) so you know the numbers before writing RTL.

## M2 — RTL + quality measurement (reuses HW1 ALU + HW2 datapath/control)
- Implement `01_RTL/mimo_detector.v`: complex multiply (reuse the Q6.10
  multiply/round/saturate idea from the HW1 ALU), PED metric, and the
  depth-first tree-search FSM with pruning.
- Adapt `00_TB/mimo_detector_tb.v` to your interface so it writes the detected
  symbols (`01_RTL/build/detected.txt`); from `01_RTL` run `make vsim`, then
  `make score` (PSNR + SER vs `../00_TB/golden/truth.txt`). Aim for high
  **PSNR**; report PSNR/SER across SNRs. (Remember: the grade is PSNR + area +
  time + power — an approximate decoder that's smaller/faster can win, so decide
  your search-radius / early-termination tradeoff here.)

## M3 — Synthesis + STA (reuses HW3)
- From `02_SYN`: `make synth` → SKY130 netlist + area; tune `mimo.sdc` and run
  `make sta`.
- From `03_GATE`: `make gl-sim` for gate-level equivalence vs the same committed
  vectors. No latches; meet a clock.

## M4 — Power (reuses HW4)
- From `06_POWER`: `make compare` runs a representative workload through
  gate-level sim, captures activity, and reports OpenSTA power for the **baseline**
  vs a **clock-gated** build (the tree-search units idle when pruned). Report the
  quantified before/after PPA.

## M5 — APR → GDSII (reuses HW5)
- From `04_APR`: `make apr` (LibreLane). Inspect floorplan/congestion/CTS; reach a
  DRC-clean, LVS-matching GDSII meeting post-route timing. View in KLayout.

## M6 — Report & runbook
- Algorithm + microarchitecture, verification (incl. SNR curve), PPA summary
  (area/timing/power, baseline vs optimized), and a reproduction runbook (the
  per-stage `make` commands above, in order). Note any scope decisions (e.g.
  2×2 vs 4×4) and their impact.
