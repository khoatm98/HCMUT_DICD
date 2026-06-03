# HW3 — 3×3 convolution engine (synthesis homework)

Design a small streaming **3×3 convolution accelerator** in Q6.10 fixed-point,
then take it through the **front end of the ASIC flow**: synthesize it to SKY130
gates, prove the netlist is equivalent to your RTL, and analyze its area and
timing. This is the design that HW5 places-and-routes to GDSII.

## Read in this order
1. [OBJECTIVES.md](OBJECTIVES.md) — what you'll learn.
2. [SPEC.md](SPEC.md) — the protocol, Q6.10 rules, and microarchitecture. **Start here.**
3. [INSTRUCTIONS.md](INSTRUCTIONS.md) — step-by-step (RTL + SDC, then synth/STA/gate-sim).
4. [RUBRIC.md](RUBRIC.md) — how it's graded.

## Stage directories
This module is organized into numbered ASIC-flow stages:

| Stage | What lives there |
|-------|------------------|
| `00_TB/` | the self-checking testbench + `golden/` (committed public test patterns the TB reads) |
| `01_RTL/` | the engine you implement (`conv_engine.v`) + the functional-sim Makefile |
| `02_SYN/` | synthesis Makefile + `conv.sdc` timing constraints |
| `03_GATE/` | gate-level (post-synthesis) equivalence-sim Makefile |
| `artifacts/` | put your submission here (logs, reports, note) |

The test patterns under `00_TB/golden/` are **pre-committed** — you do **not**
generate them. Just run the sims; the testbench reads them directly.

## Quick commands
```bash
# functional simulation (front end):
cd 01_RTL
make vsim       # Verilator self-checking sim (fast)   <- iterate with this
make sim        # Icarus self-checking sim
make ref        # run the SAME testbench against the reference engine (sanity)
make wave       # open the waveform in GTKWave
make lint       # Verilator lint of your RTL

# back-end flow (inside the EDA container):
cd ../02_SYN
make synth      # Yosys -> build/conv_netlist.v + build/conv_area.rpt
make sta        # OpenSTA timing using your conv.sdc -> build/conv_sta.rpt
cd ../03_GATE
make gl-sim     # gate-level sim of the netlist vs the SAME golden (equivalence)
```
Run artifacts land in each stage's `build/` (git-ignored).

## Files you edit
| Path | Edit? | What |
|------|:----:|------|
| `01_RTL/conv_engine.v` | ✅ | the engine you implement (starter stub: COMPUTE TODOs) |
| `02_SYN/conv.sdc` | ✅ | timing constraints (clock + CVSD-style I/O delays) |
| `00_TB/conv_engine_tb.v` | ❌ | self-checking testbench (drives the stream, compares golden) |
| `00_TB/golden/` | ❌ | committed public stimulus/expected the TB reads |

Provided building blocks you reuse (do not edit):
[`common/rtl/conv/conv_defs.vh`](../../../common/rtl/conv/conv_defs.vh) and the
flow wrappers in [`common/flow/`](../../../common/flow/).

You pass the functional gate when the testbench prints `RESULT: PASS`, and you
complete HW3 when `make gl-sim` also passes (gate equivalence) and `make sta`
reports no timing violations. The completed `conv_engine.v` is the canonical
[`common/rtl/conv/conv_engine.v`](../../../common/rtl/conv/conv_engine.v) carried
into HW5 — so write it cleanly.
