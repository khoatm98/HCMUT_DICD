# HW1 — Learning objectives

By the end of HW1 you should be able to:

1. **Write clean, parameterized combinational Verilog.** Implement a 14-operation
   ALU driven by a 4-bit opcode, using a `WIDTH`/`FRAC` parameterization (no
   hard-coded magic numbers) and shared opcode macros.

2. **Reason about signed fixed-point arithmetic.** Implement Q6.10 add/sub with
   **saturation** and Q6.10 multiply with **round-half-up + saturation**, and
   explain when and why `overflow` is raised — the numeric foundation the CPU
   and its MAC instruction build on.

3. **Use signedness and shifts deliberately.** Get `$signed`/`$unsigned`,
   logical vs arithmetic shifts (`>>` vs `>>>`), and width extension right.

4. **Practice real verification habits.** Run a **self-checking** testbench that
   compares your design against a golden reference model over thousands of
   directed + random vectors, and interpret a `RESULT: PASS/FAIL` outcome rather
   than eyeballing waveforms.

5. **Read waveforms in GTKWave** to debug a specific failing vector.

6. **Run the open-source simulators** (Icarus and Verilator) and produce a
   lint-clean design.

These habits — parameterized RTL, a fixed reusable interface, and golden-model
self-checking — recur in every later homework.
