// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#define XSSR
#include "axpy.h"

void axpy_job_unified(void* job_args) {
    double* local_x;
    double* local_y;
    double* local_z;

    axpy_args_t* args = (axpy_args_t *)job_args;
    local_x = (double*)(ALIGN_UP((uint32_t)args + sizeof(axpy_job_t), 4096));
    local_y = local_x + args->n;
    local_z = local_y + args->n;
    
    // Copy job operands
    if (snrt_is_dm_core()) {
        snrt_dma_load_1d_tile(local_x, (void *)args->x_addr, snrt_cluster_idx(), args->n, sizeof(double));
        snrt_dma_load_1d_tile(local_y, (void *)args->y_addr, snrt_cluster_idx(), args->n, sizeof(double));
        snrt_dma_wait_all();
    }

    // Synchronize with DM core to wait for job operands
    snrt_mcycle();
    snrt_cluster_hw_barrier();

    // Compute
    if (snrt_is_compute_core()) {
        snrt_mcycle();
        axpy(args->n, args->a, local_x, local_y, local_z);
        snrt_mcycle();
    }

    // Synchronize with DM core to wait for job results
    snrt_cluster_hw_barrier();
    snrt_mcycle();

    // Copy job results
    if (snrt_is_dm_core()) {
        snrt_dma_store_1d_tile((void *)args->z_addr, local_z, snrt_cluster_idx(), args->n, sizeof(double));
        snrt_dma_wait_all();
        snrt_mcycle();
    }

    snrt_cluster_hw_barrier();
}
