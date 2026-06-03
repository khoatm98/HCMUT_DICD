# HW2 — TinyRISC-16 CPU with a MAC custom instruction

Build a 16-bit single-cycle CPU whose execution unit is the **HW1 ALU**, then add
the **MAC** custom instruction. This is the design synthesized in HW3, power-
optimized in HW4, and placed-and-routed to GDSII in HW5.

## Read in this order
1. [OBJECTIVES.md](OBJECTIVES.md)
2. [SPEC.md](SPEC.md) — the ISA + MAC definition. **Start here.**
3. [INSTRUCTIONS.md](INSTRUCTIONS.md) — step-by-step (six TODOs).
4. [RUBRIC.md](RUBRIC.md)

## Quick commands (from this folder)
```bash
make ref            # reference CPU passes all programs (sanity)
make vsim PROG=ops  # Verilator self-checking sim (fast) -- iterate with this
make vsim PROG=mac  # the MAC dot-product showcase
make                # graded check: Icarus over all programs
make wave PROG=mac  # waveform in GTKWave
```

## Files
| Path | Edit? | What |
|------|:----:|------|
| `rtl/cpu_core.v` | ✅ | the CPU control you implement (6 TODOs) |
| `tb/cpu_tb.v` | ❌ | self-checking testbench (owns memory, compares to golden) |
| `tools/asm.py` | ❌ | assembler (`.s` → instruction/data hex) |
| `tools/iss.py` | ❌ | golden instruction-set simulator |
| `programs/*.s` | ✅ | test programs (add your own!) |
| `artifacts/` | ✅ | your submission |

Provided building blocks you reuse (do not edit):
[`common/rtl/alu/alu.v`](../../common/rtl/alu/alu.v) (HW1) and
[`common/rtl/cpu/regfile.v`](../../common/rtl/cpu/regfile.v).

You pass when `make` prints `ALL PROGRAMS PASS`.
