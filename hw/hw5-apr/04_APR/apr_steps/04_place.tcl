# =============================================================================
# STEP 4 -- PLACEMENT
# -----------------------------------------------------------------------------
# WHAT THIS DOES
#   Decides where every standard cell sits, in two passes: GLOBAL placement
#   (approximate, find good positions) then DETAILED placement (legalize them).
#
# WHY IT MATTERS -- placement decides wirelength, timing, and routability
#   * GLOBAL placement solves an analytic optimization: spread the cells to roughly
#     minimize total WIRELENGTH (so connected cells sit near each other) while
#     pushing toward the target DENSITY so they're not all piled up. At this stage
#     cells may still slightly overlap / sit off-grid -- it's about good *positions*.
#     "-pad_left/-pad_right 1" leaves a 1-site gap beside each cell so the router
#     has room (a cheap way to relieve congestion).
#   * estimate_parasitics -placement gives each net a rough R/C from the placement,
#     so timing analysis is meaningful BEFORE routing (placement is timing-aware).
#   * DETAILED placement then snaps every cell onto a legal row/site with NO overlap;
#     check_placement errors out if anything is still illegal.
#   Good placement is the single biggest lever on final timing -- the router can
#   only connect what placement put close together.
#
# IN THE GUI
#   The core fills with std cells flowing around the fixed SRAM. Try the placement-
#   density heat map (Display Control -> Heat Maps) to spot dense regions.
# =============================================================================
source [file join [file dirname [info script]] _config.tcl]

puts "STEP 4> global placement (target density = $density)"
global_placement -density $density -pad_left 1 -pad_right 1
estimate_parasitics -placement        ;# rough RC so timing is meaningful

puts "STEP 4> detailed placement (legalize onto rows)"
detailed_placement
check_placement                        ;# error out if anything is still illegal

puts "STEP 4> std cells placed + legal."
puts "STEP 4> next:  source 05_cts.tcl"
