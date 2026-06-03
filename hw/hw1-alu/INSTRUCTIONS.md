# HW1 — Step-by-step instructions

> Work inside the environment (`make shell`, or `conda activate hcmut-eda`, or
> the front-end conda profile). For HW1 you can also just use a local
> Verilator + Python install. Run everything from `hw/hw1-alu/`.

## 0. Orient yourself

```bash
cd hw/hw1-alu
ls
```
- `rtl/alu.v` — **the file you edit** (the starter stub).
- `tb/alu_tb.v` — the self-checking testbench (don't edit).
- `tools/gen_vectors.py` — the Python reference model + golden-vector generator.
- `SPEC.md` — the exact operation table and Q6.10 rules. **Read it first.**

## 1. Generate the golden vectors

```bash
make vectors
```
This writes `golden/alu_vectors.hex` (thousands of `op,a,b → y,zero,overflow`
cases) and `golden/alu_count.vh`. The Python model in `tools/gen_vectors.py` is
the source of truth for correct behavior.

## 2. Run the check once to see it fail

```bash
make vsim        # Verilator (fast); or `make sim` for Icarus
```
The starter only implements `ADD` and `PASSB`, so you'll see lots of
mismatches and `RESULT: FAIL`. That's expected — now make it pass.

## 3. Implement the ALU

Edit `rtl/alu.v`. Fill in every `op` in the case statement per [SPEC.md](SPEC.md):

- Integer ops: `SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU`.
- Fixed-point ops: `FXADD, FXSUB` (saturate) and `FXMUL` (round-half-up + saturate).
- Drive `overflow` high exactly when a fixed-point op saturates.
- Replace the placeholder `assign zero = 1'b0;` so `zero` is high when `y == 0`.

Tips: use the symbolic opcodes (`` `ALU_SUB `` …), declare wide signed
temporaries for the fixed-point math, and re-read the FXMUL worked example in
the spec.

## 4. Iterate until it passes

```bash
make vsim
```
Repeat edit → run until you see:
```
Checked 4256 vectors, 0 mismatch(es).
RESULT: PASS
```
When a vector fails, the testbench prints the `op/a/b`, what your ALU produced,
and what was expected — start from the first failure.

## 5. Look at the waveform (at least once)

```bash
make sim        # produces sim/alu.vcd
make wave       # opens GTKWave
```
Find an `FXMUL` operation and confirm the inputs/outputs match your mental model.

## 6. Clean up and check lint

```bash
make lint       # aim for no warnings in your finished design
```

## 7. What to submit

Put these in `artifacts/` (see [RUBRIC.md](RUBRIC.md)):
- your completed `rtl/alu.v`,
- the `make vsim` (or `make sim`) log showing `RESULT: PASS`,
- one annotated GTKWave screenshot (e.g. an `FXMUL` with saturation),
- a 3–5 sentence note: how you handled rounding and saturation.

## Common pitfalls

- **Logical vs arithmetic shift:** `SRL` zero-fills (`$unsigned(a) >> sh`),
  `SRA` sign-fills (`a >>> sh`).
- **Signed comparisons:** `SLT` is signed, `SLTU` unsigned — wrap operands in
  `$signed`/`$unsigned` so the comparison is unambiguous.
- **FXMUL width:** the product is 32 bits — use a `2*WIDTH`-wide signed temp, add
  the rounding bias *before* the `>>> FRAC` shift, then saturate.
- **Forgetting `overflow`:** only the three FX ops set it, and only when clamped.
- **Latches:** assign `y` on every path (the `default` case) so synthesis later
  doesn't infer a latch.
