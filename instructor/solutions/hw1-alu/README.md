# HW1 — instructor notes & reference solution

> **Do not distribute to students.** Release the reference RTL only after grading.

## Reference solution

The complete, correct ALU is the canonical
[`common/rtl/alu/alu.v`](../../../common/rtl/alu/alu.v) (the same file HW2+
reuse). To confirm it passes the released testbench:

```bash
cd hw/hw1-alu
make vectors
make ref            # compiles common/rtl/alu/alu.v against tb/alu_tb.v
# expect: "Checked 4256 vectors, 0 mismatch(es)."  /  "RESULT: PASS"  /  ">> reference ALU PASS"
```

(There is intentionally no second copy of the solution here — keeping one
canonical file avoids drift between "the reference" and "what HW2 reuses".)

## Grading a submission

```bash
# with the student's rtl/alu.v in place:
make vectors        # or regenerate with a different seed for hidden testing
make sim            # -> RESULT: PASS / FAIL ; non-zero exit on FAIL
make lint           # style/lint points
```

### Hidden testing
Re-run with a different RNG seed and extra fixed-point corners by editing the
`rng = random.Random(...)` seed (and/or the `corners` list) in
`tools/gen_vectors.py`, then `make vectors && make sim`. This defeats hard-coded
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
