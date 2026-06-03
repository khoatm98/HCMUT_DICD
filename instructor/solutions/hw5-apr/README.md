# HW5 — instructor notes

> **Do not distribute.**

## Reference flow
The design is the unmodified `common/rtl/conv/conv_engine.v` (symlinked into
`src/` by `make prep`). Validate in the container:

```bash
cd hw/hw5-apr
make apr          # full LibreLane flow -> runs/<tag>/
make summary      # post-route timing + DRC/LVS status
make klayout      # view the GDS
```

## What to expect
- **Macro-free, small block:** image/kernel/result are flop arrays + one shared
  16×16 multiplier, so it's all standard cells — places and routes quickly on a
  laptop. The floorplan is dominated by the flop arrays; the clock tree fans out
  to them.
- **DRC/LVS:** should be clean/match for this size at sane utilization
  (`FP_CORE_UTIL` ~40, density ~50). If a student hits DRC/congestion, the fix is
  lower utilization/density.
- **Timing:** post-route slack should be comfortably ≥ 0 at the HW3-class clock
  (the per-cycle logic is a single multiply-accumulate step).

## Grading hooks
Look in the latest `runs/<tag>/`:
- a final `*.gds` exists (flow completed);
- DRC report shows 0 violations;
- LVS reports a match;
- post-route STA worst slack ≥ 0.

## Caveats (tool-version dependent)
- **`make apr`** uses LibreLane via `common/flow/openlane_run.sh` (prefers
  `librelane`, falls back to `openlane`). Confirm your image provides one.
- **Conda path:** no LibreLane → use OpenROAD-flow-scripts (ORFS) with
  `sky130hd`, the conv RTL, and the `conv_defs.vh` include dir (see student
  INSTRUCTIONS.md). Same objectives, different orchestrator.
- Report file names/paths under `runs/` vary by LibreLane version; `make inspect`
  / `make summary` search for them rather than hard-coding paths.
