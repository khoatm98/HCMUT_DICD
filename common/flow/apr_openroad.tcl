# =============================================================================
# apr_openroad.tcl  --  transparent RTL->GDS place-and-route for the course,
# driven by the conda OpenROAD (NO Docker, NO Nix, NO LibreLane). Reads the
# in-repo SKY130 PDK. Each stage is explicit so students can read the flow.
#
# Inputs via env (set by apr_openroad.sh):
#   TECH_LEF SC_LEF        sky130_fd_sc_hd tech LEF + cell LEF
#   MACRO_LEFS MACRO_LIBS  space-separated macro LEF/lib (may be empty)
#   LIB                    std-cell typical liberty
#   NETLIST TOP SDC        synthesized netlist, top module, constraints
#   OUT_DEF OUT_NETLIST    outputs (GDS is streamed by magic afterwards)
#   CORE_UTIL PLACE_DENSITY CLOCK_PORT   (optional; sensible defaults below)
#   MACRO_INSTS            space-separated macro instance names (for PDN power), may be empty
# =============================================================================
proc env_or {k d} { return [expr {[info exists ::env($k)] ? $::env($k) : $d}] }

set util    [env_or CORE_UTIL 35]
set density [env_or PLACE_DENSITY 0.55]
set macro_lefs [env_or MACRO_LEFS ""]
set macro_libs [env_or MACRO_LIBS ""]
set macro_insts [env_or MACRO_INSTS ""]

# ---- 1. read the PDK + the synthesized design ----------------------------
read_lef $::env(TECH_LEF)
read_lef $::env(SC_LEF)
foreach m $macro_lefs { if {$m ne ""} { read_lef $m } }
read_liberty $::env(LIB)
foreach m $macro_libs { if {$m ne ""} { read_liberty $m } }
read_verilog $::env(NETLIST)
link_design $::env(TOP)
read_sdc $::env(SDC)

# ---- 2. floorplan + routing tracks ---------------------------------------
puts "APR> floorplan (util=$util%)"
initialize_floorplan -utilization $util -aspect_ratio 1 -core_space 6.0 -site unithd
make_tracks

# ---- 3. IO pins + (if macros) seed placement so the macro placer has one -
place_pins -hor_layers met3 -ver_layers met2
if {[llength $macro_insts] > 0} {
  puts "APR> macro placement: $macro_insts"
  global_placement -density $density                ;# initial positions
  macro_placement -halo {8 8} -channel {16 16}      ;# place + fix the hard macro(s)
}

# ---- 4. tapcells + power delivery network --------------------------------
puts "APR> tapcells"
tapcell -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1 -distance 13 \
        -endcap_master sky130_fd_sc_hd__decap_3
puts "APR> power delivery network"
add_global_connection -net VPWR -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net VGND -inst_pattern {.*} -pin_pattern {^VGND$} -ground
# macro power pins (OpenRAM sky130 macros use vccd1/vssd1)
foreach inst $macro_insts {
  if {$inst ne ""} {
    add_global_connection -net VPWR -inst_pattern $inst -pin_pattern {^vccd1$} -power
    add_global_connection -net VGND -inst_pattern $inst -pin_pattern {^vssd1$} -ground
  }
}
set_voltage_domain -name CORE -power VPWR -ground VGND
define_pdn_grid -name stdcell_grid -voltage_domains CORE
add_pdn_stripe  -grid stdcell_grid -layer met1 -width 0.48 -followpins
add_pdn_stripe  -grid stdcell_grid -layer met4 -width 1.60 -pitch 27.14 -offset 13.57
add_pdn_stripe  -grid stdcell_grid -layer met5 -width 1.60 -pitch 27.14 -offset 13.57
add_pdn_connect -grid stdcell_grid -layers {met1 met4}
add_pdn_connect -grid stdcell_grid -layers {met4 met5}
pdngen

# ---- 5. placement (std cells around the fixed macros) --------------------
puts "APR> global + detailed placement"
global_placement -density $density -pad_left 1 -pad_right 1
estimate_parasitics -placement
detailed_placement
check_placement

# ---- 6. clock tree synthesis ---------------------------------------------
puts "APR> clock tree synthesis"
clock_tree_synthesis -buf_list sky130_fd_sc_hd__clkbuf_4 \
                     -root_buf sky130_fd_sc_hd__clkbuf_4 -sink_clustering_enable
set_propagated_clock [all_clocks]
detailed_placement

# ---- 7. routing ----------------------------------------------------------
puts "APR> global + detailed routing"
set_routing_layers -signal met1-met5
global_route
detailed_route -output_drc [file rootname $::env(OUT_DEF)].drc.rpt -verbose 0

# ---- 8. fill + outputs ---------------------------------------------------
filler_placement {sky130_fd_sc_hd__fill_1 sky130_fd_sc_hd__fill_2 \
                  sky130_fd_sc_hd__fill_4 sky130_fd_sc_hd__fill_8}
write_def $::env(OUT_DEF)
write_verilog $::env(OUT_NETLIST)
puts "APR> wrote DEF -> $::env(OUT_DEF)"
report_wns
report_tns
