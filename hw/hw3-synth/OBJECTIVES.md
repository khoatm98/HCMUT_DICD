# HW3 — Learning objectives

HW3 is the **synthesis** homework: you design a small hardware accelerator, then
take it through the front end of the ASIC flow (synthesis → gate equivalence →
static timing). By the end you should be able to:

1. **Design a streaming, FSM-driven datapath.** Build a 3×3 convolution engine
   with a clean `LOAD → COMPUTE → OUTPUT → DONE` state machine, a streaming
   valid/data input/output protocol, and on-chip flop arrays — all
   parameterized (`WIDTH`/`FRAC`/`IMG`), active-low synchronous reset, no latches.

2. **Reuse the Q6.10 fixed-point discipline at the dot-product level.** Apply the
   HW1 ALU's **round-half-up + saturation** rule (`FXMUL`) to a *sum of nine
   products*: accumulate in **full precision** first, round and saturate **once**.
   Understand why accumulate-then-round beats round-then-accumulate.

3. **Share expensive datapath resources.** Implement the convolution with **one**
   multiplier and a **sequential** multiply-accumulate instead of nine parallel
   multipliers — the area/throughput trade-off that motivates the rest of the
   flow.

4. **Synthesize RTL to standard cells.** Run Yosys to map your design onto the
   SKY130 library, read the **area/cell report**, and connect logic decisions
   (sequential MAC, flop arrays) to the gate count you get.

5. **Prove gate-level equivalence.** Run the **same** self-checking testbench
   against the synthesized netlist + SKY130 cell models and confirm it matches
   the golden — the practical form of "did synthesis preserve behavior?"

6. **Write timing constraints and read an STA report.** Author an `.sdc`
   (clock, input/output delays) for a sequential single-clock design, run
   OpenSTA, and interpret setup/hold **slack** and the **critical path**.

7. **Use the open-source flow** (Verilator/Icarus, Yosys, OpenSTA) with the
   course's reusable flow wrappers and one-command Makefile targets.

This same engine is **placed-and-routed to GDSII in HW5**, so a clean,
macro-free, timing-friendly design here pays off downstream — the continuity
principle of the course.
