# =============================================================================
# conv.sdc  --  timing constraints for the convolution engine (HW3, 02_SYN).
#
# The engine is a SEQUENTIAL, SINGLE-CLOCK design (one clock `clk`, active-low
# synchronous reset). Used by `make sta` (OpenSTA on the synthesized netlist)
# and later by HW5 APR.
#
# The shared clock definition lives in common/constraints/common.sdc: we set
# CLK_PORT and CLK_PERIOD (ns) here, then `source` it -- that creates a clock
# named `core_clk` on the clock port with CVSD-style 130nm uncertainty/transition
# pessimism. The I/O block below uses the CVSD-style constraint values.
# =============================================================================

# ---- 1. clock ----
# 20 ns (50 MHz) is comfortable for one 16x16 signed multiply + the 40-bit
# accumulate add on sky130_fd_sc_hd at the tt corner.
set CLK_PORT   clk
set CLK_PERIOD 20.0
source ../../../common/constraints/common.sdc

# ---- 2. I/O delays (CVSD-style) ----
# Constrain every data/control input EXCEPT the clock, and every output,
# relative to core_clk.
set_input_delay  1.0 -clock core_clk [get_ports {rst_n i_valid i_data[*]}]
set_output_delay 1.0 -clock core_clk [all_outputs]

# ---- 3. drive / load / fanout (CVSD-style realism) ----
set_drive 1 [all_inputs]
set_load 0.05 [all_outputs]
set_max_fanout 8 [current_design]
