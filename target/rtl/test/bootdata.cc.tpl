// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include <tb_lib.hh>

namespace sim {

const BootData BOOTDATA = {.boot_addr = ${boot_addr},
                           .core_count = ${core_count},
                           .hartid_base = ${hart_id_base},
                           .tcdm_start = ${tcdm_start},
                           .tcdm_size = ${tcdm_size},
                           .tcdm_offset = ${tcdm_offset},
                           .global_mem_start = ${global_mem_start},
                           .global_mem_end = ${global_mem_end},
                           .cluster_count = ${cluster_count},
                           .s1_quadrant_count = ${s1_quadrant_count},
                           .clint_base = ${clint_base}};

}  // namespace sim
