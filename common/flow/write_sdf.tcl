# =============================================================================
# write_sdf.tcl  --  emit an SDF (Standard Delay Format) for the synthesized
# netlist, using OpenSTA (embedded in OpenROAD). At the SYNTHESIS stage there are
# no routing parasitics yet, so these are CELL-ARC delays from the liberty (with
# the SDC drive/load); post-route net delays are added at APR (HW5). Good enough
# to exercise a timing-annotated ($sdf_annotate) gate-level sim.
#
# Env: TECH_LEF SC_LEF MACRO_LEFS  LIB MACRO_LIBS  NETLIST TOP SDC  SDF_OUT
# =============================================================================
proc env_or {k d} { return [expr {[info exists ::env($k)] ? $::env($k) : $d}] }

# Standalone OpenSTA builds the timing graph from liberty alone. OpenROAD's
# link_design instead needs a technology (LEF), so read it only when running
# under OpenROAD (where the read_lef command exists).
if {[llength [info commands read_lef]] > 0} {
  read_lef $::env(TECH_LEF)
  read_lef $::env(SC_LEF)
  foreach m [env_or MACRO_LEFS ""] { if {$m ne ""} { read_lef $m } }
}
read_liberty $::env(LIB)
foreach m [env_or MACRO_LIBS ""] { if {$m ne ""} { read_liberty $m } }
read_verilog $::env(NETLIST)
link_design $::env(TOP)
read_sdc $::env(SDC)
# propagate the clock so cell-arc delays are reflected in the SDF
set_propagated_clock [all_clocks]
write_sdf -include_typ $::env(SDF_OUT)
puts ">> wrote SDF -> $::env(SDF_OUT)"
