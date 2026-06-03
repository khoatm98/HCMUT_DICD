# HW5 — Learning objectives

1. **Run the RTL-to-GDSII flow.** Configure and drive LibreLane/OpenROAD to take
   a synthesized design through floorplan → PDN → placement → CTS → routing →
   stream-out on SKY130.
2. **Inspect intermediate stages** (pedagogical visibility, not push-button):
   read the floorplan, a congestion heatmap, the clock tree, and the routed
   layout — and relate them to the RTL (flop arrays, the multiplier).
3. **Do physical signoff.** Confirm post-route timing (OpenSTA), a clean **DRC**
   (Magic), and an **LVS** match (Netgen) — what "tape-out-clean" means.
4. **View and navigate a layout** in KLayout, and connect what you see back to
   synthesis/area decisions.
5. **Tune the flow.** Adjust utilization/clock and observe the effect on
   congestion, timing, and area.
