# Copyright 2024 KU Leuven, ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Cyril Koenig <cykoenig@iis.ee.ethz.ch>

# This constraint file is written for VCU128 + FMC XM105 Debug Card and is included only when EXT_JTAG = 1

# 5 MHz max JTAG
create_clock -period 200 -name jtag_tck_i [get_pins occamy_vcu128_i/jtag_tck_i]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -of [get_pins jtag_tck_i_IBUF_inst/O]]
set_property CLOCK_BUFFER_TYPE NONE [get_nets -of [get_pins jtag_tck_i_IBUF_inst/O]]
set_input_jitter jtag_tck_i 1.000

# JTAG clock is asynchronous with every other clocks.
set_clock_groups -asynchronous -group [get_clocks jtag_tck_i]

# Minimize routing delay
set_input_delay  -clock jtag_tck_i -clock_fall 5 [get_ports jtag_tdi_i]
set_input_delay  -clock jtag_tck_i -clock_fall 5 [get_ports jtag_tms_i]
set_output_delay -clock jtag_tck_i             5 [get_ports jtag_tdo_o]

set_max_delay -to   [get_ports { jtag_tdo_o }] 20
set_max_delay -from [get_ports { jtag_tms_i }] 20
set_max_delay -from [get_ports { jtag_tdi_i }] 20

# C23 - C18 (FMCP_HSPC_LA14_P) - J1.02 - VDD
set_property PACKAGE_PIN C23     [get_ports jtag_vdd_o]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_vdd_o]
# B22 - C19 (FMCP_HSPC_LA14_N) - J1.04 - GND
set_property PACKAGE_PIN B22     [get_ports jtag_gnd_o]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_gnd_o]
# E19 - C22 (FMCP_HSPC_LA18_CC_P) - J1.06 - TCK
set_property PACKAGE_PIN E19     [get_ports jtag_tck_i]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_tck_i]
# E18 - C23 (FMCP_HSPC_LA19_CC_N) - J1.08 - TDO
set_property PACKAGE_PIN E18     [get_ports jtag_tdo_o]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_tdo_o]
# E21 - C26 (FMCP_HSPC_LA27_P) - J1.10 - TDI
set_property PACKAGE_PIN E21     [get_ports jtag_tdi_i]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_tdi_i]
# D21 - C27 (FMCP_HSPC_LA27_N) - J1.12 - TNS
set_property PACKAGE_PIN D21     [get_ports jtag_tms_i]
set_property IOSTANDARD LVCMOS18 [get_ports jtag_tms_i]
