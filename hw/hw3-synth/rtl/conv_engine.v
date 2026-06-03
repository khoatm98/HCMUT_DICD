// =============================================================================
// conv_engine.v  --  HW3 STARTER. Complete the TODOs to implement the 3x3
// convolution engine, then SYNTHESIZE it, prove gate-equivalence, and analyze
// area/timing.
//
// The module interface (ports/params) is FIXED -- do NOT change it, or the
// testbench, the synthesis flow, and HW5 (which places-and-routes this design)
// will break. Read SPEC.md for the streaming protocol and the Q6.10 rules, and
// study common/rtl/alu/alu.v for the FXMUL round-half-up + saturation idiom.
//
// What is provided for you:
//   * the full port list + parameters,
//   * the saturation/rounding constants and wide accumulator declaration,
//   * the FSM state register and the LOAD phase (streaming kernel+image in),
//   * the OUTPUT and DONE phases (streaming results out + o_done pulse).
// What YOU implement (the heart of the design):
//   * the tap -> (dr,dc) neighbour mapping with zero padding,
//   * the single shared multiplier and the sequential 9-tap accumulate,
//   * the per-pixel round-half-up + saturate write-back into res[].
//
// RTL style requirements (graded + needed for clean synthesis): synthesizable
// (NO $readmemh/initial here), parameterized, active-low SYNCHRONOUS reset, no
// latches (assign every reg on every path).
// =============================================================================
`include "conv_defs.vh"

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
    // ---------------- derived sizes ----------------
    localparam integer NPIX  = IMG * IMG;
    localparam integer NTAP  = 9;
    localparam integer IDXW  = $clog2(NPIX);
    localparam integer KIDXW = 4;

    // ---------------- saturation / rounding constants (mirror the ALU) ----------------
    localparam signed [WIDTH:0]     MAXV = (1 <<< (WIDTH-1)) - 1;   // +32767
    localparam signed [WIDTH:0]     MINV = -(1 <<< (WIDTH-1));      // -32768
    localparam signed [WIDTH-1:0]   SMAX = MAXV[WIDTH-1:0];         // 0x7FFF
    localparam signed [WIDTH-1:0]   SMIN = MINV[WIDTH-1:0];         // 0x8000
    localparam integer ACCW = 2*WIDTH + 8;                          // wide accumulator
    localparam signed [ACCW-1:0]    RND  = (1 <<< (FRAC-1));        // round-half-up bias

    // ---------------- storage (flop arrays, loaded by the stream) ----------------
    reg signed [WIDTH-1:0] kern  [0:NTAP-1];
    reg signed [WIDTH-1:0] img   [0:NPIX-1];
    reg signed [WIDTH-1:0] res   [0:NPIX-1];

    // ---------------- control state ----------------
    reg  [1:0]            state;
    reg  [KIDXW-1:0]      kcnt;
    reg  [IDXW:0]         icnt;
    reg  [IDXW:0]         ocnt;
    reg  [IDXW-1:0]       pix;
    reg  [3:0]            tap;
    reg  signed [ACCW-1:0] acc;
    integer ii;

    // ---------------- output-pixel row/col and tap offsets ----------------
    wire [IDXW-1:0] prow = pix / IMG[IDXW-1:0];
    wire [IDXW-1:0] pcol = pix % IMG[IDXW-1:0];
    reg  signed [IDXW+1:0] nrow, ncol;
    reg  signed [3:0]      dr, dc;
    always @* begin
        // TODO: decode the current tap (0..8) into (dr, dc), each in {-1,0,1},
        //       using the layout t = (dr+1)*3 + (dc+1). Beware: tap mod 3, NOT
        //       tap[1:0]. Then form nrow = prow + dr, ncol = pcol + dc.
        dr   = 4'sd0;                    // <-- replace
        dc   = 4'sd0;                    // <-- replace
        nrow = $signed({2'b00, prow}) + dr;
        ncol = $signed({2'b00, pcol}) + dc;
    end

    // in-bounds neighbour pixel (zero padding) and its flat index
    wire inb = (nrow >= 0) && (nrow < IMG) && (ncol >= 0) && (ncol < IMG);
    wire [IDXW-1:0] nidx = nrow[IDXW-1:0] * IMG[IDXW-1:0] + ncol[IDXW-1:0];
    wire signed [WIDTH-1:0] pixval = inb ? img[nidx] : {WIDTH{1'b0}};

    // ---------------- the single shared multiplier ----------------
    // TODO: form the Q12.20 product of the current kernel tap and pixval.
    wire signed [2*WIDTH-1:0] prod = {(2*WIDTH){1'b0}};   // <-- replace

    // ---------------- per-pixel round-half-up + saturate ----------------
    wire signed [ACCW-1:0] accr = (acc + RND) >>> FRAC;
    reg  signed [WIDTH-1:0] pixres;
    always @* begin
        // TODO: clamp accr to [SMIN, SMAX] (mirror the ALU FXMUL saturation).
        pixres = accr[WIDTH-1:0];        // <-- replace with saturating clamp
    end

    assign o_busy = (state != `CONV_S_DONE);

    // ---------------- sequential control + datapath ----------------
    always @(posedge clk) begin
        if (!rst_n) begin
            state   <= `CONV_S_LOAD;
            kcnt    <= {KIDXW{1'b0}};
            icnt    <= {(IDXW+1){1'b0}};
            ocnt    <= {(IDXW+1){1'b0}};
            pix     <= {IDXW{1'b0}};
            tap     <= 4'd0;
            acc     <= {ACCW{1'b0}};
            o_valid <= 1'b0;
            o_data  <= {WIDTH{1'b0}};
            o_done  <= 1'b0;
            for (ii = 0; ii < NTAP; ii = ii + 1) kern[ii] <= {WIDTH{1'b0}};
            for (ii = 0; ii < NPIX; ii = ii + 1) begin
                img[ii] <= {WIDTH{1'b0}};
                res[ii] <= {WIDTH{1'b0}};
            end
        end else begin
            o_valid <= 1'b0;
            o_done  <= 1'b0;

            case (state)
                // -------- LOAD (provided): 9 kernel words then NPIX image words --------
                `CONV_S_LOAD: begin
                    if (i_valid) begin
                        if (kcnt < NTAP[KIDXW-1:0]) begin
                            kern[kcnt] <= i_data;
                            kcnt       <= kcnt + 1'b1;
                        end else begin
                            img[icnt[IDXW-1:0]] <= i_data;
                            if (icnt == (NPIX-1)) begin
                                icnt  <= icnt + 1'b1;
                                state <= `CONV_S_COMPUTE;
                                pix   <= {IDXW{1'b0}};
                                tap   <= 4'd0;
                                acc   <= {ACCW{1'b0}};
                            end else begin
                                icnt <= icnt + 1'b1;
                            end
                        end
                    end
                end

                // -------- COMPUTE (TODO): 9-tap MAC, then round+sat into res --------
                `CONV_S_COMPUTE: begin
                    // TODO: implement the sequential multiply-accumulate.
                    //   while tap < 9 : acc <= acc + sign_extend(prod); tap <= tap+1;
                    //   at tap == 9   : res[pix] <= pixres; reset acc, tap; advance
                    //                   pix; when pix == NPIX-1 -> go to OUTPUT.
                    // The starter just jumps straight to OUTPUT with res[] = 0,
                    // so the checker will report mismatches until you fill this in.
                    state <= `CONV_S_OUTPUT;
                    ocnt  <= {(IDXW+1){1'b0}};
                end

                // -------- OUTPUT (provided): stream NPIX results in raster order --------
                `CONV_S_OUTPUT: begin
                    o_valid <= 1'b1;
                    o_data  <= res[ocnt[IDXW-1:0]];
                    if (ocnt == (NPIX-1)) state <= `CONV_S_DONE;
                    ocnt <= ocnt + 1'b1;
                end

                // -------- DONE (provided): pulse o_done once, then park --------
                default: begin
                    if (ocnt == NPIX[IDXW:0]) begin
                        o_done <= 1'b1;
                        ocnt   <= ocnt + 1'b1;
                    end
                    state <= `CONV_S_DONE;
                end
            endcase
        end
    end
endmodule
