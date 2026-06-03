#!/usr/bin/env bash
# =============================================================================
# healthcheck.sh -- print the version of every tool the course uses.
# Run INSIDE the EDA container:  make healthcheck
# =============================================================================
set -u

ver() {   # ver <label> <cmd> <version-flag>
    printf "  %-12s " "$1"
    if command -v "$2" >/dev/null 2>&1; then
        "$2" $3 2>&1 | head -1
    else
        echo "NOT FOUND"
    fi
}
present() {  # present <label> <cmd>  (for interactive tools we must not launch)
    printf "  %-12s " "$1"
    if command -v "$2" >/dev/null 2>&1; then
        echo "present ($(command -v "$2"))"
    else
        echo "NOT FOUND"
    fi
}

echo "==================== HCMUT_DICD tool healthcheck ===================="
echo "Front-end (simulation / waveforms):"
ver     "iverilog"  iverilog  "-V"
ver     "verilator" verilator "--version"
present "gtkwave"   gtkwave
echo "Synthesis / timing:"
ver     "yosys"     yosys     "--version"
present "abc"       abc
ver     "opensta"   sta       "-version"
echo "Physical (APR / layout / signoff):"
ver     "openroad"  openroad  "-version"
present "klayout"   klayout
present "magic"     magic
present "netgen"    netgen
if command -v librelane >/dev/null 2>&1; then ver "librelane" librelane "--version"
else present "openlane" openlane; fi

echo "PDK:"
echo "  PDK_ROOT   = ${PDK_ROOT:-<unset>}"
echo "  PDK        = ${PDK:-<unset>}"
LIB="${PDK_ROOT:-/foss/pdks}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
if [ -f "$LIB" ]; then echo "  sky130 lib = FOUND"; else echo "  sky130 lib = NOT FOUND ($LIB)"; fi
echo "===================================================================="
