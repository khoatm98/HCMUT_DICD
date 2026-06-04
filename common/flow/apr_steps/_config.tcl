# =============================================================================
# _config.tcl  --  shared helpers + knobs for the step scripts. Each NN_*.tcl
# sources this at its top so every step is self-contained (safe to re-source).
# It only sets Tcl variables -- it never touches the design DB.
#
# All knobs come from environment variables (the Makefile / `make gui-*` set
# them, exactly like the headless flow); each has a sensible default.
# =============================================================================
proc env_or {k d} { return [expr {[info exists ::env($k)] ? $::env($k) : $d}] }

set util        [env_or CORE_UTIL 35]        ;# core utilization % for the floorplan
set density     [env_or PLACE_DENSITY 0.55]  ;# target placement density
set macro_lefs  [env_or MACRO_LEFS ""]       ;# space-separated macro LEF(s), may be empty
set macro_libs  [env_or MACRO_LIBS ""]       ;# space-separated macro .lib(s), may be empty
set macro_insts [env_or MACRO_INSTS ""]      ;# macro instance name(s), e.g. "u_img"
set macro_loc   [env_or MACRO_LOC "40 40"]   ;# lower-left corner (um) for the macro
