# HW4 — Step-by-step instructions

> Functional work (steps 0–6) runs locally with **Verilator/Icarus + Python**.
> The power flow (steps 7–9) needs the **EDA container** (Yosys, Icarus, OpenSTA,
> SKY130 PDK): from the repo root run `make shell`, then `cd hw/hw4-power`.

## 0. Orient yourself

```bash
cd hw/hw4-power
ls
```
- `rtl/iotdf.v` — **the file you edit** (starter stub).
- `tb/iotdf_tb.v` — self-checking testbench (don't edit).
- `tb/iotdf_workload_tb.v` — activity-capture testbench for the power flow.
- `tools/gen_golden.py` — Python golden model + stimulus/workload generator.
- `SPEC.md` — the function table, streaming contract, and power structure. **Read first.**

## 1. Generate the golden vectors + workload

```bash
make vectors
```
Writes `golden/iotdf_vectors.hex` + `golden/iotdf_count.vh` (the self-checking
stream) and `workload/workload.hex` + `workload/workload_count.vh` (the power
workload). The Python model in `tools/gen_golden.py` is the source of truth.

## 2. Run the check once to see it fail

```bash
make vsim        # Verilator (fast); or `make sim` for Icarus
```
The starter only implements `BIN2GRAY`, so GRAY2BIN / CRC8 / LFSR mismatch and
you'll see `RESULT: FAIL`. That's expected — now make it pass.

## 3. Implement the four units

Edit `rtl/iotdf.v` per [SPEC.md](SPEC.md). Keep the power structure:

- Add the per-function enables (`en_g2b`, `en_crc`, `en_lfsr`) and the
  **operand-isolated** inputs (`din_* = en_* ? i_data : 8'h00`).
- **GRAY2BIN:** `o[k] = ^(i >> k)` (suffix-XOR), or the `o[k]=o[k+1]^i[k]` recurrence.
- **CRC8:** keep a `crc_reg` flop; compute `crc_next` with an 8-iteration loop
  (poly `0x07`, MSB-first); output `crc_next`; update `crc_reg` **only when `en_crc`**.
- **LFSR:** keep an `lfsr_reg` (seed `0xFF`); `o = i ^ lfsr_reg`; advance 8 steps
  per byte (feedback `s[7]^s[5]^s[4]^s[3]`); update **only when `en_lfsr`**; seed on reset.
- Wire all four into the result mux, and reset `crc_reg`/`lfsr_reg` correctly.

## 4. Iterate until it passes

```bash
make vsim
```
Repeat edit → run until you see:
```
Checked 345 cycles, 0 mismatch(es).
RESULT: PASS
```
On a failure the TB prints the cycle index, the inputs, and expected vs actual —
start from the first one.

## 5. Look at the waveform (at least once)

```bash
make sim         # produces sim/iotdf.vcd
make wave        # opens GTKWave
```
Find a CRC8 stream and watch `crc_reg` accumulate; find an LFSR stream and watch
`o_data = i ^ lfsr_reg`.

## 6. Lint

```bash
make lint        # aim for no warnings in your finished design
```

## 7. Measure the BASELINE power (container)

```bash
make power-base
```
This (1) synthesizes your RTL to SKY130 cells (Yosys), (2) runs a **gate-level**
simulation of the netlist on the **workload** to record `sim/iotdf_workload_base.vcd`,
and (3) runs OpenSTA `report_power` with that activity → `build/power_base.rpt`
(area in `build/area_base.rpt`). Read the Total power row.

## 8. Apply clock gating and re-measure

```bash
make power-cg
```
Same flow, but Yosys runs with `CLOCKGATE=1` (inserts integrated clock-gating
cells). Because your CRC/LFSR registers hold when idle and the idle units are
operand-isolated, gating removes their needless clock toggling →
`build/power_cg.rpt`.

## 9. Compare and write up the PPA

```bash
make compare
```
Prints baseline vs clock-gated **power and area** and writes a filled
`artifacts/ppa_compare.md`. Open it, confirm the numbers, and **complete the
discussion**: where the baseline power went, what clock gating saved (and its
small area cost), and the role of operand isolation for the idle units.

## What to submit

Put these in `artifacts/`:
- your completed `rtl/iotdf.v`,
- the `make vsim` log showing `RESULT: PASS`,
- `build/power_base.rpt` and `build/power_cg.rpt` (or excerpts),
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
