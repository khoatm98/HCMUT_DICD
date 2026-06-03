# =============================================================================
# conv.sdc  --  STARTER timing constraints for the convolution engine (HW3).
#
# YOU complete this file. The engine is a SEQUENTIAL, SINGLE-CLOCK design (one
# clock `clk`, active-low synchronous reset). Used by `make sta` (OpenSTA on the
# synthesized netlist) and later by HW5 APR.
#
# The shared clock definition lives in common/constraints/common.sdc: set
# CLK_PORT and CLK_PERIOD (ns) here, then `source` it -- that creates a clock
# named `core_clk` on the clock port with uncertainty/transition pessimism.
#
# Read INSTRUCTIONS.md step 5 before editing. Goal: a realistic constraint set
# so `make sta` reports POSITIVE setup/hold slack (no violations) at a sensible
# period for this small datapath.
# =============================================================================

# ---- 1. clock ----
# TODO: pick a target clock period in ns for this design. The critical path is
#       roughly one 16x16 signed multiply + the 40-bit accumulate add. Start
#       loose (e.g. 20 ns = 50 MHz) and tighten until you understand the slack.
set CLK_PORT   clk
set CLK_PERIOD 20.0
source ../../common/constraints/common.sdc

# ---- 2. input delays ----
# TODO: constrain ALL data/control inputs relative to core_clk. The inputs are:
#       rst_n, i_valid, and the 16-bit bus i_data[15:0].
#       (Do NOT put an input delay on the clock port itself.)
# Example pattern (uncomment + complete):
# set_input_delay 2.0 -clock core_clk [get_ports {rst_n i_valid}]
# set_input_delay 2.0 -clock core_clk [get_ports {i_data[*]}]

# ---- 3. output delays ----
# TODO: constrain ALL outputs relative to core_clk. The outputs are:
#       o_valid, o_done, o_busy, and the 16-bit bus o_data[15:0].
# Example pattern (uncomment + complete):
# set_output_delay 2.0 -clock core_clk [all_outputs]

# ---- 4. (optional) driving cell / load ----
# Real flows model the driver strength and the capacitive load on the pins.
# You may add set_driving_cell / set_load for extra realism (not required).
