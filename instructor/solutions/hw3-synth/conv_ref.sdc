# =============================================================================
# conv_ref.sdc  --  REFERENCE timing constraints for the convolution engine.
#
# Instructor solution for the student-written constraints/conv.sdc (HW3). The
# engine is a sequential single-clock design; this is a realistic, complete
# constraint set that yields positive setup/hold slack on the SKY130 netlist.
#
# To check the reference engine + this SDC inside the container:
#   cd hw/hw3-synth
#   make synth
#   TOP=conv_engine LIB="$LIB" NETLIST=build/conv_netlist.v \
#     SDC=../../instructor/solutions/hw3-synth/conv_ref.sdc \
#     sta -no_init -exit ../../common/flow/sta.tcl
# =============================================================================

# ---- 1. clock ----
# 20 ns (50 MHz) is comfortable for one 16x16 signed multiply + a 40-bit add on
# sky130_fd_sc_hd at the tt corner. The clock named `core_clk` is created by the
# shared file below (with uncertainty 0.25 ns, transition 0.15 ns).
set CLK_PORT   clk
set CLK_PERIOD 20.0
source ../../common/constraints/common.sdc

# ---- 2. input delays ----
# Allow ~10% of the period for upstream logic on every data/control input.
set_input_delay 2.0 -clock core_clk [get_ports {rst_n i_valid}]
set_input_delay 2.0 -clock core_clk [get_ports {i_data[*]}]

# ---- 3. output delays ----
# Reserve ~10% of the period for downstream logic on every output.
set_output_delay 2.0 -clock core_clk [all_outputs]

# ---- 4. driving cell / load (realism) ----
# Model a medium-strength driver on the inputs and a small load on the outputs.
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y \
    [get_ports {rst_n i_valid i_data[*]}]
set_load 0.05 [all_outputs]
