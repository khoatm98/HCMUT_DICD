# HW5 — Step-by-step instructions

> APR is heavy → easiest in **Docker**: from the repo root `make shell`, then
> `cd hw/hw5-apr` (or just `make hw5` to run the default flow in the container).
> You do **not** need to install a PDK — the SKY130 std cells, SRAM macro, and the
> `libs.tech` APR decks are committed in [`pdk/`](../../pdk/) (3 sign-off corners)
> and the `04_APR` Makefile points LibreLane at them automatically. You only need
> the APR **tools** (the Docker image, or LibreLane via Nix / OpenROAD-flow on conda).

## 1. Run the flow

```bash
make apr
```
`make prep` first symlinks the conv-engine RTL into `src/`, then LibreLane runs
the whole flow into a timestamped `runs/<tag>/` directory. First run is slower
(tool/PDK warm-up); the design itself is small.

## 2. Inspect each stage (the point of this lab)

```bash
make inspect        # prints where the per-stage artifacts live
```
Open and look at, in `runs/<tag>/`:
- **Floorplan** — die/core, rows, I/O placement.
- **Placement / congestion** — where cells landed; congestion heatmap (hot spots
  predict routing trouble).
- **CTS** — the clock tree fanning out to all storage flops.
- **Routed layout** — metal layers.

## 3. Signoff

```bash
make summary        # post-route timing + DRC/LVS status
```
Confirm: **DRC = 0 violations**, **LVS = match**, and post-route **worst slack ≥ 0**.
If timing fails, loosen `CLOCK_PERIOD` in `config.json`; if routing is congested,
lower `FP_CORE_UTIL` / `PL_TARGET_DENSITY_PCT` and re-run.

## 4. View the layout

```bash
make klayout        # opens the final GDS
```
Find the **SRAM macro** (the big rectangular block — the feature-map buffer),
the multiplier, and the kernel/result flops placed around it; note how the macro
dominates the floorplan and how routing reaches its pins.

## 5. Submit (see [RUBRIC.md](RUBRIC.md))
In `artifacts/`: screenshots (floorplan, congestion, routed layout), the DRC/LVS
status, the post-route timing summary, your final `config.json`, and a short
write-up relating the layout to the design.

## Conda back-end (no Docker): Yosys → OpenROAD → Magic
LibreLane isn't reliably installable on conda, so the repo ships its **own**
transparent conda flow — each stage is a readable script in
[`common/flow/`](../../common/flow/), no orchestrator black box:

```bash
make apr-conda        # RTL -> GDS with the conda EDA env (yosys + openroad + magic)
```
What it does (see [`common/flow/apr_openroad.tcl`](../../common/flow/apr_openroad.tcl)):
1. **yosys** synthesizes `conv_engine` against the in-repo std-cell `.lib` + SRAM `.lib`;
2. **OpenROAD** floorplans, places the SRAM macro (`place_macro`), drops tapcells +
   the PDN, global/detailed-places the std cells, runs CTS, then global + detailed
   routing — writing `build/conv.def`, `build/conv.odb`, and `build/conv.apr.v`;
3. **magic** streams the routed DEF + the std-cell/SRAM GDS into `build/conv.gds`.

Outputs land in `build/`: `conv_netlist.v`, `conv.def`, `conv.odb`,
`conv.gds`, `conv.drc.rpt`, plus `apr_conda.log` (look for `report_wns` /
`report_tns` — both should be `0.00` for the default 45 ns clock). The route is
**cached**: re-running `make apr-conda` only re-routes if the RTL changed.

> The conda EDA `openroad` has **no GUI** (`openroad -gui` → "GUI disabled"). The
> headless flow above still works; for the **interactive GUI** below you need a
> Qt-enabled OpenROAD build (point `OPENROAD=` at it).

## Interactive APR in the OpenROAD GUI (step by step)
The GUI lets you *watch* the back-end happen and inspect the result. You need a
Qt-enabled OpenROAD and a display.

**Display options (headless box, e.g. dcs-gpu01):**
- `ssh -Y you@host` then run the GUI normally — Qt uses X11 forwarding.
- Or render to a built-in VNC server (no X forwarding): add `-platform vnc` to the
  `openroad` command, then tunnel `ssh -L 5900:localhost:5900 you@host` and point a
  VNC client at `localhost:5900`.

**A. Watch the whole flow build, live:**
```bash
make gui-apr OPENROAD=$HOME/openroad-install/bin/openroad
```
This synthesizes headlessly, then runs the same `apr_openroad.tcl` *inside* the GUI.
Each stage renders as it finishes — die/rows appear, the SRAM macro lands in the
lower-left, std cells fill in, the clock tree fans out, then metal routing. The
window stays open at the end for inspection.

**B. Or step through it yourself** (most instructive):
```bash
make gui-steps OPENROAD=$HOME/openroad-install/bin/openroad
```
This opens the GUI with the libraries + design **already loaded** (step 0) and
prints the `source …/01_floorplan.tcl … 07_finish.tcl` lines. Paste them into the
**Scripting** console one at a time and watch the canvas update after each — every
step also prints what it did and which one to run next. Each stage is one small
readable file in [`common/flow/apr_steps/`](../../common/flow/apr_steps/) (see its
[README](../../common/flow/apr_steps/README.md)):

| Step | Stage |
|---|---|
| `00_load` | load LEF + Liberty + netlist + SDC (the "import design") |
| `01_floorplan` | die/core + rows + tracks |
| `02_place_io_macro` | I/O pins, then drop the SRAM macro |
| `03_pdn` | tap cells + power grid |
| `04_place` | global + detailed std-cell placement |
| `05_cts` | clock tree synthesis |
| `06_route` | global + detailed routing (the long one) |
| `07_finish` | fill, write DEF/DB, report timing |

Use the **Display Control** panel (left) to toggle layers/instances, and **click
any instance/net** to inspect it in the Inspector.

**C. Re-open an already-routed result (fast, no re-route):**
```bash
make gui-view OPENROAD=$HOME/openroad-install/bin/openroad   # reads build/conv.odb
```
To save a layout image, run `save_image layout.png` in the GUI's Tcl console once
the window is up, or use **File → Save Image**.

## Common pitfalls
- **Resource/time** — APR is RAM-hungry; close other apps, ensure ≥ 8 GB.
- **Include dir** — `conv_engine.v` needs `conv_defs.vh`; `make prep` symlinks
  both into `src/` and `config.json` sets `VERILOG_INCLUDE_DIRS: dir::src`.
- **Timing fail** — start from your HW3 closing period; single-stage logic here
  is simple, so it should close comfortably.
- **DRC/LVS fail on first try** — usually utilization too high → congestion;
  lower density and re-run.
