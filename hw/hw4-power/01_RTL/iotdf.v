// =============================================================================
// iotdf.v  --  HW4 STARTER. Complete the TODOs to implement the IoT Data Filter.
//
// The module interface (ports) is FIXED -- do NOT change it, or the testbench
// and the back-end (synth / STA / power) flow will break. Read SPEC.md for the
// full function table, the CRC-8 and LFSR definitions, and the 1-cycle-latency
// streaming contract.
//
// ONE function (BIN2GRAY) is provided as an example. Implement GRAY2BIN, CRC8,
// and LFSR. HW4 is the POWER homework: STRUCTURE the design so the three idle
// units stay quiet -- give each function its own unit, operand-isolate the idle
// units' inputs, and update the CRC/LFSR state registers ONLY when selected.
// That structure is what makes clock gating (`CLOCKGATE=1`) effective later.
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
    // Per-function enables + operand isolation (idle units see 0 -> no toggling).
    // -------------------------------------------------------------------------
    wire en_b2g  = i_valid & (i_fn == `FN_BIN2GRAY);
    // TODO: en_g2b, en_crc, en_lfsr  (one per remaining function)

    wire [7:0] din_b2g = en_b2g ? i_data : 8'h00;
    // TODO: din_g2b, din_crc, din_lfsr  (operand-isolated inputs)

    // -------------------------------------------------------------------------
    // UNIT 0 -- BIN2GRAY (example, already done): o = i ^ (i>>1).
    // -------------------------------------------------------------------------
    wire [7:0] y_b2g = din_b2g ^ {1'b0, din_b2g[7:1]};

    // -------------------------------------------------------------------------
    // TODO UNIT 1 -- GRAY2BIN: o[7]=i[7]; o[k]=o[k+1]^i[k] (prefix-XOR).
    // -------------------------------------------------------------------------
    // wire [7:0] y_g2b; ...

    // -------------------------------------------------------------------------
    // TODO UNIT 2 -- CRC8: poly 0x07, MSB-first, init 0. Keep a `crc_reg` flop;
    // compute crc_next (fold in din_crc, 8 bit-iterations); OUTPUT the updated
    // CRC; update crc_reg ONLY when en_crc (so it holds = clock-gate hook).
    // -------------------------------------------------------------------------
    // reg [7:0] crc_reg;  function ... crc8_byte; ...

    // -------------------------------------------------------------------------
    // TODO UNIT 3 -- LFSR scramble: 8-bit Fibonacci LFSR, taps x^8+x^6+x^5+x^4
    // (feedback = s[7]^s[5]^s[4]^s[3]), seed 0xFF. o = i ^ lfsr_reg; advance the
    // register 8 steps per byte; update ONLY when en_lfsr; seed on reset.
    // -------------------------------------------------------------------------
    // reg [7:0] lfsr_reg;  function ... lfsr_step / lfsr_adv8; ...

    // -------------------------------------------------------------------------
    // Result mux. (Right now only BIN2GRAY is wired -> the others are wrong and
    // the testbench will report RESULT: FAIL until you finish all four.)
    // -------------------------------------------------------------------------
    reg [7:0] result;
    always @* begin
        case (i_fn)
            `FN_BIN2GRAY: result = y_b2g;
            // TODO: `FN_GRAY2BIN: result = y_g2b;
            // TODO: `FN_CRC8    : result = crc_next;
            // TODO: `FN_LFSR    : result = y_lfsr;
            default     : result = 8'h00;
        endcase
    end

    // -------------------------------------------------------------------------
    // Sequential: output register (+ your CRC/LFSR state registers).
    // Synchronous active-low reset. Assign every reg on every path (no latch).
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            o_valid <= 1'b0;
            o_data  <= 8'h00;
            // TODO: reset crc_reg <= 0;  lfsr_reg <= seed;
        end else begin
            o_valid <= i_valid;
            o_data  <= i_valid ? result : o_data;
            // TODO: crc_reg  <= en_crc  ? crc_next  : crc_reg;
            // TODO: lfsr_reg <= en_lfsr ? lfsr_next : lfsr_reg;
        end
    end
endmodule
