`ifndef CONV_DEFS_VH
`define CONV_DEFS_VH
// =============================================================================
// conv_defs.vh -- shared parameters/encodings for the 3x3 convolution engine.
//
// Single source of truth for the FSM state codes and the streaming-protocol
// constants, shared by the engine (HW3 RTL) and the testbench. Reuses the same
// Q6.10 numeric model as the HW1 ALU (WIDTH=16, FRAC=10): each 16-bit word is
// signed fixed-point (1 sign + 5 integer + 10 fraction bits, value = raw/1024).
// =============================================================================

// ---- FSM state encoding (4 states) ----
`define CONV_S_LOAD    2'd0   // streaming in kernel (9) + image (64) words
`define CONV_S_COMPUTE 2'd1   // sequential 9-tap MAC per output pixel
`define CONV_S_OUTPUT  2'd2   // streaming out 64 results in raster order
`define CONV_S_DONE    2'd3   // all 64 outputs sent; o_done asserted

`endif
