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

## What gets vendored (mirrors the PDK layout under `pdk/sky130A/libs.ref/`)
- `sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib` — std-cell timing (synth + STA)
- `sky130_fd_sc_hd/verilog/{sky130_fd_sc_hd.v,primitives.v}` — cell models (gate-sim)
- `sky130_fd_sc_hd/lef/…`, `…/techlef/*.tlef` — abstracts (APR)
- `sky130_sram_macros/{lib,lef,gds}/sky130_sram_1kbyte_1rw1r_32x256_8*` — the HW3/HW5 SRAM macro

> Size note: the std-cell `.lib` is ~30 MB, so committing `pdk/` adds a few tens
> of MB to the repo. That's the cost of a self-contained, PDK-path-independent
> back-end; if you'd rather not commit it, leave `pdk/` empty and the flow falls
> back to `$PDK_ROOT`.
