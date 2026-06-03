# HW2 — Learning objectives

By the end of HW2 you should be able to:

1. **Design a single-cycle datapath + control.** Wire a PC, instruction decode,
   a register file, and the ALU into a working processor, and write the
   combinational control that steers them per instruction.

2. **Reuse IP across a design boundary.** Instantiate the **HW1 ALU unchanged**
   as the execution unit — experiencing first-hand why a stable, well-specified
   interface matters (the continuity principle).

3. **Implement and verify a custom instruction.** Add **MAC** end-to-end:
   encoding → decode → datapath (reusing the multiplier + a saturating
   accumulate) → verification, and articulate why it is a small, cheap extension.

4. **Reason about an ISA.** Understand instruction formats, immediate
   sign-extension, PC-relative branches, jumps, and load/store addressing.

5. **Verify at scale with a golden model.** Write programs in assembly, assemble
   them, and self-check the CPU against a reference instruction-set simulator —
   the same golden-model discipline used through HW3 (gate-level) and beyond.

This CPU is the design that is synthesized (HW3), power-optimized (HW4), and
placed-and-routed to GDSII (HW5) — so build it cleanly.
