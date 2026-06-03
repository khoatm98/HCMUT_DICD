# HCMUT_DICD — Digital IC Design: an Open-Source RTL-to-GDSII Course

A complete, self-contained university course that takes students from **writing
Verilog** all the way to a **manufacturable chip layout (GDSII)** — using only
**free, open-source EDA tools**, everything reproducible inside one Docker
container, and friendly to modest laptops and low-bandwidth/offline classrooms.

> Modeled on NTU's CVSD course, re-built on an all-open-source toolchain and
> reorganized around a single **running design** that you carry through every
> stage of the flow.

---

## How the course is built

A front-end pair builds design + verification habits, then each back-end
homework is a focused, **standalone** design that spotlights one stage of the
flow (the NTU-CVSD model), culminating in a full RTL-to-GDSII capstone:

```
 FRONT-END (design + verify)        BACK-END (one flow stage each)          CAPSTONE
 ┌──────┐   ┌──────────┐    ┌────────────┐ ┌────────────┐ ┌────────────┐  ┌─────────────┐
 │ HW1  │──▶│  HW2     │    │   HW3      │ │   HW4      │ │   HW5      │  │   Final     │
 │ ALU  │alu│ CPU+MAC  │    │ conv eng.  │ │ IoT filter │ │ conv eng.  │  │ MIMO sphere │
 │ Q6.10│reuse│(reuses │    │ SYNTHESIS  │ │  POWER     │ │ APR→GDSII  │  │  decoder    │
 │      │   │ HW1 ALU) │    │(Yosys+STA) │ │(VCD/SAIF)  │ │(OpenROAD)  │  │ RTL→GDSII   │
 └──────┘   └──────────┘    └────────────┘ └────────────┘ └────────────┘  └─────────────┘
   front-end continuity        standalone designs, one per back-end stage    everything
```

**HW1 → HW2** share a running design — the Q6.10 ALU you build in HW1 becomes the
execution unit of the TinyRISC-16 CPU in HW2 (and the CPU adds a MAC custom
instruction). **HW3–HW5** are standalone designs, each spotlighting one back-end
stage: a **convolution engine** (synthesized in HW3, placed-and-routed to GDSII
in HW5) and an **IoT data filter** (power-optimized in HW4). The **Final** is a
new **MIMO sphere-decoder** taken the whole way, applying every skill — graded as
a competition on detection quality (PSNR) plus area, time, and power.

---

## The RTL-to-GDSII flow and the tools at each stage

```
            ┌─────────────────────────────────────────────────────────────────┐
            │                     RTL-to-GDSII flow                            │
            └─────────────────────────────────────────────────────────────────┘

  Verilog RTL ──▶ Simulation ──▶ Synthesis ──▶ Gate-level ──▶ Static Timing
   (design)        (verify)     (RTL→gates)    sim (equiv.)    Analysis (STA)
      │           Icarus /         Yosys         Icarus           OpenSTA
      │           Verilator       + ABC        (+SKY130 cells)
      │           GTKWave
      │                                                              │
      ▼                                                              ▼
  Power analysis ◀── Switching activity (VCD/SAIF) ◀────────── (optimize) ──┐
   OpenSTA               from gate-level sim                                 │
      │                                                                      │
      ▼                                                                      │
  Floorplan ─▶ Power plan ─▶ Placement ─▶ CTS ─▶ Routing ─▶ DRC/LVS ─▶ GDSII │
   └──────────────────── OpenLane / LibreLane (OpenROAD) ─────────┘  KLayout │
                                                                  Magic/Netgen
   HW1 ── HW2 ──────────── HW3 ──────────────── HW4 ───────── HW5 ───────────┘
```

| Stage | Open-source tool | Homework |
|-------|------------------|----------|
| RTL design | Verilog | HW1 (ALU), HW2 (CPU) |
| RTL simulation / verification | **Icarus Verilog**, **Verilator** | HW1, HW2 |
| Waveform inspection | **GTKWave** | HW1, HW2 |
| Logic synthesis | **Yosys + ABC** | HW3 |
| Timing constraints (SDC) + STA | **OpenSTA** | HW3, HW5 |
| Gate-level simulation | **Icarus** + SKY130 cell models | HW3 |
| Power (activity-driven) | **OpenSTA** (+ VCD/SAIF) | HW4 |
| Place & route (RTL→GDSII) | **OpenLane / LibreLane → OpenROAD** | HW5 |
| Physical verification | **Magic** (DRC), **Netgen** (LVS) | HW5 |
| Layout viewing | **KLayout** | HW5 |
| Process design kit | **SkyWater SKY130** | HW3–HW5 |

Everything above ships in **one container image** (`hpretl/iic-osic-tools`) with
the SKY130 PDK baked in — no per-tool installation.

---

## Getting started (3 commands)

You only need **Docker** on the host. Then, from the repo root:

```bash
make image-pull     # pull the pinned EDA image once (~4 GB)
make healthcheck    # confirm every tool is callable inside the container
make smoke          # push a tiny design through the WHOLE flow to prove setup
```

When `make smoke` prints `SMOKE TEST PASSED`, you're ready for HW1.

> **No Docker?** On Linux a conda env (no root) runs the whole flow: the
> front-end always (sim + Yosys synthesis), and `PROFILE=full bash
> env/conda/setup.sh` adds the back-end (OpenROAD/Magic/Netgen + SKY130 PDK;
> STA/power via OpenROAD, APR via OpenROAD-flow-scripts). The full profile pins
> **python 3.7** (the resolvable OpenROAD build needs it) and leaves KLayout as a
> separate install. See [env/conda/README.md](env/conda/README.md).

Full walkthrough (including the browser-based GUI for GTKWave/KLayout):
[docs/00-getting-started.md](docs/00-getting-started.md).
Air-gapped or low-bandwidth campus? [docs/03-offline-deployment.md](docs/03-offline-deployment.md).

---

## Repository layout

```
HCMUT_DICD/
├── env/             # the only thing you install: the pinned Docker image + compose
├── smoke/           # `make smoke` — one-command end-to-end toolchain check
├── common/          # shared RTL: HW1 ALU + HW2 CPU (front-end), conv engine, IoT filter + flow scripts
├── hw/
│   ├── hw1-alu/     # HW1: parameterized Q6.10 ALU (design + verification)
│   ├── hw2-cpu/     # HW2: TinyRISC-16 CPU + MAC custom instruction (reuses HW1 ALU)
│   ├── hw3-synth/   # HW3: SYNTHESIS of a 3x3 convolution engine (Yosys/SKY130 + SDC + gate sim + STA)
│   ├── hw4-power/   # HW4: POWER opt of an IoT data filter (activity capture, clock gating, PPA)
│   └── hw5-apr/     # HW5: APR of the conv engine to clean GDSII (LibreLane/OpenROAD, KLayout)
├── final-project/   # FINAL: MIMO sphere-decoder, full RTL-to-GDSII (PSNR + area/time/power)
├── docs/            # getting-started, flow guide, offline deployment, troubleshooting
├── instructor/      # reference solutions, autograder, grading notes (not for students)
├── scripts/         # host helpers (preflight, offline bundle, clean)
└── templates/       # skeletons that keep every module consistent
```

Each `hw/` module is self-contained and organized into **CVSD-style stage
directories**: `00_TB/` (testbench + committed public test patterns), `01_RTL/`
(the starter RTL you edit + its Makefile), and back-end stages `02_SYN/`,
`03_GATE/`, `04_APR/`, `06_POWER/` where applicable — plus `SPEC.md`,
`OBJECTIVES.md`, `INSTRUCTIONS.md`, `RUBRIC.md` at the module root and an
`artifacts/` folder. Run each stage from its directory (e.g. `cd 01_RTL && make
vsim`). Patterns are pre-committed; the generator scripts are instructor-private
(graded later with hidden patterns).

---

## The designs at a glance

**Front-end (HW1–HW2) — TinyRISC-16:** a 16-bit single-cycle CPU (8 regs, R0=0,
Harvard memory, 4-bit opcode). The HW1 **ALU** (integer **and** signed **Q6.10**
fixed-point add/sub/mul with rounding + saturation) becomes the CPU's execution
unit in HW2, which adds the **MAC** custom instruction (`rd += rs*rt`, Q6.10),
reusing the ALU multiplier. A Python **assembler + golden ISA simulator** verify
it, fully offline.

**Back-end standalone designs (CVSD-style — one per flow stage):**
- **HW3 — 3×3 convolution engine** (Q6.10, 8×8 image, zero-pad): the *synthesis*
  subject — one shared multiplier + sequential MAC + flop arrays, macro-free.
- **HW4 — IoT data filter** (CRC-8 / Gray↔binary / LFSR scramble): the *power*
  subject — idle function units enable clock gating + operand isolation.
- **HW5** places-and-routes the **HW3 convolution engine** to a clean GDSII.

**Final — MIMO sphere-decoder:** QR done in software; the hardware searches
`min ‖ỹ − R·s‖²`. Taken RTL→GDSII and graded as a competition on **PSNR** plus
**area, time, power**.

Per-design specs live in each module's `SPEC.md`.

---

## Principles

- **Open-source / free only** — no commercial-tool dependencies, ever.
- **Reproducible** — one pinned container; identical results on every machine.
- **Pedagogical visibility** — you *inspect* intermediate artifacts (netlists,
  floorplans, congestion, timing/power reports), not push a magic button.
- **Continuity where it teaches** — HW1→HW2 reuse one design (ALU→CPU); the
  back-end homeworks are focused standalone designs (CVSD-style), one per flow stage.
- **Beginner-friendly** — assumes basic Verilog and digital logic; no back-end
  experience required.

## License & credits

Open educational material (see `LICENSE`). Built on the open-source EDA ecosystem
(Icarus Verilog, Verilator, Yosys, OpenROAD, OpenLane/LibreLane, OpenSTA,
KLayout, Magic, Netgen) and the SkyWater **SKY130** PDK. Course design inspired
by NTU's CVSD.
