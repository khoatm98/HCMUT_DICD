# =============================================================================
# STEP 5 -- CLOCK TREE SYNTHESIS (CTS)
# -----------------------------------------------------------------------------
# WHAT THIS DOES
#   Builds a balanced tree of buffers from the clock port out to every flip-flop,
#   so the clock edge arrives at all flops at nearly the same time.
#
# WHY IT MATTERS -- skew steals your timing budget
#   Until now the clock was IDEAL (assumed to reach every flop instantly). Real
#   clock wires + buffers have delay, and if the clock reaches some flops later
#   than others, that difference is SKEW. Skew directly eats into the setup/hold
#   margin of every path, so a clock network is built as a balanced (often H-tree
#   like) network of identical buffers (here clkbuf_4) to keep LATENCY matched and
#   SKEW small. -sink_clustering_enable groups nearby flops so the tree is compact.
#   Two important follow-ups:
#     * set_propagated_clock -- switch timing from the ideal clock to the REAL one,
#       so all later analysis sees actual buffer/wire delay;
#     * detailed_placement -- CTS just inserted new buffers, so legalize again.
#
# IN THE GUI
#   Toggle "Timing Path" / select the clock net to see the buffer tree fan out to
#   the flops. The added clkbuf cells are the new instances.
# =============================================================================
source [file join [file dirname [info script]] _config.tcl]

puts "STEP 5> clock tree synthesis"
clock_tree_synthesis -buf_list sky130_fd_sc_hd__clkbuf_4 \
                     -root_buf sky130_fd_sc_hd__clkbuf_4 -sink_clustering_enable
set_propagated_clock [all_clocks]      ;# stop using the ideal clock
detailed_placement                     ;# legalize the newly inserted clock buffers

puts "STEP 5> clock tree built (toggle 'Timing Path' / clock nets in Display Control)."
puts "STEP 5> next:  source 06_route.tcl"
