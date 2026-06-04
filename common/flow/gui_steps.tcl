# =============================================================================
# gui_steps.tcl  --  GUI entry point for the STEP-BY-STEP walkthrough. Launched
# by 'make gui-steps'. It loads the libraries + design (apr_steps/00_load.tcl),
# fits the view, and then leaves you at the GUI's Tcl console to run the rest of
# the flow one step at a time -- printing the exact 'source ...' lines to paste.
# =============================================================================
set steps [file join [file dirname [info script]] apr_steps]

# STEP 0: load libs + netlist + SDC
source [file join $steps 00_load.tcl]
catch {gui::fit}

puts ""
puts "==================================================================="
puts " Libraries + design loaded. Step through the flow by pasting these"
puts " into the Scripting console below, one at a time (watch the canvas):"
puts "==================================================================="
foreach s {01_floorplan 02_place_io_macro 03_pdn 04_place 05_cts 06_route 07_finish} {
  puts "   source [file join $steps $s.tcl]"
}
puts "-------------------------------------------------------------------"
puts " Tip: press 'Fit' after step 1; toggle layers in Display Control."
puts "==================================================================="
