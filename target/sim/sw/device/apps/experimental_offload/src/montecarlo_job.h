// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "lcg.h"
#include "pi_estimation.h"

__thread uint32_t seed0, seed1, Ap, Cp;

inline void mc_init() {
    // Double the sequences as each core produces two random numbers
    unsigned int num_sequences = 2 * snrt_cluster_compute_core_num() * N_CLUSTERS_TO_USE;
    init_2d_lcg_params(num_sequences, 0, LCG_A, LCG_C, &seed0, &seed1, &Ap, &Cp);
}

void mc_job_dm_core(job_t* job) {
#ifdef MULTICAST
    mc_job_t* mc_job = (mc_job_t*)job;
#else
    mc_job_t* mc_job = (mc_job_t*)l1_job_ptr;
#endif

    snrt_mcycle(); // Retrieve job information (get job arguments)

#ifndef MULTICAST
    // Copy job info (cluster 0 already has the data, no need to copy)
    if (snrt_cluster_idx() != (N_CLUSTERS_TO_USE - 1)) {
        snrt_dma_start_1d(mc_job, job, sizeof(mc_job_t));
        // Wait for job info transfer to complete
        snrt_dma_wait_all();
    }
#endif

    snrt_mcycle(); // Retrieve job operands

#ifndef MULTICAST
    // Synchronize with compute cores before updating the l1 alloc pointer
    // such that they can retrieve the local job pointer.
    // Also ensures compute cores see the transferred job information.
    snrt_cluster_hw_barrier();
#endif

    // Update the L1 alloc pointer
    void* next = (void*)((uint32_t)(mc_job) + sizeof(mc_job_t));
    snrt_l1_update_next(next);

    snrt_mcycle(); // Barrier

    // Synchronize with compute cores to make sure the  
    // L1 pointer is up to date before they can start computing
    snrt_cluster_hw_barrier();

    snrt_mcycle(); // Job execution

    // Intra-cluster barrier
    snrt_cluster_hw_barrier();
}

void mc_job_compute_core(job_t* job) {
    // Cast local job
    mc_job_t* mc_job = (mc_job_t*)job;

    snrt_mcycle();

    // Get args
    uint32_t n_samples = mc_job->args.n_samples;
    double* result_ptr = (double *)(mc_job->args.result_ptr);

    snrt_mcycle();

    // Synchronize with DM core to make sure the  
    // L1 pointer is up to date before they can start computing
    snrt_cluster_hw_barrier();

    snrt_mcycle();

    // Get addresses of partial sum arrays
    uint32_t* reduction_array = (uint32_t*) snrt_l1_next();
    uint32_t* global_reduction_array = reduction_array + snrt_cluster_compute_core_num();

    // Run core-local kernel
    reduction_array[snrt_cluster_core_idx()] = calculate_partial_sum(seed0, seed1, Ap, Cp, n_samples);

    snrt_mcycle();

    // Intra-cluster barrier
    snrt_cluster_hw_barrier();

    snrt_mcycle();

    // Reduction
    if (snrt_cluster_core_idx() == 0) {
        uint32_t sum = 0;

        // Intra-cluster reduction
        for (int i = 0; i < snrt_cluster_compute_core_num(); i++) {
            sum += reduction_array[i];
        }

        snrt_mcycle(); // Exchange partial sums

        if (snrt_cluster_idx() != 0) {
            // Calculate address of cluster 0's reduction array
            global_reduction_array = (uint32_t *)(((uint32_t)global_reduction_array) - snrt_cluster_idx() * cluster_offset);

            // Store partial sum to cluster 0's reduction array
            global_reduction_array[snrt_cluster_idx()] = sum;

            // Inter-cluster barrier
            uint32_t barrier_ptr = (uint32_t)(&ct_barrier_cnt);
            barrier_ptr -= cluster_offset * snrt_cluster_idx();
            uint32_t cnt = __atomic_add_fetch((volatile uint32_t*)barrier_ptr, 1, __ATOMIC_RELAXED);

            // Send interrupt if last to arrive on barrier
            if (cnt == (N_CLUSTERS_TO_USE - 1)) {

                // Reset inter-cluster barrier counter
                *((volatile uint32_t*)barrier_ptr) = 0;
            
                // Send interrupt to cluster 0
                *(cluster_clint_set_ptr(0)) = 1;
            }

        } else {
            // Wait other clusters on inter-cluster barrier
            if (N_CLUSTERS_TO_USE > 1) {
                snrt_wfi();
                snrt_int_clr_mcip_unsafe();
            }

            snrt_mcycle(); // Inter-cluster reduction

            for (int i = 1; i < N_CLUSTERS_TO_USE; i++) {
                sum += global_reduction_array[i];
            }

            // Calculate PI
            *result_ptr = estimate_pi(sum, n_samples * N_CLUSTERS_TO_USE * snrt_cluster_compute_core_num());
            snrt_fpu_fence();
        }
    }

    snrt_mcycle();

    if (snrt_global_core_idx() == 0)
        set_host_sw_interrupt();
}
