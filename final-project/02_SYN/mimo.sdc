# =============================================================================
# mimo.sdc -- timing constraints for the MIMO detector (02_SYN / STA + APR).
#
# The clock + pessimism come from common/constraints/common.sdc (which creates a
# clock named core_clk on $CLK_PORT). Set CLK_PORT / CLK_PERIOD (ns) BEFORE
# sourcing it. CVSD-style 130nm I/O budget is applied below; tune CLK_PERIOD
# after reading STA -- the PED/compare path (multiply + accumulate + compare) is
# the long pole.
# =============================================================================
set CLK_PORT   clk
set CLK_PERIOD 20.0
source ../../common/constraints/common.sdc

# ---- CVSD-style 130nm I/O constraints ----
# Off-chip timing budget on every port except the clock, plus drive/load/fanout.
set_input_delay  1.0 -clock core_clk [remove_from_collection [all_inputs] [get_ports $CLK_PORT]]
set_output_delay 1.0 -clock core_clk [all_outputs]
set_drive 1 [all_inputs]
set_load 0.05 [all_outputs]
set_max_fanout 8 [current_design]
