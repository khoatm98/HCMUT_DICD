# HW3 — Step-by-step instructions

> Run the **functional** steps (1–4) with a local Verilator + Python install or
> the front-end conda env. Run the **back-end** steps (5–7: synth/STA/gate-sim)
> inside the EDA container (`make shell`) — they need Yosys, OpenSTA, and the
> SKY130 PDK. Run everything from `hw/hw3-synth/`.

## 0. Orient yourself

```bash
cd hw/hw3-synth
ls
```
- `rtl/conv_engine.v` — **the file you edit** (the starter stub).
- `constraints/conv.sdc` — **the second file you edit** (timing constraints).
- `tb/conv_engine_tb.v` — the self-checking testbench (don't edit).
- `tools/gen_golden.py` — the Python reference model + stimulus/expected generator.
- `SPEC.md` — protocol, Q6.10 rules, microarchitecture. **Read it first.**

## 1. Generate the golden stimulus + expected outputs

```bash
make golden
```
This writes `golden/conv_stim.hex` (the input streams) and `golden/conv_exp.hex`
(expected outputs) plus `golden/conv_count.vh` (sizes the TB includes). The
Python model in `tools/gen_golden.py` is the source of truth.

## 2. Run the check once to see it fail

```bash
make vsim        # Verilator (fast); or `make sim` for Icarus
```
The starter jumps straight to OUTPUT with all-zero results, so you'll see many
mismatches and `RESULT: FAIL`. That's expected — now make it pass.

## 3. Implement the COMPUTE datapath

Edit `rtl/conv_engine.v`. The FSM, LOAD, OUTPUT, and DONE phases are provided;
fill in the TODOs per [SPEC.md](SPEC.md):

- **Tap → (dr,dc) mapping.** For `tap = 0..8`, set `dc = (tap mod 3) − 1` and
  `dr = (tap / 3) − 1`, each in `{−1,0,1}`. (Decode from the full `tap` value —
  `tap[1:0]` is mod-4, **not** mod-3.) `nrow = prow + dr`, `ncol = pcol + dc`.
  Zero padding is already wired (`pixval` is 0 when out of bounds).
- **Shared multiplier.** `prod = $signed(kern[tap]) * $signed(pixval)` (Q12.20).
- **Sequential accumulate (COMPUTE state).** While `tap < 9`: add the
  sign-extended product into the wide `acc` and increment `tap`. At `tap == 9`:
  write `res[pix] <= pixres`, clear `acc`/`tap`, advance `pix`; when the last
  pixel is done, go to `OUTPUT`.
- **Per-pixel round + saturate.** Complete `pixres`: clamp `accr` to
  `[SMIN, SMAX]` (mirror the ALU FXMUL saturation). `accr` is already
  `(acc + RND) >>> FRAC`.

Tips: accumulate **all nine** products before rounding; round half-up by the
`+ RND` that's already declared; saturate exactly like `alu.v`.

## 4. Iterate until it passes

```bash
make vsim
```
Repeat edit → run until you see:
```
Checked 8 case(s) x 64 pixels, 0 mismatch(es).
RESULT: PASS
```
On a mismatch the TB prints `case`, `pixel`, your value, and the expected one —
start from the first failure. Sanity-check against the reference any time:
```bash
make ref         # runs the same TB against common/rtl/conv/conv_engine.v
make wave        # sim/conv_engine.vcd in GTKWave (watch the FSM + acc)
make lint        # aim for no warnings in the finished design
```

## 5. Write the timing constraints

Edit `constraints/conv.sdc` (TODOs):
- pick a clock period (`CLK_PERIOD`, ns) — the critical path is ~one 16×16
  signed multiply plus the wide accumulate add; 20 ns (50 MHz) is a safe start;
- add `set_input_delay` for `rst_n`, `i_valid`, `i_data[*]`;
- add `set_output_delay` for `all_outputs` (`o_valid`, `o_data`, `o_done`, `o_busy`).

Do **not** constrain the clock port as a data input.

## 6. Synthesize, check timing, prove equivalence (in the container)

```bash
make synth       # Yosys -> build/conv_netlist.v + build/conv_area.rpt
make sta         # OpenSTA using your constraints/conv.sdc -> build/conv_sta.rpt
make gl-sim      # gate-level sim of the netlist vs the SAME golden
make all         # synth + sta + gl-sim in one shot
```
- In `build/conv_area.rpt`, note the **cell count / area** and which cells
  dominate (you should see flip-flops for the arrays + a multiplier's worth of
  combinational cells).
- In `build/conv_sta.rpt`, confirm **positive** setup (`max`) and hold (`min`)
  slack. If setup is negative, relax `CLK_PERIOD`; understand the critical path.
- `make gl-sim` must print `RESULT: PASS` — that's your **gate-equivalence**
  proof (the netlist matches the RTL on the golden vectors).

## 7. What to submit

Put these in `artifacts/` (see [RUBRIC.md](RUBRIC.md)):
- your completed `rtl/conv_engine.v` and `constraints/conv.sdc`,
- the `make vsim` (or `make sim`) log showing `RESULT: PASS`,
- the `make gl-sim` log showing `RESULT: PASS` (gate equivalence),
- `build/conv_area.rpt` and `build/conv_sta.rpt` (area + slack),
- a 4–6 sentence note: your clock period + worst slack, the dominant cells in
  the area report, and how the sequential MAC trades area for cycles.

## Common pitfalls

- **Round-then-accumulate.** Rounding each product back to Q6.10 before summing
  loses precision — accumulate the nine **Q12.20** products first, round once.
- **`tap[1:0]` for the column offset.** That's mod-4; you need `tap mod 3`.
- **Forgetting saturation.** Big kernels × big pixels overflow 16 bits — clamp
  to `[0x8000, 0x7FFF]` (the `saturate` case fails loudly otherwise).
- **Zero padding off-by-one.** Corners see 4 neighbours, edges 6, interior 9.
- **Latches.** Assign every reg on every path (the `default`/else branches) or
  synthesis infers a latch — caught here, not silently passed.
- **Negative slack in STA.** Loosen the clock period and re-read the critical
  path rather than over-constraining the I/O delays.
- **Changing the interface.** Breaks the TB, the netlist port list (gl-sim), and
  HW5 → no credit.
