# HW1 — Parameterized Q6.10 ALU

Build and verify the Arithmetic Logic Unit that becomes the execution unit of
the TinyRISC-16 CPU in HW2. This is the first link in the course's running
design.

## Read in this order
1. [OBJECTIVES.md](OBJECTIVES.md) — what you'll learn.
2. [SPEC.md](SPEC.md) — the exact operation table + Q6.10 rules. **Start here.**
3. [INSTRUCTIONS.md](INSTRUCTIONS.md) — step-by-step.
4. [RUBRIC.md](RUBRIC.md) — how it's graded.

## Layout (CVSD-style stage dirs)
| Path | Edit? | What |
|------|:----:|------|
| `01_RTL/alu.v` | ✅ | the ALU you implement (starter stub) |
| `01_RTL/Makefile` | ❌ | functional-sim targets (run from here) |
| `00_TB/alu_tb.v` | ❌ | self-checking testbench |
| `00_TB/golden/` | ❌ | the committed public test patterns (vectors + count) |
| `artifacts/` | ✅ | put your submission here (log, screenshot, note) |

The test patterns in `00_TB/golden/` are **pre-committed** — you do **not**
generate them, and you do **not** need Python. Just simulate against them.

## Quick commands (run from `01_RTL/`)
```bash
cd 01_RTL
make vsim       # Verilator self-checking sim (fast)   <- iterate with this
make sim        # Icarus self-checking sim
make wave       # open build/alu.vcd in GTKWave
make lint       # Verilator lint of your RTL
```

You pass when the testbench prints `RESULT: PASS`. The completed `alu.v` is the
canonical [`common/rtl/alu/alu.v`](../../common/rtl/alu/alu.v) reused from HW2
onward — so write it cleanly.
