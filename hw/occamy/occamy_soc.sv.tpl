// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
//
// AUTOMATICALLY GENERATED by genoccamy.py; edit the script instead.

<%
  cuts_narrow_to_quad = cfg["cuts"]["narrow_to_quad"]
  cuts_quad_to_narrow = cfg["cuts"]["quad_to_narrow"]
  cuts_quad_to_pre = cfg["cuts"]["quad_to_pre"]
  cuts_pre_to_inter = cfg["cuts"]["pre_to_inter"]
  cuts_inter_to_quad = cfg["cuts"]["inter_to_quad"]
  cuts_narrow_to_cva6 = cfg["cuts"]["narrow_to_cva6"]
  cuts_narrow_conv_to_spm_narrow_pre = cfg["cuts"]["narrow_conv_to_spm_narrow_pre"]
  cuts_narrow_conv_to_spm_narrow = cfg["cuts"]["narrow_conv_to_spm_narrow"]
  cuts_narrow_and_pcie = cfg["cuts"]["narrow_and_pcie"]
  cuts_narrow_and_wide = cfg["cuts"]["narrow_and_wide"]
  cuts_wide_conv_to_spm_wide = cfg["cuts"]["wide_conv_to_spm_wide"]
  cuts_wide_to_wide_zero_mem = cfg["cuts"]["wide_to_wide_zero_mem"]
  cuts_wide_to_hbm = cfg["cuts"]["wide_to_hbm"]
  cuts_wide_and_inter = cfg["cuts"]["wide_and_inter"]
  cuts_wide_and_hbi = cfg["cuts"]["wide_and_hbi"]
  cuts_narrow_and_hbi = cfg["cuts"]["narrow_and_hbi"]
  cuts_pre_to_hbmx = cfg["cuts"]["pre_to_hbmx"]
  cuts_hbmx_to_hbm = cfg["cuts"]["hbmx_to_hbm"]
  cuts_periph_axi_lite_narrow = cfg["cuts"]["periph_axi_lite_narrow"]
  cuts_periph_axi_lite = cfg["cuts"]["periph_axi_lite"]
  txns_wide_and_inter = cfg["txns"]["wide_and_inter"]
  txns_wide_to_hbm = cfg["txns"]["wide_to_hbm"]
  txns_narrow_and_wide = cfg["txns"]["narrow_and_wide"]
  cuts_withing_atomic_adapter_narrow = cfg["cuts"]["atomic_adapter_narrow"]
  cuts_withing_atomic_adapter_narrow_wide = cfg["cuts"]["atomic_adapter_narrow_wide"]
  max_atomics_narrow = 8
  max_atomics_wide = 8
  max_trans_atop_filter_per = 4
  max_trans_atop_filter_ser = 32
  hbi_trunc_addr_width = 40
%>

`include "common_cells/registers.svh"
`include "register_interface/typedef.svh"
`include "axi/assign.svh"
`include "idma/typedef.svh"

module ${name}_soc
  import ${name}_pkg::*;
(
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        test_mode_i,

  /// HBM2e Ports
% for i in range(nr_hbm_channels):
  output  ${hbm_xbar.__dict__["out_hbm_{}".format(i)].req_type()} hbm_${i}_req_o,
  input   ${hbm_xbar.__dict__["out_hbm_{}".format(i)].rsp_type()} hbm_${i}_rsp_i,
% endfor

  /// HBI Ports
  input   ${soc_wide_xbar.in_hbi.req_type()} hbi_wide_req_i,
  output  ${soc_wide_xbar.in_hbi.rsp_type()} hbi_wide_rsp_o,
  output  ${soc_wide_xbar.out_hbi.req_type()} hbi_wide_req_o,
  input   ${soc_wide_xbar.out_hbi.rsp_type()} hbi_wide_rsp_i,

  input   ${soc_narrow_xbar.in_hbi.req_type()} hbi_narrow_req_i,
  output  ${soc_narrow_xbar.in_hbi.rsp_type()} hbi_narrow_rsp_o,
  output  ${soc_narrow_xbar.out_hbi.req_type()} hbi_narrow_req_o,
  input   ${soc_narrow_xbar.out_hbi.rsp_type()} hbi_narrow_rsp_i,

  /// PCIe Ports
  output  ${soc_narrow_xbar.out_pcie.req_type()} pcie_axi_req_o,
  input   ${soc_narrow_xbar.out_pcie.rsp_type()} pcie_axi_rsp_i,

  input  ${soc_narrow_xbar.in_pcie.req_type()} pcie_axi_req_i,
  output ${soc_narrow_xbar.in_pcie.rsp_type()} pcie_axi_rsp_o,

% for i in range(nr_remote_quadrants):
  /// Remote Quadrant ${i} Ports: AXI master/slave and GPIO
  output   ${quadrant_inter_xbar.__dict__["out_rmq_{}".format(i)].req_type()} rmq_${i}_wide_req_o,
  input  ${quadrant_inter_xbar.__dict__["out_rmq_{}".format(i)].rsp_type()} rmq_${i}_wide_rsp_i,
  input   ${quadrant_inter_xbar.__dict__["in_rmq_{}".format(i)].req_type()} rmq_${i}_wide_req_i,
  output  ${quadrant_inter_xbar.__dict__["in_rmq_{}".format(i)].rsp_type()} rmq_${i}_wide_rsp_o,
  output   ${soc_narrow_xbar.__dict__["out_rmq_{}".format(i)].req_type()} rmq_${i}_narrow_req_o,
  input  ${soc_narrow_xbar.__dict__["out_rmq_{}".format(i)].rsp_type()} rmq_${i}_narrow_rsp_i,
  input   ${soc_narrow_xbar.__dict__["in_rmq_{}".format(i)].req_type()} rmq_${i}_narrow_req_i,
  output  ${soc_narrow_xbar.__dict__["in_rmq_{}".format(i)].rsp_type()} rmq_${i}_narrow_rsp_o,
  output rmq_${i}_mst_out_t rmq_${i}_mst_o,
% endfor

  // Peripheral Ports (to AXI-lite Xbar)
  output  ${soc_narrow_xbar.out_periph.req_type()} periph_axi_lite_req_o,
  input   ${soc_narrow_xbar.out_periph.rsp_type()} periph_axi_lite_rsp_i,

  input   ${soc_narrow_xbar.in_periph.req_type()} periph_axi_lite_req_i,
  output  ${soc_narrow_xbar.in_periph.rsp_type()} periph_axi_lite_rsp_o,

  // Peripheral Ports (to Regbus Xbar)
  output  ${soc_narrow_xbar.out_axi_lite_narrow_periph.req_type()} periph_axi_lite_narrow_req_o,
  input   ${soc_narrow_xbar.out_axi_lite_narrow_periph.rsp_type()} periph_axi_lite_narrow_rsp_i,

  // SoC control register IO
  output logic [1:0] spm_narrow_rerror_o,
  output logic [1:0] spm_wide_rerror_o,

  // Interrupts and debug requests
  input  logic [${cores-1}:0] mtip_i,
  input  logic [${cores-1}:0] msip_i,
  input  logic [1:0] eip_i,
  input  logic [0:0] debug_req_i,

  /// SRAM configuration
  input sram_cfgs_t sram_cfgs_i,

  /// HBM XBAR configuration
  input logic hbm_xbar_interleaved_mode_ena_i
);

  ///////////////////
  // HBM XBAR CTRL //
  ///////////////////
  logic       hbm_xbar_interleaved_mode_ena;
  assign hbm_xbar_interleaved_mode_ena  = hbm_xbar_interleaved_mode_ena_i;

  ///////////////
  // Crossbars //
  ///////////////

  addr_t [${nr_s1_quadrants-1}:0] s1_quadrant_base_addr, s1_quadrant_cfg_base_addr;
  % for i in range(nr_s1_quadrants):
  assign s1_quadrant_base_addr[${i}] = ClusterBaseOffset + ${i} * S1QuadrantAddressSpace;
  assign s1_quadrant_cfg_base_addr[${i}] = S1QuadrantCfgBaseOffset + ${i} * S1QuadrantCfgAddressSpace;
  % endfor

  // Crossbars
  ${module}

  ///////////////////////////////////
  // Connections between crossbars //
  ///////////////////////////////////
  <%
    #// inter xbar -> wide xbar & wide xbar -> inter xbar
    quadrant_inter_xbar.out_wide_xbar \
      .change_iw(context, soc_wide_xbar.iw, "inter_to_wide_iw_conv_{}".format(i), max_txns_per_id=txns_wide_and_inter) \
      .cut(context, cuts_wide_and_inter, name="inter_to_wide_cut_{}".format(i), to=soc_wide_xbar.in_quadrant_inter_xbar)
    soc_wide_xbar.out_quadrant_inter_xbar \
      .cut(context, cuts_wide_and_inter, name="wide_to_inter_cut_{}".format(i)) \
      .change_iw(context, quadrant_inter_xbar.iw, "wide_to_inter_iw_conv_{}".format(i), to=quadrant_inter_xbar.in_wide_xbar,  max_txns_per_id=txns_wide_and_inter)
    #// wide xbar -> hbm xbar
    soc_wide_xbar.out_hbm_xbar \
      .change_iw(context, hbm_xbar.iw, "wide_to_hbm_iw_conv_{}".format(i), max_txns_per_id=txns_wide_to_hbm) \
      .cut(context, cuts_wide_to_hbm, name="wide_to_hbm_iw_cut_{}".format(i), to=hbm_xbar.in_wide_xbar)
    #// narrow xbar -> wide xbar & wide xbar -> narrow xbar
    soc_narrow_xbar.out_soc_wide \
      .atomic_adapter(context, max_trans=max_atomics_wide, user_as_id=1, user_id_msb=soc_narrow_xbar.out_soc_wide.uw-1, user_id_lsb=0, n_cuts= cuts_withing_atomic_adapter_narrow_wide, name="soc_narrow_wide_amo_adapter") \
      .cut(context, cuts_narrow_and_wide) \
      .change_iw(context, soc_wide_xbar.in_soc_narrow.iw, "soc_narrow_wide_iwc", max_txns_per_id=txns_narrow_and_wide) \
      .change_uw(context, soc_wide_xbar.in_soc_narrow.uw, "soc_narrow_wide_uwc") \
      .change_dw(context, soc_wide_xbar.in_soc_narrow.dw, "soc_narrow_wide_dw", to=soc_wide_xbar.in_soc_narrow)
    soc_wide_xbar.out_soc_narrow \
      .change_iw(context, soc_narrow_xbar.in_soc_wide.iw, "soc_wide_narrow_iwc", max_txns_per_id=txns_narrow_and_wide) \
      .change_uw(context, soc_narrow_xbar.in_soc_wide.uw, "soc_wide_narrow_uwc") \
      .change_dw(context, soc_narrow_xbar.in_soc_wide.dw, "soc_wide_narrow_dw") \
      .cut(context, cuts_narrow_and_wide, to=soc_narrow_xbar.in_soc_wide)
  %>\

  //////////
  // PCIe //
  //////////
  <%
    pcie_out = soc_narrow_xbar.__dict__["out_pcie"] \
      .atomic_adapter(context, filter=True, max_trans=max_trans_atop_filter_ser, name="pcie_out_noatop", inst_name="i_pcie_out_atop_filter") \
      .cut(context, cuts_narrow_and_pcie, name="pcie_out", inst_name="i_pcie_out_cut")
    pcie_in = soc_narrow_xbar.__dict__["in_pcie"].copy(name="pcie_in").declare(context)
    pcie_in.cut(context, cuts_narrow_and_pcie, to=soc_narrow_xbar.__dict__["in_pcie"])
  %>\

  assign pcie_axi_req_o = ${pcie_out.req_name()};
  assign ${pcie_out.rsp_name()} = pcie_axi_rsp_i;
  assign ${pcie_in.req_name()} = pcie_axi_req_i;
  assign pcie_axi_rsp_o = ${pcie_in.rsp_name()};

  //////////
  // CVA6 //
  //////////
  <%
    cva6_mst = soc_narrow_xbar.__dict__["in_cva6"].copy(name="cva6_mst").declare(context)
    cva6_mst.cut(context, cuts_narrow_to_cva6, to=soc_narrow_xbar.__dict__["in_cva6"])
  %>\

  ${name}_cva6 i_${name}_cva6 (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .irq_i (eip_i),
    .ipi_i (msip_i[0]),
    .time_irq_i (mtip_i[0]),
    .debug_req_i (debug_req_i[0]),
    .axi_req_o (${cva6_mst.req_name()}),
    .axi_resp_i (${cva6_mst.rsp_name()}),
    .sram_cfg_i (sram_cfgs_i.cva6)
  );

  % for i in range(nr_s1_quadrants):
  //////////////////////
  // S1 Quadrant ${i} //
  //////////////////////
  <%
    #// Derived parameters
    nr_cores_s1_quadrant = nr_s1_clusters * nr_cluster_cores
    lower_core = i * nr_cores_s1_quadrant + 1
    #// narrow xbar -> quad & quad -> narrow xbar
    narrow_in = soc_narrow_xbar.__dict__["out_s1_quadrant_{}".format(i)].cut(context, cuts_narrow_to_quad, name="narrow_in_{}".format(i))
    narrow_out = soc_narrow_xbar.__dict__["in_s1_quadrant_{}".format(i)].copy(name="narrow_out_{}".format(i)).declare(context)
    narrow_out.cut(context, cuts_quad_to_narrow, name="narrow_out_cut_{}".format(i), to=soc_narrow_xbar.__dict__["in_s1_quadrant_{}".format(i)])
    #// inter xbar -> quad & quad -> pre xbar
    wide_in = quadrant_inter_xbar.__dict__["out_quadrant_{}".format(i)].cut(context, cuts_inter_to_quad, name="wide_in_{}".format(i))
    wide_out = quadrant_pre_xbars[i].in_quadrant.copy(name="wide_out_{}".format(i)).declare(context)
    wide_out.cut(context, cuts_quad_to_pre, name="wide_out_cut_{}".format(i), to=quadrant_pre_xbars[i].in_quadrant)
    #// pre xbar -> inter xbar
    quadrant_pre_xbars[i].out_quadrant_inter_xbar \
      .cut(context, cuts_pre_to_inter, name="pre_to_inter_cut_{}".format(i), to=quadrant_inter_xbar.__dict__["in_quadrant_{}".format(i)])
    #// pre xbar -> hbm xbar
    quadrant_pre_xbars[i].out_hbm_xbar \
      .cut(context, cuts_pre_to_hbmx, name="pre_to_hbm_cut_{}".format(i), to=hbm_xbar.__dict__["in_quadrant_{}".format(i)])
  %>\

  ${name}_quadrant_s1 i_${name}_quadrant_s1_${i} (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .test_mode_i (test_mode_i),
    .tile_id_i (6'd${i}),
    .meip_i ('0),
    .mtip_i (mtip_i[${lower_core + nr_cores_s1_quadrant - 1}:${lower_core}]),
    .msip_i (msip_i[${lower_core + nr_cores_s1_quadrant - 1}:${lower_core}]),
    .quadrant_narrow_out_req_o (${narrow_out.req_name()}),
    .quadrant_narrow_out_rsp_i (${narrow_out.rsp_name()}),
    .quadrant_narrow_in_req_i (${narrow_in.req_name()}),
    .quadrant_narrow_in_rsp_o (${narrow_in.rsp_name()}),
    .quadrant_wide_out_req_o (${wide_out.req_name()}),
    .quadrant_wide_out_rsp_i (${wide_out.rsp_name()}),
    .quadrant_wide_in_req_i (${wide_in.req_name()}),
    .quadrant_wide_in_rsp_o (${wide_in.rsp_name()}),
    .sram_cfg_i (sram_cfgs_i.quadrant)
  );

  % endfor

  ////////////////
  // SPM NARROW //
  ////////////////
  <% narrow_spm_mst = soc_narrow_xbar.out_spm_narrow \
                      .cut(context, cuts_narrow_conv_to_spm_narrow_pre) \
                      .atomic_adapter(context, max_trans=max_atomics_narrow, user_as_id=1, user_id_msb=soc_narrow_xbar.out_spm_narrow.uw-1, user_id_lsb=0, n_cuts= cuts_withing_atomic_adapter_narrow,name="spm_narrow_amo_adapter") \
                      .cut(context, cuts_narrow_conv_to_spm_narrow)
  %>\

  <% spm_narrow_words = cfg["spm_narrow"]["length"]//(soc_narrow_xbar.out_spm_narrow.dw//8) %>\

  typedef logic [${util.clog2(spm_narrow_words) + util.clog2(soc_narrow_xbar.out_spm_narrow.dw//8)-1}:0] mem_narrow_addr_t;
  typedef logic [${soc_narrow_xbar.out_spm_narrow.dw-1}:0] mem_narrow_data_t;
  typedef logic [${soc_narrow_xbar.out_spm_narrow.dw//8-1}:0] mem_narrow_strb_t;

  logic spm_narrow_req, spm_narrow_gnt, spm_narrow_we, spm_narrow_rvalid;
  mem_narrow_addr_t spm_narrow_addr;
  mem_narrow_data_t spm_narrow_wdata, spm_narrow_rdata;
  mem_narrow_strb_t spm_narrow_strb;

  axi_to_mem_interleaved #(
    .axi_req_t (${narrow_spm_mst.req_type()}),
    .axi_resp_t (${narrow_spm_mst.rsp_type()}),
    .AddrWidth (${util.clog2(spm_narrow_words) + util.clog2(narrow_spm_mst.dw//8)}),
    .DataWidth (${narrow_spm_mst.dw}),
    .IdWidth (${narrow_spm_mst.iw}),
    .NumBanks (1),
    .BufDepth (16)
  ) i_axi_to_wide_mem (
    .clk_i (${narrow_spm_mst.clk}),
    .rst_ni (${narrow_spm_mst.rst}),
    .busy_o (),
    .axi_req_i (${narrow_spm_mst.req_name()}),
    .axi_resp_o (${narrow_spm_mst.rsp_name()}),
    .mem_req_o (spm_narrow_req),
    .mem_gnt_i (spm_narrow_gnt),
    .mem_addr_o (spm_narrow_addr),
    .mem_wdata_o (spm_narrow_wdata),
    .mem_strb_o (spm_narrow_strb),
    .mem_atop_o (),
    .mem_we_o (spm_narrow_we),
    .mem_rvalid_i (spm_narrow_rvalid),
    .mem_rdata_i (spm_narrow_rdata)
  );

  spm_1p_adv #(
    .NumWords (${spm_narrow_words}),
    .DataWidth (${narrow_spm_mst.dw}),
    .ByteWidth (8),
    .EnableInputPipeline (1'b1),
    .EnableOutputPipeline (1'b1),
    .sram_cfg_t (sram_cfg_t)
  ) i_spm_narrow_cut (
    .clk_i (${narrow_spm_mst.clk}),
    .rst_ni (${narrow_spm_mst.rst}),
    .valid_i (spm_narrow_req),
    .ready_o (spm_narrow_gnt),
    .we_i (spm_narrow_we),
    .addr_i (spm_narrow_addr[${util.clog2(spm_narrow_words) + util.clog2(narrow_spm_mst.dw//8)-1}:${util.clog2(narrow_spm_mst.dw//8)}]),
    .wdata_i (spm_narrow_wdata),
    .be_i (spm_narrow_strb),
    .rdata_o (spm_narrow_rdata),
    .rvalid_o (spm_narrow_rvalid),
    .rerror_o (spm_narrow_rerror_o),
    .sram_cfg_i (sram_cfgs_i.spm_narrow)
  );

  //////////////
  // SPM WIDE //
  //////////////
  <% wide_spm_mst = soc_wide_xbar.out_spm_wide \
                    .cut(context, cuts_wide_conv_to_spm_wide)
  %>\

  <% spm_wide_words = cfg["spm_wide"]["length"]//(soc_wide_xbar.out_spm_wide.dw//8) %>\

  typedef logic [${util.clog2(spm_wide_words) + util.clog2(soc_wide_xbar.out_spm_wide.dw//8)-1}:0] mem_wide_addr_t;
  typedef logic [${soc_wide_xbar.out_spm_wide.dw-1}:0] mem_wide_data_t;
  typedef logic [${soc_wide_xbar.out_spm_wide.dw//8-1}:0] mem_wide_strb_t;

  logic spm_wide_req, spm_wide_gnt, spm_wide_we, spm_wide_rvalid;
  mem_wide_addr_t spm_wide_addr;
  mem_wide_data_t spm_wide_wdata, spm_wide_rdata;
  mem_wide_strb_t spm_wide_strb;

  axi_to_mem_interleaved #(
    .axi_req_t (${wide_spm_mst.req_type()}),
    .axi_resp_t (${wide_spm_mst.rsp_type()}),
    .AddrWidth (${util.clog2(spm_wide_words) + util.clog2(wide_spm_mst.dw//8)}),
    .DataWidth (${wide_spm_mst.dw}),
    .IdWidth (${wide_spm_mst.iw}),
    .NumBanks (1),
    .BufDepth (16)
  ) i_axi_to_mem (
    .clk_i (${wide_spm_mst.clk}),
    .rst_ni (${wide_spm_mst.rst}),
    .busy_o (),
    .axi_req_i (${wide_spm_mst.req_name()}),
    .axi_resp_o (${wide_spm_mst.rsp_name()}),
    .mem_req_o (spm_wide_req),
    .mem_gnt_i (spm_wide_gnt),
    .mem_addr_o (spm_wide_addr),
    .mem_wdata_o (spm_wide_wdata),
    .mem_strb_o (spm_wide_strb),
    .mem_atop_o (),
    .mem_we_o (spm_wide_we),
    .mem_rvalid_i (spm_wide_rvalid),
    .mem_rdata_i (spm_wide_rdata)
  );

  spm_1p_adv #(
    .NumWords (${spm_wide_words}),
    .DataWidth (${wide_spm_mst.dw}),
    .ByteWidth (8),
    .EnableInputPipeline (1'b1),
    .EnableOutputPipeline (1'b1),
    .sram_cfg_t (sram_cfg_t)
  ) i_spm_wide_cut (
    .clk_i (${wide_spm_mst.clk}),
    .rst_ni (${wide_spm_mst.rst}),
    .valid_i (spm_wide_req),
    .ready_o (spm_wide_gnt),
    .we_i (spm_wide_we),
    .addr_i (spm_wide_addr[${util.clog2(spm_wide_words) + util.clog2(wide_spm_mst.dw//8)-1}:${util.clog2(wide_spm_mst.dw//8)}]),
    .wdata_i (spm_wide_wdata),
    .be_i (spm_wide_strb),
    .rdata_o (spm_wide_rdata),
    .rvalid_o (spm_wide_rvalid),
    .rerror_o (spm_wide_rerror_o),
    .sram_cfg_i (sram_cfgs_i.spm_wide)
  );

  //////////////////////
  // WIDE ZERO MEMORY //
  //////////////////////
  <% wide_zero_mem_mst = soc_wide_xbar.out_wide_zero_mem \
                         .cut(context, cuts_wide_to_wide_zero_mem)
  %>\

  <% wide_zero_mem_words = cfg["wide_zero_mem"]["length"]//(soc_wide_xbar.out_wide_zero_mem.dw//8) %>\

  axi_zero_mem #(
    .axi_req_t (${wide_zero_mem_mst.req_type()}),
    .axi_resp_t (${wide_zero_mem_mst.rsp_type()}),
    .AddrWidth (${util.clog2(wide_zero_mem_words) + util.clog2(wide_zero_mem_mst.dw//8)}),
    .DataWidth (${wide_zero_mem_mst.dw}),
    .IdWidth (${wide_zero_mem_mst.iw}),
    .NumBanks (1),
    .BufDepth (4)
  ) i_axi_wide_zero_mem (
    .clk_i (${wide_zero_mem_mst.clk}),
    .rst_ni (${wide_zero_mem_mst.rst}),
    .busy_o (),
    .axi_req_i (${wide_zero_mem_mst.req_name()}),
    .axi_resp_o (${wide_zero_mem_mst.rsp_name()})
  );

  //////////////
  // SYS iDMA //
  //////////////

  <% out_sys_idma_cfg = soc_narrow_xbar.__dict__["out_sys_idma_cfg"] \
  .atomic_adapter(context, filter=True, max_trans=max_trans_atop_filter_per, name="out_sys_idma_cfg_noatop", inst_name="i_out_sys_idma_cfg_atop_filter") \
  .change_dw(context, 32, "out_sys_idma_cfg_dw") \
  %>\

  <% in_sys_idma_mst  = soc_wide_xbar.__dict__["in_sys_idma_mst"] %>\

  // local regbus definition
  `REG_BUS_TYPEDEF_ALL(idma_cfg_reg_a${wide_in.aw}_d32, logic [${wide_in.aw-1}:0], logic [31:0], logic [3:0])

  // iDMA types
  localparam int unsigned iDMAStrbWidth = ${wide_in.dw} / 32'd8;
  localparam int unsigned iDMAOffsetWidth = $clog2(iDMAStrbWidth);
  localparam type idma_addr_t = logic[${wide_in.aw-1}:0];
  localparam type idma_id_t = logic[${wide_in.iw-1}:0];
  localparam type idma_tf_len_t = logic[${wide_in.aw-1}:0];
  localparam type idma_tf_id_t = logic[31:0];

  // iDMA backend types
  `IDMA_TYPEDEF_OPTIONS_T(options_t, idma_id_t)
  `IDMA_TYPEDEF_REQ_T(idma_req_t, idma_tf_len_t, idma_addr_t, options_t)
  `IDMA_TYPEDEF_ERR_PAYLOAD_T(err_payload_t, idma_addr_t)
  `IDMA_TYPEDEF_RSP_T(idma_rsp_t, err_payload_t)

  // AXI meta channels
  typedef struct packed {
    ${wide_out.ar_chan_type()} ar_chan;
  } axi_read_meta_channel_t;

  typedef struct packed {
    axi_read_meta_channel_t axi;
  } read_meta_channel_t;

  typedef struct packed {
    ${wide_out.aw_chan_type()} aw_chan;
  } axi_write_meta_channel_t;

  typedef struct packed {
    axi_write_meta_channel_t axi;
  } write_meta_channel_t;

  // internal AXI channels
  ${in_sys_idma_mst.req_type()} idma_axi_read_req, idma_axi_write_req;
  ${in_sys_idma_mst.rsp_type()} idma_axi_read_rsp, idma_axi_write_rsp;

  // backend signals
  idma_req_t idma_req, idma_req_fe;
  logic idma_req_valid, idma_req_fe_valid;
  logic idma_req_ready, idma_req_fe_ready;

  // counter signals
  logic idma_issue_id;
  logic idma_retire_id;
  idma_tf_id_t idma_next_id;
  idma_tf_id_t idma_completed_id;

  // busy signals
  idma_pkg::idma_busy_t idma_busy;

  // Regbus instance
  idma_cfg_reg_a${wide_in.aw}_d32_req_t idma_cfg_reg_req;
  idma_cfg_reg_a${wide_in.aw}_d32_rsp_t idma_cfg_reg_rsp;

  axi_to_reg #(
    .ADDR_WIDTH( ${out_sys_idma_cfg.aw}                 ),
    .DATA_WIDTH( ${out_sys_idma_cfg.dw}                 ),
    .ID_WIDTH  ( ${out_sys_idma_cfg.iw}                 ),
    .USER_WIDTH( ${out_sys_idma_cfg.uw}                 ),
    .axi_req_t ( ${out_sys_idma_cfg.req_type()}         ),
    .axi_rsp_t ( ${out_sys_idma_cfg.rsp_type()}         ),
    .reg_req_t ( idma_cfg_reg_a${wide_in.aw}_d32_req_t  ),
    .reg_rsp_t ( idma_cfg_reg_a${wide_in.aw}_d32_rsp_t  )
  ) i_axi_to_reg_sys_idma_cfg (
    .clk_i,
    .rst_ni,
    .testmode_i ( 1'b0                           ),
    .axi_req_i  ( ${out_sys_idma_cfg.req_name()} ),
    .axi_rsp_o  ( ${out_sys_idma_cfg.rsp_name()} ),
    .reg_req_o  ( idma_cfg_reg_req               ),
    .reg_rsp_i  ( idma_cfg_reg_rsp               )
  );

  idma_reg64_1d # (
    .NumRegs        ( 32'd1 ),
    .NumStreams     ( 32'd1 ),
    .IdCounterWidth ( 32'd32 ),
    .reg_req_t      ( idma_cfg_reg_a${wide_in.aw}_d32_req_t ),
    .reg_rsp_t      ( idma_cfg_reg_a${wide_in.aw}_d32_rsp_t ),
    .dma_req_t      ( idma_req_t )
  ) i_idma_reg64_1d (
    .clk_i,
    .rst_ni,
    .dma_ctrl_req_i ( idma_cfg_reg_req ),
    .dma_ctrl_rsp_o ( idma_cfg_reg_rsp ),
    .dma_req_o      ( idma_req_fe ),
    .req_valid_o    ( idma_req_fe_valid ),
    .req_ready_i    ( idma_req_fe_ready ),
    .next_id_i      ( idma_next_id ),
    .stream_idx_o   ( /* NOT CONNECTED */ ),
    .done_id_i      ( idma_completed_id ),
    .busy_i         ( idma_busy ),
    .midend_busy_i  ( 1'b0 )
  );

  stream_fifo_optimal_wrap #(
    .Depth     ( 32'd16 ),
    .type_t    ( idma_req_t ),
    .PrintInfo ( 1'b0 )
  ) i_stream_fifo_optimal_wrap (
    .clk_i,
    .rst_ni,
    .testmode_i ( test_mode_i ),
    .flush_i    ( 1'b0 ),
    .usage_o    ( /* NC */ ),
    .data_i     ( idma_req_fe ),
    .valid_i    ( idma_req_fe_valid ),
    .ready_o    ( idma_req_fe_ready ),
    .data_o     ( idma_req ),
    .valid_o    ( idma_req_valid ),
    .ready_i    ( idma_req_ready )
  );

  idma_backend_rw_axi #(
    .DataWidth            ( ${wide_out.dw} ),
    .AddrWidth            ( ${wide_out.aw} ),
    .UserWidth            ( ${wide_out.uw+1} ),
    .AxiIdWidth           ( ${wide_out.iw} ),
    .NumAxInFlight        ( 32'd64 ),
    .BufferDepth          ( 32'd3 ),
    .TFLenWidth           ( ${wide_in.aw-1} ),
    .MemSysDepth          ( 32'd16 ),
    .CombinedShifter      ( 1'b1 ),
    .RAWCouplingAvail     ( 1'b1 ),
    .MaskInvalidData      ( 1'b0 ),
    .HardwareLegalizer    ( 1'b1 ),
    .RejectZeroTransfers  ( 1'b1 ),
    .ErrorCap             ( idma_pkg::NO_ERROR_HANDLING ),
    .PrintFifoInfo        ( 1'b0 ),
    .idma_req_t           ( idma_req_t ),
    .idma_rsp_t           ( idma_rsp_t ),
    .idma_eh_req_t        ( idma_pkg::idma_eh_req_t ),
    .idma_busy_t          ( idma_pkg::idma_busy_t ),
    .axi_req_t            ( ${in_sys_idma_mst.req_type()} ),
    .axi_rsp_t            ( ${in_sys_idma_mst.rsp_type()} ),
    .read_meta_channel_t  ( read_meta_channel_t ),
    .write_meta_channel_t ( write_meta_channel_t )
  ) i_idma_backend_rw_axi (
    .clk_i,
    .rst_ni,
    .testmode_i      ( test_mode_i ),
    .idma_req_i      ( idma_req ),
    .req_valid_i     ( idma_req_valid ),
    .req_ready_o     ( idma_req_ready ),
    .idma_rsp_o      ( /* NC */ ),
    .rsp_valid_o     ( idma_retire_id ),
    .rsp_ready_i     ( 1'b1 ),
    .idma_eh_req_i   ( '0 ),
    .eh_req_valid_i  ( 1'b0 ),
    .eh_req_ready_o  ( /* NC */ ),
    .axi_read_req_o  ( idma_axi_read_req ),
    .axi_read_rsp_i  ( idma_axi_read_rsp ),
    .axi_write_req_o ( idma_axi_write_req ),
    .axi_write_rsp_i ( idma_axi_write_rsp ),
    .busy_o          ( idma_busy )
  );

  axi_rw_join #(
    .axi_req_t  ( ${in_sys_idma_mst.req_type()} ),
    .axi_resp_t ( ${in_sys_idma_mst.rsp_type()} )
  ) i_axi_rw_join (
    .clk_i,
    .rst_ni,
    .slv_read_req_i   ( idma_axi_read_req  ),
    .slv_read_resp_o  ( idma_axi_read_rsp  ),
    .slv_write_req_i  ( idma_axi_write_req ),
    .slv_write_resp_o ( idma_axi_write_rsp ),
    .mst_req_o        ( ${in_sys_idma_mst.req_name()} ),
    .mst_resp_i       ( ${in_sys_idma_mst.rsp_name()} )
  );

  idma_transfer_id_gen #(
    .IdWidth ( 32'd32 )
  ) i_idma_transfer_id_gen (
    .clk_i,
    .rst_ni,
    .issue_i     ( idma_issue_id ),
    .retire_i    ( idma_retire_id ),
    .next_o      ( idma_next_id ),
    .completed_o ( idma_completed_id )
  );

  // issue ids
  assign idma_issue_id = idma_req_valid & idma_req_ready;

  ///////////
  // HBM2e //
  ///////////
  % for i in range(nr_hbm_channels):
  <% hbm_out_soc = hbm_xbar.__dict__["out_hbm_{}".format(i)] \
      .cut(context, cuts_hbmx_to_hbm, name="hbm_out_soc_{}".format(i))
  %>\

  assign hbm_${i}_req_o = ${hbm_out_soc.req_name()};
  assign ${hbm_out_soc.rsp_name()} = hbm_${i}_rsp_i;

  % endfor

  /////////
  // HBI //
  /////////

  <%
    #// hbi <-> wide xbar
    hbi_in_wide_soc = soc_wide_xbar.in_hbi.copy(name="hbi_in_wide_soc").declare(context)
    hbi_in_wide_soc.cut(context, cuts_wide_and_hbi, name="hbi_to_wide_cut", to=soc_wide_xbar.in_hbi)
    hbi_out_wide_soc = soc_wide_xbar.out_hbi \
      .trunc_addr(context, hbi_trunc_addr_width, name="wide_to_hbi_trunc") \
      .atomic_adapter(context, filter=True, max_trans=max_trans_atop_filter_ser, name="wide_to_hbi_noatop", inst_name="i_wide_to_hbi_atop_filter") \
      .cut(context, cuts_wide_and_hbi, name="wide_to_hbi_cut")
    #// hbi <-> narrow xbar
    hbi_in_narrow_soc = soc_narrow_xbar.in_hbi.copy(name="hbi_in_narrow_soc").declare(context)
    hbi_in_narrow_soc.cut(context, cuts_narrow_and_hbi, name="hbi_to_narrow_cut", to=soc_narrow_xbar.in_hbi)
    hbi_out_narrow_soc = soc_narrow_xbar.out_hbi \
      .trunc_addr(context, hbi_trunc_addr_width, name="narrow_to_hbi_trunc") \
      .cut(context, cuts_narrow_and_hbi, name="narrow_to_hbi_cut")
  %>\

  assign hbi_wide_req_o = ${hbi_out_wide_soc.req_name()};
  assign ${hbi_out_wide_soc.rsp_name()} = hbi_wide_rsp_i;
  assign ${hbi_in_wide_soc.req_name()} = hbi_wide_req_i;
  assign hbi_wide_rsp_o = ${hbi_in_wide_soc.rsp_name()};

  assign hbi_narrow_req_o = ${hbi_out_narrow_soc.req_name()};
  assign ${hbi_out_narrow_soc.rsp_name()} = hbi_narrow_rsp_i;
  assign ${hbi_in_narrow_soc.req_name()} = hbi_narrow_req_i;
  assign hbi_narrow_rsp_o = ${hbi_in_narrow_soc.rsp_name()};

%if nr_remote_quadrants > 0:
  //////////////////////
  // Remote Quadrants //
  //////////////////////
%endif
% for i, rq in enumerate(remote_quadrants):
  /// Remote Quadrant ${i} Ports
  assign rmq_${i}_wide_req_o = ${quadrant_inter_xbar.__dict__["out_rmq_{}".format(i)].req_name()};
  assign ${quadrant_inter_xbar.__dict__["out_rmq_{}".format(i)].rsp_name()} = rmq_${i}_wide_rsp_i;
  assign rmq_${i}_narrow_req_o = ${soc_narrow_xbar.__dict__["out_rmq_{}".format(i)].req_name()};
  assign ${soc_narrow_xbar.__dict__["out_rmq_{}".format(i)].rsp_name()} = rmq_${i}_narrow_rsp_i;
  assign ${quadrant_inter_xbar.__dict__["in_rmq_{}".format(i)].req_name()} = rmq_${i}_wide_req_i;
  assign rmq_${i}_wide_rsp_o = ${quadrant_inter_xbar.__dict__["in_rmq_{}".format(i)].rsp_name()};
  assign ${soc_narrow_xbar.__dict__["in_rmq_{}".format(i)].req_name()} = rmq_${i}_narrow_req_i;
  assign rmq_${i}_narrow_rsp_o = ${soc_narrow_xbar.__dict__["in_rmq_{}".format(i)].rsp_name()};
  /// GPIO
  <% rm_cores = rq["nr_clusters"]*rq["nr_cluster_cores"] %>
  <% rm_core_off = lcl_cores + i*rm_cores %>
  assign rmq_${i}_mst_o.mtip = mtip_i[${rm_core_off+rm_cores-1}:${rm_core_off}];
  assign rmq_${i}_mst_o.msip = msip_i[${rm_core_off+rm_cores-1}:${rm_core_off}];
% endfor

  /////////////////
  // Peripherals //
  /////////////////
  <%
    periph_axi_lite_narrow_out = soc_narrow_xbar.__dict__["out_axi_lite_narrow_periph"] \
      .atomic_adapter(context, filter=True, max_trans=max_trans_atop_filter_per, name="periph_axi_lite_narrow_out_noatop", inst_name="i_periph_axi_lite_narrow_out_atop_filter") \
      .cut(context, cuts_periph_axi_lite_narrow, name="periph_axi_lite_narrow_out", inst_name="i_periph_axi_lite_narrow_out_cut")
    periph_axi_lite_out = soc_narrow_xbar.__dict__["out_periph"] \
      .atomic_adapter(context, filter=True, max_trans=max_trans_atop_filter_per, name="periph_axi_lite_out_noatop", inst_name="i_periph_axi_lite_out_atop_filter") \
      .cut(context, cuts_periph_axi_lite, name="periph_axi_lite_out", inst_name="i_periph_axi_lite_out_cut") \

    periph_axi_lite_in = soc_narrow_xbar.__dict__["in_periph"].copy(name="periph_axi_lite_in").declare(context)
    periph_axi_lite_in.cut(context, cuts_periph_axi_lite, to=soc_narrow_xbar.__dict__["in_periph"])
  %>\

  // Inputs
  assign ${periph_axi_lite_in.req_name()} = periph_axi_lite_req_i;
  assign periph_axi_lite_rsp_o = ${periph_axi_lite_in.rsp_name()};

  // Outputs
  assign periph_axi_lite_req_o = ${periph_axi_lite_out.req_name()};
  assign ${periph_axi_lite_out.rsp_name()} = periph_axi_lite_rsp_i;
  assign periph_axi_lite_narrow_req_o = ${periph_axi_lite_narrow_out.req_name()};
  assign ${periph_axi_lite_narrow_out.rsp_name()} = periph_axi_lite_narrow_rsp_i;

endmodule
