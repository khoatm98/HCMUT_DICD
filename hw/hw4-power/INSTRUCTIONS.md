# HW4 — Step-by-step instructions

> Functional work (steps 0–5) runs locally with **Verilator/Icarus**.
> The power flow (steps 6–9) needs the **EDA container** (Yosys, Icarus, OpenSTA,
> SKY130 PDK): from the repo root run `make shell`, then `cd hw/hw4-power`.
>
> This homework is organized as numbered stage directories
> (`00_TB/ 01_RTL/ 02_SYN/ 03_GATE/ 06_POWER/`); you run each command from inside
> the stage directory shown.

## 0. Orient yourself

```bash
cd hw/hw4-power
ls
```
- `01_RTL/iotdf.v` — **the file you edit** (starter stub).
- `00_TB/iotdf_tb.v` — self-checking testbench (don't edit).
- `00_TB/iotdf_workload_tb.v` — activity-capture testbench for the power flow.
- `00_TB/golden/`, `00_TB/workload/` — the **committed public** test patterns
  (already generated; there is nothing to regenerate).
- `SPEC.md` — the function table, streaming contract, and power structure. **Read first.**

## 1. Run the check once to see it fail

```bash
cd 01_RTL
make vsim        # Verilator (fast); or `make sim` for Icarus
```
The starter only implements `BIN2GRAY`, so GRAY2BIN / CRC8 / LFSR mismatch and
you'll see `RESULT: FAIL`. That's expected — now make it pass. (The vectors come
from the pre-committed `../00_TB/golden/`; no generator step is needed.)

## 2. Implement the four units

Edit `01_RTL/iotdf.v` per [SPEC.md](SPEC.md). Keep the power structure:

- Add the per-function enables (`en_g2b`, `en_crc`, `en_lfsr`) and the
  **operand-isolated** inputs (`din_* = en_* ? i_data : 8'h00`).
- **GRAY2BIN:** `o[k] = ^(i >> k)` (suffix-XOR), or the `o[k]=o[k+1]^i[k]` recurrence.
- **CRC8:** keep a `crc_reg` flop; compute `crc_next` with an 8-iteration loop
  (poly `0x07`, MSB-first); output `crc_next`; update `crc_reg` **only when `en_crc`**.
- **LFSR:** keep an `lfsr_reg` (seed `0xFF`); `o = i ^ lfsr_reg`; advance 8 steps
  per byte (feedback `s[7]^s[5]^s[4]^s[3]`); update **only when `en_lfsr`**; seed on reset.
- Wire all four into the result mux, and reset `crc_reg`/`lfsr_reg` correctly.

## 3. Iterate until it passes

```bash
make vsim        # from 01_RTL
```
Repeat edit → run until you see:
```
Checked 345 cycles, 0 mismatch(es).
RESULT: PASS
```
On a failure the TB prints the cycle index, the inputs, and expected vs actual —
start from the first one.

## 4. Look at the waveform (at least once)

```bash
make sim         # from 01_RTL; produces build/sim/iotdf.vcd
make wave        # opens GTKWave
```
Find a CRC8 stream and watch `crc_reg` accumulate; find an LFSR stream and watch
`o_data = i ^ lfsr_reg`.

## 5. Lint

```bash
make lint        # from 01_RTL; aim for no warnings in your finished design
```

## 6. Synthesize (container)

```bash
cd ../02_SYN
make synth       # baseline netlist     -> build/iotdf_base.v + build/area_base.rpt
make synth-cg    # clock-gated netlist  -> build/iotdf_cg.v   + build/area_cg.rpt
```
`synth-cg` runs Yosys with `CLOCKGATE=1` (inserts integrated clock-gating cells).
Both read your `../01_RTL/iotdf.v` and the CVSD timing constraints `iotdf.sdc`
that live in this directory.

## 7. Capture switching activity (container)

```bash
cd ../03_GATE
make gate        # gate-level sim of the baseline netlist on the workload
make gate-cg     # same for the clock-gated netlist
```
Each runs the **workload** testbench against the synthesized netlist (with the
SKY130 cell models) and records `build/sim/iotdf_workload_{base,cg}.vcd` — the
representative switching activity the power report needs.

## 8. Measure power and compare (container)

```bash
cd ../06_POWER
make compare
```
This runs OpenSTA `report_power` with the workload VCD on both netlists
(`build/power_base.rpt`, `build/power_cg.rpt`), prints baseline-vs-clock-gated
**power and area**, and writes a filled `../artifacts/ppa_compare.md`. (You can
also run `make power-base` / `make power-cg` individually.) Because your CRC/LFSR
registers hold when idle and the idle units are operand-isolated, gating removes
their needless clock toggling → lower dynamic power.

## 9. Write up the PPA

Open `artifacts/ppa_compare.md`, confirm the numbers, and **complete the
discussion**: where the baseline power went, what clock gating saved (and its
small area cost), and the role of operand isolation for the idle units.

## What to submit

Put these in `artifacts/`:
- your completed `01_RTL/iotdf.v`,
- the `make vsim` log showing `RESULT: PASS`,
- `06_POWER/build/power_base.rpt` and `06_POWER/build/power_cg.rpt` (or excerpts),
- the completed `artifacts/ppa_compare.md` (quantified before/after + discussion),
- one GTKWave screenshot (e.g. CRC8 accumulating, or an LFSR stream).

## Common pitfalls

- **Latency/phasing:** outputs are registered (1-cycle latency). Don't make
  `o_data` combinational — the TB samples one clock after the input.
- **CRC output value:** output the **updated** register (`crc_next`), not the old
  `crc_reg`. MSB-first means XOR the byte in *before* the 8 shift iterations.
- **CRC/LFSR not resetting:** clear `crc_reg` to 0 and reload the LFSR seed on
  reset, else streams after the first one start from stale state.
- **LFSR step count:** advance **8** steps per byte, and XOR with the register
  value *before* advancing.
- **Breaking the power structure:** if idle units aren't operand-isolated, or the
  state registers update every cycle, clock gating buys little and your PPA
  improvement will be small — that *is* the lesson, so keep the structure.
- **Changing the interface:** breaks the TB and the power flow → no credit.
