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
# 45 ns (~22 MHz). The critical path is a HALF-CYCLE path: the SRAM macro launches
# read data on the falling edge, through the 9-tap MAC (16x16 multiply + 40-bit
# accumulate), captured on the next rising edge -- so only ~period/2 is available.
# 40 ns misses by ~0.7 ns; ~42 ns is the knee; 45 ns gives comfortable margin
# (+1.8 ns setup). Students may tighten toward 42 ns and report the WNS.
set CLK_PORT   clk
set CLK_PERIOD 45.0
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
