# HW2 — TinyRISC-16 CPU specification

You will implement **TinyRISC-16**, a 16-bit, single-cycle processor whose
execution unit is the **HW1 ALU** (reused unchanged), and add a **MAC custom
instruction**. The module interface is fixed (the testbench and HW3+ depend on it).

## Architecture

- **16-bit** data and instructions. **Single-cycle**: one instruction per clock,
  no pipeline, hazards, or forwarding.
- **8 registers** `r0..r7`, 16-bit. `r0` is hardwired to 0. `r7` is the link
  register written by `jal`.
- **Harvard memory**: separate instruction and data memories, word-addressed,
  `2^AW` words (AW=8 → 256). Instruction read and data read are combinational;
  data write is synchronous. Memory is **external** to the core (ports), which
  keeps the synthesizable core macro-free for HW3–HW5.
- Reset is **synchronous, active-low**: `pc ← 0`, registers ← 0.

The register file (3 read ports) and the ALU are **provided**; you write the
datapath control in `01_RTL/cpu_core.v`.

## Instruction formats (16 bits)

```
 R-type : | op[15:12] | rd[11:9] | rs[8:6] | rt[5:3] | funct[2:0] |
 I-type : | op[15:12] | rd[11:9] | rs[8:6] |     imm[5:0]         |   (imm sign-extended)
 J-type : | op[15:12] |              addr[11:0]                   |
```

## Instruction set

Opcodes and funct codes are in
[`common/rtl/cpu/isa_defs.vh`](../../common/rtl/cpu/isa_defs.vh) — use the macros.

| op | mnemonic | asm | type | operation |
|----|----------|-----|------|-----------|
| 0x0 | ALU  | `add/sub/and/or/xor/slt/sll/sra rd,rs,rt` | R | `rd = rs <op> rt` (integer; funct selects) |
| 0x1 | FALU | `fxadd/fxsub/fxmul rd,rs,rt` | R | `rd = rs <op> rt` (Q6.10; funct selects) |
| 0x2 | MAC  | `mac rd,rs,rt` | R | `rd = sat(rd + round(rs*rt))` — **custom** |
| 0x3 | ADDI | `addi rd,rs,imm` | I | `rd = rs + sext(imm)` |
| 0x4 | LW   | `lw rd,imm(rs)` | I | `rd = DMEM[rs + sext(imm)]` |
| 0x5 | SW   | `sw rd,imm(rs)` | I | `DMEM[rs + sext(imm)] = rd` |
| 0x6 | BEQ  | `beq rd,rs,label` | I | if `rd == rs`: `pc = pc+1+sext(imm)` |
| 0x7 | BNE  | `bne rd,rs,label` | I | if `rd != rs`: `pc = pc+1+sext(imm)` |
| 0x8 | JMP  | `jmp label` | J | `pc = addr` |
| 0x9 | JAL  | `jal label` | J | `r7 = pc+1; pc = addr` |
| 0xF | HALT | `halt` | — | stop execution |

`funct` for `OP_ALU`: ADD=0, SUB=1, AND=2, OR=3, XOR=4, SLT=5, SLL=6, SRA=7.
`funct` for `OP_FALU`: FXADD=0, FXSUB=1, FXMUL=2. These map directly to the HW1
ALU operation codes.

Notes:
- Immediates are 6-bit **signed** (−32..31). Branch displacements are relative to
  `pc+1`. Jump addresses are 12-bit (low `AW` bits used).
- Loads/stores compute the address with the ALU's integer `ADD`.
- There is no `jr`; subroutines "return" with `jmp` (the link in `r7` is for
  demonstrating linkage / nested-call bookkeeping).

## The custom instruction — MAC

`mac rd, rs, rt`  computes  `rd = saturate( rd + round(rs * rt) )` in **one cycle**,
treating values as Q6.10.

This is the course's "a custom instruction is a small, cheap extension that
reuses the expensive datapath" lesson. In the datapath you:
1. drive the ALU with `FXMUL` of `rs, rt` (reusing the **multiplier** the ALU
   already has from HW1) to get `round(rs*rt)`;
2. add the accumulator `reg[rd]` (the register file's **third read port**, `rdc`)
   and **saturate** to 16 bits;
3. write the result back to `rd`.

So MAC adds only: one decode case, one saturating adder, one write-back path —
the multiplier is reused. (HW4 will show that the multiplier + register file
dominate area and power, while MAC's extra logic is tiny — yet it replaces a
multi-instruction software sequence.)

## Encoding example

`mac r1, r2, r3`  →  op=`0x2`, rd=1, rs=2, rt=3, funct=0
= `0010_001_010_011_000` = `0x2298`.  (`lw r2, 3(r0)` = `0x4` r2 r0 imm3 = `0x4603`.)

## Memory & verification model

Each test program is provided as **pre-assembled, committed patterns** in
`00_TB/patterns/<prog>.{imem,dmem,golden}.hex`: an instruction-memory image, an
initial data-memory image, and the expected FINAL data memory (the golden,
computed by a reference instruction-set simulator that is the source of truth
for correct behavior). You do not assemble anything — the patterns are ready to
run.

A program communicates results by **storing them to data memory**; the
testbench runs your CPU to `halt`, then compares the final data memory to the
golden. You pass when it prints `RESULT: PASS`.

Two programs are provided: `ops` (covers the whole ISA) and `mac` (a Q6.10 dot
product showcasing MAC, result `4.0 = 0x1000`). The `01_RTL/Makefile` copies the
selected program's patterns into `build/` before each run (`make vsim PROG=ops`,
`make vsim PROG=mac`).
