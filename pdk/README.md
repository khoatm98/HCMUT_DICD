# `pdk/` — in-repo SKY130 library subset (vendored)

This directory holds the **minimal SKY130 libraries the flow needs**, kept *in
the repo* so **synth / STA / gate-sim / power run with no PDK install** — students
don't fight Docker-native (`/foss/pdks`) or conda-native (`$CONDA_PREFIX/share/pdk`)
storage. The subset **is already committed** (≈28 MB); every stage Makefile
**auto-uses it** via [`common/flow/pdk.mk`](../common/flow/pdk.mk) — no `PDK_ROOT`
needed.

To **refresh or re-vendor** it on a machine that has a SKY130 PDK:

```bash
bash scripts/vendor-pdk.sh                 # auto-detect PDK ($PDK_ROOT / conda / /foss)
#   or: bash scripts/vendor-pdk.sh /path/to/pdk
git add pdk/ && git commit -m "refresh SKY130 lib subset"
```

Delete `pdk/sky130A/...` to fall back to an external PDK.

## What lives here (mirrors the PDK layout under `pdk/sky130A/libs.ref/`)

**Committed (≈28 MB total) — see [`NOTICE`](NOTICE) for provenance + license:**
- `sky130_fd_sc_hd/` — **standard-cell subset** so synth/STA/gate-sim/power run with
  **no PDK install**:
  - `lib/sky130_fd_sc_hd__tt_025C_1v80.lib` (12 MB) — std-cell timing (synth + STA)
  - `verilog/{sky130_fd_sc_hd.v,primitives.v}` — cell models (gate-sim)
  - `lef/sky130_fd_sc_hd.lef`, `techlef/*.tlef` — abstracts
- `sky130_sram_macros/{lib,lef,gds,verilog}/sky130_sram_1kbyte_1rw1r_32x256_8*` —
  the OpenRAM macro HW3 (`conv_engine`) and HW5 (APR) instantiate.

`pdk.mk` resolves the **std-cell files** (`STD_CELL_DIR` → `LIB`/`CELLS`) and the
**SRAM macro** (`SRAM_MACRO_DIR`/`SRAM_LIB`) to these in-repo copies automatically —
no `PDK_ROOT`, no Makefile edits. Delete `pdk/sky130A/...` to fall back to an
external PDK.

> **This is a SUBSET, not a full PDK** (one timing corner; no std-cell GDS; no
> `libs.tech`). It covers **synth · STA · gate-sim · power** offline. **Full APR**
> (HW5 / Final, via LibreLane/OpenROAD-flow-scripts) still needs a **complete
> external PDK** — `pdk.mk` deliberately leaves `PDK_ROOT` pointing at that
> (`$PDK_ROOT` / `/foss/pdks`), never at this subset. Fetch a full PDK with
> `volare`/`ciel` or the conda `full` profile.
