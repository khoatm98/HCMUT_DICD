# HW1 — Parameterized Q6.10 ALU

Build and verify the Arithmetic Logic Unit that becomes the execution unit of
the TinyRISC-16 CPU in HW2. This is the first link in the course's running
design.

## Read in this order
1. [OBJECTIVES.md](OBJECTIVES.md) — what you'll learn.
2. [SPEC.md](SPEC.md) — the exact operation table + Q6.10 rules. **Start here.**
3. [INSTRUCTIONS.md](INSTRUCTIONS.md) — step-by-step.
4. [RUBRIC.md](RUBRIC.md) — how it's graded.

## Quick commands (run from this folder)
```bash
make vectors    # generate golden vectors from the Python reference model
make vsim       # Verilator self-checking sim (fast)   <- iterate with this
make sim        # Icarus self-checking sim
make wave       # open sim/alu.vcd in GTKWave
make lint       # Verilator lint of your RTL
```

## Files
| Path | Edit? | What |
|------|:----:|------|
| `rtl/alu.v` | ✅ | the ALU you implement (starter stub) |
| `tb/alu_tb.v` | ❌ | self-checking testbench |
| `tools/gen_vectors.py` | ❌ | golden reference model + vector generator |
| `golden/` | — | generated vectors (`make vectors`) |
| `artifacts/` | ✅ | put your submission here (log, screenshot, note) |

You pass when the testbench prints `RESULT: PASS`. The completed `alu.v` is the
canonical [`common/rtl/alu/alu.v`](../../common/rtl/alu/alu.v) reused from HW2
onward — so write it cleanly.
