# `pdk/` — in-repo SKY130 library subset (vendored)

This directory holds the **minimal SKY130 libraries the flow needs**, kept *in
the repo* so synthesis / STA / gate-sim / APR don't depend on Docker-native
(`/foss/pdks`) or conda-native (`$CONDA_PREFIX/share/pdk`) storage.

It is **populated by a one-time vendoring step** (the files aren't checked in
until you run it on a machine that has a SKY130 PDK):

```bash
bash scripts/vendor-pdk.sh                 # auto-detect PDK ($PDK_ROOT / conda / /foss)
#   or: bash scripts/vendor-pdk.sh /path/to/pdk
git add pdk/ && git commit -m "vendor SKY130 lib subset"
```

After that, every stage Makefile **auto-uses `pdk/`** (via
[`common/flow/pdk.mk`](../common/flow/pdk.mk)) — no `PDK_ROOT` needed. Delete
`pdk/sky130A/` to fall back to an external PDK.

## What lives here (mirrors the PDK layout under `pdk/sky130A/libs.ref/`)

**Already committed — the SRAM hard macro** (≈9.5 MB, see [`NOTICE`](NOTICE) for
provenance + license):
- `sky130_sram_macros/{lib,lef,gds,verilog}/sky130_sram_1kbyte_1rw1r_32x256_8*` —
  the exact OpenRAM macro HW3 (`conv_engine`) and HW5 (APR) instantiate. `pdk.mk`
  resolves `SRAM_MACRO_DIR`/`SRAM_LIB` to this copy automatically, so STA + APR
  find the macro with no external PDK and no Makefile edits.

**Vendored on demand by `scripts/vendor-pdk.sh` — the standard cells** (the bulk;
not in the repo until you run it on a machine that has a SKY130 PDK):
- `sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib` — std-cell timing (synth + STA)
- `sky130_fd_sc_hd/verilog/{sky130_fd_sc_hd.v,primitives.v}` — cell models (gate-sim)
- `sky130_fd_sc_hd/lef/…`, `…/techlef/*.tlef` — abstracts (APR)

`pdk.mk` only switches `PDK_ROOT` to this in-repo `pdk/` once the **std cells**
are present (`sky130_fd_sc_hd/`); a SRAM-macro-only `pdk/` does **not** hijack the
std-cell path — those still come from `$PDK_ROOT` / `/foss/pdks` until vendored.

> Size note: the std-cell `.lib` is ~30 MB, so vendoring the cells adds a few tens
> of MB on top of the committed SRAM macro. That's the cost of a self-contained,
> PDK-path-independent back-end; if you'd rather not commit the cells, leave them
> out and the flow falls back to `$PDK_ROOT` for std cells (the SRAM macro stays
> in-repo regardless).
