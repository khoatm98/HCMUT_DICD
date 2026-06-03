# =============================================================================
# common.sdc  --  baseline timing constraints shared by HW3+ and the smoke test.
#
# A per-design .sdc sets CLK_PORT / CLK_PERIOD (in ns) BEFORE sourcing this file,
# then adds its own input/output delays. Keeping the clock definition in one
# place means every stage (synthesis, STA, APR) sees an identical clock.
# =============================================================================

if {![info exists CLK_PORT]}   { set CLK_PORT   clk  }
if {![info exists CLK_PERIOD]} { set CLK_PERIOD 20.0 }

create_clock -name core_clk -period $CLK_PERIOD [get_ports $CLK_PORT]

# Pessimism so timing is not artificially easy on this teaching flow.
set_clock_uncertainty 0.25 [get_clocks core_clk]
set_clock_transition  0.15 [get_clocks core_clk]
