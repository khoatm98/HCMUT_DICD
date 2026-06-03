# Final Project — instructor notes

> **Do not distribute.** This is an open-ended capstone (students implement the
> RTL); there is no single reference solution, so this documents the golden
> harness, expectations, and grading.

## The PRIVATE golden generator
`instructor/solutions/final-project/tools/gen_golden.py` is the open-source
(pure-Python, no MATLAB) replacement for NTU's `H_generator.m`. It generates a
random complex channel, does the QR (modified Gram-Schmidt), forms R and
`ỹ = Qᴴy`, and computes the exhaustive-ML detected symbols. It is **private** —
it must NOT live anywhere under `final-project/`.

The **public** dev set it produced is committed at
`final-project/00_TB/golden/{vectors.hex, truth.txt, expected.txt}` (generated
once with `--seed 1`). Students simulate against those committed patterns; they
never run a generator. `final-project/00_TB/score.py` (the scorer) stays public.

**Regenerate HIDDEN patterns for grading** with this private generator using a
DIFFERENT `--seed` (and/or `--snr`), then re-score each student's detector
against them:
```bash
python3 instructor/solutions/final-project/tools/gen_golden.py \
  --n 4 --m 8 --cases 20 --snr 20 --seed 9999 \
  --out_vectors /tmp/hidden_v.hex --out_truth /tmp/hidden_t.txt --out_expected /tmp/hidden_e.txt
# Sanity: "ML recovered the transmitted vector in 20/20 cases" at high SNR;
# at --snr 3 it recovers far fewer (noise -> detection errors). Both confirm the
# QR + ML model are correct. R's diagonal is real-positive (imag = 0x0000).
```

## Scope
- **4×4 8-PSK** (default, matches the NTU reference) or **2×2 QPSK** (`--n 2 --m 4`,
  for weaker laptops / tighter schedules). Same rubric; students justify scope.
- Reference architecture (for guidance): depth-first sphere decode — complex
  multiply → accumulate `R·s` → PED `||ỹ−Rs||²` → tree search with pruning. A
  full exhaustive-ML datapath is acceptable for the scaled variant.

## Grading
Weighted toward the **APR-to-GDSII** result (25 pts) since the capstone's point
is a finished layout; functional/synth/power feed it. Use the rubric in
`final-project/RUBRIC.md`. Autograde hooks (per stage dir):
- `01_RTL/make vsim` + `make score` (functional vs committed golden); re-score
  on HIDDEN patterns (regenerate with a different `--seed`) for the hidden check.
- `02_SYN/make synth`+`sta`, `03_GATE/make gl-sim` (equivalence),
  `06_POWER/make compare` (PPA present), `04_APR/make apr` → `runs/<tag>/` GDS
  with DRC=0, LVS match, post-route slack ≥ 0.

## Notes / caveats
- The per-stage flow Makefiles + `04_APR/config.json` are scaffolding; students
  complete `01_RTL/` (RTL), adapt `00_TB/mimo_detector_tb.v` to their interface,
  and tune `02_SYN/mimo.sdc`.
- The NTU reference design (Verilog + MATLAB + test vectors) lives outside this
  repo; describe the algorithm from `SPEC.md` rather than relying on it.
- Q6.10 keeps R/ỹ in range; remind students PED must accumulate in WIDER
  precision before comparison (same lesson as the HW1 ALU FXMUL).
