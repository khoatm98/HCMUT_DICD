# =============================================================================
# STEP 7 -- FILL + OUTPUTS + TIMING SIGN-OFF
# -----------------------------------------------------------------------------
# WHAT THIS DOES
#   Fills the empty gaps with filler cells, writes the result out in several
#   formats, and reports whether the design meets timing.
#
# WHY IT MATTERS -- a manufacturable, checkable result
#   * FILLER cells occupy the gaps left between std cells. They carry no logic but
#     are required: they keep the power rails and the n-well/implant layers
#     CONTINUOUS across each row and help satisfy metal/poly DENSITY rules the
#     foundry imposes. (Empty gaps would break the well/rail and fail DRC.)
#   * OUTPUTS:
#       - DEF  = the placed-and-routed layout (positions + wires) -> magic turns
#                this into the final GDS;
#       - Verilog = the post-layout gate netlist (now with clock buffers/fillers);
#       - DB   = OpenROAD's own database -> reopen the FULL routed state instantly
#                with read_db (that's what `make gui-view` uses).
#   * TIMING SIGN-OFF: report_wns / report_tns.
#       - WNS = Worst Negative Slack: the margin of the single most critical path.
#       - TNS = Total Negative Slack: the sum over ALL failing paths.
#       Slack = (required arrival time) - (actual). You want WNS >= 0 and TNS = 0,
#       i.e. nothing arrives late. (Negative setup slack -> LOOSEN, i.e. lengthen,
#       the clock period, or speed up the path -- shortening it makes it worse.)
#
# IN THE GUI
#   The gaps fill in. Use Timing -> report to browse the critical paths; the WNS/TNS
#   numbers print in the console.
# =============================================================================
source [file join [file dirname [info script]] _config.tcl]

puts "STEP 7> metal/std-cell fill"
filler_placement {sky130_fd_sc_hd__fill_1 sky130_fd_sc_hd__fill_2 \
                  sky130_fd_sc_hd__fill_4 sky130_fd_sc_hd__fill_8}

if {[info exists ::env(OUT_DEF)]} {
  write_def $::env(OUT_DEF)
  puts "STEP 7> wrote DEF -> $::env(OUT_DEF)"
}
if {[info exists ::env(OUT_NETLIST)]} {
  write_verilog $::env(OUT_NETLIST)
}
# Self-contained DB (cells + nets + routing): reopen instantly with read_db.
if {[env_or OUT_DB ""] ne ""} {
  write_db $::env(OUT_DB)
  puts "STEP 7> wrote DB  -> $::env(OUT_DB)"
}

puts "STEP 7> post-route timing:"
report_wns                             ;# worst negative slack -- want >= 0
report_tns                             ;# total negative slack -- want 0
puts "STEP 7> DONE. (Magic streams the DEF to GDS afterwards in the headless flow.)"
