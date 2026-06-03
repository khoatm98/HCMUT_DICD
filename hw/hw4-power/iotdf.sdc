# =============================================================================
# iotdf.sdc  --  timing constraints for the IoT Data Filter back-end (HW4).
#
# Sets the clock (via the shared common.sdc) and reasonable I/O delays so STA
# (and the activity-driven report_power) run on the synthesized netlist. The
# clock definition lives in common/constraints/common.sdc so every stage sees an
# identical 50 MHz (20 ns) clock.
# =============================================================================
set CLK_PORT   clk
set CLK_PERIOD 20.0
source ../../common/constraints/common.sdc

# Streaming control + data inputs / outputs (everything but the clock).
set_input_delay  2.0 -clock core_clk [get_ports {rst_n i_valid i_fn[*] i_data[*]}]
set_output_delay 2.0 -clock core_clk [get_ports {o_valid o_data[*]}]
