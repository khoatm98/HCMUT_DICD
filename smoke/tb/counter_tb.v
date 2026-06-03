// =============================================================================
// counter_tb.v  --  self-checking testbench for the smoke-test counter.
//
// Convention used across this whole course:
//   * A self-checking testbench prints exactly ONE summary line:
//        "RESULT: PASS"   or   "RESULT: FAIL"
//   * The run scripts/Makefiles grep for "RESULT: PASS" to set their exit code.
//     This makes pass/fail robust across Icarus Verilog and Verilator.
// =============================================================================
`timescale 1ns/1ps

module counter_tb;

    localparam WIDTH = 8;

    reg              clk = 1'b0;
    reg              rst_n;
    reg              en;
    wire [WIDTH-1:0] count;

    integer          errors = 0;
    integer          i;
    reg  [WIDTH-1:0] expected;

    // Device under test
    counter #(.WIDTH(WIDTH)) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .count (count)
    );

    // 100 MHz clock (10 ns period)
    always #5 clk = ~clk;

    // Waveform dump for GTKWave
    initial begin
        $dumpfile("sim/counter.vcd");
        $dumpvars(0, counter_tb);
    end

    // Compare helper
    task check;
        input [WIDTH-1:0] got;
        input [WIDTH-1:0] exp;
        begin
            if (got !== exp) begin
                errors = errors + 1;
                $display("[FAIL] time=%0t  count=%0d  expected=%0d", $time, got, exp);
            end
        end
    endtask

    initial begin
        // ---- reset ----
        rst_n = 1'b0;
        en    = 1'b0;
        @(negedge clk);
        @(negedge clk);
        check(count, {WIDTH{1'b0}});   // held at 0 during reset

        // ---- count, including a full wrap (256 -> 0) ----
        rst_n    = 1'b1;
        en       = 1'b1;
        expected = {WIDTH{1'b0}};
        for (i = 0; i < 300; i = i + 1) begin
            @(posedge clk);
            #1;                         // let the non-blocking update settle
            expected = expected + 1'b1; // value after this clock edge
            check(count, expected);
        end

        // ---- enable held low keeps the value ----
        en = 1'b0;
        @(posedge clk);
        #1;
        check(count, expected);

        // ---- single summary line ----
        if (errors == 0)
            $display("RESULT: PASS  (counted up, wrapped, and honored enable)");
        else
            $display("RESULT: FAIL  (%0d mismatches)", errors);

        $finish;
    end

endmodule
