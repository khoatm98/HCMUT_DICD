# HW4 — IoT Data Filter specification

You will implement **`iotdf`**, an 8-bit byte-stream engine with four selectable
functions, and then **measure and reduce its power**. The module interface is
fixed (the testbench and the back-end power flow depend on it).

## Module interface (do not change)

```verilog
module iotdf (
    input  wire       clk,
    input  wire       rst_n,      // synchronous, active-low reset
    input  wire       i_valid,    // 1 -> i_data/i_fn are a valid input byte
    input  wire [7:0] i_data,     // input byte
    input  wire [1:0] i_fn,       // function select (hold STABLE for a stream)
    output reg        o_valid,    // 1 -> o_data is valid this cycle
    output reg  [7:0] o_data      // transformed byte
);
```

## Streaming contract

- **1-in / 1-out with a fixed ONE-cycle latency.** A byte presented with
  `i_valid=1` on cycle *t* produces its result on `o_data` with `o_valid=1` on
  cycle *t+1* (the outputs are registered).
- When `i_valid=0`, `o_valid` is 0 the next cycle and `o_data` **holds** its last
  value (don't-care while `o_valid=0`).
- **Hold `i_fn` stable for the duration of a stream.** CRC8 and LFSR are stateful
  per-stream; mixing functions mid-stream mixes their state (allowed, but the
  golden models it exactly — keep `i_fn` constant in your own streams).
- Reset is **synchronous, active-low**: `o_valid←0`, `o_data←0`, the CRC register
  clears to 0, and the LFSR reloads its seed (reset == stream start).

## Function table (`i_fn`)

Codes are in [`common/rtl/iotdf/iotdf_defs.vh`](../../common/rtl/iotdf/iotdf_defs.vh)
— include that file and use the macros (`` `FN_BIN2GRAY `` …), never bare numbers.

| `i_fn` | name | `o_data` | stateful? |
|--------|------|----------|:---------:|
| `0` | `FN_BIN2GRAY` | `i ^ (i >> 1)` | no |
| `1` | `FN_GRAY2BIN` | Gray→binary of `i` | no |
| `2` | `FN_CRC8` | running CRC-8 register **after** folding in `i` | **yes** |
| `3` | `FN_LFSR` | `i ^ keystream` (LFSR scramble) | **yes** |

### 0 — BIN2GRAY
`o = i ^ (i >> 1)` (logical right shift, zero-fill into bit 7).
Example: `bin2gray(0x0B) = 0x0E`.

### 1 — GRAY2BIN
Inverse of BIN2GRAY. The classic recurrence is
`o[7] = i[7]; o[k] = o[k+1] ^ i[k]` for `k = 6..0`, which unrolls to the
suffix parity `o[k] = ^(i >> k)` (XOR of bits `i[7..k]`). Either form is fine.
Property to sanity-check: `gray2bin(bin2gray(x)) == x` for all `x`.

### 2 — CRC8 (poly 0x07, MSB-first, init 0)
A **running** CRC-8 (the CRC-8/SMBUS family). Each byte is folded into an 8-bit
CRC register that persists across the stream; `o_data` is the **updated** register
after the byte:

```
crc = crc ^ byte                         // XOR byte into the high bits (MSB-first)
repeat 8 times:
    crc = (crc & 0x80) ? ((crc << 1) ^ 0x07) : (crc << 1)   // 8-bit, drop carry
o_data = crc                              // output the updated register
```

The CRC register is **0 at reset / stream start**. Known check value: the running
CRC over the ASCII bytes `"123456789"` ends at **`0xF4`**. (Single bytes:
`crc8(0x00)=0x00`, `crc8(0x01)=0x07`.)

### 3 — LFSR_SCRAMBLE (8-bit Fibonacci LFSR)
`o = i ^ keystream`, where an 8-bit **Fibonacci** LFSR supplies the keystream:

- **Taps:** `x^8 + x^6 + x^5 + x^4` → feedback bit = `s[7] ^ s[5] ^ s[4] ^ s[3]`.
- **Step:** `s_next = {s[6:0], feedback}` (shift left, feedback into bit 0).
- **Seed:** `0xFF` at reset / stream start.
- **Per byte:** XOR the input with the **current** register value (the keystream
  byte), output that, then **advance the register 8 steps** for the next byte.

So the keystream bytes are the register snapshots: `0xFF, 0x0B, 0xC6, 0x80, …`.
Because XOR is self-inverse, scrambling a stream and then re-scrambling an
identically-seeded stream recovers the original bytes.

## Power-homework structure (this is the graded design intent)

Implement **each function as its own small unit** and select `o_data` with a
final mux on `i_fn`. On any given stream exactly **one** unit is active — the
other three are idle. Structure the RTL so the idle units stay quiet:

1. **Operand isolation.** Gate each unit's input data to `0` when its function
   is not selected (`din_unit = (selected & i_valid) ? i_data : 8'h00`). Idle
   combinational logic then sees a constant and does not toggle.
2. **Stateful units gate their registers.** Update `crc_reg` only when CRC8 is
   selected, and `lfsr_reg` only when LFSR is selected. Holding the flop is the
   structural hook that lets synthesis insert a **clock-gating** cell
   (`make power-cg`, which runs Yosys with `CLOCKGATE=1`).

This is the whole point of HW4: the same RTL, synthesized with and without clock
gating and exercised by the **same workload**, lets you *measure* the dynamic
power saved by keeping idle logic from switching.

## Verification model

- **Functional.** The self-checking testbench
  ([`00_TB/iotdf_tb.v`](00_TB/iotdf_tb.v)) drives a per-cycle stimulus/expected
  stream — directed corners (the `"123456789"` CRC, Gray round-trips, LFSR
  keystream) plus randomized streams — read from the **committed public** vectors
  in [`00_TB/golden/`](00_TB/golden/), and prints `RESULT: PASS` on zero
  mismatches.
- **Power.** [`00_TB/iotdf_workload_tb.v`](00_TB/iotdf_workload_tb.v) drives a
  long mixed-function workload (the committed [`00_TB/workload/`](00_TB/workload/)
  stream) to capture switching activity (a VCD). The flow synthesizes the netlist
  in `02_SYN/` (baseline and with clock gating), runs gate-level sim in `03_GATE/`
  to record the VCD, and OpenSTA `report_power` annotates the activity in
  `06_POWER/`. `cd 06_POWER && make compare` tabulates baseline vs clock-gated
  **power and area**.

## What "done" means

1. `cd 01_RTL && make vsim` (or `make sim`) prints **`RESULT: PASS`** for all four functions.
2. `cd 06_POWER && make compare` produces `06_POWER/build/power_base.rpt`,
   `06_POWER/build/power_cg.rpt`, the `02_SYN/build` area reports, and a filled
   `artifacts/ppa_compare.md` with a **quantified** before/after power (and area)
   comparison and a short discussion of clock gating + operand isolation.
