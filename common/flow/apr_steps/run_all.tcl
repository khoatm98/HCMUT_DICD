# =============================================================================
# run_all.tcl  --  run the whole back-end by sourcing each step in order. This
# is the headless equivalent of the step-by-step GUI walkthrough, and what
# common/flow/apr_openroad.tcl (the Makefile entry point) uses. Edit the steps,
# not a second copy -- there is ONE source of truth.
# =============================================================================
set _steps_dir [file dirname [info script]]
foreach _s {00_load 01_floorplan 02_place_io_macro 03_pdn 04_place 05_cts 06_route 07_finish} {
  puts "=== apr_steps/$_s.tcl ==="
  source [file join $_steps_dir $_s.tcl]
}
