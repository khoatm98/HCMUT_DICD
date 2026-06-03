# HW4 — IoT Data Filter (the power homework)

Build an 8-bit byte-stream engine (`iotdf`), then **measure its power, reduce it
with clock gating, and report a quantified before/after PPA**. This is the
course's power-optimization homework: functional RTL is the warm-up — the grade
is mostly about *measuring* and *reducing* dynamic power.

## Read in this order
1. [OBJECTIVES.md](OBJECTIVES.md) — what you'll learn.
2. [SPEC.md](SPEC.md) — the exact function table (BIN2GRAY / GRAY2BIN / CRC8 /
   LFSR), the streaming contract, and the power-structure requirements. **Start here.**
3. [INSTRUCTIONS.md](INSTRUCTIONS.md) — step-by-step (functional → power).
4. [RUBRIC.md](RUBRIC.md) — how it's graded.

## Stage directories
This homework is organized as numbered back-end stages. Each stage has its own
Makefile; you run commands from inside the stage directory.

| Stage | What | You run |
|-------|------|---------|
| `00_TB/` | testbenches + committed public test patterns (`golden/`, `workload/`) | — (read-only) |
| `01_RTL/` | the engine you implement (`iotdf.v`) + functional-sim Makefile | `make vsim`, `make sim`, `make lint`, `make wave` |
| `02_SYN/` | Yosys synthesis (baseline + clock-gated) + `iotdf.sdc` | `make synth`, `make synth-cg` |
| `03_GATE/` | gate-level sim of the netlist on the workload (activity VCD) | `make gate`, `make gate-cg` |
| `06_POWER/` | OpenSTA activity-driven power + before/after compare | `make power-base`, `make power-cg`, `make compare` |

## Quick commands

```bash
# --- functional (local: Verilator / Icarus) ---
cd 01_RTL
make vsim       # Verilator self-checking sim (fast)   <- iterate with this
make sim        # Icarus self-checking sim
make wave       # open the VCD in GTKWave
make lint       # Verilator lint of your RTL

# --- power (EDA container: Yosys + Icarus + OpenSTA + SKY130) ---
cd ../02_SYN  && make synth synth-cg     # baseline + clock-gated netlists
cd ../03_GATE && make gate gate-cg       # gate-level sim -> activity VCDs
cd ../06_POWER && make compare           # report_power + writes ../artifacts/ppa_compare.md
```

The **public** test patterns in `00_TB/golden/` (and the power `00_TB/workload/`)
are **pre-committed** — there is no generator step to run. You implement
`01_RTL/iotdf.v` and iterate with `make vsim` until the testbench prints
`RESULT: PASS`.

## Files
| Path | Edit? | What |
|------|:----:|------|
| `01_RTL/iotdf.v` | ✅ | the byte-stream engine you implement (starter stub) |
| `00_TB/iotdf_tb.v` | ❌ | self-checking testbench (all four functions) |
| `00_TB/iotdf_workload_tb.v` | ❌ | activity-capture testbench for the power flow |
| `00_TB/golden/` | ❌ | committed public self-checking vectors (`.hex` + count `.vh`) |
| `00_TB/workload/` | ❌ | committed public power workload (`.hex` + count `.vh`) |
| `02_SYN/iotdf.sdc` | ❌ | timing constraints for synth / STA / power |
| `06_POWER/make_ppa.py` | ❌ | builds the PPA comparison table for `make compare` |
| `artifacts/` | ✅ | put your submission here (logs, reports, ppa_compare.md, screenshot) |

You pass the **functional** check when the testbench prints `RESULT: PASS`. You
finish the **power** part by completing `artifacts/ppa_compare.md` with measured
baseline-vs-clock-gated numbers and a short discussion (see RUBRIC). The
completed `iotdf.v` matches the reference
[`common/rtl/iotdf/iotdf.v`](../../common/rtl/iotdf/iotdf.v).
