# =============================================================================
# gui_start.tcl  --  GUI entry point for the STEP-BY-STEP walkthrough (driven by
# 'make gui-steps'). Loads the libraries + design (00_load.tcl), fits the view,
# then leaves you at the GUI's Tcl console to run 01..07 one at a time --
# printing the exact 'source ...' lines to paste.
# =============================================================================
set here [file dirname [info script]]

# STEP 0: load libs + netlist + SDC
source [file join $here 00_load.tcl]
catch {gui::fit}

puts ""
puts "==================================================================="
puts " Libraries + design loaded. Step through the flow by pasting these"
puts " into the Scripting console below, one at a time (watch the canvas):"
puts "==================================================================="
foreach s {01_floorplan 02_place_io_macro 03_pdn 04_place 05_cts 06_route 07_finish} {
  puts "   source [file join $here $s.tcl]"
}
puts "-------------------------------------------------------------------"
puts " Tip: press 'Fit' after step 1; toggle layers in Display Control."
puts "==================================================================="
