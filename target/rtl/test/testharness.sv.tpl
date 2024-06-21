// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "axi/typedef.svh"

module testharness import occamy_pkg::*; (
  input  logic        clk_i,
  input  logic        rst_ni
);

  // verilog_lint: waive explicit-parameter-storage-type
  localparam RTCTCK = 30.518us; // 32.768 kHz

  logic rtc_i;

  // Generate reset and clock.
  initial begin
    forever begin
      rtc_i = 1;
      #(RTCTCK/2);
      rtc_i = 0;
      #(RTCTCK/2);
    end
  end

  logic clk_periph_i, rst_periph_ni;
  assign clk_periph_i = clk_i;
  assign rst_periph_ni = rst_ni;

<%def name="tb_memory(bus, name)">
  ${bus.req_type()} ${name}_req;
  ${bus.rsp_type()} ${name}_rsp;

  % if isinstance(bus, solder.AxiBus):
  tb_memory_axi #(
    .AxiAddrWidth (${bus.aw}),
    .AxiDataWidth (${bus.dw}),
    .AxiIdWidth (${bus.iw}),
    .AxiUserWidth (${bus.uw + 1}),
    .ATOPSupport (0),
  % else:
  tb_memory_regbus #(
    .AddrWidth (${bus.aw}),
    .DataWidth (${bus.dw}),
  % endif
    .req_t (${bus.req_type()}),
    .rsp_t (${bus.rsp_type()})
  ) i_${name}_channel (
    .clk_i,
    .rst_ni,
    .req_i (${name}_req),
    .rsp_o (${name}_rsp)
  );
</%def>

<%def name="tb_memory_no_def(bus, name)">
  % if isinstance(bus, solder.AxiBus):
  tb_memory_axi #(
    .AxiAddrWidth (${bus.aw}),
    .AxiDataWidth (${bus.dw}),
    .AxiIdWidth (${bus.iw}),
    .AxiUserWidth (${bus.uw + 1}),
    .ATOPSupport (0),
  % else:
  tb_memory_regbus #(
    .AddrWidth (${bus.aw}),
    .DataWidth (${bus.dw}),
  % endif
    .req_t (${bus.req_type()}),
    .rsp_t (${bus.rsp_type()})
  ) i_${name}_channel (
    .clk_i,
    .rst_ni,
    .req_i (${name}_req),
    .rsp_o (${name}_rsp)
  );
</%def>

  /// Uart signals
  logic tx, rx;

  /// SPM Wide Mem
  /// Simulated by fesvr
  ${tb_memory(soc_wide_xbar.out_spm_wide,"spm_wide")}

  /// Bootrom
  /// Simulated by fesvr
  axi_lite_a48_d32_req_t axi_lite_bootrom_req;
  axi_lite_a48_d32_rsp_t axi_lite_bootrom_rsp;

<% regbus_bootrom = soc_axi_lite_narrow_periph_xbar.out_bootrom.to_reg(context, "bootrom_regbus", fr="axi_lite_bootrom") %>

  ${tb_memory_no_def(regbus_bootrom, "bootrom_regbus")}

  occamy_top i_occamy (
    .clk_i,
    .rst_ni,
    .sram_cfgs_i ('0),
    .clk_periph_i,
    .rst_periph_ni,
    .rtc_i,
    .test_mode_i (1'b0),
    .chip_id_i ('0),
    .boot_mode_i ('0),
    .uart_tx_o (tx),
    .uart_cts_ni ('0),
    .uart_rts_no (),
    .uart_rx_i (rx),
    .gpio_d_i ('0),
    .gpio_d_o (),
    .gpio_oe_o (),
    .jtag_trst_ni ('0),
    .jtag_tck_i ('0),
    .jtag_tms_i ('0),
    .jtag_tdi_i ('0),
    .jtag_tdo_o (),
    .i2c_sda_io (),
    .i2c_scl_io (),
    .spim_sck_o (),
    .spim_csb_o (),
    .spim_sd_io (),
    .bootrom_req_o (axi_lite_bootrom_req),
    .bootrom_rsp_i (axi_lite_bootrom_rsp),
    .spm_axi_wide_req_o (spm_wide_req),
    .spm_axi_wide_rsp_i (spm_wide_rsp),
    .ext_irq_i ('0)
    );

  // Must be the frequency of i_uart0.clk_i in Hz
  localparam int unsigned UartDPIFreq = 1_000_000_000;

  uartdpi #(
    .BAUD ('d20_000_000),
    // Frequency shouldn't matter since we are sending with the same clock.
    .FREQ (UartDPIFreq),
    .NAME("uart0")
  ) i_uart0 (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .tx_o (rx),
    .rx_i (tx)
  );

endmodule
