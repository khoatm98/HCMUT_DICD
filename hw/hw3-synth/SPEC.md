# HW3 — 3×3 convolution engine specification

You will implement a parameterized, streaming **3×3 convolution engine** in
Verilog, then **synthesize** it to SKY130 standard cells, **prove** the gate
netlist is equivalent to your RTL, and **analyze** its area and timing. HW3 is
the *synthesis* homework: design **and** push it through the front-end of the
ASIC flow.

## Module interface (do not change)

```verilog
module conv_engine #(
    parameter integer WIDTH = 16,   // data width
    parameter integer FRAC  = 10,   // fraction bits (Q6.10)
    parameter integer IMG   = 8     // image is IMG x IMG
) (
    input  wire                    clk,
    input  wire                    rst_n,     // active-low SYNCHRONOUS reset
    input  wire                    i_valid,   // host asserts when i_data is valid
    input  wire signed [WIDTH-1:0] i_data,    // streamed word (Q6.10)
    output reg                     o_valid,   // high for one cycle per result word
    output reg  signed [WIDTH-1:0] o_data,    // result word (Q6.10)
    output reg                     o_done,    // high for one cycle after last result
    output wire                    o_busy     // high while loading/computing
);
```

The interface is fixed: the testbench, the synthesis flow, and HW5 (place &
route) all depend on it. The state codes are in
[`common/rtl/conv/conv_defs.vh`](../../../common/rtl/conv/conv_defs.vh).

## What it computes

A **3×3 convolution with zero padding** of an `IMG×IMG` image (default 8×8),
producing a **same-size** `IMG×IMG` output in raster (row-major) order:

```
out[r][c] = saturate( round_q10( SUM over dr,dc in {-1,0,1}
                                  of kernel[dr+1][dc+1] * img[r+dr][c+dc] ) )
```

Out-of-bounds neighbours (`r+dr` or `c+dc` outside `0..IMG-1`) are treated as
**0** (zero padding). So corner output pixels see 4 real neighbours, edge pixels
see 6, interior pixels see all 9.

## Numeric format — Q6.10 (same as the HW1 ALU)

Every 16-bit word — kernel and pixels — is **signed fixed-point Q6.10**: 1 sign
bit, 5 integer bits, 10 fraction bits, real value = `raw / 1024`. Range
−32.0 … +31.9990234375, step 2⁻¹⁰.

| raw (hex) | Q6.10 value |
|-----------|-------------|
| `0x0400` | +1.0 |
| `0x0200` | +0.5 |
| `0xFC00` | −1.0 |
| `0x0072` | +0.111 ≈ 1/9 (a box-blur tap) |
| `0x7FFF` | +31.999 (max) |
| `0x8000` | −32.0 (min) |

### The fixed-point math (the tricky part — mirror `alu.v`'s FXMUL)

A single product `kernel × pixel` is Q6.10 × Q6.10 = **Q12.20** (32-bit signed).
The nine taps are **accumulated in FULL precision** (use a wide signed
accumulator — the reference uses `2*WIDTH+8 = 40` bits, plenty of headroom),
**then** converted back to Q6.10 **once per output pixel**:

```
acc  = SUM of nine Q12.20 products          // wide signed accumulator
accr = (acc + (1 << (FRAC-1))) >>> FRAC      // round HALF-UP, back to Q6.10
out  = saturate(accr)                        // clamp to [0x8000, 0x7FFF]
```

- **Round half-up:** add `1 << (FRAC-1) = 512` *before* the arithmetic right
  shift `>>> FRAC`. Do **not** truncate.
- **Saturate:** if `accr > +32767` output `0x7FFF`; if `accr < −32768` output
  `0x8000`; else output the low 16 bits.
- Rounding/saturation happen **once per output pixel** (after summing all nine
  products), **not** per product — this is exactly the ALU FXMUL rule applied to
  a dot product. Study [`common/rtl/alu/alu.v`](../../../common/rtl/alu/alu.v).

> ⚠️ Common mistake: rounding each product back to Q6.10 and then summing. That
> loses precision and fails the golden check. Accumulate first, round last.

## Streaming protocol

The host streams 16-bit words in, one accepted per clock while `i_valid` is
high (the engine is **always ready** during loading — no back-pressure):

1. **9 kernel words**, row-major: `k00 k01 k02 k10 k11 k12 k20 k21 k22`
   (i.e. `kernel[dr+1][dc+1]` with tap index `t = (dr+1)*3 + (dc+1)`).
2. **`IMG*IMG` image words** (64 for 8×8), row-major: `img[0][0] … img[7][7]`.

Total **9 + 64 = 73** input words. After the **last image word** the engine
computes (no further input needed). Then it **streams the 64 results**: each
result cycle it raises `o_valid` for one cycle with `o_data` = the next result
in raster order. After the **last** result it pulses `o_done` for one cycle and
parks. `o_busy` is high from reset until it parks in the DONE state.

```
            <-------- 73 input words --------> <-- compute --> <-- 64 outputs -->
 i_valid  __/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\______________________________________
 i_data     k00 k01 ... k22 img0 img1 ... img63
 o_valid  ________________________________________________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\________
 o_data                                                     out0 out1 ... out63
 o_done   ____________________________________________________________________/‾\__
```

The testbench samples `o_data` on **every** cycle `o_valid` is high and collects
exactly `IMG*IMG` results — so your output latency (how many idle cycles after
the stream) does not matter, only the **values, count, and order**.

## Microarchitecture (small + a memory macro — required)

- **One shared multiplier**, driven by a **sequential 9-tap multiply-accumulate**
  — accumulate the nine products over several cycles per output pixel. Do **not**
  instantiate nine multipliers or a parallel adder tree.
- A **4-state FSM**: `LOAD → COMPUTE → OUTPUT → DONE` (codes in `conv_defs.vh`).
- The **feature map lives in a SKY130 OpenRAM SRAM hard macro**
  (`sky130_sram_1kbyte_1rw1r_32x256_8`), **not** a flop array — this is the
  memory-macro integration lesson (synthesis blackboxes it; HW5 APR places it).
  The 9-word kernel and the result buffer stay in flops.
- **Synchronous (registered) SRAM read.** The macro samples the address on a
  clock edge and the data is valid the **next** cycle, so each tap runs in two
  phases: **ISSUE** (drive the read address — done *combinationally*) then
  **ACCUMULATE** (the data is ready → multiply-accumulate). Write the 64 pixels
  into the SRAM during LOAD (port 0); read during COMPUTE (port 1).
- **Active-low synchronous reset**; **no latches**.

The starter `01_RTL/conv_engine.v` provides the SRAM instance + its combinational
control, the tap → (dr,dc) zero-padded mapping, the datapath wires, and the
LOAD/OUTPUT/DONE phases. You implement the **COMPUTE accumulate**: use the read
pixel, accumulate the nine products, and write the per-pixel round-half-up +
saturate result.

> **Why an SRAM?** A real image/feature buffer is on-chip SRAM, and integrating a
> hard macro (blackbox in synthesis, place + power-connect in APR) is a core
> back-end skill (and what NTU CVSD's HW3 exercises). For simulation a behavioral
> model (`common/rtl/conv/sky130_sram_1kbyte_1rw1r_32x256_8.v`) stands in for the
> macro; synthesis/APR use the real macro's `.lib`/`.lef`/`.gds`.

## The back-end half of HW3 (synthesis / equivalence / STA)

Once the RTL passes the functional check:

- **`make synth`** (in `02_SYN/`) runs Yosys → a SKY130 gate-level netlist
  (`02_SYN/build/conv_netlist.v`) + an **area/cell report**
  (`02_SYN/build/conv_area.rpt`).
- **`make sta`** (in `02_SYN/`) runs OpenSTA on that netlist using **your**
  [`02_SYN/conv.sdc`](02_SYN/conv.sdc) (clock period + CVSD-style I/O delays) and
  reports setup/hold **slack**.
- **`make gl-sim`** (in `03_GATE/`) runs the **same** self-checking testbench
  against the synthesized netlist + SKY130 cell models, compared to the **same**
  golden — proving the gate netlist is **functionally equivalent** to your RTL.

## What "correct" means

The self-checking testbench ([`00_TB/conv_engine_tb.v`](00_TB/conv_engine_tb.v))
drives the input stream and compares your outputs against the **committed public
golden patterns** in [`00_TB/golden/`](00_TB/golden) over several test cases (box
blur, Sobel edge, identity, random kernels, and a saturation stress case). You
pass the functional gate when it prints `RESULT: PASS` (zero pixel mismatches
across all cases). You complete HW3 when `make gl-sim` also prints `RESULT: PASS`
(gate equivalence) and `make sta` reports no timing violations.
