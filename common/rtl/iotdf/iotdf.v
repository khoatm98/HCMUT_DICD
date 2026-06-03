// =============================================================================
// iotdf.v  --  IoT Data Filter: 8-bit byte-stream engine (reference design).
//
// A 1-in / 1-out streaming datapath with a fixed ONE-cycle latency: a byte
// accepted on `i_valid` (with function select `i_fn`) appears on `o_data` with
// `o_valid` exactly one clock later. Four selectable byte transforms:
//
//   i_fn = 0  BIN2GRAY : o = i ^ (i>>1)
//   i_fn = 1  GRAY2BIN : Gray-to-binary  (o[7]=i[7]; o[k]=o[k+1]^i[k])
//   i_fn = 2  CRC8     : running CRC-8, poly 0x07, MSB-first, init 0; outputs the
//                        UPDATED CRC register after folding in each byte.
//   i_fn = 3  LFSR     : o = i ^ keystream, where an 8-bit Fibonacci LFSR
//                        (taps x^8+x^6+x^5+x^4, seed 0xFF) supplies one keystream
//                        byte per input byte and then advances 8 steps.
//
// POWER-HOMEWORK STRUCTURE (HW4): each function is its OWN small unit and a final
// mux selects `o_data` by `i_fn`. Inputs to the idle units are OPERAND-ISOLATED
// (held at zero) so the combinational logic of unselected units does not toggle,
// and the two stateful units (CRC, LFSR) only update their registers when they
// are actually selected -- a structural hook for clock-gating during synthesis.
//
// Codes are in iotdf_defs.vh (single source of truth).  Reset: synchronous,
// active-low; CRC clears to 0 and the LFSR reloads its seed (= stream start).
// =============================================================================
`include "iotdf_defs.vh"

module iotdf (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       i_valid,        // 1 -> i_data/i_fn are a valid input byte
    input  wire [7:0] i_data,         // input byte
    input  wire [1:0] i_fn,           // function select (hold stable for a stream)
    output reg        o_valid,        // 1 -> o_data is the result of the prior byte
    output reg  [7:0] o_data          // transformed byte (1-cycle latency)
);
    // -------------------------------------------------------------------------
    // Per-function ENABLE strobes. A function's combinational unit and state
    // register only see live data when that function is selected AND a byte is
    // valid this cycle; otherwise its operand is isolated (held at 0). This is
    // the operand-isolation that keeps idle units quiet for power.
    // -------------------------------------------------------------------------
    wire en_b2g  = i_valid & (i_fn == `FN_BIN2GRAY);
    wire en_g2b  = i_valid & (i_fn == `FN_GRAY2BIN);
    wire en_crc  = i_valid & (i_fn == `FN_CRC8);
    wire en_lfsr = i_valid & (i_fn == `FN_LFSR);

    // Operand-isolated input bytes (idle units see 0 -> no toggling).
    wire [7:0] din_b2g  = en_b2g  ? i_data : 8'h00;
    wire [7:0] din_g2b  = en_g2b  ? i_data : 8'h00;
    wire [7:0] din_crc  = en_crc  ? i_data : 8'h00;
    wire [7:0] din_lfsr = en_lfsr ? i_data : 8'h00;

    // -------------------------------------------------------------------------
    // UNIT 0 -- BIN2GRAY (combinational): o = i ^ (i>>1).
    // -------------------------------------------------------------------------
    wire [7:0] y_b2g = din_b2g ^ {1'b0, din_b2g[7:1]};

    // -------------------------------------------------------------------------
    // UNIT 1 -- GRAY2BIN (combinational). The prefix-XOR recurrence
    //   o[7]=i[7]; o[k]=o[k+1]^i[k]  unrolls to a suffix parity:
    //   o[k] = i[7] ^ i[6] ^ ... ^ i[k] = ^(i >> k)  -- no self-reference.
    // -------------------------------------------------------------------------
    wire [7:0] y_g2b = { ^din_g2b[7:7], ^din_g2b[7:6], ^din_g2b[7:5], ^din_g2b[7:4],
                         ^din_g2b[7:3], ^din_g2b[7:2], ^din_g2b[7:1], ^din_g2b[7:0] };

    // -------------------------------------------------------------------------
    // UNIT 2 -- CRC8 (stateful): poly 0x07, MSB-first, 8 bits/byte.
    // crc_next folds din_crc into the running register; the register updates only
    // when en_crc (selected + valid), so the flop holds otherwise (clock-gate
    // hook). The output is the UPDATED CRC after the byte.
    // -------------------------------------------------------------------------
    reg [7:0] crc_reg;
    function [7:0] crc8_byte;
        input [7:0] crc_in;
        input [7:0] data;
        reg   [7:0] c;
        integer     b;
        begin
            c = crc_in ^ data;                 // MSB-first: XOR byte into high bits
            for (b = 0; b < 8; b = b + 1)
                c = c[7] ? ((c << 1) ^ `IOTDF_CRC_POLY) : (c << 1);
            crc8_byte = c;
        end
    endfunction
    wire [7:0] crc_next = crc8_byte(crc_reg, din_crc);

    // -------------------------------------------------------------------------
    // UNIT 3 -- LFSR scrambler (stateful): 8-bit Fibonacci LFSR.
    // The CURRENT lfsr_reg is the keystream byte XORed with the input; the
    // register then advances 8 steps (so consecutive bytes use fresh keystream).
    // Updates only when en_lfsr (clock-gate hook); seeds on reset/stream start.
    // -------------------------------------------------------------------------
    reg [7:0] lfsr_reg;
    function [7:0] lfsr_step;
        input [7:0] s;
        reg         fb;
        begin
            fb        = s[7] ^ s[5] ^ s[4] ^ s[3];   // taps 8,6,5,4
            lfsr_step = {s[6:0], fb};
        end
    endfunction
    function [7:0] lfsr_adv8;                          // advance 8 steps
        input [7:0] s;
        reg   [7:0] t;
        integer     k;
        begin
            t = s;
            for (k = 0; k < 8; k = k + 1) t = lfsr_step(t);
            lfsr_adv8 = t;
        end
    endfunction
    wire [7:0] y_lfsr        = din_lfsr ^ lfsr_reg;    // scramble with current state
    wire [7:0] lfsr_next     = lfsr_adv8(lfsr_reg);

    // -------------------------------------------------------------------------
    // Result mux (registered -> the fixed 1-cycle latency). For CRC the result
    // is the UPDATED register value; for the others it is the combinational unit.
    // -------------------------------------------------------------------------
    reg [7:0] result;
    always @* begin
        case (i_fn)
            `FN_BIN2GRAY: result = y_b2g;
            `FN_GRAY2BIN: result = y_g2b;
            `FN_CRC8    : result = crc_next;
            `FN_LFSR    : result = y_lfsr;
            default     : result = 8'h00;
        endcase
    end

    // -------------------------------------------------------------------------
    // Sequential: output register + the two stateful units' registers.
    // Synchronous active-low reset; every reg assigned on every path (no latch).
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            o_valid  <= 1'b0;
            o_data   <= 8'h00;
            crc_reg  <= 8'h00;                 // CRC init = 0
            lfsr_reg <= `IOTDF_LFSR_SEED;      // LFSR seed = stream start
        end else begin
            o_valid  <= i_valid;
            o_data   <= i_valid ? result : o_data;
            crc_reg  <= en_crc  ? crc_next  : crc_reg;
            lfsr_reg <= en_lfsr ? lfsr_next : lfsr_reg;
        end
    end
endmodule
