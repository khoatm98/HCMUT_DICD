# Constraints for the standalone OpenSTA stage of the smoke test.
# (The APR stage gets its clock from config.json's CLOCK_PORT/CLOCK_PERIOD.)
set CLK_PORT   clk
set CLK_PERIOD 20.0
source ../common/constraints/common.sdc

set_input_delay  2.0 -clock core_clk [get_ports {rst_n en}]
set_output_delay 2.0 -clock core_clk [all_outputs]
