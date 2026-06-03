# HW4 — instructor notes & reference solution

> **Do not distribute to students.** Release the reference RTL only after grading.

## Test patterns: public data + private generator

The student-facing patterns are **pre-committed** under
`hw/hw4-power/00_TB/golden/` (self-checking vectors) and
`hw/hw4-power/00_TB/workload/` (power workload). The generator
[`tools/gen_golden.py`](tools/gen_golden.py) is **private to this folder** and is
NOT shipped under `hw/`. Regenerate HIDDEN patterns for grading with the private
generator and a different `--seed` (edit the `random.Random(20260603)` seed
and/or the directed `streams`/`corner` lists), then drop the new `.hex`/`.vh`
into `00_TB/golden` and `00_TB/workload`.

## Reference solution

The complete, correct engine is the canonical
[`common/rtl/iotdf/iotdf.v`](../../../common/rtl/iotdf/iotdf.v) (with
[`iotdf_defs.vh`](../../../common/rtl/iotdf/iotdf_defs.vh)). There is intentionally
no second copy here. To confirm it passes the released testbench:

```bash
cd hw/hw4-power/01_RTL
make ref            # compiles common/rtl/iotdf/iotdf.v against ../00_TB/iotdf_tb.v (Icarus)
# expect: "Checked 345 cycles, 0 mismatch(es)."  /  "RESULT: PASS"  /  ">> reference iotdf PASS"
```

(Local front-end machines may only have Verilator; equivalently, from `01_RTL`,
`make vsim RTL=../../../common/rtl/iotdf/iotdf.v` → `RESULT: PASS`.)

## Grading a submission

```bash
# with the student's 01_RTL/iotdf.v in place:
cd hw/hw4-power/01_RTL
make sim            # -> RESULT: PASS / FAIL ; non-zero exit on FAIL
make lint           # style/structure points
# power part (container):
cd ../02_SYN  && make synth synth-cg      # baseline + clock-gated netlists
cd ../03_GATE && make gate gate-cg        # gate-level sim -> activity VCDs
cd ../06_POWER && make compare            # power_base.rpt, power_cg.rpt, ../artifacts/ppa_compare.md
```

### Hidden testing
The committed patterns in `00_TB/golden` + `00_TB/workload` are the PUBLIC set.
For hidden grading, run the private generator
`instructor/solutions/hw4-power/tools/gen_golden.py` with a different seed (edit
`rng = random.Random(20260603)` and/or the directed `streams`/`corner` lists),
then overwrite the `00_TB/golden` + `00_TB/workload` `.hex`/`.vh` with the new
files and re-run `cd 01_RTL && make sim`. Because the testbench compares
cycle-by-cycle against the golden, any new stimulus is a valid self-checking
test — hard-coding released vectors fails. (Students never run the generator;
their Makefiles read the committed patterns directly, no Python required.)

## Expected values / hand-checks

Independently verified (different implementation than the golden loop):

- **BIN2GRAY:** `bin2gray(0x0B) = 0x0E`. `bin2gray(0xFF)=0x80`, `bin2gray(0x80)=0xC0`.
- **GRAY2BIN:** `gray2bin(bin2gray(x)) == x` for all 256 bytes (round-trip identity).
- **CRC-8 (poly 0x07, MSB-first, init 0):**
  - running CRC over ASCII `"123456789"` ends at **`0xF4`** (the CRC-8/SMBUS check value);
  - single byte `0x00 → 0x00`, `0x01 → 0x07` (= the polynomial).
- **LFSR (taps x^8+x^6+x^5+x^4, seed 0xFF):** keystream bytes (= register
  snapshots, advancing 8 steps/byte) are `0xFF, 0x0B, 0xC6, 0x80, …`; scrambling
  a zero stream emits exactly those bytes; XOR is self-inverse, so an
  identically-seeded re-scramble recovers the plaintext.

The committed public golden has **345** self-checking cycles
(`00_TB/golden/iotdf_vectors.hex`) and a **385**-cycle power workload
(`00_TB/workload/workload.hex`), produced by the private `tools/gen_golden.py`.
The whole golden file was re-derived a second way (table-driven CRC, log-fold
gray2bin) with 0 mismatches.

## Design notes (why this is the power homework)

- **Operand isolation:** each unit's data input is `din = (sel & i_valid) ?
  i_data : 0`, so the three idle units' combinational logic does not toggle on
  every byte — this cuts *switching* power even without clock gating.
- **Gated state:** `crc_reg` updates only on `en_crc`, `lfsr_reg` only on
  `en_lfsr`. Holding the flop is what lets Yosys `clockgate -liberty` insert an
  ICG cell for those registers (the CG pass keys off the enable). That removes
  needless **clock** toggling on the idle stateful unit → the bulk of the
  measured saving.
- **Activity-driven power:** power is meaningless without a workload. The flow
  runs a gate-level sim on `00_TB/workload/workload.hex` (03_GATE) to a VCD, then
  OpenSTA `report_power` with `VCD_SCOPE=iotdf_workload_tb/dut` (06_POWER)
  annotates real switching.
- The CRC and LFSR are written with synthesizable Verilog `function`s (loops with
  a constant bound) so the netlist is flop-array + combinational logic — no macros.

## Common student pitfalls
- **Phasing:** making `o_data` combinational (no 1-cycle latency) — the TB samples
  one clock after the input; combinational outputs fail by a cycle.
- **CRC old vs new:** outputting `crc_reg` (pre-update) instead of `crc_next`.
- **CRC byte injection:** XORing the byte in *after* the shifts, or LSB-first.
- **State not reset:** `crc_reg`/`lfsr_reg` not cleared/seeded on reset → second
  stream starts dirty.
- **LFSR step count / order:** advancing ≠ 8 steps, wrong taps, or advancing
  before the XOR.
- **Killing the power structure:** updating the state registers every cycle, or
  not isolating idle operands → clock gating saves little (still "correct"
  functionally, but loses items 2/4/5/6).
- **Static power report:** running `report_power` without the VCD → no activity,
  no credit for the measurement items.
- **Interface edits:** break the TB + the back-end flow.

## Toolchain note
In `01_RTL`, `make sim`/`make ref` use Icarus; `make vsim` uses Verilator
(faster). The power stages need the container: `02_SYN` runs Yosys
(`synth_sky130.tcl`, `CLOCKGATE=1`), `03_GATE` runs Icarus gate-level sim against
the SKY130 cell models (`-DFUNCTIONAL -DUNIT_DELAY="#1"`), and `06_POWER` runs
OpenSTA (`sta.tcl`, `VCD`/`VCD_SCOPE`). `cd 06_POWER && make compare` ties the
power reports together and fills `../artifacts/ppa_compare.md` via the public
`06_POWER/make_ppa.py`.
