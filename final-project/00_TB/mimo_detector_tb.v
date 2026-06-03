// =============================================================================
// mimo_detector_tb.v  --  self-checking testbench TEMPLATE for the capstone.
//
// This is a STARTING POINT: wire it to YOUR mimo_detector interface (the TODOs).
// It follows the course convention -- own the stimulus, drive the DUT through
// ports only (Icarus + Verilator portable), and print exactly one
// "RESULT: PASS" / "RESULT: FAIL" line so the Makefile can grep it.
//
// Inputs come from the COMMITTED public dev set in ../00_TB/golden/:
//   ../00_TB/golden/vectors.hex  R upper-triangle (i<=j) then y_tilde, "re im" Q6.10 hex
// This TB does NOT check exact-match. It runs your detector on every case and
// WRITES the detected symbol indices to build/detected.txt (one line per case);
// grading is by PSNR + area + time + power. Score quality afterwards with:
//   python3 ../00_TB/score.py --detected build/detected.txt --truth ../00_TB/golden/truth.txt --m 8
// (Load vectors via $readmemh into a reg array, or $fscanf under Icarus.)
// =============================================================================
`timescale 1ns/1ps

module mimo_detector_tb;
    localparam integer N = 4;      // antennas (match your gen_golden --n)
    localparam integer M = 8;      // M-PSK   (match your gen_golden --m)

    reg clk = 1'b0;
    reg rst_n;
    always #5 clk = ~clk;

    // ---- DUT instance (TODO: match your module's ports) ----
    // mimo_detector dut ( .clk(clk), .rst_n(rst_n), ... );

    integer ncases, fout;

    initial begin
        $dumpfile("build/mimo_detector.vcd");
        $dumpvars(0, mimo_detector_tb);
        ncases = 0;
        fout = $fopen("build/detected.txt", "w");

        rst_n = 1'b0; @(negedge clk); @(negedge clk); rst_n = 1'b1;

        // ============================ TODO ============================
        // For each test case in ../00_TB/golden/vectors.hex:
        //   1) stream the R upper-triangle entries, then the y_tilde entries,
        //      into the DUT using your load protocol (i_valid / i_is_R / i_data);
        //   2) wait for o_out_valid;
        //   3) write the detected symbol indices (N per line) to `fout`, e.g.
        //      $fwrite(fout, "%0d %0d %0d %0d\n", s0, s1, s2, s3);
        //   4) ncases = ncases + 1;
        // (Read vectors with $readmemh into a reg array, or $fscanf under Icarus.)
        // Then score quality:
        //   ../00_TB/score.py --detected build/detected.txt --truth ../00_TB/golden/truth.txt
        // ==============================================================

        $fclose(fout);
        // The run completing (all cases driven) is the gate `make vsim` checks;
        // detection QUALITY is graded by score.py (PSNR), not by this line.
        if (ncases > 0) $display("RESULT: PASS  (%0d cases -> build/detected.txt; score with ../00_TB/score.py)", ncases);
        else            $display("RESULT: FAIL  (no cases ran -- complete the TODO)");
        $finish;
    end
endmodule
