// =============================================================================
// cpu_tb.v  --  self-checking testbench for the TinyRISC-16 CPU (HW2).
//
// The testbench OWNS the instruction + data memories (so it works identically
// in Icarus and Verilator -- no hierarchical access into the DUT). It loads the
// assembled program, runs until HALT, then compares the final data memory to
// the golden image produced by the ISS. Prints one "RESULT: PASS/FAIL" line.
//
// Files (the 01_RTL Makefile copies the selected program's committed patterns
// from 00_TB/patterns/<PROG>.* into build/ before running; paths are relative
// to the 01_RTL run dir):
//   build/imem.hex    instruction image      (asm)
//   build/dmem.hex    initial data image     (asm)
//   build/golden.hex  expected FINAL data    (iss)
// =============================================================================
`timescale 1ns/1ps

module cpu_tb;
    localparam integer WIDTH = 16;
    localparam integer AW    = 8;
    localparam integer NMEM  = (1 << AW);
    localparam integer TIMEOUT = 100000;

    reg                  clk = 1'b0;
    reg                  rst_n;

    // memories owned by the testbench
    reg [WIDTH-1:0] imem   [0:NMEM-1];
    reg [WIDTH-1:0] dmem   [0:NMEM-1];
    reg [WIDTH-1:0] golden [0:NMEM-1];

    // DUT <-> memory wiring
    wire [AW-1:0]    iaddr, daddr;
    wire [WIDTH-1:0] idata, dwdata, drdata;
    wire             dwe, halted;
    wire [AW-1:0]    pc;

    assign idata  = imem[iaddr];
    assign drdata = dmem[daddr];

    cpu_core #(.WIDTH(WIDTH), .AW(AW)) dut (
        .clk(clk), .rst_n(rst_n),
        .imem_addr(iaddr), .imem_rdata(idata),
        .dmem_addr(daddr), .dmem_wdata(dwdata), .dmem_we(dwe), .dmem_rdata(drdata),
        .halted(halted), .pc_out(pc)
    );

    // synchronous data writes go into the TB-owned memory
    always @(posedge clk) if (dwe) dmem[daddr] <= dwdata;

    always #5 clk = ~clk;

    initial begin
        $dumpfile("build/cpu.vcd");
        $dumpvars(0, cpu_tb);
    end

    integer i, errors, cyc;
    initial begin
        for (i = 0; i < NMEM; i = i + 1) begin
            imem[i] = {WIDTH{1'b0}};
            dmem[i] = {WIDTH{1'b0}};
            golden[i] = {WIDTH{1'b0}};
        end
        $readmemh("build/imem.hex",   imem);
        $readmemh("build/dmem.hex",   dmem);
        $readmemh("build/golden.hex", golden);
        errors = 0;

        rst_n = 1'b0;
        @(negedge clk); @(negedge clk);
        rst_n = 1'b1;

        cyc = 0;
        while (!halted && cyc < TIMEOUT) begin
            @(posedge clk);
            cyc = cyc + 1;
        end
        #1;

        for (i = 0; i < NMEM; i = i + 1) begin
            if (dmem[i] !== golden[i]) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("[FAIL] dmem[%0d] = %h  expected %h", i, dmem[i], golden[i]);
            end
        end

        if (!halted)
            $display("[WARN] CPU did not HALT within %0d cycles", cyc);
        $display("Ran %0d cycles, %0d data-memory mismatch(es).", cyc, errors);
        if (errors == 0 && halted) $display("RESULT: PASS");
        else                       $display("RESULT: FAIL");
        $finish;
    end
endmodule
