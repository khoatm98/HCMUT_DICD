// =============================================================================
// alu.v  --  TinyRISC-16 Arithmetic Logic Unit (reference implementation).
//
// Combinational ALU shared by HW1 (build + verify it) and HW2+ (it becomes the
// CPU's execution unit -- this is the continuity spine of the course).
//
// Numeric model (WIDTH=16, FRAC=10): each 16-bit word is read either as a signed
// two's-complement integer, or as signed fixed-point Q6.10 (1 sign + 5 integer +
// 10 fraction bits). Fixed-point ops saturate; FXMUL rounds half-up.
//
// Operation codes are in alu_defs.vh (single source of truth, shared with the
// CPU decoder and testbenches).
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
    output wire                    zero,      // y == 0
    output reg                     overflow   // set when a fixed-point op saturates
);
    // Signed saturation limits (wide enough to compare against extended sums).
    localparam signed [WIDTH:0]     MAXV = (1 <<< (WIDTH-1)) - 1;   // +32767
    localparam signed [WIDTH:0]     MINV = -(1 <<< (WIDTH-1));      // -32768
    localparam signed [WIDTH-1:0]   SMAX = MAXV[WIDTH-1:0];         // 0x7FFF
    localparam signed [WIDTH-1:0]   SMIN = MINV[WIDTH-1:0];         // 0x8000
    localparam signed [2*WIDTH-1:0] RND  = (1 <<< (FRAC-1));        // round half-up bias

    wire [4:0]                sh = b[4:0];          // shift amount 0..31
    reg  signed [WIDTH:0]     addv, subv;           // 1 extra bit for overflow test
    reg  signed [2*WIDTH-1:0] prod, prnd;           // full + rounded product

    always @* begin
        overflow = 1'b0;
        addv = $signed(a) + $signed(b);
        subv = $signed(a) - $signed(b);
        prod = $signed(a) * $signed(b);
        prnd = (prod + RND) >>> FRAC;               // Q12.20 -> Q6.10, rounded

        case (op)
            `ALU_ADD  : y = a + b;                  // integer add (wraps)
            `ALU_SUB  : y = a - b;                  // integer sub (wraps)
            `ALU_AND  : y = a & b;
            `ALU_OR   : y = a | b;
            `ALU_XOR  : y = a ^ b;
            `ALU_SLL  : y = a << sh;                // logical left
            `ALU_SRL  : y = $unsigned(a) >> sh;     // logical right
            `ALU_SRA  : y = a >>> sh;               // arithmetic right
            `ALU_SLT  : y = ($signed(a)   < $signed(b))   ? {{(WIDTH-1){1'b0}}, 1'b1} : {WIDTH{1'b0}};
            `ALU_SLTU : y = ($unsigned(a) < $unsigned(b)) ? {{(WIDTH-1){1'b0}}, 1'b1} : {WIDTH{1'b0}};
            `ALU_FXADD: begin                       // Q6.10 saturating add
                if      (addv > MAXV) begin y = SMAX; overflow = 1'b1; end
                else if (addv < MINV) begin y = SMIN; overflow = 1'b1; end
                else                       y = addv[WIDTH-1:0];
            end
            `ALU_FXSUB: begin                       // Q6.10 saturating sub
                if      (subv > MAXV) begin y = SMAX; overflow = 1'b1; end
                else if (subv < MINV) begin y = SMIN; overflow = 1'b1; end
                else                       y = subv[WIDTH-1:0];
            end
            `ALU_FXMUL: begin                       // Q6.10 multiply, round + saturate
                if      (prnd > MAXV) begin y = SMAX; overflow = 1'b1; end
                else if (prnd < MINV) begin y = SMIN; overflow = 1'b1; end
                else                       y = prnd[WIDTH-1:0];
            end
            `ALU_PASSB: y = b;                      // pass operand B (load-immediate)
            default   : y = {WIDTH{1'b0}};
        endcase
    end

    assign zero = (y == {WIDTH{1'b0}});
endmodule
