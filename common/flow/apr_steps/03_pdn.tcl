# =============================================================================
# STEP 3 -- TAP CELLS + POWER DELIVERY NETWORK (PDN)
# -----------------------------------------------------------------------------
# WHAT THIS DOES
#   Inserts well-tie/tap cells across the rows, then builds the on-chip power grid
#   that feeds VPWR/VGND to every cell, and connects the grid to the cell pins.
#
# WHY IT MATTERS -- every gate needs clean power, everywhere
#   * TAP CELLS tie the substrate/wells to VGND/VPWR at a regular pitch. Without
#     enough taps a CMOS chip can LATCH UP (a parasitic short that destroys it).
#     The endcap cells cap the ends of each row.
#   * The PDN is a mesh, built bottom-up:
#       - met1 "follow-pin" RAILS run along each row, over the cells' power pins
#         (thin, local);
#       - met4/met5 STRAPS run across the whole die (thick, low-resistance) and
#         carry current from the edge ring deep into the core;
#       - vias staple the layers together (add_pdn_connect).
#     A weak grid -> IR DROP (the local supply voltage sags), which slows gates and
#     can cause functional failures. Thick upper-metal straps keep resistance low.
#   add_global_connection maps each cell's VPWR/VGND pins (and the SRAM's vccd1/
#   vssd1) onto the global power/ground nets so the grid actually reaches them.
#   pdngen realizes the grid you described.
#
# IN THE GUI
#   Toggle met4/met5 in Display Control to see the straps: the two layers run in
#   ORTHOGONAL directions (one horizontal, one vertical) and the vias at their
#   crossings knit them into a mesh. Toggle met1 for the per-row rails on the cells.
# =============================================================================
source [file join [file dirname [info script]] _config.tcl]

puts "STEP 3> tap cells (well ties)"
tapcell -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1 -distance 13 \
        -endcap_master sky130_fd_sc_hd__decap_3

puts "STEP 3> power delivery network"
# connect every cell's VPWR/VGND pins to the global power/ground nets
add_global_connection -net VPWR -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net VGND -inst_pattern {.*} -pin_pattern {^VGND$} -ground
# the OpenRAM SRAM macro uses vccd1/vssd1 names -- tie those in too
foreach inst $macro_insts {
  if {$inst ne ""} {
    add_global_connection -net VPWR -inst_pattern $inst -pin_pattern {^vccd1$} -power
    add_global_connection -net VGND -inst_pattern $inst -pin_pattern {^vssd1$} -ground
  }
}
set_voltage_domain -name CORE -power VPWR -ground VGND
define_pdn_grid -name stdcell_grid -voltage_domains CORE
add_pdn_stripe  -grid stdcell_grid -layer met1 -width 0.48 -followpins        ;# per-row rails
add_pdn_stripe  -grid stdcell_grid -layer met4 -width 1.60 -pitch 27.14 -offset 13.57  ;# straps
add_pdn_stripe  -grid stdcell_grid -layer met5 -width 1.60 -pitch 27.14 -offset 13.57  ;# straps
add_pdn_connect -grid stdcell_grid -layers {met1 met4}                        ;# staple layers
add_pdn_connect -grid stdcell_grid -layers {met4 met5}
pdngen

puts "STEP 3> PDN built (toggle the met4/met5 layers in Display Control to see straps)."
puts "STEP 3> next:  source 04_place.tcl"
