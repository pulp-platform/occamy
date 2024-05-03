// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "lcg.h"
#include "pi_estimation.h"

__thread uint32_t seed0, seed1, Ap, Cp;

inline void mc_init() {
    if (snrt_is_compute_core()) {
        // Double the sequences as each core produces two random numbers
        unsigned int num_sequences =
            2 * snrt_cluster_compute_core_num() * N_CLUSTERS_TO_USE;
        init_2d_lcg_params(num_sequences, 0, LCG_A, LCG_C, &seed0, &seed1, &Ap,
                        &Cp);
    }
}

void montecarlo_job_unified(void* job_args) {
    mc_args_t* args = (mc_args_t*)job_args;
    uint32_t n_samples = args->n_samples;
    double* result_ptr = (double*)(args->result_ptr);
    snrt_mcycle();

    // Get addresses of partial sum arrays
    uint32_t* core_sum = (uint32_t*)snrt_l1_alloc_compute_core_local(
        sizeof(uint32_t), sizeof(uint32_t));
    uint32_t* global_reduction_array = (uint32_t*)snrt_l1_alloc_cluster_local(
        sizeof(uint32_t), sizeof(uint32_t));

    // Run core-local kernel
    if (snrt_is_compute_core()) {
        *core_sum = calculate_partial_sum(seed0, seed1, Ap, Cp, n_samples);
    }

    snrt_mcycle();

    // Intra-cluster barrier
    snrt_cluster_hw_barrier();

    snrt_mcycle();

    // Reduction
    if (snrt_cluster_core_idx() == 0) {
        uint32_t sum = 0;

        // Intra-cluster reduction
        for (int i = 0; i < snrt_cluster_compute_core_num(); i++) {
            sum += core_sum[i];
        }

        snrt_mcycle();  // Exchange partial sums

        if (snrt_cluster_idx() != 0) {
            // Calculate address of cluster 0's reduction array
            global_reduction_array =
                (uint32_t*)(((uint32_t)global_reduction_array) -
                            snrt_cluster_idx() * cluster_offset);

            // Store partial sum to cluster 0's reduction array
            global_reduction_array[snrt_cluster_idx()] = sum;

            // Inter-cluster barrier
            uint32_t barrier_ptr = (uint32_t)(&ct_barrier_cnt);
            barrier_ptr -= cluster_offset * snrt_cluster_idx();
            uint32_t cnt = __atomic_add_fetch((volatile uint32_t*)barrier_ptr,
                                              1, __ATOMIC_RELAXED);

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

            snrt_mcycle();  // Inter-cluster reduction

            for (int i = 1; i < N_CLUSTERS_TO_USE; i++) {
                sum += global_reduction_array[i];
            }

            // Calculate PI
            *result_ptr = estimate_pi(sum, n_samples * N_CLUSTERS_TO_USE *
                                               snrt_cluster_compute_core_num());
            snrt_fpu_fence();
        }
    }

    snrt_mcycle();
    snrt_cluster_hw_barrier();
}
