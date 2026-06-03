# Final Project — MIMO Sphere-Decoder: specification

Design a hardware **MIMO detector** and take it the whole way — RTL → verify →
synthesize → power-optimize → APR → **clean GDSII** — applying everything from
HW1–HW5. This is the culmination; it is a *new* design (not a homework reused).

> Inspired by NTU's CVSD/Digital-Comm-IC final (a 4×4 MIMO 8-PSK sphere
> decoder). We replace the MATLAB/commercial flow with the course's open-source
> toolchain and a pure-Python golden model.

## The problem

An **N×N MIMO** system transmits a symbol vector **s** (each entry an *M*-PSK
symbol) over a complex channel **H**, received as **y = H·s + n**.

A receiver recovers **s**. Brute-force maximum-likelihood (ML) detection solves
`argmin_s ||y − H·s||²` over all `Mᴺ` candidates — accurate but expensive.
**Sphere decoding** gets the same answer far more cheaply by:
1. **QR decomposition** `H = Q·R` (done in *software* — it's per-channel, not
   per-symbol), giving an upper-triangular **R** and `ỹ = Qᴴ·y`. The problem
   becomes `argmin_s ||ỹ − R·s||²`.
2. Because **R** is upper-triangular, the cost decomposes level-by-level over the
   antennas → a **tree search** (depth N, branching M). A **partial Euclidean
   distance (PED)** is accumulated down the tree, and branches whose PED already
   exceeds the best full solution are **pruned**.

**Your hardware** takes **R** and **ỹ** (the software-preprocessed inputs) and
outputs the detected symbols. The QR is *not* in hardware.

## Recommended scope (pick one)

| Variant | N | Modulation | Tree | Use when |
|---------|---|-----------|------|----------|
| **Full (default)** | 4×4 | 8-PSK | 8⁴ = 4096 leaves | normal laptops; matches the NTU reference |
| **Scaled** | 2×2 | QPSK | 4² = 16 leaves | weak laptops / tighter schedule |

Either is a valid capstone; the scaled variant is smaller to verify and APR.

## Numerics
Signed fixed-point **Q6.10** (16-bit), the course standard. **R** and **ỹ** fit
comfortably in range; M-PSK symbol components are `±1, ±1/√2` (`0x0400`,
`0x02D4`...). PED accumulates in wider precision before comparison. The provided
golden emits R and ỹ as Q6.10 hex.

## Suggested I/O interface (adapt as you like)
```
module mimo_detector (
  input              clk, rst_n,
  input              i_valid,        // input beat valid
  input              i_is_R,         // 1 = loading R entry, 0 = loading y_tilde
  input  [31:0]      i_data,         // {real[15:0], imag[15:0]} Q6.10 complex
  output             o_ready,        // ready to accept
  output             o_out_valid,    // detected symbols valid (1 cycle)
  output [N*log2(M)-1:0] o_symbols    // detected symbol indices (bits)
);
```
You may choose a streaming or wide-bus load and any internal microarchitecture
(a depth-first sphere decoder with PED + pruning is recommended; a full ML search
is acceptable for the scaled variant). Put your RTL in `01_RTL/`.

## How you are graded — quality (PSNR) + area + time + power

You are **not** graded on matching the golden bit-for-bit. You are graded on a
**competition score** over four axes — exactly the quality-vs-PPA tradeoff real
detectors make:

- **Quality — PSNR (dB).** How close your detector's output is to the
  ground-truth transmitted symbols, in the symbol domain
  (`PSNR = 10·log10(peak²/MSE)`, PSK peak = 1; higher is better). An approximate
  or early-terminated sphere search that occasionally misses costs PSNR but can
  save a lot of area/time/power — making that tradeoff well is the point.
- **Area** — chip area / cell count (from synthesis + APR).
- **Time** — detection latency = cycles to process the test set × clock period
  (sphere-decode latency varies with pruning, so this rewards a good search order).
- **Power** — activity-driven average power on the workload.

The provided harness gives you the committed dev set and the scorer:
- `00_TB/golden/` holds the **committed** public vectors: `vectors.hex` (R + ỹ),
  `truth.txt` (ground-truth transmitted symbols), and `expected.txt` (the
  ML-optimal symbols, for comparison). They are pre-generated — no Python needed
  to simulate.
- Your testbench (`00_TB/mimo_detector_tb.v`) runs your detector on
  `vectors.hex` and writes its detected symbols to `01_RTL/build/detected.txt`;
  [`00_TB/score.py`](00_TB/score.py) reports **PSNR** and SER vs `truth.txt`
  (`cd 01_RTL && make score`). Report PSNR/SER across a range of SNRs.

A typical ranking metric (CVSD-style): **minimize Area × Time × Power subject to
PSNR ≥ a threshold** — the smallest / fastest / lowest-power design that still
detects well enough. Your instructor sets the threshold and weights (see RUBRIC.md).

## Deliverables
1. **RTL** + a testbench that runs the golden `vectors.hex` and writes the
   detector's detected symbols (for `score.py`), at RTL and gate level.
2. **Synthesis**: SKY130 netlist + SDC + area/timing, gate-level equivalence.
3. **Power**: activity-driven OpenSTA power on a representative workload + at
   least one optimization (clock gating / operand isolation) with quantified PPA.
4. **APR**: a **DRC-clean, LVS-matching GDSII** meeting post-route timing.
5. **Report**: algorithm, microarchitecture, PPA summary, and the full-flow
   runbook (one-command reproduction).
