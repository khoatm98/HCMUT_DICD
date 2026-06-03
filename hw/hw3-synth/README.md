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

## Quick commands (run from this folder)
```bash
make golden     # generate stimulus + expected from the Python reference model
make vsim       # Verilator self-checking sim (fast)   <- iterate with this
make sim        # Icarus self-checking sim
make ref        # run the SAME testbench against the reference engine (sanity)
make wave       # open sim/conv_engine.vcd in GTKWave
make lint       # Verilator lint of your RTL

# back-end flow (inside the EDA container):
make synth      # Yosys -> build/conv_netlist.v + build/conv_area.rpt
make sta        # OpenSTA timing using your constraints/conv.sdc
make gl-sim     # gate-level sim of the netlist vs the SAME golden (equivalence)
make all        # synth + sta + gl-sim
```

## Files
| Path | Edit? | What |
|------|:----:|------|
| `rtl/conv_engine.v` | ✅ | the engine you implement (starter stub: COMPUTE TODOs) |
| `constraints/conv.sdc` | ✅ | timing constraints you write (clock + I/O delays) |
| `tb/conv_engine_tb.v` | ❌ | self-checking testbench (drives the stream, compares golden) |
| `tools/gen_golden.py` | ❌ | golden reference model + stimulus/expected generator |
| `golden/` | — | generated stimulus/expected (`make golden`) |
| `build/` | — | synthesis netlist + area/STA reports |
| `artifacts/` | ✅ | put your submission here (logs, reports, note) |

Provided building blocks you reuse (do not edit):
[`common/rtl/conv/conv_defs.vh`](../../common/rtl/conv/conv_defs.vh) and the
flow wrappers in [`common/flow/`](../../common/flow/).

You pass the functional gate when the testbench prints `RESULT: PASS`, and you
complete HW3 when `make gl-sim` also passes (gate equivalence) and `make sta`
reports no timing violations. The completed `conv_engine.v` is the canonical
[`common/rtl/conv/conv_engine.v`](../../common/rtl/conv/conv_engine.v) carried
into HW5 — so write it cleanly.
