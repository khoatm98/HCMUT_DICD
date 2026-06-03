// =============================================================================
// conv_engine.v  --  HW3 STARTER. Complete the TODOs to implement the 3x3
// convolution engine, then SYNTHESIZE it, prove gate-equivalence, and analyze
// area/timing.
//
// The feature map is stored in a SKY130 OpenRAM HARD MACRO
// (sky130_sram_1kbyte_1rw1r_32x256_8): you write the 64 pixels into it during
// LOAD, and read them back during COMPUTE. The macro has SYNCHRONOUS (registered)
// read -- the address is sampled on a clock edge and the data is valid the NEXT
// cycle -- so each 3x3 tap takes two phases: ISSUE (present the read address) then
// ACCUMULATE (the data is ready -> multiply-accumulate). The SRAM control signals
// must be driven COMBINATIONALLY so the macro samples the right address.
//
// The module interface (ports/params) is FIXED -- do NOT change it (the
// testbench, synthesis, and HW5 APR depend on it). Read SPEC.md and study
// common/rtl/alu/alu.v for the FXMUL round-half-up + saturate idiom.
//
// PROVIDED: the SRAM instance + its combinational control, the tap->(dr,dc)
// mapping with zero padding, the datapath wires (product, rounded sum, saturate),
// the LOAD / OUTPUT / DONE phases. YOU IMPLEMENT the COMPUTE accumulate (TODO).
// =============================================================================
`include "conv_defs.vh"

module conv_engine #(
    parameter integer WIDTH = 16,
    parameter integer FRAC  = 10,
    parameter integer IMG   = 8
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    i_valid,
    input  wire signed [WIDTH-1:0] i_data,
    output reg                     o_valid,
    output reg  signed [WIDTH-1:0] o_data,
    output reg                     o_done,
    output wire                    o_busy
);
    localparam integer NPIX  = IMG * IMG;
    localparam integer NTAP  = 9;
    localparam integer IDXW  = $clog2(NPIX);
    localparam integer KIDXW = 4;
    localparam signed [WIDTH:0]     MAXV = (1 <<< (WIDTH-1)) - 1;
    localparam signed [WIDTH:0]     MINV = -(1 <<< (WIDTH-1));
    localparam signed [WIDTH-1:0]   SMAX = MAXV[WIDTH-1:0];
    localparam signed [WIDTH-1:0]   SMIN = MINV[WIDTH-1:0];
    localparam integer              ACCW = 2*WIDTH + 8;
    localparam signed [ACCW-1:0]    RND  = (1 <<< (FRAC-1));

    reg signed [WIDTH-1:0] kern [0:NTAP-1];
    reg signed [WIDTH-1:0] res  [0:NPIX-1];

    reg  [1:0]             state;
    reg  [KIDXW-1:0]       kcnt;
    reg  [IDXW:0]          icnt, ocnt;
    reg  [IDXW-1:0]        pix;
    reg  [3:0]             tap;
    reg                    rd_phase;
    reg  signed [ACCW-1:0] acc;
    reg                    pad_lat;
    reg  signed [WIDTH-1:0] kern_lat;
    integer ii;

    // ---- tap -> neighbour coordinate (PROVIDED) ----
    wire [IDXW-1:0] prow = pix / IMG[IDXW-1:0];
    wire [IDXW-1:0] pcol = pix % IMG[IDXW-1:0];
    reg  signed [3:0]      dr, dc;
    reg  signed [IDXW+1:0] nrow, ncol;
    always @* begin
        case (tap)
            4'd0,4'd3,4'd6: dc = -1;  4'd1,4'd4,4'd7: dc = 0;  default: dc = 1;
        endcase
        case (tap)
            4'd0,4'd1,4'd2: dr = -1;  4'd3,4'd4,4'd5: dr = 0;  default: dr = 1;
        endcase
        nrow = $signed({2'b00, prow}) + dr;
        ncol = $signed({2'b00, pcol}) + dc;
    end
    wire inb = (nrow >= 0) && (nrow < IMG) && (ncol >= 0) && (ncol < IMG);
    wire [IDXW-1:0] nidx = nrow[IDXW-1:0] * IMG[IDXW-1:0] + ncol[IDXW-1:0];

    // ---- SRAM hard macro + its COMBINATIONAL control (PROVIDED) ----
    reg         csb0, web0;  reg [7:0] addr0;  reg [31:0] din0;  wire [31:0] dout0;
    reg         csb1;        reg [7:0] addr1;                    wire [31:0] dout1;
    sky130_sram_1kbyte_1rw1r_32x256_8 u_img (
        .clk0(clk), .csb0(csb0), .web0(web0), .wmask0(4'hF),
        .addr0(addr0), .din0(din0), .dout0(dout0),
        .clk1(clk), .csb1(csb1), .addr1(addr1), .dout1(dout1)
    );
    always @* begin
        csb0 = 1'b1; web0 = 1'b1; addr0 = 8'd0; din0 = 32'd0;
        csb1 = 1'b1; addr1 = 8'd0;
        if (state == `CONV_S_LOAD && i_valid && (kcnt >= NTAP[KIDXW-1:0])) begin
            csb0 = 1'b0; web0 = 1'b0; addr0 = {{(8-(IDXW+1)){1'b0}}, icnt};
            din0 = {{(32-WIDTH){1'b0}}, i_data};
        end
        if (state == `CONV_S_COMPUTE && rd_phase == 1'b0) begin
            csb1 = 1'b0; addr1 = inb ? {{(8-IDXW){1'b0}}, nidx} : 8'd0;   // issue read
        end
    end

    // ---- datapath wires (PROVIDED): pixel read -> product -> rounded+saturated sum ----
    wire signed [WIDTH-1:0]   pixval   = pad_lat ? {WIDTH{1'b0}} : dout1[WIDTH-1:0];
    wire signed [2*WIDTH-1:0] prod     = $signed(kern_lat) * $signed(pixval);
    wire signed [ACCW-1:0]    acc_next = acc + {{(ACCW-2*WIDTH){prod[2*WIDTH-1]}}, prod};
    wire signed [ACCW-1:0]    accr     = (acc_next + RND) >>> FRAC;
    reg  signed [WIDTH-1:0]   pixres;
    always @* begin
        if      (accr > MAXV) pixres = SMAX;
        else if (accr < MINV) pixres = SMIN;
        else                  pixres = accr[WIDTH-1:0];
    end

    assign o_busy = (state != `CONV_S_DONE);

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= `CONV_S_LOAD; kcnt <= 0; icnt <= 0; ocnt <= 0;
            pix <= 0; tap <= 0; rd_phase <= 0; acc <= 0; pad_lat <= 0; kern_lat <= 0;
            o_valid <= 1'b0; o_data <= 0; o_done <= 1'b0;
            for (ii = 0; ii < NTAP; ii = ii + 1) kern[ii] <= 0;
            for (ii = 0; ii < NPIX; ii = ii + 1) res[ii]  <= 0;
        end else begin
            o_valid <= 1'b0;
            o_done  <= 1'b0;
            case (state)
                // -------- LOAD: kernel -> flops, image -> SRAM (write via comb control) --------
                `CONV_S_LOAD: begin
                    if (i_valid) begin
                        if (kcnt < NTAP[KIDXW-1:0]) begin
                            kern[kcnt] <= i_data; kcnt <= kcnt + 1'b1;
                        end else begin
                            if (icnt == (NPIX-1)) begin
                                icnt <= icnt + 1'b1; state <= `CONV_S_COMPUTE;
                                pix <= 0; tap <= 0; rd_phase <= 0; acc <= 0;
                            end else icnt <= icnt + 1'b1;
                        end
                    end
                end

                // -------- COMPUTE: ISSUE read, then ACCUMULATE (the data is ready) --------
                `CONV_S_COMPUTE: begin
                    if (rd_phase == 1'b0) begin
                        // ISSUE phase: the read address is presented combinationally
                        // this cycle (see the SRAM control block above). Latch the
                        // pad flag + the kernel weight for use next cycle.
                        pad_lat  <= ~inb;
                        kern_lat <= kern[tap[3:0]];
                        rd_phase <= 1'b1;
                    end else begin
                        // ACCUMULATE phase: dout1 (hence `pixval`/`prod`/`acc_next`) is
                        // now valid for this tap.
                        rd_phase <= 1'b0;
                        // ===================== TODO =====================
                        // 1) Add this tap's product to the accumulator.
                        // 2) After the 9th tap (tap == NTAP-1), write the rounded +
                        //    saturated result `pixres` into res[pix], clear acc, and
                        //    advance to the next pixel (or to OUTPUT after the last).
                        //    Otherwise just advance `tap`.
                        // (Use `acc_next` / `pixres` -- the provided datapath wires.)
                        //
                        // Placeholder so the design compiles + runs (and FAILS until
                        // you implement it): finish the pixel with a zero result.
                        if (tap == NTAP[3:0]-1) begin
                            res[pix] <= {WIDTH{1'b0}};   // <-- TODO: should be pixres
                            acc <= 0; tap <= 0;
                            if (pix == (NPIX-1)) begin state <= `CONV_S_OUTPUT; ocnt <= 0; end
                            else pix <= pix + 1'b1;
                        end else begin
                            tap <= tap + 1'b1;           // <-- TODO: also accumulate (acc <= acc_next)
                        end
                        // ================================================
                    end
                end

                // -------- OUTPUT: stream NPIX results in raster order (PROVIDED) --------
                `CONV_S_OUTPUT: begin
                    o_valid <= 1'b1;
                    o_data  <= res[ocnt[IDXW-1:0]];
                    if (ocnt == (NPIX-1)) state <= `CONV_S_DONE;
                    ocnt <= ocnt + 1'b1;
                end

                // -------- DONE (PROVIDED) --------
                default: begin
                    if (ocnt == NPIX[IDXW:0]) begin o_done <= 1'b1; ocnt <= ocnt + 1'b1; end
                    state <= `CONV_S_DONE;
                end
            endcase
        end
    end

    wire _unused = &{1'b0, dout0, acc_next, pixres};   // (remove once you use these)
endmodule
