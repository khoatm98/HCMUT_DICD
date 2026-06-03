# HW2 — TinyRISC-16 CPU with a MAC custom instruction

Build a 16-bit single-cycle CPU whose execution unit is the **HW1 ALU**, then add
the **MAC** custom instruction. This is the design synthesized in HW3, power-
optimized in HW4, and placed-and-routed to GDSII in HW5.

## Read in this order
1. [OBJECTIVES.md](OBJECTIVES.md)
2. [SPEC.md](SPEC.md) — the ISA + MAC definition. **Start here.**
3. [INSTRUCTIONS.md](INSTRUCTIONS.md) — step-by-step (six TODOs).
4. [RUBRIC.md](RUBRIC.md)

This module is organized into CVSD-style stage directories:
`00_TB/` (testbench + committed `patterns/`) and `01_RTL/` (the `cpu_core.v`
stub you edit + its Makefile). You work and run from `01_RTL/`.

## Quick commands (from `01_RTL/`)
```bash
cd 01_RTL
make vsim PROG=ops  # Verilator self-checking sim (fast) -- iterate with this
make vsim PROG=mac  # the MAC dot-product showcase
make lint           # Verilator lint of your RTL
make                # graded check: Icarus over all programs (ops + mac)
make wave PROG=mac  # waveform in GTKWave
```
The test patterns are **pre-committed** in `00_TB/patterns/` — no assembler or
Python needed. The Makefile copies the selected program's patterns into
`01_RTL/build/` before each run.

## Layout
| Path | Edit? | What |
|------|:----:|------|
| `01_RTL/cpu_core.v` | ✅ | the CPU control you implement (6 TODOs) |
| `01_RTL/Makefile` | ❌ | functional-sim targets (`sim`/`vsim`/`lint`/`wave`/`ref`/`clean`) |
| `00_TB/cpu_tb.v` | ❌ | self-checking testbench (owns memory, compares to golden) |
| `00_TB/patterns/*.hex` | ❌ | committed public patterns (`<prog>.imem/.dmem/.golden`) |
| `artifacts/` | ✅ | your submission |

Provided building blocks you reuse (do not edit):
[`common/rtl/alu/alu.v`](../../common/rtl/alu/alu.v) (HW1) and
[`common/rtl/cpu/regfile.v`](../../common/rtl/cpu/regfile.v).

You pass when `make` (from `01_RTL/`) prints `ALL PROGRAMS PASS`.
