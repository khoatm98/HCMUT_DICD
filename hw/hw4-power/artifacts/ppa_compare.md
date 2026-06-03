# HW4 -- IoT Data Filter: PPA before/after clock gating

> TEMPLATE. `cd 06_POWER && make compare` overwrites this file with the measured
> numbers (via make_ppa.py), then you replace the discussion placeholders with
> your own analysis before submitting.

## Power (OpenSTA `report_power`, activity-driven from the workload VCD)

| Metric (W)       | Baseline | Clock-gated | Reduction |
|------------------|----------|-------------|-----------|
| Internal power   | ?        | ?           | ?         |
| Switching power  | ?        | ?           | ?         |
| Leakage power    | ?        | ?           | ?         |
| **Total power**  | **?**    | **?**       | **?**     |

## Area (Yosys `stat -liberty`)

| Metric           | Baseline | Clock-gated | Delta |
|------------------|----------|-------------|-------|
| Cell count       | ?        | ?           | ?     |
| Chip area (um^2) | ?        | ?           | ?     |

## Discussion (fill in)

- **Where did the power go?** Identify the dominant contributor in the baseline
  (clock tree vs the CRC/LFSR state registers vs the combinational units).
- **What did clock gating buy?** Explain the total-power reduction and the
  small area cost of the inserted clock-gating cells.
- **Operand isolation:** the idle units' inputs are held at 0 so their
  combinational logic does not toggle. Quantify the switching-power effect and
  contrast it with gating the sequential state (CRC/LFSR registers).
- **PPA trade-off:** clock gating typically *adds* a few cells (area up slightly)
  while cutting dynamic power -- state the numbers above and conclude.
