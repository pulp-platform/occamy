// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#define XSSR
#include "gemm.h"

void matmul(uint32_t M, uint32_t N, uint32_t K, double* A, double* B,
            double* C) {
    const uint32_t compute_num = snrt_cluster_compute_core_num();
    const uint32_t compute_id = snrt_cluster_core_idx();

    // Compute fraction of C rows every core computes
    uint32_t m = M / compute_num;

    // Compute cores work not on contiguous blocks but on strided rows
    uint32_t stride_a = compute_num * K;
    uint32_t stride_b = K;
    uint32_t stride_c = compute_num * N;

    // Compute cores access A and C at offsets of one row from each other
    uint32_t offset_a = compute_id * K;
    uint32_t offset_c = compute_id * N;
    double* a = A + offset_a;
    double* c = C + offset_c;

    // SSR strides and bounds only have to be configured
    // once in the beginning
    const uint32_t ssr0_b[3] = {K, N, m};
    const uint32_t ssr0_i[3] = {sizeof(double), 0, sizeof(double) * stride_a};

    snrt_ssr_loop_3d(SNRT_SSR_DM0, ssr0_b[0], ssr0_b[1], ssr0_b[2], ssr0_i[0],
                     ssr0_i[1], ssr0_i[2]);

    // Second matrix is stored in transposed format
    const uint32_t ssr1_b[3] = {K, N, m};
    const uint32_t ssr1_i[3] = {8, 8 * stride_b, 0};

    snrt_ssr_loop_3d(SNRT_SSR_DM1, ssr1_b[0], ssr1_b[1], ssr1_b[2], ssr1_i[0],
                     ssr1_i[1], ssr1_i[2]);

    // SSR start address need to be configured each time
    snrt_ssr_read(SNRT_SSR_DM0, SNRT_SSR_3D, a);
    snrt_ssr_read(SNRT_SSR_DM1, SNRT_SSR_3D, B);
    snrt_ssr_enable();

    for (uint32_t i = 0; i < m; i++) {
        for (uint32_t j = 0; j < N; j++) {
            double accum = 0.0;

            asm volatile(
                "frep.o %[n_frep], 1, 0, 0 \n"
                "fmadd.d %[accum], ft0, ft1, %[accum] \n"
                : [ accum ] "+f"(accum)
                : [ n_frep ] "r"(K - 1)
                : "ft0", "ft1", "ft2");

            // Store results back
            c[i * stride_c + j] = accum;
        }
    }

    snrt_fpu_fence();
    snrt_ssr_disable();
}

void gemm_job_dm_core(job_t* job) {
#if defined(SUPPORTS_MULTICAST) && defined(USE_MULTICAST)
    gemm_local_job_t* gemm_job = (gemm_local_job_t*)job;
#else
    gemm_local_job_t* gemm_job = (gemm_local_job_t*)local_job_addr;
#endif

    snrt_mcycle();  // Retrieve job information (get job arguments)

#if !defined(SUPPORTS_MULTICAST) || !defined(USE_MULTICAST)
    // Copy job info (cluster 0 already has the data, no need to copy)
    if (snrt_cluster_idx() != (N_CLUSTERS_TO_USE - 1))
        snrt_dma_start_1d(gemm_job, job, sizeof(gemm_job_t));

    // Get pointer to next free slot in l1 alloc
    double* b = (double*)(ALIGN_UP(
        (uint32_t)gemm_job + sizeof(gemm_local_job_t), 4096));

    // Wait for job info transfer to complete
    snrt_dma_wait_all();
    snrt_mcycle();  // Retrieve job operands
#else
    snrt_mcycle();  // Retrieve job operands
    // Get pointer to next free slot in l1 alloc
    double* b = (double*)(ALIGN_UP(
        (uint32_t)gemm_job + sizeof(gemm_local_job_t), 4096));
#endif

    // Copy operand b
    size_t size_b = gemm_job->args.n * gemm_job->args.k * 8;
    void* b_l3_ptr = (void*)(uint32_t)(gemm_job->args.b_l3_ptr);
    snrt_dma_start_1d(b, b_l3_ptr, size_b);

#if !defined(SUPPORTS_MULTICAST) || !defined(USE_MULTICAST)
    // Synchronize with compute cores before updating the l1 alloc pointer
    // such that they can retrieve the local job pointer.
    // Also ensures compute cores see the transferred job information.
    snrt_cluster_hw_barrier();
#endif

    // Copy operand a
    size_t size_a = gemm_job->args.m * gemm_job->args.k * 8;
    size_t offset_a = snrt_cluster_idx() * size_a;
    void* a_l3_ptr = (void*)(uint32_t)(gemm_job->args.a_l3_ptr + offset_a);
    double* a = (double*)(ALIGN_UP((uint32_t)b + size_b, 4096));
    snrt_dma_start_1d(a, a_l3_ptr, size_a);

    // Set pointers to local job operands
    gemm_job->args.b = b;
    gemm_job->args.a = a;
    gemm_job->args.c = (double*)((uint32_t)a + size_a);

    // Synchronize with compute cores again such that they see
    // also the local job operands locations (a, b, c)
    snrt_cluster_hw_barrier();

    // Update the L1 alloc pointer
    size_t size_c = gemm_job->args.m * gemm_job->args.n * 8;
    size_t offset_c = snrt_cluster_idx() * size_c;
    void* next = (void*)((uint32_t)(gemm_job->args.c) + size_c);
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
    void* c_l3_ptr = (void*)(uint32_t)(gemm_job->args.c_l3_ptr + offset_c);
    snrt_dma_start_1d(c_l3_ptr, gemm_job->args.c, size_c);
    snrt_dma_wait_all();

    snrt_mcycle();

#if defined(SUPPORTS_MULTICAST) && defined(USE_MULTICAST)
    return_to_cva6_accelerated(gemm_job->offload_id);
#else
    return_to_cva6(SYNC_CLUSTERS);
#endif
}

void gemm_job_compute_core(job_t* job) {
    // Cast local job
    gemm_local_job_t* gemm_job = (gemm_local_job_t*)job;

    snrt_mcycle();

    // Get args
    uint32_t m = gemm_job->args.m;
    uint32_t n = gemm_job->args.n;
    uint32_t k = gemm_job->args.k;

    // Synchronize with DM core to wait for local job
    // operand pointers (a, b, c) to be up to date
    snrt_cluster_hw_barrier();

    double* a = gemm_job->args.a;
    double* b = gemm_job->args.b;
    double* c = gemm_job->args.c;

    snrt_mcycle();

    // Synchronize with DM core to wait for operands
    // to be fully transferred in L1
    snrt_cluster_hw_barrier();

    snrt_mcycle();

    // Run kernel
    matmul(m, n, k, (void*)a, (void*)b, (void*)c);

    snrt_mcycle();

    // Synchronize with DM core to make sure results are available
    // before DMA starts transfer to L3
    snrt_cluster_hw_barrier();

    snrt_mcycle();
}
