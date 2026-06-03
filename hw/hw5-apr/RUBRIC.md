# HW5 — Grading rubric (100 points)

| # | Criterion | Pts | How it's checked |
|---|-----------|-----|------------------|
| 1 | **Flow completes to routed GDSII** | 30 | `make apr`; a `*.gds` is produced under `runs/` |
| 2 | **DRC clean** (0 violations) | 20 | `make summary` / the run's DRC report |
| 3 | **LVS match** (layout ≡ netlist) | 15 | the run's LVS report |
| 4 | **Post-route timing met** (worst slack ≥ 0) | 15 | post-route STA summary |
| 5 | **Stage inspection** — floorplan / congestion / CTS explained, related to the RTL | 15 | submitted screenshots + write-up |
| 6 | **Layout viewed in KLayout** + reproducible `config.json` | 5 | submitted artifact |
| | **Total** | **100** | |

## Notes
- **Functional gate:** items 2–6 require item 1 (a completed routed GDSII).
- Grading rewards a **clean, signed-off** result + correct *explanation* of the
  physical stages — not a particular area/MHz.
- Tuning `FP_CORE_UTIL` / `CLOCK_PERIOD` to fix congestion/timing is expected and
  encouraged; document what you changed and why.
- The design is the unmodified `common/rtl/conv` engine (symlinked) — APR runs
  the same logic verified in HW3.

## Autograde
Check `runs/<tag>/` for a GDS, DRC=0, LVS match, and a non-negative post-route
slack. See `instructor/solutions/hw5-apr/`.
