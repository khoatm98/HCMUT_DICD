// =============================================================================
// iotdf_tb.v  --  self-checking testbench for the IoT Data Filter (HW4 power).
//
// Reads a packed per-cycle stimulus/expected stream produced by
// tools/gen_golden.py and checks the DUT cycle-by-cycle. The testbench OWNS all
// stimulus and drives the DUT through its ports only (no hierarchical access),
// so it runs identically under Icarus and Verilator. Prints exactly one summary
// line ("RESULT: PASS" / "RESULT: FAIL") for the Makefiles to grep. Dumps
// sim/iotdf.vcd for GTKWave.
//
// Each vector word (24-bit, MSB first):
//   [23] i_valid  [22:21] i_fn  [20:13] i_data
//   [12] o_valid_exp  [11:4] o_data_exp  [3:0] 0
// =============================================================================
`timescale 1ns/1ps

module iotdf_tb;
`include "iotdf_count.vh"          // defines N_VECTORS (generated)

    reg        clk = 1'b0;
    reg        rst_n;
    reg        i_valid;
    reg  [7:0] i_data;
    reg  [1:0] i_fn;
    wire       o_valid;
    wire [7:0] o_data;

    reg  [23:0] vec [0:N_VECTORS-1];
    integer     i, errors;
    reg         ov_exp;
    reg  [7:0]  od_exp;

    iotdf dut (
        .clk(clk), .rst_n(rst_n),
        .i_valid(i_valid), .i_data(i_data), .i_fn(i_fn),
        .o_valid(o_valid), .o_data(o_data)
    );

    initial begin
        $dumpfile("sim/iotdf.vcd");
        $dumpvars(0, iotdf_tb);
    end

    always #5 clk = ~clk;

    initial begin
        errors  = 0;
        i_valid = 1'b0;
        i_data  = 8'h00;
        i_fn    = 2'b00;
        $readmemh("golden/iotdf_vectors.hex", vec);

        // synchronous active-low reset for two clocks
        rst_n = 1'b0;
        @(negedge clk); @(negedge clk);
        rst_n = 1'b1;

        for (i = 0; i < N_VECTORS; i = i + 1) begin
            // drive this cycle's inputs just after the falling edge
            @(negedge clk);
            i_valid = vec[i][23];
            i_fn    = vec[i][22:21];
            i_data  = vec[i][20:13];
            ov_exp  = vec[i][12];
            od_exp  = vec[i][11:4];

            // sample outputs right after the rising edge (registered DUT)
            @(posedge clk);
            #1;
            if (o_valid !== ov_exp || (o_valid && (o_data !== od_exp))) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("[FAIL] #%0d in(v=%b fn=%0d d=%h) : o_valid=%b(exp %b) o_data=%h(exp %h)",
                             i, i_valid, i_fn, i_data, o_valid, ov_exp, o_data, od_exp);
            end
        end

        $display("Checked %0d cycles, %0d mismatch(es).", N_VECTORS, errors);
        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL");
        $finish;
    end
endmodule
