# =============================================================================
# gui_view_openroad.tcl  --  open a placed/routed design in the OpenROAD GUI
# (read-only inspection). Needs a Qt-enabled OpenROAD ('openroad -gui ...') and
# a display: 'ssh -Y' (X11) or '-platform vnc' on a headless box.
#
#   DB=build/conv.odb            openroad -gui common/flow/gui_view_openroad.tcl
#   TECH_LEF=.. SC_LEF=.. DEF=.. openroad -gui common/flow/gui_view_openroad.tcl
#
# To SAVE a layout image, run this in the GUI's Tcl console once the window is
# up (it must have painted first -- that's why this isn't done from the startup
# script):   save_image layout.png
# or use the menu  File -> Save Image.
#
# Env: one of
#   DB                       an OpenROAD .odb database (self-contained -> preferred)
#   TECH_LEF SC_LEF DEF      tech LEF + std-cell LEF + a routed DEF (+ MACRO_LEFS)
# Optional:
#   MACRO_LEFS               space-separated macro LEFs (only with the DEF path)
# =============================================================================
proc env_or {k d} { return [expr {[info exists ::env($k)] ? $::env($k) : $d}] }

if {[env_or DB ""] ne ""} {
  # An .odb restores the FULL state (cells, nets, routing) with no LEF needed.
  read_db $::env(DB)
} else {
  read_lef $::env(TECH_LEF)
  read_lef $::env(SC_LEF)
  foreach m [env_or MACRO_LEFS ""] { if {$m ne ""} { read_lef $m } }
  read_def $::env(DEF)
}

# Fit the view to the design; do NOT exit -- hand control to the GUI event loop
# so the window stays open. Close the window (or 'exit' in the console) to quit.
gui::fit
