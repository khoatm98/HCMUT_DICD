# =============================================================================
# synth_sky130.tcl  --  reusable Yosys synthesis to SKY130 standard cells.
#
# Run with:  yosys -c common/flow/synth_sky130.tcl
# (the "-c" flag puts Yosys in Tcl mode; "yosys -import" exposes Yosys commands
#  as Tcl commands so we can read environment variables for parameters.)
#
# Environment variables (set by the calling Makefile):
#   TOP          - top module name                       (required)
#   RTL_FILES    - space-separated list of .v/.sv files   (required)
#   LIB          - path to the SKY130 liberty (.lib) file (required)
#   NETLIST_OUT  - path to write the gate-level netlist   (required)
#   INCDIRS      - optional space-separated `include search dirs
#   MACRO_LIBS   - optional space-separated hard-macro LIBERTY (.lib) files (e.g.
#                    an SRAM). This is the PROPER way to give a macro to synthesis:
#                    read with `read_liberty -lib` so the macro is a known blackbox
#                    (authoritative pin interface from the .lib) and its instance is
#                    preserved -- NOT its behavioral .v (that's a simulation model).
#   BLACKBOX_FILES - optional .v files read as INTERFACE-ONLY blackboxes, a fallback
#                    when a macro has no .lib (read with `read_verilog -lib`).
#   STAT_OUT     - optional path to write the area/cell report
# =============================================================================
yosys -import

set top       $::env(TOP)
set lib       $::env(LIB)
set rtl_files $::env(RTL_FILES)
set netlist   $::env(NETLIST_OUT)

# optional `include search directories
set incflags {}
if {[info exists ::env(INCDIRS)]} {
    foreach d $::env(INCDIRS) { lappend incflags -I$d }
}

# ---- hard macros as blackboxes (interface only) so they survive synthesis ----
# Preferred: the macro's LIBERTY (.lib) -- the authoritative hardware interface.
if {[info exists ::env(MACRO_LIBS)]} {
    foreach f $::env(MACRO_LIBS) { if {$f ne ""} { read_liberty -lib $f } }
}
# Fallback: a .v interface blackbox (only if a macro has no .lib).
if {[info exists ::env(BLACKBOX_FILES)]} {
    foreach f $::env(BLACKBOX_FILES) { if {$f ne ""} { read_verilog -lib {*}$incflags $f } }
}

# ---- read RTL ----
foreach f $rtl_files {
    read_verilog -sv {*}$incflags $f
}

# ---- elaborate + generic synthesis ----
hierarchy -check -top $top
synth -top $top -flatten

# ---- optional clock gating (HW4 power): insert integrated clock-gating cells ----
if {[info exists ::env(CLOCKGATE)] && $::env(CLOCKGATE) ne ""} {
    clockgate -liberty $lib
}

# ---- map to SKY130 standard cells ----
dfflibmap -liberty $lib
abc -liberty $lib

# ---- clean up ----
setundef -zero
# map constants to tie cells (sky130_fd_sc_hd__conb_1: HI=1, LO=0), AFTER setundef
# so the 0s it inserts are tied too. Without this, 1'b1/1'b0 leave bare `one_`/
# `zero_` nets that APR's router rejects ("signal type POWER is not routable").
hilomap -hicell sky130_fd_sc_hd__conb_1 HI -locell sky130_fd_sc_hd__conb_1 LO
splitnets
opt_clean -purge

# ---- write outputs ----
write_verilog -noattr $netlist

if {[info exists ::env(STAT_OUT)]} {
    tee -o $::env(STAT_OUT) stat -liberty $lib
} else {
    stat -liberty $lib
}
