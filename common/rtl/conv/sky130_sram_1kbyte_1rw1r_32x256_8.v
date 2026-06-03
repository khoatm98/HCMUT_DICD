// =============================================================================
// sky130_sram_1kbyte_1rw1r_32x256_8.v  --  BEHAVIORAL model of the SKY130 OpenRAM
// macro (256 words x 32 bits, 1 read-write port + 1 read port, 8-bit write mask
// granularity -> 4-bit wmask). FOR SIMULATION ONLY.
//
// This matches the OpenRAM macro's interface and timing (SYNCHRONOUS, registered
// read: address sampled at the clock edge, data valid the next cycle). In
// synthesis the macro is a BLACKBOX (its .lib gives timing); in APR the real
// macro's .lef/.gds are placed. Do NOT add this file to the synthesis source
// list -- it is compiled only for simulation (functional + gate-level).
//
// Used by HW3's conv_engine to store the 8x8 feature map (it uses the low 16
// bits of each 32-bit word, addresses 0..63).
// =============================================================================
`timescale 1ns/1ps

module sky130_sram_1kbyte_1rw1r_32x256_8 (
    // Port 0: read-write
    input  wire        clk0,
    input  wire        csb0,    // chip select, active low
    input  wire        web0,    // write enable, active low
    input  wire [3:0]  wmask0,  // per-byte write mask (active high)
    input  wire [7:0]  addr0,
    input  wire [31:0] din0,
    output reg  [31:0] dout0,
    // Port 1: read-only
    input  wire        clk1,
    input  wire        csb1,    // chip select, active low
    input  wire [7:0]  addr1,
    output reg  [31:0] dout1
);
    reg [31:0] mem [0:255];

    // Port 0: synchronous write (byte-masked) + registered read.
    always @(posedge clk0) begin
        if (!csb0) begin
            if (!web0) begin
                if (wmask0[0]) mem[addr0][7:0]   <= din0[7:0];
                if (wmask0[1]) mem[addr0][15:8]  <= din0[15:8];
                if (wmask0[2]) mem[addr0][23:16] <= din0[23:16];
                if (wmask0[3]) mem[addr0][31:24] <= din0[31:24];
            end
            dout0 <= mem[addr0];
        end
    end

    // Port 1: synchronous registered read.
    always @(posedge clk1) begin
        if (!csb1) dout1 <= mem[addr1];
    end
endmodule
