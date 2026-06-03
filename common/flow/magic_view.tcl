# =============================================================================
# magic_view.tcl  --  open a routed DEF in Magic's GUI for inspection (conda
# back-end; OpenROAD's GUI is unavailable in the litex-hub build). Needs an X
# display (ssh -Y / VNC). Run as:  magic -T <sky130A.tech> magic_view.tcl
#
# Env: SC_LEF MACRO_LEF DEF TOP
# =============================================================================
proc env_or {k d} { return [expr {[info exists ::env($k)] ? $::env($k) : $d}] }
drc off
lef read $::env(SC_LEF)
if {[env_or MACRO_LEF ""] ne ""} { lef read $::env(MACRO_LEF) }
def read $::env(DEF)
load $::env(TOP)
select top cell
# leave the GUI open (no quit) -- close the window to exit.
puts ">> Loaded $::env(TOP) from $::env(DEF). Use the Magic window to inspect."
