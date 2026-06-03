// =============================================================================
// regfile.v  --  TinyRISC-16 register file: 8 x 16-bit, R0 hardwired to 0.
//
// THREE read ports: ra, rb, rc. The third port (rc, reading rd) is what lets a
// single-cycle MAC read its accumulator, and is also used by branches/stores.
// One synchronous write port (write-back), with R0 never written.
// =============================================================================
module regfile #(
    parameter integer WIDTH = 16
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             we,        // write enable
    input  wire [2:0]       wa,        // write address
    input  wire [WIDTH-1:0] wd,        // write data
    input  wire [2:0]       ra, rb, rc,// read addresses
    output wire [WIDTH-1:0] rda, rdb, rdc
);
    reg [WIDTH-1:0] regs [0:7];
    integer i;

    // Reads: R0 always reads as 0.
    assign rda = (ra == 3'd0) ? {WIDTH{1'b0}} : regs[ra];
    assign rdb = (rb == 3'd0) ? {WIDTH{1'b0}} : regs[rb];
    assign rdc = (rc == 3'd0) ? {WIDTH{1'b0}} : regs[rc];

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= {WIDTH{1'b0}};
        end else if (we && (wa != 3'd0)) begin
            regs[wa] <= wd;
        end
    end
endmodule
