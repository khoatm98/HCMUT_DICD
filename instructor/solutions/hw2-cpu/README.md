# HW2 — instructor notes & reference solution

> **Do not distribute to students.**

## Reference solution

The complete CPU is the canonical
[`common/rtl/cpu/cpu_core.v`](../../../common/rtl/cpu/cpu_core.v) (the same file
HW3–HW5 synthesize). Confirm it passes all provided programs:

```bash
cd hw/hw2-cpu
make ref
# expect: ops -> RESULT: PASS, mac -> RESULT: PASS, ">> REFERENCE CPU PASS on all programs"
```

## Grading a submission

```bash
# with the student's rtl/cpu_core.v in place:
make                       # runs ops + mac via Icarus
make sim PROG=<hidden>     # any hidden program you add to programs/
```

The golden is computed by `tools/iss.py`, so **any** assembly program is a valid
self-checking test. To add hidden tests, drop `programs/<name>.s` and run
`make sim PROG=<name>` (and/or add the name to `PROGS` in the Makefile).

## Expected results / reference values
- `ops.s`: exercises the whole ISA; hand-checked goldens include
  add(17), sub(7), and(4), or(13), xor(9), slt(1/0), sll(384), sra(0),
  fxadd(1.75=1792), fxsub(−0.5=−512), fxmul(3.0=3072), lw(31), beq→1,
  jmp-skipped→0, loop-sum(10).
- `mac.s`: dot product = `4.0 = 0x1000` stored at `result`.

## Design notes
- The MAC is realized in the datapath (FXMUL product + saturating accumulate of
  `reg[rd]` via the register file's third read port `rdc`). The ALU is NOT
  modified — this keeps HW1 frozen and makes the "small, cheap extension" point.
- Memory is external to `cpu_core` (combinational read, sync write), so the
  synthesizable core is macro-free for HW3/HW5. The testbench owns the memory
  arrays (works in both Icarus and Verilator; no hierarchical access).

## Common student pitfalls
- Wrong branch operands (compare `reg[rd]` vs `reg[rs]`).
- MAC accumulator taken from `rs`/`rt` instead of the third port `rdc` (=reg[rd]).
- Missing the ALU operand-B immediate mux (breaks ADDI/LW/SW).
- Latches from an incompletely-assigned control `always @*` (surfaces in HW3).
- Not freezing `pc` on `halt`.
- Editing the module interface (breaks TB + HW3).

## Toolchain note
`make`/`make ref` use Icarus; `make vsim` uses Verilator (faster, good for the
lab). Gate-level reuse: the same `tb/cpu_tb.v` drives the HW3 synthesized
netlist (it only needs the `cpu_core` ports).
