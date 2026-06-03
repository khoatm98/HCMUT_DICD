# HW2 — Step-by-step instructions

> Run from `hw/hw2-cpu/01_RTL/`. You need the front-end tools (Icarus or
> Verilator) — the conda front-end env or Docker both work. No Python needed:
> the test patterns are pre-committed.

## 0. Orient

- `01_RTL/cpu_core.v` — **the file you edit** (datapath control; 6 TODOs).
- `01_RTL/Makefile` — the functional-sim targets you drive.
- `00_TB/cpu_tb.v` — self-checking testbench (don't edit); it owns memory and
  compares final data memory to the golden image.
- `00_TB/patterns/<prog>.{imem,dmem,golden}.hex` — committed public test patterns
  (the Makefile copies the selected program's into `01_RTL/build/` before a run).
- **Read [SPEC.md](SPEC.md) first** (ISA + the MAC definition).

```bash
cd 01_RTL
```

## 1. See the starter fail

```bash
make vsim PROG=ops    # YOUR starter cpu_core -> RESULT: FAIL (control is TODO)
```

## 2. Implement the control in `cpu_core.v`

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
make                  # the graded check: Icarus over ALL programs (ops + mac)
```
When a program fails, the testbench prints which data-memory word differs and
the expected value — compare against the committed golden in
`00_TB/patterns/<prog>.golden.hex` (the run uses a copy in `build/golden.hex`).

## 4. Inspect a waveform

```bash
make wave PROG=mac    # GTKWave on build/cpu.vcd -- watch the MAC accumulate
```

## 5. Submit (see [RUBRIC.md](RUBRIC.md))

Put in `artifacts/`: your `01_RTL/cpu_core.v`, the `make` log showing all
programs `PASS`, a MAC waveform screenshot, and a short note on how MAC reuses
the ALU.

## Common pitfalls
- **Branch operands:** `beq rd,rs` compares `reg[rd]` and `reg[rs]` — the compare
  reads `rdc` (=reg[rd]) and `rda` (=reg[rs]).
- **MAC accumulator** comes from the third read port `rdc` (=reg[rd]), not `rs`.
- **Immediate vs register ALU B:** forgetting the mux breaks ADDI/LW/SW addressing.
- **`r0` is always 0** — the register file enforces it; don't special-case it.
- **Forgetting to hold `pc` on halt** makes the CPU run off the end.
