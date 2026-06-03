// =============================================================================
// cpu_core.v  --  TinyRISC-16 single-cycle CPU core (reference implementation).
//
// One instruction per clock, no pipeline / hazards / forwarding. The HW1 ALU is
// the execution unit (instantiated unchanged). The MAC custom instruction is
// realized here in the datapath: the ALU's FXMUL produces round(rs*rt), and a
// small saturating adder accumulates it into reg[rd] -- reusing the expensive
// multiplier while adding only one decode case + one accumulate.
//
// Memory is external (Harvard): combinational instruction + data read ports,
// synchronous data write. This keeps the synthesizable core macro-free.
// ISA: see isa_defs.vh.  ALU ops: see alu_defs.vh.
// =============================================================================
`include "alu_defs.vh"
`include "isa_defs.vh"

module cpu_core #(
    parameter integer WIDTH = 16,
    parameter integer AW    = 8        // address width -> 2^AW words of imem/dmem
) (
    input  wire             clk,
    input  wire             rst_n,
    // instruction memory (read-only, combinational)
    output wire [AW-1:0]    imem_addr,
    input  wire [WIDTH-1:0] imem_rdata,
    // data memory
    output wire [AW-1:0]    dmem_addr,
    output wire [WIDTH-1:0] dmem_wdata,
    output wire             dmem_we,
    input  wire [WIDTH-1:0] dmem_rdata,
    // status
    output wire             halted,
    output wire [AW-1:0]    pc_out
);
    // ---------------- program counter ----------------
    reg  [AW-1:0] pc;
    wire [AW-1:0] pc_plus1 = pc + {{(AW-1){1'b0}}, 1'b1};
    assign imem_addr = pc;
    assign pc_out    = pc;

    // ---------------- decode ----------------
    wire [WIDTH-1:0] instr  = imem_rdata;
    wire [3:0]       op     = instr[15:12];
    wire [2:0]       rd     = instr[11:9];
    wire [2:0]       rs     = instr[8:6];
    wire [2:0]       rt     = instr[5:3];
    wire [2:0]       funct  = instr[2:0];
    wire [5:0]       imm6   = instr[5:0];
    wire [11:0]      addr12 = instr[11:0];
    wire signed [WIDTH-1:0] sext_imm = {{(WIDTH-6){imm6[5]}}, imm6};

    // ---------------- register file (3 read ports) ----------------
    wire [WIDTH-1:0] rda, rdb, rdc;     // reg[rs], reg[rt], reg[rd]
    reg              regwrite;
    reg  [2:0]       waddr;
    reg  [WIDTH-1:0] wdata;
    regfile #(.WIDTH(WIDTH)) u_rf (
        .clk(clk), .rst_n(rst_n),
        .we(regwrite & ~halted), .wa(waddr), .wd(wdata),
        .ra(rs), .rb(rt), .rc(rd),
        .rda(rda), .rdb(rdb), .rdc(rdc)
    );

    // ---------------- ALU ----------------
    reg  [3:0]              alu_op;
    wire                    use_imm = (op == `OP_ADDI) || (op == `OP_LW) || (op == `OP_SW);
    wire signed [WIDTH-1:0] alu_a   = rda;
    wire signed [WIDTH-1:0] alu_b   = use_imm ? sext_imm : rdb;
    wire signed [WIDTH-1:0] alu_y;
    wire                    alu_zero, alu_ovf;
    alu #(.WIDTH(WIDTH)) u_alu (
        .op(alu_op), .a(alu_a), .b(alu_b),
        .y(alu_y), .zero(alu_zero), .overflow(alu_ovf)
    );

    always @* begin
        alu_op = `ALU_ADD;
        case (op)
            `OP_ALU: case (funct)
                `F_ADD:  alu_op = `ALU_ADD;
                `F_SUB:  alu_op = `ALU_SUB;
                `F_AND:  alu_op = `ALU_AND;
                `F_OR:   alu_op = `ALU_OR;
                `F_XOR:  alu_op = `ALU_XOR;
                `F_SLT:  alu_op = `ALU_SLT;
                `F_SLL:  alu_op = `ALU_SLL;
                `F_SRA:  alu_op = `ALU_SRA;
                default: alu_op = `ALU_ADD;
            endcase
            `OP_FALU: case (funct)
                `FF_FXADD: alu_op = `ALU_FXADD;
                `FF_FXSUB: alu_op = `ALU_FXSUB;
                `FF_FXMUL: alu_op = `ALU_FXMUL;
                default:   alu_op = `ALU_FXADD;
            endcase
            `OP_MAC: alu_op = `ALU_FXMUL;      // product term; accumulate below
            default: alu_op = `ALU_ADD;        // ADDI / LW / SW address calc
        endcase
    end

    // ---------------- MAC accumulate: rd = saturate(reg[rd] + alu_y) ----------------
    localparam signed [WIDTH:0]   MAXV = (1 <<< (WIDTH-1)) - 1;
    localparam signed [WIDTH:0]   MINV = -(1 <<< (WIDTH-1));
    localparam signed [WIDTH-1:0] SMAX = MAXV[WIDTH-1:0];
    localparam signed [WIDTH-1:0] SMIN = MINV[WIDTH-1:0];
    wire signed [WIDTH:0] mac_sum = $signed(rdc) + $signed(alu_y);
    reg  signed [WIDTH-1:0] mac_y;
    always @* begin
        if      (mac_sum > MAXV) mac_y = SMAX;
        else if (mac_sum < MINV) mac_y = SMIN;
        else                     mac_y = mac_sum[WIDTH-1:0];
    end

    // ---------------- branch compare ----------------
    wire branch_eq   = (rdc == rda);                       // reg[rd] == reg[rs]
    wire take_branch = ((op == `OP_BEQ) &  branch_eq) |
                       ((op == `OP_BNE) & ~branch_eq);

    // ---------------- write-back ----------------
    always @* begin
        regwrite = 1'b0;
        waddr    = rd;
        wdata    = alu_y;
        case (op)
            `OP_ALU, `OP_FALU, `OP_ADDI: begin regwrite = 1'b1; wdata = alu_y;       end
            `OP_MAC:                     begin regwrite = 1'b1; wdata = mac_y;       end
            `OP_LW:                      begin regwrite = 1'b1; wdata = dmem_rdata;  end
            `OP_JAL:                     begin regwrite = 1'b1; waddr = 3'd7;
                                               wdata = {{(WIDTH-AW){1'b0}}, pc_plus1}; end
            default:                     regwrite = 1'b0;
        endcase
    end

    // ---------------- data memory ----------------
    assign dmem_addr  = alu_y[AW-1:0];
    assign dmem_wdata = rdc;                               // reg[rd]
    assign dmem_we    = (op == `OP_SW) & ~halted;

    // ---------------- halt ----------------
    assign halted = (op == `OP_HALT);

    // ---------------- next PC ----------------
    wire [AW-1:0] branch_target = pc_plus1 + sext_imm[AW-1:0];
    wire [AW-1:0] jump_target   = addr12[AW-1:0];
    reg  [AW-1:0] next_pc;
    always @* begin
        if      (halted)                            next_pc = pc;
        else if (op == `OP_JMP || op == `OP_JAL)    next_pc = jump_target;
        else if (take_branch)                       next_pc = branch_target;
        else                                        next_pc = pc_plus1;
    end

    always @(posedge clk) begin
        if (!rst_n) pc <= {AW{1'b0}};
        else        pc <= next_pc;
    end

    // alu_zero / alu_ovf are intentionally unused by the core (branches use a
    // dedicated comparator); keep them connected for waveform visibility.
    wire _unused = &{1'b0, alu_zero, alu_ovf};
endmodule
