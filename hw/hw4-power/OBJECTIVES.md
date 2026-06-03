# HW4 — Learning objectives

HW4 is the course's **power** homework. The RTL is intentionally small so the
focus is on *measuring* and *reducing* dynamic power. By the end you should be
able to:

1. **Build a clean streaming datapath.** Implement a 1-in/1-out, fixed-latency
   byte engine with a synchronous active-low reset and registered outputs, and
   four independent transforms (Gray-code encode/decode, a running CRC-8, an LFSR
   scrambler) selected by a function code.

2. **Implement standard datapath primitives correctly.** Gray↔binary conversion,
   a **CRC-8** (poly 0x07, MSB-first) running register, and a **Fibonacci LFSR**
   with specified taps and seed — and verify them against known check values
   (e.g. CRC-8 of `"123456789"` = `0xF4`).

3. **Structure RTL for low power.** Give each function its own unit, **isolate the
   operands** of idle units, and **gate the state registers** of the unselected
   stateful units — the structure that makes clock gating effective.

4. **Capture switching activity.** Drive a representative **workload** through a
   gate-level netlist and record a **VCD** — understand why power is
   *activity-dependent*, not just a static property of the netlist.

5. **Measure power with the real flow.** Synthesize with Yosys, simulate the
   gate-level netlist, and run **OpenSTA `report_power`** with the activity VCD to
   get internal / switching / leakage / total power.

6. **Reduce power and quantify the trade-off.** Re-synthesize with **clock gating**
   (`CLOCKGATE=1`), re-measure on the *same* workload, and report a **before/after
   PPA**: how much dynamic power you saved and what it cost in area.

7. **Reason about power techniques.** Explain the difference between **clock
   gating** (stops the clock to idle flops) and **operand isolation** (stops idle
   *combinational* logic from toggling), and where each helps in this design.

These are the skills behind every real low-power ASIC: a workload, an activity
measurement, a targeted optimization, and a quantified before/after result.
