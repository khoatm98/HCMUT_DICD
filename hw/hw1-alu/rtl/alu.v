// =============================================================================
// alu.v  --  HW1 STARTER. Complete the TODOs to implement the TinyRISC-16 ALU.
//
// The module interface (ports/params) is FIXED -- do NOT change it, or the
// testbench and later homeworks (the CPU reuses this exact module) will break.
// Read SPEC.md for the full operation table and the Q6.10 fixed-point rules.
//
// Two operations (ADD, PASSB) are done as examples. Implement the rest.
// =============================================================================
`include "alu_defs.vh"

module alu #(
    parameter integer WIDTH = 16,
    parameter integer FRAC  = 10
) (
    input  wire [3:0]              op,
    input  wire signed [WIDTH-1:0] a,
    input  wire signed [WIDTH-1:0] b,
    output reg  signed [WIDTH-1:0] y,
    output wire                    zero,      // high when y == 0
    output reg                     overflow   // high when a fixed-point op saturates
);
    // Signed saturation limits, useful for the FX* operations.
    localparam signed [WIDTH:0]   MAXV = (1 <<< (WIDTH-1)) - 1;   // +32767
    localparam signed [WIDTH:0]   MINV = -(1 <<< (WIDTH-1));      // -32768
    localparam signed [WIDTH-1:0] SMAX = MAXV[WIDTH-1:0];         // 0x7FFF
    localparam signed [WIDTH-1:0] SMIN = MINV[WIDTH-1:0];         // 0x8000

    wire [4:0] sh = b[4:0];        // shift amount (0..31)

    always @* begin
        overflow = 1'b0;
        case (op)
            // ---- examples (already done) ----
            `ALU_ADD  : y = a + b;
            `ALU_PASSB: y = b;

            // ---- TODO: implement these (see SPEC.md) ----
            // `ALU_SUB  : ...
            // `ALU_AND  : ...
            // `ALU_OR   : ...
            // `ALU_XOR  : ...
            // `ALU_SLL  : ...                       // logical left  by sh
            // `ALU_SRL  : ...                       // logical right by sh
            // `ALU_SRA  : ...                       // arithmetic right by sh
            // `ALU_SLT  : ...                       // signed   set-less-than -> 0/1
            // `ALU_SLTU : ...                       // unsigned set-less-than -> 0/1
            // `ALU_FXADD: ...                        // Q6.10 saturating add  (set overflow)
            // `ALU_FXSUB: ...                        // Q6.10 saturating sub  (set overflow)
            // `ALU_FXMUL: ...                        // Q6.10 round-half-up + saturate

            default   : y = {WIDTH{1'b0}};
        endcase
    end

    // TODO: drive `zero` high when the result y is zero.
    assign zero = 1'b0;   // <-- replace this
endmodule
