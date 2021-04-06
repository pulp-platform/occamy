  ${slv_dir} logic              ${prefix}_awready,
  ${mst_dir} logic              ${prefix}_awvalid,
  ${mst_dir} ${bus.id_type()}   ${prefix}_awid,
  ${mst_dir} ${bus.addr_type()} ${prefix}_awaddr,
  ${mst_dir} axi_pkg::len_t     ${prefix}_awlen,
  ${mst_dir} axi_pkg::size_t    ${prefix}_awsize,
  ${mst_dir} axi_pkg::burst_t   ${prefix}_awburst,
  ${mst_dir} logic              ${prefix}_awlock,
  ${mst_dir} axi_pkg::cache_t   ${prefix}_awcache,
  ${mst_dir} axi_pkg::prot_t    ${prefix}_awprot,
  ${mst_dir} axi_pkg::qos_t     ${prefix}_awqos,
  ${mst_dir} axi_pkg::region_t  ${prefix}_awregion,
//   ${mst_dir} axi_pkg::atop_t    ${prefix}_awatop,
  ${mst_dir} ${bus.user_type()} ${prefix}_awuser,
  ${slv_dir} logic              ${prefix}_wready,
  ${mst_dir} logic              ${prefix}_wvalid,
  ${mst_dir} ${bus.data_type()} ${prefix}_wdata,
  ${mst_dir} ${bus.strb_type()} ${prefix}_wstrb,
  ${mst_dir} logic              ${prefix}_wlast,
  ${mst_dir} ${bus.user_type()} ${prefix}_wuser,
  ${slv_dir} logic              ${prefix}_arready,
  ${mst_dir} logic              ${prefix}_arvalid,
  ${mst_dir} ${bus.id_type()}   ${prefix}_arid,
  ${mst_dir} ${bus.addr_type()} ${prefix}_araddr,
  ${mst_dir} axi_pkg::len_t     ${prefix}_arlen,
  ${mst_dir} axi_pkg::size_t    ${prefix}_arsize,
  ${mst_dir} axi_pkg::burst_t   ${prefix}_arburst,
  ${mst_dir} logic              ${prefix}_arlock,
  ${mst_dir} axi_pkg::cache_t   ${prefix}_arcache,
  ${mst_dir} axi_pkg::prot_t    ${prefix}_arprot,
  ${mst_dir} axi_pkg::qos_t     ${prefix}_arqos,
  ${mst_dir} axi_pkg::region_t  ${prefix}_arregion,
  ${mst_dir} ${bus.user_type()} ${prefix}_aruser,
  ${mst_dir} logic              ${prefix}_rready,
  ${slv_dir} logic              ${prefix}_rvalid,
  ${slv_dir} ${bus.id_type()}   ${prefix}_rid,
  ${slv_dir} ${bus.data_type()} ${prefix}_rdata,
  ${slv_dir} axi_pkg::resp_t    ${prefix}_rresp,
  ${slv_dir} logic              ${prefix}_rlast,
  ${slv_dir} ${bus.user_type()} ${prefix}_ruser,
  ${mst_dir} logic              ${prefix}_bready,
  ${slv_dir} logic              ${prefix}_bvalid,
  ${slv_dir} ${bus.id_type()}   ${prefix}_bid,
  ${slv_dir} axi_pkg::resp_t    ${prefix}_bresp,
  ${slv_dir} ${bus.user_type()} ${prefix}_buser