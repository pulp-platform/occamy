// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
//
// AUTOMATICALLY GENERATED by genoccamy.py; edit the script instead.

`include "common_cells/registers.svh"

module occamy_top
  import occamy_pkg::*;
(
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        test_mode_i,
  input  logic [1:0]  chip_id_i,
  input  logic [1:0]  boot_mode_i,
  // pad cfg
  output logic [31:0]      pad_slw_o,
  output logic [31:0]      pad_smt_o,
  output logic [31:0][1:0] pad_drv_o,
  // `uart` Interface
  output logic        uart_tx_o,
  input  logic        uart_rx_i,
  // `gpio` Interface
  input  logic [31:0] gpio_d_i,
  output logic [31:0] gpio_d_o,
  output logic [31:0] gpio_oe_o,
  output logic [31:0] gpio_puen_o,
  output logic [31:0] gpio_pden_o,
  // `serial` Interface
  input  logic        serial_clk_i,
  input  logic [3:0]  serial_data_i,
  output logic [3:0]  serial_data_o,
  // `jtag` Interface
  input  logic        jtag_trst_ni,
  input  logic        jtag_tck_i,
  input  logic        jtag_tms_i,
  input  logic        jtag_tdi_i,
  output logic        jtag_tdo_o,
  // `i2c` Interface
  output logic        i2c_sda_o,
  input  logic        i2c_sda_i,
  output logic        i2c_sda_en_o,
  output logic        i2c_scl_o,
  input  logic        i2c_scl_i,
  output logic        i2c_scl_en_o,

  /// PCIe Ports
  output  ${soc_wide_xbar.out_pcie.req_type()} pcie_axi_req_o,
  input   ${soc_wide_xbar.out_pcie.rsp_type()} pcie_axi_rsp_i,

  input  ${soc_wide_xbar.out_pcie.req_type()} pcie_axi_req_i,
  output ${soc_wide_xbar.out_pcie.rsp_type()} pcie_axi_rsp_o
  /// HBM2e Ports
  /// HBI Ports
);

  occamy_soc_reg_pkg::occamy_soc_reg2hw_t soc_ctrl_in;
  occamy_soc_reg_pkg::occamy_soc_hw2reg_t soc_ctrl_out;

  addr_t [${nr_s1_quadrants-1}:0] s1_quadrant_base_addr;
  % for i in range(nr_s1_quadrants):
  assign s1_quadrant_base_addr[${i}] = ClusterBaseOffset + ${i} * S1QuadrantAddressSpace;
  % endfor

  ///////////////////
  //   CROSSBARS   //
  ///////////////////
  ${module}

  /////////////////////////////
  // Narrow to Wide Crossbar //
  /////////////////////////////
  <% soc_narrow_xbar.out_soc_wide \
        .change_iw(context, 3, "soc_narrow_wide_iwc") \
        .change_dw(context, 512, "soc_narrow_wide_dw", to=soc_wide_xbar.in_soc_narrow)
  %>

  //////////
  // PCIe //
  //////////
  assign pcie_axi_req_o = ${soc_wide_xbar.out_pcie.req_name()};
  assign ${soc_wide_xbar.out_pcie.rsp_name()} = pcie_axi_rsp_i;
  assign ${soc_wide_xbar.in_pcie.req_name()} = pcie_axi_req_i;
  assign pcie_axi_rsp_o = ${soc_wide_xbar.in_pcie.rsp_name()};

  //////////
  // CVA6 //
  //////////
  localparam logic [63:0] BootAddr = 'h1000;
  <%
  cva6 = soc_narrow_xbar.in_cva6.copy(name="cva6_axi").declare(context)
  cva6.cut(context, to=soc_narrow_xbar.in_cva6)
  %>
  occamy_cva6 i_occamy_cva6 (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .boot_addr_i (BootAddr),
    .hart_id_i ('0),
    .irq_i ('0),
    .ipi_i ('0),
    .time_irq_i ('0),
    .debug_req_i ('0),
    .axi_req_o (${cva6.req_name()}),
    .axi_resp_i (${cva6.rsp_name()})
  );

  % for i in range(nr_s1_quadrants):
  ////////////////////
  // S1 Quadrants ${i} //
  ////////////////////
  <%
    cut_width = 1
    narrow_in = soc_narrow_xbar.__dict__["out_s1_quadrant_{}".format(i)].cut(context, cut_width, name="narrow_in_cut_{}".format(i))
    narrow_out = soc_narrow_xbar.__dict__["in_s1_quadrant_{}".format(i)].copy(name="narrow_out_cut_{}".format(i)).declare(context)
    narrow_out.cut(context, cut_width, to=soc_narrow_xbar.__dict__["in_s1_quadrant_{}".format(i)])
    wide_in = soc_wide_xbar.__dict__["out_s1_quadrant_{}".format(i)].cut(context, cut_width, name="wide_in_cut_{}".format(i))
    wide_out = soc_wide_xbar.__dict__["in_s1_quadrant_{}".format(i)].copy(name="wide_out_cut_{}".format(i)).declare(context)
    wide_out.cut(context, cut_width, to=soc_wide_xbar.__dict__["in_s1_quadrant_{}".format(i)])
  %>
  occamy_quadrant_s1 i_occamy_quadrant_s1_${i} (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .test_mode_i (test_mode_i),
    .tile_id_i (6'd${i}),
    .debug_req_i ('0),
    .meip_i ('0),
    .mtip_i ('0),
    .msip_i ('0),
    .quadrant_narrow_out_req_o (${narrow_out.req_name()}),
    .quadrant_narrow_out_rsp_i (${narrow_out.rsp_name()}),
    .quadrant_narrow_in_req_i (${narrow_in.req_name()}),
    .quadrant_narrow_in_rsp_o (${narrow_in.rsp_name()}),
    .quadrant_wide_out_req_o (${wide_out.req_name()}),
    .quadrant_wide_out_rsp_i (${wide_out.rsp_name()}),
    .quadrant_wide_in_req_i (${wide_in.req_name()}),
    .quadrant_wide_in_rsp_o (${wide_in.rsp_name()})
  );

  % endfor

  /////////////////
  // Peripherals //
  /////////////////
  <% soc_narrow_xbar.out_periph.to_axi_lite(context, "soc_narrow_periph", to=soc_periph_xbar.in_soc) %>

  /////////////////////
  //   SOC CONTROL   //
  /////////////////////
  <% regbus_soc_ctrl = soc_periph_xbar.out_soc_ctrl.to_reg(context, "regbus_soc_ctrl") %>

  occamy_soc_reg_top #(
    .reg_req_t ( ${regbus_soc_ctrl.req_type()} ),
    .reg_rsp_t ( ${regbus_soc_ctrl.rsp_type()} )
  ) i_soc_ctrl (
    .clk_i     ( clk_i  ),
    .rst_ni    ( rst_ni ),
    .reg_req_i ( ${regbus_soc_ctrl.req_name()} ),
    .reg_rsp_o ( ${regbus_soc_ctrl.rsp_name()} ),
    .reg2hw    ( soc_ctrl_in ),
    .hw2reg    ( soc_ctrl_out ),
    `ifdef SYNTHESIS
    .devmode_i ( 1'b0 )
    `else
    .devmode_i ( 1'b1 )
    `endif
  );

endmodule
