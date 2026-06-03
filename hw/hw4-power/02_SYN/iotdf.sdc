# =============================================================================
# iotdf.sdc  --  timing constraints for the IoT Data Filter back-end (HW4).
#
# Sources the shared clock (common.sdc defines core_clk) and adds CVSD-style
# 130nm I/O constraints so STA (and the activity-driven report_power) run on the
# synthesized netlist. The clock definition lives in
# common/constraints/common.sdc so every stage sees an identical 50 MHz (20 ns)
# clock.
#
# iotdf ports:  clk rst_n i_valid i_data i_fn | o_valid o_data
# =============================================================================
set CLK_PORT   clk
set CLK_PERIOD 20.0
source ../../../common/constraints/common.sdc

# CVSD-style 130nm I/O budget: all input ports EXCEPT the clock, and all outputs.
set_input_delay  1.0 -clock core_clk [get_ports {rst_n i_valid i_fn[*] i_data[*]}]
set_output_delay 1.0 -clock core_clk [all_outputs]
set_drive        1    [all_inputs]
set_load         0.05 [all_outputs]
set_max_fanout   8    [current_design]
