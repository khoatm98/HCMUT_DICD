// =============================================================================
// counter.v  --  tiny synchronous up-counter used by the toolchain smoke test.
//
// Why a counter (and not a combinational adder)?
//   The smoke test must exercise the WHOLE flow, including clock-tree synthesis
//   (CTS) and routing in the APR stage. A purely combinational design has no
//   clock and no flip-flops, so it would skip CTS entirely. This counter is the
//   smallest design that still has a clock + registers, so it touches every
//   stage: sim -> synth -> STA -> floorplan -> placement -> CTS -> route -> GDS.
//
// It is intentionally trivial; it is NOT part of any homework.
// =============================================================================
module counter #(
    parameter WIDTH = 8
) (
    input  wire             clk,     // clock
    input  wire             rst_n,   // active-low SYNCHRONOUS reset
    input  wire             en,      // count enable
    output reg  [WIDTH-1:0] count    // current count value
);

    always @(posedge clk) begin
        if (!rst_n)
            count <= {WIDTH{1'b0}};
        else if (en)
            count <= count + 1'b1;
    end

endmodule
