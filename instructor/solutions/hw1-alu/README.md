# HW1 — instructor notes & reference solution

> **Do not distribute to students.** Release the reference RTL only after grading.

## Layout

HW1 uses CVSD-style numbered stage dirs:
- `hw/hw1-alu/00_TB/`        — `alu_tb.v` + `golden/` (the COMMITTED public patterns).
- `hw/hw1-alu/01_RTL/`       — student starter stub `alu.v` + functional-sim `Makefile`.
- `instructor/solutions/hw1-alu/tools/gen_vectors.py` — the PRIVATE generator (here).

## Golden patterns

The PUBLIC test patterns in `hw/hw1-alu/00_TB/golden/` are pre-committed (4256
vectors, default seed) and are what students simulate against — students never
run any generator. Regenerate HIDDEN grading patterns with the private generator
(`instructor/solutions/hw1-alu/tools/gen_vectors.py`) using a different `--seed`,
e.g. `python3 gen_vectors.py --seed 1234 --outdir /tmp/hidden`, then point the TB
at that dir to defeat hard-coded released vectors.

## Reference solution

The complete, correct ALU is the canonical
[`common/rtl/alu/alu.v`](../../../common/rtl/alu/alu.v) (the same file HW2+
reuse). To confirm it passes the released testbench:

```bash
cd hw/hw1-alu/01_RTL
make vsim RTL=../../../common/rtl/alu/alu.v   # Verilator (fast)
make ref                                      # Icarus: common/rtl/alu/alu.v vs ../00_TB/alu_tb.v
# expect: "Checked 4256 vectors, 0 mismatch(es)."  /  "RESULT: PASS"
```

(There is intentionally no second copy of the solution here — keeping one
canonical file avoids drift between "the reference" and "what HW2 reuses".)

## Grading a submission

```bash
# with the student's 01_RTL/alu.v in place:
cd hw/hw1-alu/01_RTL
make vsim           # -> RESULT: PASS / FAIL ; non-zero exit on FAIL (Verilator)
make sim            # same check under Icarus
make lint           # style/lint points
```

### Hidden testing
The committed `00_TB/golden/` is the PUBLIC set. For hidden testing, run the
private `instructor/solutions/hw1-alu/tools/gen_vectors.py` with a different
`--seed` (and/or extend the `corners` list) into a scratch dir, then point the
testbench's `$readmemh`/`-I` golden path at that dir. This defeats hard-coded
released vectors.

## Expected results
- Reference ALU: `0` mismatches over the 4256 released vectors.
- The reference lints clean under `verilator --lint-only -Wall` with the
  width-warning waivers in the Makefile (`-Wno-WIDTHEXPAND/-Wno-WIDTHTRUNC`,
  which are benign intentional truncations in the arithmetic).

## Common student pitfalls (see also INSTRUCTIONS.md)
- **SRL vs SRA**: using `>>` on a `signed` operand still zero-fills; using `>>>`
  on an `unsigned` operand still zero-fills. Students must cast explicitly
  (`$unsigned(a) >> sh` for SRL, `a >>> sh` with `a` signed for SRA).
- **FXMUL rounding**: forgetting the `+ (1<<(FRAC-1))` bias (truncates instead of
  rounds) — fails the half-way vectors only, so it looks "almost right."
- **Saturation sign**: clamping to the wrong rail, or not setting `overflow`.
- **Unsigned/signed compare** for SLT/SLTU swapped.
- **Latch inference**: missing `default` or an unassigned path — flagged later in
  HW3 synthesis, but catch it here.
- **Changing the interface**: breaks the TB and HW2; zero functional credit.

## Timing
Most students finish in one sitting once they've read SPEC.md. The fixed-point
ops (FXMUL especially) are where time goes — budget a short lecture on Q-format
and round-half-up.
