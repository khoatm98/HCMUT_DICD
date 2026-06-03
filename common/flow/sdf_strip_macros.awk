# sdf_strip_macros.awk -- drop CELL blocks whose CELLTYPE matches `pat` (default
# "sram") from an SDF. A hard macro (e.g. the OpenRAM SRAM) is a BEHAVIORAL model
# in gate sim -- it has no structural clk0->dout0[n] paths -- so iverilog can't
# annotate its SDF IOPATHs and aborts the whole parse. Removing the macro's CELL
# block leaves a clean std-cell-only SDF; the macro keeps its behavioral timing.
#
#   awk -f sdf_strip_macros.awk [-v pat=sram] conv.sdf > conv.sim.sdf
function nopen(s,  t){ t=s; return gsub(/\(/,"",t) }
function nclose(s,  t){ t=s; return gsub(/\)/,"",t) }
BEGIN { if (pat == "") pat = "sram"; incell = 0; depth = 0; buf = ""; drop = 0 }
{
  if (incell == 0 && $0 ~ /\(CELL([[:space:]]|$)/) { incell = 1; depth = 0; buf = ""; drop = 0 }
  if (incell) {
    buf = buf $0 ORS
    if ($0 ~ ("CELLTYPE.*" pat)) drop = 1
    depth += nopen($0) - nclose($0)
    if (depth <= 0) { if (!drop) printf "%s", buf; incell = 0 }
    next
  }
  print
}
