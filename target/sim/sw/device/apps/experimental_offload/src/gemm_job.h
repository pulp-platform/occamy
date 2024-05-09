// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#define XSSR
// #include "gemm.h"

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

void gemm_job_unified(void* job_args) {
    size_t size_a;
    size_t size_b;
    size_t size_c;
    double* local_a;
    double* local_b;
    double* local_c;

    offload_gemm_args_t* args = (offload_gemm_args_t *)job_args;
    size_a = args->m * args->k * sizeof(double);
    size_b = args->k * args->n * sizeof(double);
    size_c = args->m * args->n * sizeof(double);
    local_a = (double*)snrt_l1_alloc_cluster_local(size_a, 4096);
    local_b = (double*)snrt_l1_alloc_cluster_local(size_b, 4096);
    local_c = (double*)snrt_l1_alloc_cluster_local(size_c, 4096);
    
    // Copy job operands (row block of A and full B)
    if (snrt_is_dm_core()) {
        snrt_dma_load_2d_tile(
            local_a,
            (void *)args->a_ptr,
            snrt_cluster_idx(),
            0,
            args->m,
            args->k,
            args->k,
            sizeof(double)
        );
        snrt_dma_load_2d_tile(
            local_b,
            (void *)args->b_ptr,
            0,
            0,
            args->k,
            args->n,
            args->n,
            sizeof(double));
        snrt_dma_wait_all();
    }

    // Synchronize with DM core to wait for job operands
    snrt_mcycle();
    snrt_cluster_hw_barrier();

    // Compute
    if (snrt_is_compute_core()) {
        snrt_mcycle();
        matmul(args->m, args->n, args->k, local_a, local_b, local_c);
        snrt_mcycle();
    }

    // Synchronize with DM core to wait for job results
    snrt_cluster_hw_barrier();
    snrt_mcycle();

    // Copy job results
    if (snrt_is_dm_core()) {
        snrt_dma_store_2d_tile(
            (void *)args->c_ptr,
            local_c,
            snrt_cluster_idx(),
            0,
            args->m,
            args->n,
            args->n,
            sizeof(double)
        );
        snrt_dma_wait_all();
        snrt_mcycle();
    }

    snrt_cluster_hw_barrier();

    // Free memory
    snrt_l1_update_next_v2(local_a);
}
