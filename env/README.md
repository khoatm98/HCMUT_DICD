# Environment (`env/`)

This is the **only thing you install**: Docker, then one pinned image that
already contains every tool the course uses **and** the SKY130 PDK.

| File | What it is |
|------|------------|
| `docker-compose.yml` | Defines the `eda` service (the container) with the repo mounted at `/foss/designs/HCMUT_DICD`. |
| `.env.example` | Copy to `env/.env` to override the image tag, ports, or the VNC password. |
| `pdk/pdk.lock` | Records the exact PDK variant the course standardizes on (`sky130A` / `sky130_fd_sc_hd`). |
| `scripts/healthcheck.sh` | Prints every tool's version from inside the container (used by `make healthcheck`). |

## Quick start (from the repo root)

```bash
make image-pull     # pull the pinned image once (~4 GB; one time)
make healthcheck    # confirm every tool is callable
make smoke          # run a tiny design through the WHOLE flow
make shell          # drop into the course shell when you're ready to work
```

GUI tools (GTKWave, KLayout) work through a **browser desktop**: run
`make env-up`, then open <http://localhost:8888> (password: `hcmut`). No XQuartz
or VcXsrv setup required. See [../docs/00-getting-started.md](../docs/00-getting-started.md).

For air-gapped / low-bandwidth campuses, see
[../docs/03-offline-deployment.md](../docs/03-offline-deployment.md).
