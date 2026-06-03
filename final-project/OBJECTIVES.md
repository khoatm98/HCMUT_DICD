# Final Project — Learning objectives

1. **Integrate the whole flow.** Take one non-trivial design from RTL to a
   DRC/LVS-clean GDSII, reusing the HW1–HW5 methodology end-to-end on the
   open-source toolchain.
2. **Design a real datapath + control.** Implement complex-number arithmetic
   (fixed-point), a partial-Euclidean-distance metric, and a tree-search FSM with
   pruning — a genuine signal-processing accelerator.
3. **Own verification.** Build a self-checking flow against a golden ML model,
   across RTL and gate level, and characterize detection quality vs SNR.
4. **Close PPA.** Meet timing in synthesis and post-route, measure and reduce
   power, and report area/timing/power tradeoffs with evidence.
5. **Produce a reproducible result.** A one-command runbook that regenerates the
   GDSII and the PPA numbers — the hallmark of a real tape-out flow.
6. **Communicate.** A report that explains the algorithm, the microarchitecture
   choices, and the measured PPA.
