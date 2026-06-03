# `src/` — APR design sources

Populated by `make prep` with symlinks to the canonical convolution-engine RTL
in [`common/rtl/conv/`](../../../common/rtl/conv/) — the **same** design you
built and synthesized in HW3. Keeping links (not copies) preserves the single
source of truth: APR runs exactly the verified engine.

LibreLane reads `dir::src/*.v` with `dir::src` on the include path (see
`../config.json`). The symlinks are git-ignored; run `make prep` (or `make apr`,
which depends on it).
