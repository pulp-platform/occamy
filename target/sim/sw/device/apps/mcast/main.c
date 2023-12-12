// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Author: Luca Colagrande <colluca@iis.ee.ethz.ch>

#include "snrt.h"

#define LENGTH 32
#define INITIALIZER 0xAAAAAAAA

// Allocate a buffer in main memory which we will use to copy data around
// with the DMA.
uint32_t buffer_src[LENGTH];

int main() {
    uint32_t is_first_cluster = snrt_cluster_idx() == 0;

    // Allocate destination buffer
    uint32_t *buffer_dst = snrt_l1_next();

    // First cluster initializes the source buffer in DRAM and multicast-
    // copies it to the destination buffer in every cluster's TCDM.
    if (snrt_is_dm_core() && is_first_cluster) {
        // Initializing the DRAM source buffer using the LSU may cause data
        // races with the DMA "later" copying the source buffer to the TCDM
        // destinations. We therefore initialize the DRAM source buffer using
        // the DMA itself, from a TCDM source buffer initialized with the LSU.
        uint32_t *buffer_src_tcdm = buffer_dst + LENGTH;
        for (uint32_t i = 0; i < LENGTH; i++) {
            buffer_src_tcdm[i] = INITIALIZER;
        }
        snrt_dma_start_1d(buffer_src, buffer_src_tcdm, sizeof(buffer_src));

        // Initiate DMA transfer
        dma_broadcast_to_clusters(buffer_dst, buffer_src, sizeof(buffer_src));
    }

    // All other clusters wait on a global barrier to signal the transfer
    // completion.
    snrt_global_barrier();

    // Every cluster checks that the data in the destination buffer is correct.
    if (snrt_is_dm_core()) {
        uint32_t n_errs = LENGTH;
        for (uint32_t i = 0; i < LENGTH; i++) {
            if (buffer_dst[i] == INITIALIZER) n_errs--;
        }
        return n_errs;
    } else
        return 0;
}
