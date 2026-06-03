# HW3 — instructor notes & reference solution

> **Do not distribute to students.** Release the reference RTL/SDC only after grading.

## Test patterns: PUBLIC data + PRIVATE generator

The committed **public** test patterns live in
[`hw/hw3-synth/00_TB/golden/`](../../../hw/hw3-synth/00_TB/golden) (`conv_stim.hex`,
`conv_exp.hex`, `conv_count.vh`). The generator that produced them,
[`tools/gen_golden.py`](tools/gen_golden.py), is **private** (here, not under
`hw/`). Regenerate **HIDDEN** patterns for grading with a **different `--seed`**:

```bash
python3 instructor/solutions/hw3-synth/tools/gen_golden.py --seed <N> --outdir /tmp/hidden_golden
# default seed (20260603) reproduces the committed public 00_TB/golden byte-for-byte
```

## Reference solution

The complete, correct engine is the canonical
[`common/rtl/conv/conv_engine.v`](../../../common/rtl/conv/conv_engine.v) (the
same file HW5 places-and-routes). The reference timing constraints are
[`conv_ref.sdc`](conv_ref.sdc) in this folder (the released student SDC now lives
at `hw/hw3-synth/02_SYN/conv.sdc`, completed with the CVSD-style I/O block).
There is intentionally **no** second copy of the RTL here — one canonical file
avoids drift between "the reference" and "what HW5 reuses".

Confirm the reference passes the released testbench (stage-dir layout):

```bash
cd hw/hw3-synth/01_RTL
make ref            # == make vsim RTL=../../../common/rtl/conv/conv_engine.v
# expect: "Checked 8 case(s) x 64 pixels, 0 mismatch(es)." / "RESULT: PASS" / ">> verilator sim PASS"
```

(With only Verilator available, `make ref` runs the released testbench against
the reference engine and prints `RESULT: PASS`.)

## Grading a submission

```bash
# with the student's 01_RTL/conv_engine.v in place:
cd hw/hw3-synth/01_RTL
make vsim                   # -> RESULT: PASS / FAIL ; non-zero exit on FAIL (Verilator)
make sim                    # Icarus equivalent (container)
make lint                   # style/lint points

# back-end (container):
cd ../02_SYN
make synth                  # -> 02_SYN/build/conv_netlist.v + conv_area.rpt
make sta                    # student SDC (conv.sdc) -> 02_SYN/build/conv_sta.rpt (positive slack)
# or check timing with the reference SDC:
TOP=conv_engine LIB="$LIB" NETLIST=build/conv_netlist.v \
  SDC=../../../instructor/solutions/hw3-synth/conv_ref.sdc \
  sta -no_init -exit ../../../common/flow/sta.tcl
cd ../03_GATE
make gl-sim                 # -> RESULT: PASS  (gate equivalence)
```

### Hidden testing
The public patterns under `00_TB/golden/` are committed; the generator is
private (`instructor/solutions/hw3-synth/tools/gen_golden.py`). Regenerate
HIDDEN patterns with a different seed and drop them into `00_TB/golden/` before
re-running the stages:
```bash
python3 instructor/solutions/hw3-synth/tools/gen_golden.py --seed <N> \
    --outdir hw/hw3-synth/00_TB/golden
```
Because the golden is computed by the Python model, **any** kernel+image is a
valid self-checking test — this defeats hard-coded released outputs. (Restore the
committed public set with the default seed when done.)

## Expected results / reference values

Reference engine: **0 mismatches** over the 8 released cases × 64 pixels
(512 checks). Released cases (seed 20260603): `blur_ramp`, `sobel_step`,
`identity_rand`, `rand0..3`, `saturate`.

Hand-checkable golden values (Q6.10 raw):

- **`blur_ramp`** (3×3 box blur of a ramp `(r*8+c)/16`): out[0][0] = `0x0080`
  (=128 = +0.125), out[0][7] = `0x012b` (=299), out[7][7] = `0x0683` (=1667).
  Corner (0,0) sums 4 in-bounds neighbours × `1/9`.
- **`sobel_step`** (Sobel-X on a left-0 / right-1.0 vertical step): the interior
  row 3 response is `[0, 0, 0, +4096, +4096, 0, 0, −4096]` — `+4.0` at the rising
  step (cols 3,4) and `−4.0` at the right boundary (zero-padding makes a falling
  edge). This independently verifies zero-padding + signed accumulate.
- **`identity_rand`** (center tap = 1.0): output equals the input on the interior
  (a clean equivalence sanity case for gate-level sim).
- **`saturate`** (kernel = 8.0 each, large pixels): **all 64** outputs clamp to
  `0x7FFF`/`0x8000` — flushes out a missing saturation clamp.

Independent cross-check (computed a different way than the generator, via
`math.floor((acc+512)/1024)` and a pure-float convolution) agrees with every
released `blur_ramp` and `sobel_step` value.

## Synthesis / timing reference
- The reference lints clean under `verilator --lint-only -Wall` with the
  width/unused waivers in the Makefile (benign intentional truncations in the
  index/accumulate arithmetic).
- Yosys maps the kernel/result flop arrays + control + one shared 16×16
  multiplier to standard cells, and **blackboxes the SRAM macro**
  (`sky130_sram_1kbyte_1rw1r_32x256_8`, the feature-map buffer) via
  `BLACKBOX_FILES=` (`read_verilog -lib`). The netlist instantiates the macro,
  which **HW5 places in APR**. STA reads the macro `.lib` (`MACRO_LIBS=`).

## SRAM macro (integration lesson)
- **Sim** uses the behavioral model
  `common/rtl/conv/sky130_sram_1kbyte_1rw1r_32x256_8.v` (sim-only; the
  01_RTL/03_GATE Makefiles add it to the compile). The macro read is
  **synchronous** (1-cycle latency) — the classic student bug is treating it as
  combinational (off-by-one), which the golden catches.
- **`SRAM_LIB` (02_SYN)** and the macro views staged by HW5 `04_APR/make prep`
  are IMAGE-DEPENDENT (the sky130 OpenRAM macros ship with OpenLane). Set
  `SRAM_MACRO_DIR`/`SRAM_LIB` if your image stores them elsewhere. The back-end
  steps are validated only in the container; the **functional** sim (behavioral
  model) is what runs locally.
- With `conv_ref.sdc` (20 ns / 50 MHz) the design closes timing with positive
  setup and hold slack at the tt corner; the critical path is the shared 16×16
  signed multiply into the 40-bit accumulate add. Students who instantiate a
  parallel multiplier tree will see worse area and a longer critical path —
  point them back to the "single shared multiplier" requirement.

## Common student pitfalls (see also INSTRUCTIONS.md)
- **Round-then-accumulate** instead of accumulate-then-round (precision loss;
  fails the half-way rounding pixels — looks "almost right").
- **Column offset via `tap[1:0]`** (mod-4) instead of `tap mod 3` — corrupts the
  neighbour mapping; the classic first bug.
- **Missing saturation clamp** — the `saturate` case fails loudly (all clamp).
- **Zero-padding off-by-one** at corners/edges (wrong neighbour count).
- **Latch inference** from an incompletely-assigned `always @*` — surfaces in
  synthesis; catch with `make lint`.
- **SDC mistakes:** constraining the clock port as a data input, or only loosely
  constraining I/O so slack looks artificially good; check against `conv_ref.sdc`.
- **Editing the interface:** breaks the TB, the gate-level netlist port list, and
  HW5; zero functional credit.

## Timing
Most students finish the RTL in one sitting after reading SPEC.md; the fixed-point
accumulate (accumulate-then-round) and the tap mapping are where time goes. Budget
a short lecture on synthesis (`stat`/area), gate-level equivalence, and reading an
STA slack report.
