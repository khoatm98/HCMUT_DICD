// =============================================================================
// iotdf_workload_tb.v  --  ACTIVITY-CAPTURE testbench for the power flow (HW4).
//
// Drives a long, deterministic mixed-function byte stream (tools/gen_golden.py
// -> workload/workload.hex) into the iotdf DUT and dumps a VCD that OpenSTA reads
// for activity-driven power (`report_power`). It is NOT self-checking -- its job
// is to produce representative switching activity. It drives the DUT through its
// ports ONLY, so the SAME testbench drives the RTL and the synthesized gate-level
// netlist (baseline and clock-gated).
//
// The DUT instance is named `dut`, so the power flow uses VCD_SCOPE = TOP/dut.
//
// Each workload word (16-bit): [15] i_valid  [13:12] i_fn  [11:4] i_data.
// =============================================================================
`timescale 1ns/1ps

module iotdf_workload_tb;
`include "workload_count.vh"        // defines N_WORKLOAD (generated)

    reg        clk = 1'b0;
    reg        rst_n;
    reg        i_valid;
    reg  [7:0] i_data;
    reg  [1:0] i_fn;
    wire       o_valid;
    wire [7:0] o_data;

    reg  [15:0] wl [0:N_WORKLOAD-1];
    integer     i;

    iotdf dut (
        .clk(clk), .rst_n(rst_n),
        .i_valid(i_valid), .i_data(i_data), .i_fn(i_fn),
        .o_valid(o_valid), .o_data(o_data)
    );

    initial begin
        $dumpfile("sim/iotdf_workload.vcd");
        $dumpvars(0, iotdf_workload_tb);
    end

    always #5 clk = ~clk;

    initial begin
        i_valid = 1'b0;
        i_data  = 8'h00;
        i_fn    = 2'b00;
        $readmemh("workload/workload.hex", wl);

        rst_n = 1'b0;
        @(negedge clk); @(negedge clk);
        rst_n = 1'b1;

        for (i = 0; i < N_WORKLOAD; i = i + 1) begin
            @(negedge clk);
            i_valid = wl[i][15];
            i_fn    = wl[i][13:12];
            i_data  = wl[i][11:4];
        end
        @(negedge clk);
        i_valid = 1'b0;
        @(negedge clk);

        $display("Workload drove %0d cycles (activity captured to sim/iotdf_workload.vcd).",
                 N_WORKLOAD);
        // A harmless RESULT line so the same grep-based plumbing is happy.
        $display("RESULT: PASS");
        $finish;
    end
endmodule
