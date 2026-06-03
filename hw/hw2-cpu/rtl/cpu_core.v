// =============================================================================
// cpu_core.v  --  HW2 STARTER. Complete the TODOs to build the TinyRISC-16 CPU.
//
// The datapath skeleton (PC, instruction decode, register file, ALU instance)
// is provided. You implement the CONTROL: how each instruction drives the ALU,
// the write-back, data memory, the MAC custom instruction, and the next PC.
//
// The module interface is FIXED (the testbench and HW3+ depend on it). The ALU
// (HW1) and register file are provided -- do not edit them. See SPEC.md.
// =============================================================================
`include "alu_defs.vh"
`include "isa_defs.vh"

module cpu_core #(
    parameter integer WIDTH = 16,
    parameter integer AW    = 8
) (
    input  wire             clk,
    input  wire             rst_n,
    output wire [AW-1:0]    imem_addr,
    input  wire [WIDTH-1:0] imem_rdata,
    output wire [AW-1:0]    dmem_addr,
    output wire [WIDTH-1:0] dmem_wdata,
    output wire             dmem_we,
    input  wire [WIDTH-1:0] dmem_rdata,
    output wire             halted,
    output wire [AW-1:0]    pc_out
);
    // ---- program counter ----
    reg  [AW-1:0] pc;
    wire [AW-1:0] pc_plus1 = pc + 1'b1;
    assign imem_addr = pc;
    assign pc_out    = pc;

    // ---- instruction decode (provided) ----
    wire [WIDTH-1:0] instr  = imem_rdata;
    wire [3:0]       op     = instr[15:12];
    wire [2:0]       rd     = instr[11:9];
    wire [2:0]       rs     = instr[8:6];
    wire [2:0]       rt     = instr[5:3];
    wire [2:0]       funct  = instr[2:0];
    wire [5:0]       imm6   = instr[5:0];
    wire [11:0]      addr12 = instr[11:0];
    wire signed [WIDTH-1:0] sext_imm = {{(WIDTH-6){imm6[5]}}, imm6};

    // ---- register file (provided): reads reg[rs], reg[rt], reg[rd] ----
    wire [WIDTH-1:0] rda, rdb, rdc;
    reg              regwrite;
    reg  [2:0]       waddr;
    reg  [WIDTH-1:0] wdata;
    regfile #(.WIDTH(WIDTH)) u_rf (
        .clk(clk), .rst_n(rst_n),
        .we(regwrite & ~halted), .wa(waddr), .wd(wdata),
        .ra(rs), .rb(rt), .rc(rd), .rda(rda), .rdb(rdb), .rdc(rdc)
    );

    // ---- ALU (provided instance); you drive alu_op and alu_b ----
    reg  [3:0]              alu_op;
    reg  signed [WIDTH-1:0] alu_b;
    wire signed [WIDTH-1:0] alu_a = rda;
    wire signed [WIDTH-1:0] alu_y;
    wire                    alu_zero, alu_ovf;
    alu #(.WIDTH(WIDTH)) u_alu (
        .op(alu_op), .a(alu_a), .b(alu_b),
        .y(alu_y), .zero(alu_zero), .overflow(alu_ovf)
    );

    // ===================== TODO #1: ALU operand-B mux =====================
    // ADDI / LW / SW use the sign-extended immediate; everything else uses rdb.
    always @* begin
        alu_b = rdb;        // TODO: pick sext_imm for OP_ADDI / OP_LW / OP_SW
    end

    // ===================== TODO #2: ALU operation decode ==================
    // Map (op, funct) -> ALU op (see SPEC.md and alu_defs.vh):
    //   OP_ALU  funct -> ADD/SUB/AND/OR/XOR/SLT/SLL/SRA
    //   OP_FALU funct -> FXADD/FXSUB/FXMUL
    //   OP_MAC        -> FXMUL (product; accumulate in TODO #3)
    //   OP_ADDI/LW/SW -> ADD   (address / immediate add)
    always @* begin
        alu_op = `ALU_ADD;  // TODO: full decode
    end

    // ===================== TODO #3: MAC accumulate ========================
    // rd = saturate(reg[rd] + alu_y), where alu_y = round(rs*rt) from FXMUL.
    reg signed [WIDTH-1:0] mac_y;
    always @* begin
        mac_y = alu_y;      // TODO: saturating add of rdc (=reg[rd]) and alu_y
    end

    // ===================== TODO #4: write-back ============================
    // Set regwrite / waddr / wdata per opcode:
    //   ALU,FALU,ADDI -> alu_y ;  MAC -> mac_y ;  LW -> dmem_rdata ;
    //   JAL -> write R7 with pc_plus1 ;  others -> no write.
    always @* begin
        regwrite = 1'b0;    // TODO
        waddr    = rd;
        wdata    = alu_y;
    end

    // ===================== TODO #5: data memory ===========================
    assign dmem_addr  = alu_y[AW-1:0];   // provided: rs+imm for LW/SW
    assign dmem_wdata = rdc;             // provided: store reg[rd]
    assign dmem_we    = 1'b0;            // TODO: assert for OP_SW (and not halted)

    // ===================== TODO #6: branch + next PC ======================
    assign halted = (op == `OP_HALT);    // provided
    reg [AW-1:0] next_pc;
    always @* begin
        next_pc = pc_plus1; // TODO: JMP/JAL -> addr12 ; taken BEQ/BNE -> pc+1+imm ;
                            //       when halted, hold pc
    end

    always @(posedge clk) begin
        if (!rst_n) pc <= {AW{1'b0}};
        else        pc <= next_pc;
    end

    // keep currently-unused decode signals from tripping lint while you build
    wire _unused = &{1'b0, alu_zero, alu_ovf, addr12, funct, sext_imm, rdc};
endmodule
