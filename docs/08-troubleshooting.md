# Troubleshooting (modest-laptop edition)

Most problems are environment, not your design. Work top to bottom.

## Setup / Docker

**`make image-pull` is slow or fails.**
Big download (~4 GB). On a weak network, use the offline bundle your instructor
mirrored — see [03-offline-deployment.md](03-offline-deployment.md). If a
corporate proxy blocks Docker Hub, the local-registry option there also helps.

**`docker: permission denied` (Linux).**
Add yourself to the docker group: `sudo usermod -aG docker $USER`, then log out
and back in (or `newgrp docker`).

**`make smoke` says `librelane: command not found`.**
You ran it on the host instead of in the container. Use `make smoke` (which
enters the container) — not `cd smoke && make all` on the host.

## Resources

**Routing/`make smoke` is very slow or the machine freezes.**
APR is the heaviest stage. Close other apps; ensure ≥ 8 GB RAM and a few GB of
free swap. On Docker Desktop (macOS/Windows), raise the VM's CPU/RAM limits in
Settings → Resources.

**"No space left on device."**
The image is ~20 GB on disk plus run artifacts. Free space, then
`docker system prune` to reclaim old layers. `make clean` removes course build
files.

## Simulation

**Testbench "passes" but nothing was checked.**
The convention is a single `RESULT: PASS` / `RESULT: FAIL` line, and the
Makefiles grep for it. If your run shows no `RESULT:` line, your testbench
exited early — check for a missing `$finish` or a stuck wait.

**Icarus vs Verilator disagree.**
Verilator is stricter. If `make lint` complains, fix it — it usually catches a
real width/latch bug Icarus silently tolerated. For gate-level sim, prefer
Icarus (SKY130 cell models with timing constructs run more naturally there).

## Synthesis / timing

**Yosys reports latches.**
You have an incompletely-assigned signal in a combinational block (a missing
`else` or `default`). Give every output a value on every path.

**STA shows negative slack (WNS < 0).**
A path is too slow for the clock. Either relax `CLOCK_PERIOD` in your SDC (this
is a teaching flow — a slow single-cycle CPU is expected) or simplify the
critical path. Read which path with `report_checks`.

## GUI

**GTKWave/KLayout won't open.**
Use the browser desktop: `make env-up`, then <http://localhost:8888>
(password `hcmut`). Avoid fighting host X11 unless you're on Linux.

---

Still stuck? Re-run `make healthcheck` and note the first stage that fails — that
narrows it to one tool.
