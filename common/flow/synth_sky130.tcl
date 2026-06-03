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
splitnets
opt_clean -purge

# ---- write outputs ----
write_verilog -noattr $netlist

if {[info exists ::env(STAT_OUT)]} {
    tee -o $::env(STAT_OUT) stat -liberty $lib
} else {
    stat -liberty $lib
}
