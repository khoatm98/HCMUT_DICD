`ifndef ISA_DEFS_VH
`define ISA_DEFS_VH
// =============================================================================
// TinyRISC-16 ISA -- single source of truth (shared by RTL, assembler, ISS).
//
// 16-bit instructions, 16-bit data, 8 registers R0..R7 (R0 hardwired 0),
// single-cycle, Harvard memory (separate instruction + data memories).
//
// Instruction formats (bit 15 .. bit 0):
//   R-type : [op:4][rd:3][rs:3][rt:3][funct:3]
//   I-type : [op:4][rd:3][rs:3][imm:6]            (imm sign-extended)
//   J-type : [op:4][addr:12]
// =============================================================================

// ---- opcodes (instr[15:12]) ----
`define OP_ALU    4'h0   // R: rd = rs <funct> rt              (integer)
`define OP_FALU   4'h1   // R: rd = rs <funct> rt              (fixed-point Q6.10)
`define OP_MAC    4'h2   // R: rd = sat(rd + round(rs*rt))     (CUSTOM instruction)
`define OP_ADDI   4'h3   // I: rd = rs + sext(imm)
`define OP_LW     4'h4   // I: rd = DMEM[rs + sext(imm)]
`define OP_SW     4'h5   // I: DMEM[rs + sext(imm)] = rd
`define OP_BEQ    4'h6   // I: if (rd == rs) PC = PC+1+sext(imm)
`define OP_BNE    4'h7   // I: if (rd != rs) PC = PC+1+sext(imm)
`define OP_JMP    4'h8   // J: PC = addr
`define OP_JAL    4'h9   // J: R7 = PC+1; PC = addr
`define OP_HALT   4'hF   // stop execution

// ---- funct for OP_ALU (instr[2:0]) -> selects an integer ALU op ----
`define F_ADD   3'd0
`define F_SUB   3'd1
`define F_AND   3'd2
`define F_OR    3'd3
`define F_XOR   3'd4
`define F_SLT   3'd5
`define F_SLL   3'd6
`define F_SRA   3'd7

// ---- funct for OP_FALU (instr[2:0]) -> selects a fixed-point ALU op ----
`define FF_FXADD 3'd0
`define FF_FXSUB 3'd1
`define FF_FXMUL 3'd2

`endif
