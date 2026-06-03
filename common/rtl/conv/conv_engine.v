// =============================================================================
// conv_engine.v  --  3x3 convolution engine (reference implementation).
//
// Streaming, single-clock, macro-free convolution accelerator. This is the
// design HW3 SYNTHESIZES to SKY130 gates, proves gate-equivalent, and analyzes
// for area/timing (and that HW5 places-and-routes). It is deliberately small:
// one shared multiplier driven by a sequential 9-tap multiply-accumulate, a
// 4-state FSM, and on-chip flop arrays (no SRAM macros).
//
// Numeric model (WIDTH=16, FRAC=10): pixels and kernel are signed fixed-point
// Q6.10 (1 sign + 5 integer + 10 fraction bits, value = raw/1024), EXACTLY as in
// common/rtl/alu/alu.v. Each product is Q6.10 * Q6.10 = Q12.20; the nine
// products are accumulated in FULL precision, then the accumulator is rounded
// half-up (add 1<<(FRAC-1), arithmetic >>> FRAC) and SATURATED to signed 16 bits
// -- the same FXMUL rounding/saturation rule as the ALU, applied once per pixel.
//
// Convolution: 3x3 kernel over an IMG x IMG image with ZERO PADDING, producing
// a same-size IMG x IMG output in raster (row-major) order:
//   out[r][c] = sat( round_q10( SUM_{dr,dc in -1,0,1} k[dr+1][dc+1]*img[r+dr][c+dc] ) )
// with out-of-bounds img pixels treated as 0.
//
// Streaming protocol (host-driven; the engine is always ready while loading):
//   After reset (active-low, SYNCHRONOUS) the host streams, each beat qualified
//   by i_valid (one accepted word per clock):
//     * 9  kernel words, row-major  k00 k01 k02 k10 k11 k12 k20 k21 k22
//     * 64 image  words, row-major  img[0][0]..img[7][7]
//   i.e. KCNT + ICNT = 9 + 64 = 73 input words. o_busy is high while loading is
//   not yet complete or a computation is in flight. After the last image word
//   the engine computes (COMPUTE), then streams 64 results: each cycle in OUTPUT
//   it raises o_valid with o_data = next result in raster order. After the 64th
//   result it asserts o_done (1 cycle) and parks in DONE until reset.
//
// RTL style: fully synthesizable (no $readmemh / initial in this module; memory
// is flop arrays loaded by the stream), parameterized, active-low synchronous
// reset, no latches (every reg assigned on every path).
// =============================================================================
`include "conv_defs.vh"

module conv_engine #(
    parameter integer WIDTH = 16,   // data width
    parameter integer FRAC  = 10,   // fraction bits (Q6.10)
    parameter integer IMG   = 8     // image is IMG x IMG
) (
    input  wire                    clk,
    input  wire                    rst_n,     // active-low SYNCHRONOUS reset
    // input stream: 9 kernel words then IMG*IMG image words (row-major)
    input  wire                    i_valid,   // host asserts when i_data is valid
    input  wire signed [WIDTH-1:0] i_data,    // streamed word (Q6.10)
    // output stream: IMG*IMG results (row-major)
    output reg                     o_valid,   // high for one cycle per result word
    output reg  signed [WIDTH-1:0] o_data,    // result word (Q6.10)
    output reg                     o_done,     // high for one cycle after last result
    output wire                    o_busy      // high while loading/computing (not idle-done)
);
    // ---------------- derived sizes ----------------
    localparam integer NPIX  = IMG * IMG;          // pixels per image (64)
    localparam integer NTAP  = 9;                  // 3x3 kernel taps
    localparam integer IDXW  = $clog2(NPIX);       // index width for pixel arrays (6)
    localparam integer KIDXW = 4;                  // index width for 0..8 load counter

    // ---------------- saturation / rounding constants (mirror the ALU) ----------------
    localparam signed [WIDTH:0]     MAXV = (1 <<< (WIDTH-1)) - 1;   // +32767
    localparam signed [WIDTH:0]     MINV = -(1 <<< (WIDTH-1));      // -32768
    localparam signed [WIDTH-1:0]   SMAX = MAXV[WIDTH-1:0];         // 0x7FFF
    localparam signed [WIDTH-1:0]   SMIN = MINV[WIDTH-1:0];         // 0x8000
    // Accumulator is wide: 9 products of Q12.20 each -> keep generous headroom.
    localparam integer ACCW = 2*WIDTH + 8;                          // 40 bits
    localparam signed [ACCW-1:0]    RND  = (1 <<< (FRAC-1));        // round-half-up bias

    // ---------------- storage (flop arrays, loaded by the stream) ----------------
    reg signed [WIDTH-1:0] kern  [0:NTAP-1];       // 9 kernel words
    reg signed [WIDTH-1:0] img   [0:NPIX-1];       // IMG*IMG image words
    reg signed [WIDTH-1:0] res   [0:NPIX-1];       // IMG*IMG result words

    // ---------------- control state ----------------
    reg  [1:0]            state;
    reg  [KIDXW-1:0]      kcnt;                     // kernel load counter   0..8
    reg  [IDXW:0]         icnt;                     // image  load counter   0..NPIX
    reg  [IDXW:0]         ocnt;                     // output stream counter 0..NPIX
    reg  [IDXW-1:0]       pix;                      // current output pixel  0..NPIX-1
    reg  [3:0]            tap;                      // current tap           0..8 (then writeback at 9)
    reg  signed [ACCW-1:0] acc;                     // wide signed accumulator

    integer ii;

    // ---------------- output-pixel row/col and tap offsets (combinational) ----------------
    // pixel index -> (row, col); tap index -> (dr, dc) in {-1,0,1}.
    wire [IDXW-1:0] prow = pix / IMG[IDXW-1:0];
    wire [IDXW-1:0] pcol = pix % IMG[IDXW-1:0];
    // signed neighbour coordinates for the current tap
    reg  signed [IDXW+1:0] nrow, ncol;             // r+dr, c+dc (can be -1..IMG)
    reg  signed [3:0]      dr, dc;
    always @* begin
        // tap layout: t = (dr+1)*3 + (dc+1), so dc = (t mod 3) - 1 and
        // dr = (t / 3) - 1. Decode both from the full tap value (NOT tap[1:0],
        // which is mod-4, not mod-3).
        case (tap)
            4'd0,4'd3,4'd6: dc = -1;               // t mod 3 == 0
            4'd1,4'd4,4'd7: dc =  0;               // t mod 3 == 1
            default:        dc =  1;               // t mod 3 == 2  (taps 2,5,8)
        endcase
        case (tap)
            4'd0,4'd1,4'd2: dr = -1;
            4'd3,4'd4,4'd5: dr =  0;
            default:        dr =  1;               // taps 6,7,8
        endcase
        nrow = $signed({2'b00, prow}) + dr;
        ncol = $signed({2'b00, pcol}) + dc;
    end

    // in-bounds neighbour pixel (zero padding) and its flat index
    wire inb = (nrow >= 0) && (nrow < IMG) && (ncol >= 0) && (ncol < IMG);
    wire [IDXW-1:0] nidx = nrow[IDXW-1:0] * IMG[IDXW-1:0] + ncol[IDXW-1:0];
    wire signed [WIDTH-1:0] pixval = inb ? img[nidx] : {WIDTH{1'b0}};

    // ---------------- the single shared multiplier (Q12.20 product) ----------------
    wire signed [2*WIDTH-1:0] prod = $signed(kern[tap[3:0]]) * $signed(pixval);

    // ---------------- per-pixel round-half-up + saturate (once, at tap==9) ----------------
    wire signed [ACCW-1:0] accr = (acc + RND) >>> FRAC;     // back to Q6.10, rounded
    reg  signed [WIDTH-1:0] pixres;
    always @* begin
        if      (accr > MAXV) pixres = SMAX;
        else if (accr < MINV) pixres = SMIN;
        else                  pixres = accr[WIDTH-1:0];
    end

    // ---------------- busy / idle ----------------
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
            // defaults each cycle (avoid latches; pulse outputs)
            o_valid <= 1'b0;
            o_done  <= 1'b0;

            case (state)
                // -------- LOAD: accept 9 kernel words then NPIX image words --------
                `CONV_S_LOAD: begin
                    if (i_valid) begin
                        if (kcnt < NTAP[KIDXW-1:0]) begin
                            kern[kcnt] <= i_data;
                            kcnt       <= kcnt + 1'b1;
                        end else begin
                            img[icnt[IDXW-1:0]] <= i_data;
                            if (icnt == (NPIX-1)) begin
                                // last image word accepted -> start computing
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

                // -------- COMPUTE: 9-tap sequential MAC, then round+sat into res --------
                `CONV_S_COMPUTE: begin
                    if (tap < NTAP[3:0]) begin
                        acc <= acc + {{(ACCW-2*WIDTH){prod[2*WIDTH-1]}}, prod};
                        tap <= tap + 1'b1;
                    end else begin
                        // tap == 9: writeback this pixel's rounded+saturated result
                        res[pix] <= pixres;
                        acc      <= {ACCW{1'b0}};
                        tap      <= 4'd0;
                        if (pix == (NPIX-1)) begin
                            state <= `CONV_S_OUTPUT;
                            ocnt  <= {(IDXW+1){1'b0}};
                        end else begin
                            pix <= pix + 1'b1;
                        end
                    end
                end

                // -------- OUTPUT: stream NPIX results in raster order --------
                // Cycle k (k=0..NPIX-1) presents res[k] with o_valid high. After
                // the last word is presented the engine moves to DONE, which
                // pulses o_done for exactly one cycle.
                `CONV_S_OUTPUT: begin
                    o_valid <= 1'b1;
                    o_data  <= res[ocnt[IDXW-1:0]];
                    if (ocnt == (NPIX-1)) state <= `CONV_S_DONE;
                    ocnt <= ocnt + 1'b1;
                end

                // -------- DONE: pulse o_done once on entry, then park until reset --------
                default: begin
                    // o_done is high only on the first cycle in DONE (ocnt==NPIX);
                    // ocnt freezes at NPIX so the pulse is exactly one cycle.
                    if (ocnt == NPIX[IDXW:0]) begin
                        o_done <= 1'b1;
                        ocnt   <= ocnt + 1'b1;     // advance past NPIX so pulse ends
                    end
                    state <= `CONV_S_DONE;
                end
            endcase
        end
    end
endmodule
