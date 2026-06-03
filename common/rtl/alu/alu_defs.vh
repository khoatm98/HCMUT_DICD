`ifndef ALU_DEFS_VH
`define ALU_DEFS_VH
// =============================================================================
// TinyRISC-16 ALU operation codes (4-bit `op`). Single source of truth shared
// by the ALU (HW1), the CPU decoder (HW2), and the testbenches.
//
// Numeric model: 16-bit words interpreted either as signed integers (two's
// complement) or as signed fixed-point Q6.10 (1 sign + 5 integer + 10 fraction
// bits). Q6.10 range is [-32.0, +31.9990234375], resolution 2^-10.
// =============================================================================
`define ALU_ADD    4'h0   // y = a + b              (integer, wraps)
`define ALU_SUB    4'h1   // y = a - b              (integer, wraps)
`define ALU_AND    4'h2   // y = a & b
`define ALU_OR     4'h3   // y = a | b
`define ALU_XOR    4'h4   // y = a ^ b
`define ALU_SLL    4'h5   // y = a << b[4:0]        (logical left)
`define ALU_SRL    4'h6   // y = a >> b[4:0]        (logical right)
`define ALU_SRA    4'h7   // y = a >>> b[4:0]       (arithmetic right)
`define ALU_SLT    4'h8   // y = (a <  b) ? 1 : 0   (signed)
`define ALU_SLTU   4'h9   // y = (a <  b) ? 1 : 0   (unsigned)
`define ALU_FXADD  4'hA   // y = sat(a + b)         (Q6.10, saturating)
`define ALU_FXSUB  4'hB   // y = sat(a - b)         (Q6.10, saturating)
`define ALU_FXMUL  4'hC   // y = sat(round(a*b))    (Q6.10, round-half-up + sat)
`define ALU_PASSB  4'hD   // y = b                  (pass operand B; load-immediate)
`define ALU_FXMAC  4'hE   // RESERVED for HW2: y = sat(c + round(a*b)) -- ALU gains
                          // an accumulator input `c` (the custom MAC instruction).
`endif
