`ifndef IOTDF_DEFS_VH
`define IOTDF_DEFS_VH
// =============================================================================
// iotdf_defs.vh  --  function-select codes for the IoT Data Filter (HW4 power).
//
// Single source of truth for the 2-bit `i_fn` field, shared by the RTL, the
// per-function units, the testbench, and the Python golden model. Use the
// macros (`` `FN_BIN2GRAY `` ...), never bare numbers.
//
// The four functions are deliberately independent byte-stream transforms so
// that, on any given stream, exactly ONE unit is active and the other three are
// idle -- the operand-isolation / clock-gating opportunity that is the whole
// point of the power homework.
// =============================================================================
`define FN_BIN2GRAY 2'd0   // o = i ^ (i>>1)                 (binary -> Gray)
`define FN_GRAY2BIN 2'd1   // o = Gray -> binary of i
`define FN_CRC8     2'd2   // running CRC-8 (poly 0x07, MSB-first, init 0)
`define FN_LFSR     2'd3   // o = i ^ keystream  (8-bit Fibonacci LFSR scramble)

// ---- CRC-8 parameters (CRC-8/SMBUS family: poly 0x07, init 0x00) ----
`define IOTDF_CRC_POLY 8'h07

// ---- LFSR scrambler parameters (8-bit Fibonacci LFSR) ----
//   taps x^8 + x^6 + x^5 + x^4  -> feedback = s[7]^s[5]^s[4]^s[3]
//   seed (reset / stream start) = 0xFF, advances 8 steps per byte.
`define IOTDF_LFSR_SEED 8'hFF
`endif
