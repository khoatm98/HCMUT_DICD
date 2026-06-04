# =============================================================================
# def2gds.tcl  --  Magic: stream a routed DEF to GDSII (conda APR back-end, no
# Docker). Run as:  magic -dnull -noconsole -T <sky130A.tech> def2gds.tcl
#
# Env: SC_LEF MACRO_LEF DEF TOP SC_GDS MACRO_GDS GDS_OUT
# =============================================================================
proc env_or {k d} { return [expr {[info exists ::env($k)] ? $::env($k) : $d}] }

drc off
gds readonly true
gds rescale false
# abstract views for placement, then the design itself
lef read $::env(SC_LEF)
if {[env_or MACRO_LEF ""] ne ""} { lef read $::env(MACRO_LEF) }
def read $::env(DEF)
# Upgrade the abstract (LEF-only) cells to their REAL layouts by reading the
# GDS libraries -- WITHOUT this the std cells (incl. fills) stay abstract and
# 'gds write' aborts with "Cell ... is an abstract view; cannot write GDS".
if {[env_or SC_GDS ""] ne "" && [file exists $::env(SC_GDS)]} {
    gds read $::env(SC_GDS)
}
# pull in the SRAM macro's real layout so it streams into the final GDS
if {[env_or MACRO_GDS ""] ne "" && [file exists $::env(MACRO_GDS)]} {
    gds read $::env(MACRO_GDS)
}
load $::env(TOP)
select top cell
gds write $::env(GDS_OUT)
puts ">> wrote GDS -> $::env(GDS_OUT)"
quit -noprompt
