# Smoke test (`smoke/`)

A **one-command** sanity check that the entire toolchain works, *before* you
start HW1. It pushes a tiny [8-bit counter](rtl/counter.v) through every stage
of the flow.

```bash
# from the repo root (runs inside the container):
make smoke
```

It runs six stages and prints a checklist:

```
[1/6] iverilog sim ........   # RTL simulation (Icarus) -- self-checking TB must print RESULT: PASS
[2/6] verilator sim .......   # faster RTL simulation (Verilator --binary)
[3/6] yosys synth .........   # synthesize to SKY130 gates (Yosys + ABC)
[4/6] opensta STA .........   # static timing (worst slack >= 0)
[5/6] librelane APR .......   # floorplan -> place -> CTS -> route -> GDS (LibreLane/OpenROAD)
[6/6] GDS check ...........   # a non-empty *.gds was produced under runs/
SMOKE TEST PASSED -- the toolchain is ready for HW1.
```

Why a **counter** and not an adder? The smoke test must exercise clock-tree
synthesis and routing; a purely combinational design has no clock, so it would
skip those stages. The counter is the smallest design that still touches the
whole flow. It is **not** part of any homework.

If a stage fails, the failing tool/path is the one to debug — start with
`make healthcheck` and [../docs/08-troubleshooting.md](../docs/08-troubleshooting.md).

Target runtime: a few minutes on a modest laptop (the design is trivial; almost
all the time is APR startup).
