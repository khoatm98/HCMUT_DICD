// =============================================================================
// alu_tb.v  --  self-checking testbench for the TinyRISC-16 Q6.10 ALU (HW1).
//
// Reads packed golden vectors produced by tools/gen_vectors.py and checks every
// one against the DUT. Prints exactly one summary line ("RESULT: PASS" or
// "RESULT: FAIL") so the Makefiles can grep for pass/fail (course convention).
//
// The vectors are applied on the clock so students also see the ALU exercised
// in a clocked, waveform-friendly way (open sim/alu.vcd in GTKWave).
// =============================================================================
`timescale 1ns/1ps

module alu_tb;
    localparam integer WIDTH = 16;
`include "alu_count.vh"          // defines N_VECTORS (generated)

    reg  [3:0]              op;
    reg  signed [WIDTH-1:0] a, b;
    wire signed [WIDTH-1:0] y;
    wire                    zero, overflow;

    reg  [63:0]      vec [0:N_VECTORS-1];
    integer          i, errors;
    reg  [WIDTH-1:0] y_exp;
    reg              z_exp, o_exp;
    reg              clk;

    alu #(.WIDTH(WIDTH)) dut (
        .op(op), .a(a), .b(b), .y(y), .zero(zero), .overflow(overflow)
    );

    initial begin
        $dumpfile("sim/alu.vcd");
        $dumpvars(0, alu_tb);
    end

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        errors = 0;
        $readmemh("golden/alu_vectors.hex", vec);

        for (i = 0; i < N_VECTORS; i = i + 1) begin
            @(negedge clk);
            op    = vec[i][63:60];
            a     = vec[i][59:44];
            b     = vec[i][43:28];
            y_exp = vec[i][27:12];
            z_exp = vec[i][11];
            o_exp = vec[i][10];
            @(posedge clk);
            #1;
            if (y !== y_exp || zero !== z_exp || overflow !== o_exp) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("[FAIL] #%0d op=%0h a=%h b=%h : y=%h(exp %h) z=%b(exp %b) ovf=%b(exp %b)",
                             i, op, a, b, y, y_exp, zero, z_exp, overflow, o_exp);
            end
        end

        $display("Checked %0d vectors, %0d mismatch(es).", N_VECTORS, errors);
        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL");
        $finish;
    end
endmodule
