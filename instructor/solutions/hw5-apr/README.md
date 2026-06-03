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
- **Mixed std-cell + one SRAM macro:** the conv engine has a shared 16×16
  multiplier + kernel/result flops **and one OpenRAM SRAM macro**
  (`sky130_sram_1kbyte_1rw1r_32x256_8`, the feature map). So this is a real macro
  flow — place the macro, build the PDN around it, route to it — but small enough
  to finish on a laptop. The floorplan shows the macro as one block with cells
  around it.
- **Macro setup:** `make prep` symlinks the macro `.lef`/`.gds`/`.lib` into
  `04_APR/macros/` from `SRAM_MACRO_DIR` (the sky130 OpenRAM macros that ship with
  OpenLane). `config.json` `MACROS` pins the placement (instance `u_img`) and
  `PDN_MACRO_CONNECTIONS` wires its power. **Adjust `SRAM_MACRO_DIR` / the macro
  paths to your image** — these are image-dependent and not validatable outside
  the container.
- **DRC/LVS:** should be clean/match at sane utilization (`FP_CORE_UTIL` ~35,
  density ~45 — lower than a pure std-cell block to leave room around the macro).
  If a student hits DRC/congestion, lower utilization/density or move the macro.
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
