# =============================================================================
# apr_openroad.tcl  --  transparent RTL->routed-DB place-and-route for the course,
# driven by the conda/source OpenROAD (NO Docker, NO Nix, NO LibreLane). Reads
# the in-repo SKY130 PDK.
#
# This is a THIN driver: it just runs the numbered step scripts in
# common/flow/apr_steps/ in order. The SAME steps are what students 'source' one
# at a time in the GUI (see apr_steps/README.md), so the headless flow and the
# GUI walkthrough can never drift apart.
#
# Inputs via env (set by the 04_APR Makefile):
#   TECH_LEF SC_LEF        sky130_fd_sc_hd tech LEF + cell LEF
#   MACRO_LEFS MACRO_LIBS  space-separated macro LEF/lib (may be empty)
#   LIB                    std-cell typical liberty
#   NETLIST TOP SDC        synthesized netlist, top module, constraints
#   MACRO_INSTS            macro instance name(s) for placement + PDN (may be empty)
#   MACRO_LOC              macro lower-left corner "x y" um (default "40 40")
#   CORE_UTIL PLACE_DENSITY      floorplan/placement knobs (optional)
#   OUT_DEF OUT_NETLIST OUT_DB   outputs (GDS is streamed by magic afterwards)
# =============================================================================
source [file join [file dirname [info script]] apr_steps run_all.tcl]
