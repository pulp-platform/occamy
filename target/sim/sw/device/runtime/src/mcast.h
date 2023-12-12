// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Author: Luca Colagrande <colluca@iis.ee.ethz.ch>

#define BCAST_MASK ((snrt_cluster_num() - 1) << 18)

inline void dma_broadcast_to_clusters(void* dst, void* src, size_t size) {
    snrt_dma_start_1d_mcast(dst, src, BCAST_MASK, size);
    snrt_dma_wait_all();
}
