# `pdk/` — in-repo SKY130 library subset (vendored)

This directory holds the **SKY130 libraries the flow needs**, kept *in the repo*
so the **whole flow — synth / STA / gate-sim / power / APR (RTL→GDSII) — runs with
no PDK install** — students don't fight Docker-native (`/foss/pdks`) or
conda-native (`$CONDA_PREFIX/share/pdk`) storage. The subset **is already
committed** (≈78 MB); every stage Makefile **auto-uses it** via
[`common/flow/pdk.mk`](../common/flow/pdk.mk) — no `PDK_ROOT` needed.

To **refresh or re-vendor** it on a machine that has a SKY130 PDK:

```bash
bash scripts/vendor-pdk.sh                 # auto-detect PDK ($PDK_ROOT / conda / /foss)
#   or: bash scripts/vendor-pdk.sh /path/to/pdk
git add pdk/ && git commit -m "refresh SKY130 lib subset"
```

Delete `pdk/sky130A/...` to fall back to an external PDK.

## What lives here (mirrors the PDK layout under `pdk/sky130A/libs.ref/`)

**Committed (≈78 MB total) — see [`NOTICE`](NOTICE) for provenance + license:**
- `sky130_fd_sc_hd/` — **standard-cell subset** for the whole digital flow:
  - `lib/…__{tt_025C_1v80,ff_n40C_1v95,ss_100C_1v60}.lib` — 3 sign-off corners
    (typical/fast/slow) for synth + multi-corner STA
  - `verilog/{sky130_fd_sc_hd.v,primitives.v}` — cell models (gate-sim)
  - `lef/{sky130_fd_sc_hd,sky130_ef_sc_hd}.lef`, `techlef/*.tlef` — abstracts (APR)
  - `gds/sky130_fd_sc_hd.gds` — std-cell layout (final GDS merge); `cdl/…cdl` — LVS
- `libs.tech/{magic,klayout,netgen,openlane,combined}` — the APR tool decks
- `sky130_sram_macros/{lib,lef,gds,verilog}/sky130_sram_1kbyte_1rw1r_32x256_8*` —
  the OpenRAM macro HW3 (`conv_engine`) and HW5 (APR) instantiate.

`pdk.mk` auto-resolves everything to these in-repo copies — no `PDK_ROOT` to set,
no Makefile edits:
- **`STD_CELL_DIR` → `LIB`/`CELLS`** and **`SRAM_MACRO_DIR`/`SRAM_LIB`** for
  synth / STA / gate-sim / power;
- **`PDK_ROOT` → this `pdk/`** for APR (it flips to in-repo only because
  `libs.tech/` is present), exported to LibreLane by the `04_APR` Makefiles.

So **the full flow — including HW5/Final APR (RTL→GDSII) — runs with no PDK
install.** Delete `pdk/sky130A/...` to fall back to an external PDK.

> **Still a SUBSET, not a full PDK:** 3 sign-off corners (of 18), only the digital
> `libs.tech` decks, only `sky130_fd_sc_hd`. That's plenty for the course; for full
> multi-corner sign-off, other cell libraries, or analog tools, fetch a complete
> PDK with `volare`/`ciel` or the conda `full` profile (then point `PDK_ROOT` at it).
