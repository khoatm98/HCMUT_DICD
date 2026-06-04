# =============================================================================
# STEP 2 -- I/O PINS + HARD MACRO
# -----------------------------------------------------------------------------
# WHAT THIS DOES
#   Assigns each top-level port to a physical pin location on a metal layer at the
#   die edge, then places the SRAM hard macro at a fixed spot and FIXES it.
#
# WHY IT MATTERS -- big fixed blocks first, edges/corners by choice
#   A "hard macro" (the SRAM) is a pre-built, pre-routed block: to the placer it's
#   a large fixed obstacle. You place the big fixed things FIRST, then let the std
#   cells flow around them (STEP 4). We seat the SRAM in the LOWER-LEFT corner so
#   the rest of the core stays one contiguous region for std cells, and so its
#   pins face open space (a "routing channel") instead of being buried. place_macro
#   also marks it FIXED, so global placement can't shove it. (One known macro ->
#   explicit placement is clearest. Many macros -> the automatic 'rtl_macro_placer'.)
#   place_pins puts horizontal-reaching ports on met3 and vertical ones on met2 so
#   the router can actually get to them.
#
# IN THE GUI
#   The SRAM appears as a big rectangle in the lower-left; small pin markers appear
#   around the die edge. Click the macro to inspect it in the Inspector.
# =============================================================================
source [file join [file dirname [info script]] _config.tcl]

puts "STEP 2> place I/O pins (horizontal on met3, vertical on met2)"
place_pins -hor_layers met3 -ver_layers met2

if {[llength $macro_insts] > 0} {
  puts "STEP 2> place hard macro(s) at lower-left $macro_loc um: $macro_insts"
  foreach inst $macro_insts {
    if {$inst ne ""} {
      place_macro -macro_name $inst -location $macro_loc -orientation R0
    }
  }
} else {
  puts "STEP 2> (no hard macros for this design)"
}

puts "STEP 2> macro fixed in place (see the big block in the GUI)."
puts "STEP 2> next:  source 03_pdn.tcl"
