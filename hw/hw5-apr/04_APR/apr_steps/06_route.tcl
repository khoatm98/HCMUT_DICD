# =============================================================================
# STEP 6 -- ROUTING
# -----------------------------------------------------------------------------
# WHAT THIS DOES
#   Draws the actual metal wires + vias that connect the pins, in two passes:
#   GLOBAL route (plan + check congestion) then DETAILED route (real geometry).
#
# WHY IT MATTERS -- turning "connected in the netlist" into real metal
#   * GLOBAL routing chops the die into a coarse grid of cells and decides, for each
#     net, WHICH regions and layers it will pass through -- without drawing exact
#     wires yet. Its real job is to balance CONGESTION: if too many nets want the
#     same region, some won't fit, so it spreads them out (or flags the spot).
#   * DETAILED routing then lays the exact wires on the legal TRACKS (STEP 1) and
#     drops vias to change layers, obeying spacing/width DESIGN RULES (DRC). It
#     iterates, ripping up and rerouting to remove violations.
#   set_routing_layers met1-met5 limits signals to those layers (upper metals are
#   reserved for the PDN). This is the LONG stage -- detailed routing is the most
#   compute-heavy step in the flow. -verbose 1 prints its progress; the DRC report
#   lists any remaining rule violations (we want zero).
#
# IN THE GUI
#   Metal appears layer by layer. Toggle individual met1..met5 layers in Display
#   Control to see how each net climbs through the stack; pick a net to highlight it.
# =============================================================================
source [file join [file dirname [info script]] _config.tcl]

puts "STEP 6> global route"
set_routing_layers -signal met1-met5
global_route

# DRC report path: alongside OUT_DEF when set (headless flow), else local file.
set drc_rpt [expr {[info exists ::env(OUT_DEF)] \
                   ? "[file rootname $::env(OUT_DEF)].drc.rpt" : "route.drc.rpt"}]
puts "STEP 6> detailed route  (long; DRC report -> $drc_rpt)"
detailed_route -output_drc $drc_rpt -verbose 1

puts "STEP 6> routed."
puts "STEP 6> next:  source 07_finish.tcl"
