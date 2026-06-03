# =============================================================================
# common.sdc  --  baseline timing constraints shared by HW3+ and the smoke test.
#
# A per-design .sdc sets CLK_PORT / CLK_PERIOD (in ns) BEFORE sourcing this file,
# then adds its own input/output delays. Keeping the clock definition in one
# place means every stage (synthesis, STA, APR) sees an identical clock.
# =============================================================================

if {![info exists CLK_PORT]}   { set CLK_PORT   clk  }
if {![info exists CLK_PERIOD]} { set CLK_PERIOD 30.0 }

create_clock -name core_clk -period $CLK_PERIOD [get_ports $CLK_PORT]

# CVSD-style 130nm pessimism (SKY130 is also a 130nm-class node).
set_clock_uncertainty 0.1  [get_clocks core_clk]
set_clock_transition  0.15 [get_clocks core_clk]
