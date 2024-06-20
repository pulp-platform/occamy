# Copyright 2024 KU Leuven and ETH Zurich.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>
# Yunhao Deng <yunhao.deng@kuleuven.be>


# Four-wires UART with flow control
set_property PACKAGE_PIN BP26 [get_ports uart_rx_i_0]
set_property IOSTANDARD LVCMOS18 [get_ports uart_rx_i_0]
set_property PACKAGE_PIN BN26 [get_ports uart_tx_o_0]
set_property IOSTANDARD LVCMOS18 [get_ports uart_tx_o_0]
set_property PACKAGE_PIN BP22 [get_ports uart_cts_ni_0]
set_property IOSTANDARD LVCMOS18 [get_ports uart_cts_ni_0]
set_property PACKAGE_PIN BP23 [get_ports uart_rts_no_0]
set_property IOSTANDARD LVCMOS18 [get_ports uart_rts_no_0]

# Six-wires SPIx4
# FMCP_HSPC_LA12_P
set_property PACKAGE_PIN J22 [get_ports spim_sd_io[0]]
set_property IOSTANDARD LVCMOS18 [get_ports spim_sd_io[0]]
# FMCP_HSPC LA12_N
set_property PACKAGE_PIN H22 [get_ports spim_sd_io[1]]
set_property IOSTANDARD LVCMOS18 [get_ports spim_sd_io[1]]
# FMCP_HSPC LA16_P
set_property PACKAGE_PIN K24 [get_ports spim_sd_io[2]]
set_property IOSTANDARD LVCMOS18 [get_ports spim_sd_io[2]]
# FMCP_HSPC_LA16_N
set_property PACKAGE_PIN K23 [get_ports spim_sd_io[3]]
set_property IOSTANDARD LVCMOS18 [get_ports spim_sd_io[3]]
# FMCP_HSPC_LA20_P
set_property PACKAGE_PIN A21 [get_ports spim_csb_o[0]]
set_property IOSTANDARD LVCMOS18 [get_ports spim_csb_o[0]]
# FMCP_HSPC_LA20_N
set_property PACKAGE_PIN A20 [get_ports spim_csb_o[1]]
set_property IOSTANDARD LVCMOS18 [get_ports spim_csb_o[1]]
# FMCP_HSPC_LA22_P
set_property PACKAGE_PIN B16 [get_ports spim_sck_o]
set_property IOSTANDARD LVCMOS18 [get_ports spim_sck_o]

create_clock -period 10.000 -name spi_m_sck [get_ports spim_sck_o]

# Two-wires I2C
# FMCP_HSPC_LA13_P
set_property PACKAGE_PIN A25 [get_ports i2c_sda_io]
set_property IOSTANDARD LVCMOS18 [get_ports i2c_sda_io]
# FMCP_HSPC_LA13_N
set_property PACKAGE_PIN A24 [get_ports i2c_scl_io]
set_property IOSTANDARD LVCMOS18 [get_ports i2c_scl_io]

# Eight-wires GPIO_O connected to LEDs
set_property PACKAGE_PIN BH24 [get_ports gpio_d_o[0]]
set_property IOSTANDARD LVCMOS18 [get_ports gpio_d_o[0]]
set_property PACKAGE_PIN BG24 [get_ports gpio_d_o[1]]
set_property IOSTANDARD LVCMOS18 [get_ports gpio_d_o[1]]
set_property PACKAGE_PIN BG25 [get_ports gpio_d_o[2]]
set_property IOSTANDARD LVCMOS18 [get_ports gpio_d_o[2]]
set_property PACKAGE_PIN BF25 [get_ports gpio_d_o[3]]
set_property IOSTANDARD LVCMOS18 [get_ports gpio_d_o[3]]
set_property PACKAGE_PIN BF26 [get_ports gpio_d_o[4]]
set_property IOSTANDARD LVCMOS18 [get_ports gpio_d_o[4]]
set_property PACKAGE_PIN BF27 [get_ports gpio_d_o[5]]
set_property IOSTANDARD LVCMOS18 [get_ports gpio_d_o[5]]
set_property PACKAGE_PIN BG27 [get_ports gpio_d_o[6]]
set_property IOSTANDARD LVCMOS18 [get_ports gpio_d_o[6]]
set_property PACKAGE_PIN BG28 [get_ports gpio_d_o[7]]
set_property IOSTANDARD LVCMOS18 [get_ports gpio_d_o[7]]


# CPU_RESET pushbutton switch
set_false_path -from [get_ports reset] -to [all_registers]
set_property PACKAGE_PIN BM29 [get_ports reset]
set_property IOSTANDARD LVCMOS12 [get_ports reset]

# Set RTC as false path
set_false_path -to [get_pins occamy_vcu128_i/occamy/inst/i_occamy/i_clint/i_sync_edge/i_sync/reg_q_reg[0]/D]

################################################################################
# JTAG
################################################################################

# CDC 2phase clearable of DM: i_cdc_resp/i_cdc_req
# CONSTRAINT: Requires max_delay of min_period(src_clk_i, dst_clk_i) through the paths async_req, async_ack, async_data.
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_resp/async_req*"}] 10.000
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_resp/async_ack*"}] 10.000
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_resp/async_data*"}] 10.000
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_req/async_req*"}] 10.000
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_req/async_ack*"}] 10.000
set_max_delay -through [get_nets -hier -filter {NAME =~ "*i_cdc_req/async_data*"}] 10.000

################################################################################
# TIMING GROUPS
################################################################################

# Create timing groups through the FPU to help meet timing

# ingress and egress same for all pipe configs
group_path -default -through [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_sdotp_multi || REF_NAME == fpnew_sdotp_multi}] -filter { DIRECTION == "IN" && NAME !~ *out_ready_i && NAME !~ *rst_ni && NAME !~ *clk_i}]
group_path -name {sdotp_ingress} -through [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_sdotp_multi || REF_NAME == fpnew_sdotp_multi}] -filter { DIRECTION == "IN" && NAME !~ *out_ready_i && NAME !~ *rst_ni && NAME !~ *clk_i}]
group_path -default -through [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_fma_multi || REF_NAME == fpnew_fma_multi}] -filter { DIRECTION == "IN" && NAME !~ *out_ready_i && NAME !~ *rst_ni && NAME !~ *clk_i}]
group_path -name {fma_ingress} -through [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_fma_multi || REF_NAME == fpnew_fma_multi}] -filter { DIRECTION == "IN" && NAME !~ *out_ready_i && NAME !~ *rst_ni && NAME !~ *clk_i}]
group_path -default -through [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_sdotp_multi || REF_NAME == fpnew_sdotp_multi}] -filter { DIRECTION == "OUT" && NAME !~ *in_ready_o}]
group_path -name {sdotp_egress} -through [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_sdotp_multi || REF_NAME == fpnew_sdotp_multi}] -filter { DIRECTION == "OUT" && NAME !~ *in_ready_o}]
group_path -default -through [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_fma_multi || REF_NAME == fpnew_fma_multi}] -filter { DIRECTION == "OUT" && NAME !~ *in_ready_o}]
group_path -name {fma_egress} -through [get_pins -of [get_cells -hierarchical -filter {ORIG_REF_NAME == fpnew_fma_multi || REF_NAME == fpnew_fma_multi}] -filter { DIRECTION == "OUT" && NAME !~ *in_ready_o}]

# For 2 DISTRIBUTED pipe registers, registers are placed on input and mid
# The inside path therefore goes through the registers created in `gen_inside_pipeline[0]`

# The inside path groups
group_path -default -through [get_pins -filter {NAME =~ "*/D"} -of [get_cells -hier -filter { NAME =~  "*gen_inside_pipeline[0]*" && PARENT =~  "*fpnew_sdotp_multi*" }]]
group_path -name {sdotp_fu0} -through [get_pins -filter {NAME =~ "*/D"} -of [get_cells -hier -filter { NAME =~  "*gen_inside_pipeline[0]*" && PARENT =~  "*fpnew_sdotp_multi*" }]]
group_path -default -through [get_pins -filter {NAME =~ "*/D"} -of [get_cells -hier -filter { NAME =~  "*gen_inside_pipeline[0]*" && PARENT =~  "*fpnew_fma_multi*" }]]
group_path -name {fma_fu0} -through [get_pins -filter {NAME =~ "*/D"} -of [get_cells -hier -filter { NAME =~  "*gen_inside_pipeline[0]*" && PARENT =~  "*fpnew_fma_multi*" }]]

################################################################################
# BIT_STREAM
################################################################################
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR Yes [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE Yes [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 127.5 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]


