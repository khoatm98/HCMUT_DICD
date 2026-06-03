# =============================================================================
# sta.tcl  --  reusable OpenSTA static timing (and optional power) analysis.
#
# Run with:  sta -no_init -exit common/flow/sta.tcl
#
# Environment variables (set by the calling Makefile):
#   LIB        - SKY130 liberty (.lib) file        (required)
#   MACRO_LIBS - optional space-separated extra liberties for hard macros
#                (e.g. the SRAM macro .lib) so the macro's timing is known
#   NETLIST    - gate-level netlist (.v)           (required)
#   TOP        - top module name                   (required)
#   SDC        - timing constraints (.sdc)         (required)
#   SAIF       - optional switching-activity SAIF  (for power, HW4)
#   VCD        - optional switching-activity VCD    (for power, HW4)
#   VCD_SCOPE  - hierarchical scope for SAIF/VCD (e.g. tb/dut)
# =============================================================================

read_liberty $env(LIB)
if {[info exists env(MACRO_LIBS)]} {
    foreach m $env(MACRO_LIBS) { read_liberty $m }
}
read_verilog $env(NETLIST)
link_design  $env(TOP)
read_sdc     $env(SDC)

# ---- optional activity annotation (used in HW4 power work) ----
if {[info exists env(SAIF)]} {
    read_saif -scope $env(VCD_SCOPE) $env(SAIF)
} elseif {[info exists env(VCD)]} {
    read_vcd -scope $env(VCD_SCOPE) $env(VCD)
}

puts "==================== SETUP TIMING ===================="
report_checks -path_delay max -fields {slew cap input_pin net} -digits 4

puts "==================== HOLD TIMING ====================="
report_checks -path_delay min -digits 4

puts "==================== SLACK SUMMARY ==================="
report_wns
report_tns

puts "==================== POWER ==========================="
report_power
