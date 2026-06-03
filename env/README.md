# Environment (`env/`)

The course runs entirely on open-source tools. Pick **one** of two setups —
both give you the same tools and the same SKY130 PDK, and both are driven by the
top-level `Makefile`.

| Path | When to use | Folder |
|------|-------------|--------|
| **Docker** (default) | Docker is available; you want the most reproducible, cross-OS setup with a built-in browser GUI for GTKWave/KLayout. | [`env/docker/`](docker/) |
| **Conda** | Docker is blocked/unavailable (locked-down lab, HPC, no admin). **Linux x86_64.** | [`env/conda/`](conda/) |

The Makefile selects the path with `EDA_ENV`:

```bash
make smoke                 # EDA_ENV=docker (default)
make smoke EDA_ENV=conda   # use the conda env instead
```

Shared, environment-independent bits live here:

| File | What it is |
|------|------------|
| `scripts/healthcheck.sh` | Prints every tool's version (works in either env). |
| `pdk/pdk.lock` | The exact PDK variant the course standardizes on. |

## Quick start

**Docker:**
```bash
make image-pull && make healthcheck && make smoke
```
**Conda (Linux):**
```bash
bash env/conda/setup.sh && make healthcheck EDA_ENV=conda && make smoke EDA_ENV=conda
```

GUI tools, offline mirroring, and troubleshooting:
[../docs/00-getting-started.md](../docs/00-getting-started.md),
[../docs/03-offline-deployment.md](../docs/03-offline-deployment.md).
