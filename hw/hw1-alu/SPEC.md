# HW1 — TinyRISC-16 ALU specification

You will implement a parameterized **Arithmetic Logic Unit** in Verilog. This
exact module becomes the execution unit of the TinyRISC-16 CPU in HW2, so its
interface is fixed.

## Module interface (do not change)

```verilog
module alu #(
    parameter integer WIDTH = 16,   // data width
    parameter integer FRAC  = 10    // fraction bits for the Q6.10 fixed-point ops
) (
    input  wire [3:0]              op,        // operation select (see table)
    input  wire signed [WIDTH-1:0] a,         // operand A
    input  wire signed [WIDTH-1:0] b,         // operand B
    output reg  signed [WIDTH-1:0] y,         // result
    output wire                    zero,      // 1 when y == 0
    output reg                     overflow   // 1 when a fixed-point op saturates
);
```

The ALU is **purely combinational** (no clock). The testbench applies vectors on
a clock so you can also read the behavior in GTKWave, but the DUT itself has no
state.

## Numeric formats

Each 16-bit word is interpreted in one of two ways depending on the operation:

- **Signed integer** — ordinary two's complement, range −32768 … +32767.
- **Signed fixed-point Q6.10** — 1 sign bit, 5 integer bits, 10 fraction bits.
  The real value is `raw / 1024`. Range −32.0 … +31.9990234375, step 2⁻¹⁰.

| raw (hex) | Q6.10 value |
|-----------|-------------|
| `0x0400` | +1.0 |
| `0x0600` | +1.5 |
| `0xFC00` | −1.0 |
| `0x0001` | +0.000977 (2⁻¹⁰) |
| `0x7FFF` | +31.999 (max) |
| `0x8000` | −32.0 (min) |

## Operation table

`op` is 4 bits. Symbolic names are in [`common/rtl/alu/alu_defs.vh`](../../common/rtl/alu/alu_defs.vh)
— include that file and use the macros (`` `ALU_ADD `` …), never bare numbers.

| op | name | result `y` | sets `overflow`? |
|----|------|-----------|------------------|
| `0x0` | `ALU_ADD`  | `a + b` (integer, wraps) | no |
| `0x1` | `ALU_SUB`  | `a - b` (integer, wraps) | no |
| `0x2` | `ALU_AND`  | `a & b` | no |
| `0x3` | `ALU_OR`   | `a \| b` | no |
| `0x4` | `ALU_XOR`  | `a ^ b` | no |
| `0x5` | `ALU_SLL`  | `a << b[4:0]` (logical) | no |
| `0x6` | `ALU_SRL`  | `a >> b[4:0]` (logical, zero-fill) | no |
| `0x7` | `ALU_SRA`  | `a >>> b[4:0]` (arithmetic, sign-fill) | no |
| `0x8` | `ALU_SLT`  | `1` if `a < b` signed, else `0` | no |
| `0x9` | `ALU_SLTU` | `1` if `a < b` unsigned, else `0` | no |
| `0xA` | `ALU_FXADD`| Q6.10 `a + b`, **saturated** | yes if saturated |
| `0xB` | `ALU_FXSUB`| Q6.10 `a - b`, **saturated** | yes if saturated |
| `0xC` | `ALU_FXMUL`| Q6.10 `a * b`, **rounded + saturated** | yes if saturated |
| `0xD` | `ALU_PASSB`| `b` (used by the CPU to load an immediate) | no |
| `0xE` | `ALU_FXMAC`| *reserved for HW2* (see below) | — |

`zero` is `1` whenever `y == 0`, for every operation.

## Fixed-point rules (the tricky part)

**Saturation (FXADD / FXSUB).** Compute the true signed sum/difference in extra
bits. If it exceeds `+32767`, output `0x7FFF` and set `overflow`. If it is below
`−32768`, output `0x8000` and set `overflow`. Otherwise output the low 16 bits.

```
FXADD: 20.0 + 20.0 = 40.0  ->  > 31.999  ->  y=0x7FFF, overflow=1
```

**Multiply with rounding (FXMUL).** A Q6.10 × Q6.10 product is Q12.20 (32 bits).
To return to Q6.10 you shift right by `FRAC=10`, **rounding half-up** by adding
`1 << (FRAC-1)` before the shift, then saturate to 16 bits.

```
prod  = a * b                       // 32-bit signed (Q12.20)
prnd  = (prod + (1<<9)) >>> 10      // back to Q6.10, rounded
y     = saturate(prnd)              // clamp to [0x8000, 0x7FFF], set overflow if clamped

example: 1.5 * 2.0 = 3.0  ->  0x0600 * 0x0800 -> prnd=0x0C00 (=3.0), overflow=0
```

> Hint: declare wide signed temporaries, e.g.
> `reg signed [WIDTH:0] addv;` and `reg signed [2*WIDTH-1:0] prod, prnd;`
> Use `$signed`, `$unsigned`, and the arithmetic shift `>>>` deliberately.

## Looking ahead — the custom instruction (HW2)

`ALU_FXMAC` is reserved now and implemented in HW2. It is the **MAC**
(multiply-accumulate) custom instruction: `y = sat(c + round(a*b))`, where `c`
is an accumulator. In HW2 you'll add one input port `c` and this one opcode —
reusing the multiplier from `FXMUL` and the saturating adder from `FXADD`. That
is the whole point: a "custom instruction" is a *small extension* of the ALU you
build here. Keep your FXMUL and FXADD logic clean and reusable.

## What "correct" means

The self-checking testbench ([`00_TB/alu_tb.v`](00_TB/alu_tb.v)) compares your
ALU against pre-committed golden patterns in [`00_TB/golden/`](00_TB/golden/)
over thousands of directed-corner and random vectors. You pass when it prints
`RESULT: PASS` (zero mismatches on `y`, `zero`, and `overflow`).
