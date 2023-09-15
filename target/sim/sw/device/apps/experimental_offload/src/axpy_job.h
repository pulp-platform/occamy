// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#define XSSR
#include "axpy.h"

void axpy_job_dm_core(job_t* job) {
#ifdef MULTICAST
    axpy_local_job_t* axpy_job = (axpy_local_job_t*)job;
#else
    axpy_local_job_t* axpy_job = (axpy_local_job_t*)l1_job_ptr;
#endif

    snrt_mcycle();  // Retrieve job information (get job arguments)

#ifndef MULTICAST
    // Copy job info (cluster 0 already has the data, no need to copy)
    if (snrt_cluster_idx() != (N_CLUSTERS_TO_USE - 1))
        snrt_dma_start_1d(axpy_job, job, sizeof(axpy_job_t));

    // Get pointer to next free slot in l1 alloc
    double* x = (double*)(ALIGN_UP(
        (uint32_t)axpy_job + sizeof(axpy_local_job_t), 4096));

    // Wait for job info transfer to complete
    snrt_dma_wait_all();
    snrt_mcycle();  // Retrieve job operands
#else
    snrt_mcycle();  // Retrieve job operands
    // Get pointer to next free slot in l1 alloc
    double* x = (double*)(ALIGN_UP(
        (uint32_t)axpy_job + sizeof(axpy_local_job_t), 4096));
#endif

    // Copy operand x
    size_t size = axpy_job->args.l * 8;
    size_t offset = snrt_cluster_idx() * size;
    void* x_l3_ptr = (void*)(uint32_t)(axpy_job->args.x_l3_ptr + offset);
    snrt_dma_start_1d(x, x_l3_ptr, size);

#ifndef MULTICAST
    // Synchronize with compute cores before updating the l1 alloc pointer
    // such that they can retrieve the local job pointer.
    // Also ensures compute cores see the transferred job information.
    snrt_cluster_hw_barrier();
#endif

    // Copy operand y
    double* y = (double*)((uint32_t)x + size);
    void* y_l3_ptr = (void*)(uint32_t)(axpy_job->args.y_l3_ptr + offset);
    snrt_dma_start_1d(y, y_l3_ptr, size);

    // Set pointers to local job operands
    axpy_job->args.x = x;
    axpy_job->args.y = y;
    axpy_job->args.z = (double*)((uint32_t)y + size);

    // Synchronize with compute cores again such that they see
    // also the local job operands locations (x, y, z)
    snrt_cluster_hw_barrier();

    // Update the L1 alloc pointer
    void* next = (void*)((uint32_t)(axpy_job->args.z) + size);
    snrt_l1_update_next(next);

    // Wait for DMA transfers to complete
    snrt_dma_wait_all();

    snrt_mcycle();  // Barrier

    // Synchronize with compute cores to make sure the data
    // is available before they can start computing on it
    snrt_cluster_hw_barrier();

    snrt_mcycle();  // Job execution

    // Synchronize cores to make sure results are available before
    // DMA starts transfer to L3
    snrt_cluster_hw_barrier();

    snrt_mcycle();  // Writeback job outputs

    // Transfer data out
    void* z_l3_ptr = (void*)(uint32_t)(axpy_job->args.z_l3_ptr + offset);
    snrt_dma_start_1d(z_l3_ptr, axpy_job->args.z, size);
    snrt_dma_wait_all();

    snrt_mcycle();

#ifdef MULTICAST
    return_to_cva6_accelerated(axpy_job->offload_id);
#else
    return_to_cva6(SYNC_CLUSTERS);
#endif
}

void axpy_job_compute_core(job_t* job) {
    // Cast local job
    axpy_local_job_t* axpy_job = (axpy_local_job_t*)job;

    snrt_mcycle();

    // Get args
    uint32_t l = axpy_job->args.l;
    double a = axpy_job->args.a;

    // Synchronize with DM core to wait for local job
    // operand pointers (x, y, z) to be up to date
    snrt_cluster_hw_barrier();

    double* x = axpy_job->args.x;
    double* y = axpy_job->args.y;
    double* z = axpy_job->args.z;

    snrt_mcycle();

    // Synchronize with DM core to wait for operands
    // to be fully transferred in L1
    snrt_cluster_hw_barrier();

    snrt_mcycle();

    // Run kernel
    axpy(l, a, x, y, z);

    snrt_mcycle();

    // Synchronize with DM core to make sure results are available
    // before DMA starts transfer to L3
    snrt_cluster_hw_barrier();

    snrt_mcycle();
}
