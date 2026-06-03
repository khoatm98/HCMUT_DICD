# HCMUT_DICD — Digital IC Design: an Open-Source RTL-to-GDSII Course

A complete, self-contained university course that takes students from **writing
Verilog** all the way to a **manufacturable chip layout (GDSII)** — using only
**free, open-source EDA tools**, everything reproducible inside one Docker
container, and friendly to modest laptops and low-bandwidth/offline classrooms.

> Modeled on NTU's CVSD course, re-built on an all-open-source toolchain and
> reorganized around a single **running design** that you carry through every
> stage of the flow.

---

## The big idea: one design, the whole flow

Most courses teach the chip-design flow with a *different* toy at each step. Here
you build **one** design — a small 16-bit CPU called **TinyRISC-16** — and push
that *same* design through every stage. Each homework is the next stage of the
flow applied to the thing you already built:

```
  HW1            HW2              HW3            HW4             HW5            Final
 ┌──────┐      ┌────────┐       ┌────────┐     ┌────────┐      ┌────────┐    ┌────────┐
 │ ALU  │─────▶│  CPU   │──────▶│ Synth  │────▶│ Power  │─────▶│  APR   │───▶│  Full  │
 │      │ reuse│ + MAC  │ same  │(gates) │ same│  opt   │ same │(layout)│    │  flow  │
 │ Q6.10│  ALU │ custom │  RTL  │  +STA  │ net │ VCD/   │ net  │ GDSII  │    │  GDSII │
 │      │      │ instr  │       │        │     │ SAIF   │      │        │    │        │
 └──────┘      └────────┘       └────────┘     └────────┘      └────────┘    └────────┘
 Front-end RTL + verification │  Back-end / physical implementation │ Culmination
```

Because every homework's output is the next homework's input, the final project
is a *culmination*, not a fresh start.

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

> **No Docker?** On Linux a conda env (no root) covers the front-end (HW1/HW2
> sim, Yosys): `bash env/conda/setup.sh && make smoke EDA_ENV=conda`. Use Docker
> for the back-end (STA/power/APR). See [env/README.md](env/README.md).

Full walkthrough (including the browser-based GUI for GTKWave/KLayout):
[docs/00-getting-started.md](docs/00-getting-started.md).
Air-gapped or low-bandwidth campus? [docs/03-offline-deployment.md](docs/03-offline-deployment.md).

---

## Repository layout

```
HCMUT_DICD/
├── env/             # the only thing you install: the pinned Docker image + compose
├── smoke/           # `make smoke` — one-command end-to-end toolchain check
├── common/          # shared, REUSED RTL (ALU, CPU) + flow scripts — the continuity spine
├── hw/
│   ├── hw1-alu/     # HW1: parameterized Q6.10 ALU (design + verification)
│   ├── hw2-cpu/     # HW2: TinyRISC-16 CPU + the MAC custom instruction (reuses HW1 ALU)
│   ├── hw3-synth/   # HW3: synthesis (Yosys/SKY130) + SDC + gate sim + STA
│   ├── hw4-power/   # HW4: power optimization (activity capture, clock gating, PPA)
│   └── hw5-apr/     # HW5: APR to clean GDSII (LibreLane/OpenROAD, KLayout)
├── final-project/   # full RTL-to-GDSII on the small ASIC — the culmination
├── docs/            # getting-started, flow guide, offline deployment, troubleshooting
├── instructor/      # reference solutions, autograder, grading notes (not for students)
├── scripts/         # host helpers (preflight, offline bundle, clean)
└── templates/       # skeletons that keep every module consistent
```

Each `hw/` module is self-contained: `OBJECTIVES.md`, `SPEC.md`, step-by-step
`INSTRUCTIONS.md`, `RUBRIC.md`, a `Makefile` with one-command targets, starter
RTL, a self-checking testbench, and an `artifacts/` folder for what you submit.

---

## The running design at a glance — TinyRISC-16

- **16-bit, single-cycle** CPU (no pipeline/hazards → readable with basic Verilog).
- 8 registers (R0 = 0), Harvard memory, 4-bit opcode.
- **ALU** (built in HW1) supports integer **and** signed **fixed-point Q6.10**
  (6 integer + 10 fraction bits) add/sub/mul with rounding + saturation.
- **Custom instruction = MAC**: `MAC rd, rs, rt → rd = rd + rs*rt` (Q6.10),
  which *reuses* the ALU's multiplier and adder — the heart of how a custom
  instruction is "just a small ALU extension."
- A small, course-provided **assembler + golden ISA simulator** (Python) let you
  write test programs and check the CPU against a reference — fully offline.

Full ISA and rationale: [hw/hw2-cpu/SPEC.md](hw/hw2-cpu/SPEC.md) *(added in the HW2 build)*.

---

## Principles

- **Open-source / free only** — no commercial-tool dependencies, ever.
- **Reproducible** — one pinned container; identical results on every machine.
- **Pedagogical visibility** — you *inspect* intermediate artifacts (netlists,
  floorplans, congestion, timing/power reports), not push a magic button.
- **Continuity** — each homework reuses and extends the previous one.
- **Beginner-friendly** — assumes basic Verilog and digital logic; no back-end
  experience required.

## License & credits

Open educational material (see `LICENSE`). Built on the open-source EDA ecosystem
(Icarus Verilog, Verilator, Yosys, OpenROAD, OpenLane/LibreLane, OpenSTA,
KLayout, Magic, Netgen) and the SkyWater **SKY130** PDK. Course design inspired
by NTU's CVSD.
