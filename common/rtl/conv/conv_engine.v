// =============================================================================
// conv_engine.v  --  3x3 convolution engine (reference, SRAM-backed feature map).
//
// Same EXTERNAL behavior and golden as before (stream 9 kernel + 64 image words,
// then stream 64 zero-padded 3x3 convolution results, Q6.10 round+saturate). The
// feature map now lives in a SKY130 OpenRAM hard macro
// (sky130_sram_1kbyte_1rw1r_32x256_8) instead of a flop array -- this is the HW3
// memory-macro integration lesson (synthesis blackboxes it; HW5 APR places it).
//
// SRAM usage: port 0 (rw) writes the 64 pixels during LOAD; port 1 (r) reads a
// pixel during COMPUTE. The macro has SYNCHRONOUS (registered) read: the address
// is sampled at a clock edge and the data is valid the NEXT cycle. So the 9-tap
// MAC runs as two phases per tap -- ISSUE (present the read address) then
// ACCUMULATE (the read data is ready -> multiply-accumulate). Kernel and result
// stay in flops. Numerics mirror the HW1 ALU FXMUL (accumulate full precision,
// then round-half-up + saturate to Q6.10).  States: see conv_defs.vh.
//
// The SRAM control signals are driven COMBINATIONALLY from the FSM so the macro
// samples the right address on the clock edge.  A behavioral model of the macro
// (sky130_sram_1kbyte_1rw1r_32x256_8.v) is used for simulation; synthesis/APR use
// the real macro's .lib/.lef/.gds.
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
    localparam integer NPIX  = IMG * IMG;          // 64
    localparam integer NTAP  = 9;
    localparam integer IDXW  = $clog2(NPIX);       // 6
    localparam integer KIDXW = 4;

    localparam signed [WIDTH:0]     MAXV = (1 <<< (WIDTH-1)) - 1;   // +32767
    localparam signed [WIDTH:0]     MINV = -(1 <<< (WIDTH-1));      // -32768
    localparam signed [WIDTH-1:0]   SMAX = MAXV[WIDTH-1:0];
    localparam signed [WIDTH-1:0]   SMIN = MINV[WIDTH-1:0];
    localparam integer              ACCW = 2*WIDTH + 8;             // 40
    localparam signed [ACCW-1:0]    RND  = (1 <<< (FRAC-1));

    // kernel + result in flops; image lives in the SRAM macro
    reg signed [WIDTH-1:0] kern [0:NTAP-1];
    reg signed [WIDTH-1:0] res  [0:NPIX-1];

    // control
    reg  [1:0]             state;
    reg  [KIDXW-1:0]       kcnt;
    reg  [IDXW:0]          icnt, ocnt;
    reg  [IDXW-1:0]        pix;
    reg  [3:0]             tap;
    reg                    rd_phase;                // 0 = issue read, 1 = accumulate
    reg  signed [ACCW-1:0] acc;
    reg                    pad_lat;
    reg  signed [WIDTH-1:0] kern_lat;
    integer ii;

    // ---- output pixel coordinate + tap offset (combinational) ----
    wire [IDXW-1:0] prow = pix / IMG[IDXW-1:0];
    wire [IDXW-1:0] pcol = pix % IMG[IDXW-1:0];
    reg  signed [3:0]      dr, dc;
    reg  signed [IDXW+1:0] nrow, ncol;
    always @* begin
        case (tap)
            4'd0,4'd3,4'd6: dc = -1;
            4'd1,4'd4,4'd7: dc =  0;
            default:        dc =  1;
        endcase
        case (tap)
            4'd0,4'd1,4'd2: dr = -1;
            4'd3,4'd4,4'd5: dr =  0;
            default:        dr =  1;
        endcase
        nrow = $signed({2'b00, prow}) + dr;
        ncol = $signed({2'b00, pcol}) + dc;
    end
    wire inb = (nrow >= 0) && (nrow < IMG) && (ncol >= 0) && (ncol < IMG);
    wire [IDXW-1:0] nidx = nrow[IDXW-1:0] * IMG[IDXW-1:0] + ncol[IDXW-1:0];

    // ---- SRAM macro (1RW + 1R), synchronous read ----
    reg         csb0, web0;
    reg  [7:0]  addr0;
    reg  [31:0] din0;
    wire [31:0] dout0;
    reg         csb1;
    reg  [7:0]  addr1;
    wire [31:0] dout1;
    sky130_sram_1kbyte_1rw1r_32x256_8 u_img (
        .clk0(clk), .csb0(csb0), .web0(web0), .wmask0(4'hF),
        .addr0(addr0), .din0(din0), .dout0(dout0),
        .clk1(clk), .csb1(csb1), .addr1(addr1), .dout1(dout1)
    );

    // SRAM control is COMBINATIONAL so the macro samples the right address on
    // the clock edge: write a pixel during LOAD (port0); read a pixel during the
    // ISSUE phase of COMPUTE (port1).
    always @* begin
        csb0 = 1'b1; web0 = 1'b1; addr0 = 8'd0; din0 = 32'd0;
        csb1 = 1'b1; addr1 = 8'd0;
        if (state == `CONV_S_LOAD && i_valid && (kcnt >= NTAP[KIDXW-1:0])) begin
            csb0  = 1'b0; web0 = 1'b0;            // write image pixel
            addr0 = {{(8-(IDXW+1)){1'b0}}, icnt};
            din0  = {{(32-WIDTH){1'b0}}, i_data};
        end
        if (state == `CONV_S_COMPUTE && rd_phase == 1'b0) begin
            csb1  = 1'b0;                          // issue pixel read
            addr1 = inb ? {{(8-IDXW){1'b0}}, nidx} : 8'd0;
        end
    end

    // ---- datapath: read pixel (port1) -> multiply-accumulate ----
    wire signed [WIDTH-1:0]   pixval   = pad_lat ? {WIDTH{1'b0}} : dout1[WIDTH-1:0];
    wire signed [2*WIDTH-1:0] prod     = $signed(kern_lat) * $signed(pixval);
    wire signed [ACCW-1:0]    acc_next = acc + {{(ACCW-2*WIDTH){prod[2*WIDTH-1]}}, prod};
    wire signed [ACCW-1:0]    accr     = (acc_next + RND) >>> FRAC;   // full sum, rounded (at tap 8)
    reg  signed [WIDTH-1:0]   pixres;
    always @* begin
        if      (accr > MAXV) pixres = SMAX;
        else if (accr < MINV) pixres = SMIN;
        else                  pixres = accr[WIDTH-1:0];
    end

    assign o_busy = (state != `CONV_S_DONE);

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= `CONV_S_LOAD; kcnt <= {KIDXW{1'b0}};
            icnt <= {(IDXW+1){1'b0}}; ocnt <= {(IDXW+1){1'b0}};
            pix <= {IDXW{1'b0}}; tap <= 4'd0; rd_phase <= 1'b0;
            acc <= {ACCW{1'b0}}; pad_lat <= 1'b0; kern_lat <= {WIDTH{1'b0}};
            o_valid <= 1'b0; o_data <= {WIDTH{1'b0}}; o_done <= 1'b0;
            for (ii = 0; ii < NTAP; ii = ii + 1) kern[ii] <= {WIDTH{1'b0}};
            for (ii = 0; ii < NPIX; ii = ii + 1) res[ii]  <= {WIDTH{1'b0}};
        end else begin
            o_valid <= 1'b0;
            o_done  <= 1'b0;
            case (state)
                // -------- LOAD: 9 kernel words (flops) then NPIX image words (SRAM) --------
                `CONV_S_LOAD: begin
                    if (i_valid) begin
                        if (kcnt < NTAP[KIDXW-1:0]) begin
                            kern[kcnt] <= i_data;
                            kcnt       <= kcnt + 1'b1;
                        end else begin
                            // SRAM write happens via the combinational controls above
                            if (icnt == (NPIX-1)) begin
                                icnt     <= icnt + 1'b1;
                                state    <= `CONV_S_COMPUTE;
                                pix      <= {IDXW{1'b0}};
                                tap      <= 4'd0;
                                rd_phase <= 1'b0;
                                acc      <= {ACCW{1'b0}};
                            end else begin
                                icnt <= icnt + 1'b1;
                            end
                        end
                    end
                end

                // -------- COMPUTE: per tap, ISSUE read then ACCUMULATE (SRAM is sync-read) --------
                `CONV_S_COMPUTE: begin
                    if (rd_phase == 1'b0) begin
                        // issue: address presented combinationally this cycle; latch
                        // the pad flag + kernel weight for the accumulate cycle.
                        pad_lat  <= ~inb;
                        kern_lat <= kern[tap[3:0]];
                        rd_phase <= 1'b1;
                    end else begin
                        // accumulate: dout1 is now valid
                        rd_phase <= 1'b0;
                        if (tap == NTAP[3:0]-1) begin
                            res[pix] <= pixres;        // pixres uses acc_next = full 9-tap sum
                            acc      <= {ACCW{1'b0}};
                            tap      <= 4'd0;
                            if (pix == (NPIX-1)) begin
                                state <= `CONV_S_OUTPUT;
                                ocnt  <= {(IDXW+1){1'b0}};
                            end else begin
                                pix <= pix + 1'b1;
                            end
                        end else begin
                            acc <= acc_next;
                            tap <= tap + 1'b1;
                        end
                    end
                end

                // -------- OUTPUT: stream NPIX results in raster order --------
                `CONV_S_OUTPUT: begin
                    o_valid <= 1'b1;
                    o_data  <= res[ocnt[IDXW-1:0]];
                    if (ocnt == (NPIX-1)) state <= `CONV_S_DONE;
                    ocnt <= ocnt + 1'b1;
                end

                // -------- DONE: pulse o_done once, then park --------
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

    // dout0 (port-0 read data) is unused by this design.
    wire _unused = &{1'b0, dout0};
endmodule
