# HW2 — Step-by-step instructions

> Run from `hw/hw2-cpu/`. You need the front-end tools (Icarus or Verilator) +
> Python — the conda front-end env or Docker both work.

## 0. Orient

- `rtl/cpu_core.v` — **the file you edit** (datapath control; 6 TODOs).
- `tb/cpu_tb.v` — self-checking testbench (don't edit); it owns memory and
  compares final data memory to the golden ISS.
- `tools/asm.py` — the assembler; `tools/iss.py` — the golden simulator.
- `programs/ops.s`, `programs/mac.s` — test programs.
- **Read [SPEC.md](SPEC.md) first** (ISA + the MAC definition).

## 1. See the reference work, and the starter fail

```bash
make ref              # reference CPU passes ops + mac  (sanity that the flow works)
make vsim PROG=ops    # YOUR starter cpu_core -> RESULT: FAIL (control is TODO)
```

## 2. Implement the control in `rtl/cpu_core.v`

Fill the six TODOs (the datapath skeleton, register file, and ALU are provided):

1. **ALU operand-B mux** — `sext_imm` for ADDI/LW/SW, else `rdb`.
2. **ALU op decode** — map `(op,funct)` to the ALU op (`OP_ALU`/`OP_FALU` funct,
   `OP_MAC`→FXMUL, ADDI/LW/SW→ADD).
3. **MAC accumulate** — `mac_y = saturate(rdc + alu_y)`.
4. **Write-back** — set `regwrite`/`waddr`/`wdata` (ALU/FALU/ADDI→`alu_y`,
   MAC→`mac_y`, LW→`dmem_rdata`, JAL→`r7=pc+1`; others no write).
5. **Data memory** — assert `dmem_we` for `OP_SW`.
6. **Branch + next PC** — JMP/JAL→`addr12`, taken BEQ/BNE→`pc+1+sext_imm`, else
   `pc+1`; hold `pc` when halted.

## 3. Iterate

```bash
make vsim PROG=ops    # fast (Verilator)
make vsim PROG=mac
make                  # the graded check: Icarus over ALL programs
```
When a program fails, the testbench prints which data-memory word differs and
the expected value — compare against the ISS (`make prog PROG=ops` then read
`sim/golden.hex`).

## 4. Inspect a waveform

```bash
make wave PROG=mac    # GTKWave on sim/cpu.vcd -- watch the MAC accumulate
```

## 5. Write your own test (recommended)

Add `programs/mytest.s`, then `make vsim PROG=mytest`. The ISS computes the
golden automatically, so any program you can write becomes a self-checking test.

## 6. Submit (see [RUBRIC.md](RUBRIC.md))

Put in `artifacts/`: your `rtl/cpu_core.v`, the `make` log showing all programs
`PASS`, a MAC waveform screenshot, and a short note on how MAC reuses the ALU.

## Common pitfalls
- **Branch operands:** `beq rd,rs` compares `reg[rd]` and `reg[rs]` — the compare
  reads `rdc` (=reg[rd]) and `rda` (=reg[rs]).
- **MAC accumulator** comes from the third read port `rdc` (=reg[rd]), not `rs`.
- **Immediate vs register ALU B:** forgetting the mux breaks ADDI/LW/SW addressing.
- **`r0` is always 0** — the register file enforces it; don't special-case it.
- **Forgetting to hold `pc` on halt** makes the CPU run off the end.
