# =============================================================================
# STEP 0 -- LOAD THE LIBRARIES + DESIGN
# -----------------------------------------------------------------------------
# WHAT THIS DOES
#   Reads the technology + cell libraries and the synthesized design into an
#   empty database. (Cadence Innovus does this with init_design + an MMMC setup
#   and an "Import Design" form; OpenROAD has no form -- these read_* commands
#   ARE the import, and the GUI then displays whatever is in the database.)
#
# WHY IT MATTERS -- two different "views" of every cell
#   * PHYSICAL view = LEF. An ABSTRACT: each cell's outline, pin shapes,
#     blockages, and the metal layers/vias -- enough to PLACE and ROUTE, but no
#     transistor detail. (The full polygons live in GDS, read only at the end.)
#   * TIMING view = Liberty (.lib). Characterized delay/power tables for one PVT
#     corner (here the typical corner, tt/25C/1.8V). The router places metal; the
#     .lib is how the tool knows whether the result is FAST ENOUGH.
#   The NETLIST (gate-level Verilog from synthesis) says which cells exist and how
#   they connect; link_design elaborates it against the libraries; the SDC carries
#   the clock definition + I/O timing the back-end must honor.
#
# IN THE GUI
#   Nothing is drawn yet -- there is no floorplan. The Inspector/Hierarchy panels
#   now know the design; geometry appears after STEP 1.
# =============================================================================
source [file join [file dirname [info script]] _config.tcl]

# Friendly guard: these must be set (the Makefile / `make gui-steps` does it).
foreach v {TECH_LEF SC_LEF LIB NETLIST TOP SDC} {
  if {![info exists ::env($v)]} {
    error "env var $v is not set -- launch via 'make gui-steps' (it sets all the\
           paths), or set TECH_LEF/SC_LEF/LIB/NETLIST/TOP/SDC (and MACRO_LEFS/\
           MACRO_LIBS/MACRO_INSTS) before sourcing the steps."
  }
}

puts "STEP 0> physical libraries (LEF)"
read_lef $::env(TECH_LEF)                                  ;# tech: routing layers, vias, site
read_lef $::env(SC_LEF)                                    ;# std-cell abstracts
foreach m $macro_lefs { if {$m ne ""} { read_lef $m } }    ;# hard-macro (SRAM) abstract

puts "STEP 0> timing libraries (.lib)"
read_liberty $::env(LIB)                                   ;# std cells, typical corner
foreach m $macro_libs { if {$m ne ""} { read_liberty $m } }

puts "STEP 0> netlist + constraints"
read_verilog $::env(NETLIST)
link_design  $::env(TOP)                                   ;# elaborate the top module
read_sdc     $::env(SDC)                                   ;# clock + I/O timing constraints

puts "STEP 0> loaded design '$::env(TOP)':\
        [llength [[ord::get_db_block] getInsts]] instances,\
        [llength [[ord::get_db_block] getNets]] nets (not placed yet)."
puts "STEP 0> next:  source 01_floorplan.tcl"
