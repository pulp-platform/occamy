// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

// AUTOMATICALLY GENERATED by genoccamy.py; edit the script instead.

module ${name}_cva6 import ${name}_pkg::*; (
  input  logic              clk_i,
  input  logic              rst_ni,
  input  logic [1:0]        irq_i,
  input  logic              ipi_i,
  input  logic              time_irq_i,
  input  logic              debug_req_i,
  output ${soc_narrow_xbar.in_cva6.req_type()} axi_req_o,
  input  ${soc_narrow_xbar.in_cva6.rsp_type()} axi_resp_i,
  input  sram_cfg_cva6_t    sram_cfg_i
);

  <% cva6 = soc_narrow_xbar.in_cva6.copy(name="cva6_axi").declare(context).cut(context) %>

  assign axi_req_o = cva6_axi_cut_req;
  assign cva6_axi_cut_rsp = axi_resp_i;

  // TODO(zarubaf): Derive from system parameters
  localparam ariane_pkg::ariane_cfg_t CVA6OccamyConfig = '{
    RASDepth: 2,
    BTBEntries: 32,
    BHTEntries: 128,
    // DRAM -- SPM, SPM -- Boot ROM, Boot ROM -- Debug Module
    NrNonIdempotentRules: 3,
    NonIdempotentAddrBase: {64'd${cfg["spm_narrow"]["address"]+cfg["spm_narrow"]["length"]}           , 64'd${cfg["peripherals"]["rom"]["address"]+cfg["peripherals"]["rom"]["length"]}                      , 64'h1000},
    NonIdempotentLength:   {64'd${0x80000000-cfg["spm_narrow"]["address"]-cfg["spm_narrow"]["length"]}, 64'd${cfg["spm_narrow"]["address"]-cfg["peripherals"]["rom"]["address"]-cfg["peripherals"]["rom"]["length"]}, 64'd${cfg["peripherals"]["rom"]["address"]-0x1000}},
    NrExecuteRegionRules: 5,
    // DRAM, Boot ROM, SPM, Debug Module
    ExecuteRegionAddrBase: {64'h10_0000_0000, 64'h8000_0000, 64'd${cfg["peripherals"]["rom"]["address"]}, 64'd${cfg["spm_narrow"]["address"]}, 64'h0   },
    ExecuteRegionLength:   {64'h2_0000_0000 , 64'h8000_0000, 64'd${cfg["peripherals"]["rom"]["length"]} , 64'd${cfg["spm_narrow"]["length"]} , 64'h1000},
    // cached region
    NrCachedRegionRules:    2,
    CachedRegionAddrBase:  {64'h8000_0000, 64'd${cfg["spm_narrow"]["address"]}},
    CachedRegionLength:    {(64'hff_ffff_ffff-64'h8000_0000), 64'd${cfg["spm_narrow"]["length"]}},
    //  cache config
    AxiCompliant:           1'b1,
    SwapEndianess:          1'b0,
    // debug
    DmBaseAddress:          64'h0,
    NrPMPEntries:           8
  };

  logic [1:0]        irq;
  logic              ipi;
  logic              time_irq;
  logic              debug_req;

  sync #(.STAGES (2))
    i_sync_debug (.clk_i, .rst_ni, .serial_i (debug_req_i), .serial_o (debug_req));
  sync #(.STAGES (2))
    i_sync_ipi  (.clk_i, .rst_ni, .serial_i (ipi_i), .serial_o (ipi));
  sync #(.STAGES (2))
    i_sync_time_irq  (.clk_i, .rst_ni, .serial_i (time_irq_i), .serial_o (time_irq));
  sync #(.STAGES (2))
    i_sync_irq_0  (.clk_i, .rst_ni, .serial_i (irq_i[0]), .serial_o (irq[0]));
  sync #(.STAGES (2))
    i_sync_irq_1  (.clk_i, .rst_ni, .serial_i (irq_i[1]), .serial_o (irq[1]));

  localparam logic [63:0] BootAddr = 'd${cfg["peripherals"]["rom"]["address"]};


  ariane #(
    .ArianeCfg (CVA6OccamyConfig),
    .AxiAddrWidth (${soc_narrow_xbar.in_cva6.aw}),
    .AxiDataWidth (${soc_narrow_xbar.in_cva6.dw}),
    .AxiIdWidth (${soc_narrow_xbar.in_cva6.iw}),
    .AxiUserWidth (${cfg["narrow_xbar_user_width"]}),
    .axi_ar_chan_t(${soc_narrow_xbar.in_cva6.ar_chan_type()}),
    .axi_aw_chan_t(${soc_narrow_xbar.in_cva6.aw_chan_type()}),
    .axi_w_chan_t(${soc_narrow_xbar.in_cva6.w_chan_type()}),
    .axi_req_t (${soc_narrow_xbar.in_cva6.req_type()}),
    .axi_rsp_t (${soc_narrow_xbar.in_cva6.rsp_type()}),
    .sram_cfg_t (sram_cfg_t)
  ) i_cva6 (
    .clk_i,
    .rst_ni,
    .boot_addr_i (BootAddr),
    .hart_id_i (64'h0),
    .irq_i (irq),
    .ipi_i (ipi),
    .time_irq_i (time_irq),
    .debug_req_i (debug_req),
    .axi_req_o (cva6_axi_req),
    .axi_resp_i (cva6_axi_rsp),
    .sram_cfg_idata_i (sram_cfg_i.icache_data),
    .sram_cfg_itag_i (sram_cfg_i.icache_tag),
    .sram_cfg_ddata_i (sram_cfg_i.dcache_data),
    .sram_cfg_dtag_i (sram_cfg_i.dcache_tag),
    .sram_cfg_dvalid_dirty_i (sram_cfg_i.dcache_valid_dirty)
  );

endmodule
