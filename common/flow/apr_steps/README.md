# APR, one step at a time

These are the back-end (place & route) stages of HW5, split into small,
readable scripts so you can **see the flow**. The headless `make apr-conda`
runs them all in order (via [`run_all.tcl`](run_all.tcl), which
[`../apr_openroad.tcl`](../apr_openroad.tcl) calls); in the **GUI** you run them
one at a time and watch each stage appear.

| Step | File | What it does |
|------|------|--------------|
| 0 | [`00_load.tcl`](00_load.tcl) | **Load** the libraries (LEF + Liberty) + netlist + SDC. OpenROAD has no "import design" form — this *is* it. |
| 1 | [`01_floorplan.tcl`](01_floorplan.tcl) | Floorplan: die/core from utilization, placement rows, routing tracks. |
| 2 | [`02_place_io_macro.tcl`](02_place_io_macro.tcl) | I/O pins, then drop the SRAM macro at a fixed corner (`place_macro`). |
| 3 | [`03_pdn.tcl`](03_pdn.tcl) | Tap cells + power delivery network (rails + met4/met5 straps). |
| 4 | [`04_place.tcl`](04_place.tcl) | Global + detailed placement of the std cells. |
| 5 | [`05_cts.tcl`](05_cts.tcl) | Clock tree synthesis + propagated clock. |
| 6 | [`06_route.tcl`](06_route.tcl) | Global + detailed routing (the long stage). |
| 7 | [`07_finish.tcl`](07_finish.tcl) | Filler cells, write DEF/netlist/DB, report timing. |

`_config.tcl` just sets shared knobs (utilization, density, macro name/location)
from environment variables; every step sources it, so the steps are
self-contained and safe to re-run.

## Run it step by step in the GUI

You need a Qt-enabled OpenROAD (`openroad -gui`) and a display (`ssh -Y`, or add
`-platform vnc`). From `hw/hw5-apr/04_APR`:

```bash
make gui-steps OPENROAD=$HOME/openroad-install/bin/openroad
```
This synthesizes the netlist (if needed), opens the GUI with **step 0 already
loaded**, and prints the exact `source …/01_floorplan.tcl … 07_finish.tcl`
lines. Paste them into the **Scripting** console one at a time and watch the
canvas update after each. Each step also prints what it did and the next one to
run.

## Run the whole thing live (no stopping)

```bash
make gui-apr OPENROAD=$HOME/openroad-install/bin/openroad
```

## Headless (no GUI)

```bash
make apr-conda           # runs steps 0..7, then magic streams the GDS
```

> The knobs (`CORE_UTIL`, `PLACE_DENSITY`, `MACRO_LOC`, …) are environment
> variables the Makefile sets. To experiment, e.g. `make gui-steps MACRO_LOC="60 60"`.
