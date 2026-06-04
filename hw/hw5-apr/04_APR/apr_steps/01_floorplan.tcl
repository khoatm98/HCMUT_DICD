# =============================================================================
# STEP 1 -- FLOORPLAN
# -----------------------------------------------------------------------------
# WHAT THIS DOES
#   Creates the chip canvas: a DIE, a CORE area inside it, the placement ROWS the
#   standard cells will sit in, and the routing TRACKS the wires will snap to.
#
# WHY IT MATTERS -- utilization sets the area/quality trade-off
#   "-utilization 35" means the std cells will fill ~35% of the core; the tool
#   sizes the core so cell_area / core_area = 35%. It's the single biggest knob:
#     * too HIGH (e.g. 90%) -> tiny die, but cells are packed -> ROUTING CONGESTION,
#       timing/DRC failures;
#     * too LOW  (e.g. 15%) -> easy to route, but wasted area + power + longer wires.
#   "-core_space 6.0" leaves a 6um margin between core and die edge (room for the
#   power ring / I/O). "-site unithd" is the std-cell row template (its height =
#   one row, its width = the placement grid). make_tracks lays the per-layer grid
#   of legal wire centerlines -- the detailed router may only put metal on tracks.
#
# IN THE GUI
#   The die/core outline + rows appear. Press "Fit". Toggle "Rows" and "Tracks"
#   in the Display Control panel (left) to see the placement/routing grids.
# =============================================================================
source [file join [file dirname [info script]] _config.tcl]

puts "STEP 1> floorplan (utilization = $util%)"
initialize_floorplan -utilization $util -aspect_ratio 1 -core_space 6.0 -site unithd
make_tracks                                ;# routing grid the router will snap to

puts "STEP 1> die/core + tracks created (toggle 'Rows'/'Tracks' in Display Control)."
puts "STEP 1> next:  source 02_place_io_macro.tcl"
