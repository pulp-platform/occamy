// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "offload.h"
#include "snrt.h"

// Other variables
__thread usr_data_t* volatile usr_data_ptr;
__thread uint32_t local_job_addr;
__thread uint32_t remote_job_addr;

// Job arguments are already in TCDM, no need to load them with the DMA
#define JOB_ARGS_PRELOADED

#include "axpy_job.h"
#include "gemm_job.h"
#include "montecarlo_job.h"
#include "kmeans_job.h"
#include "atax/src/atax.h"
#include "correlation/src/correlation.h"
#include "covariance/src/covariance.h"

// Job function type
typedef void (*job_func_t)(void* args);

// Job function array
__thread job_func_t jobs[N_JOB_TYPES] = {
    axpy_job_unified,
    NULL,
    NULL,
    kmeans_iteration_job,
    atax_job,
    correlation_job,
    covariance_job
};

static inline void run_job() {
    // Invoke job
#if defined(SUPPORTS_MULTICAST) && defined(USE_MULTICAST)
    job_t* job = (job_t *)local_job_addr;
    uint32_t job_id = job->id;
    if (snrt_is_dm_core()) snrt_mcycle();
    if (snrt_is_dm_core()) snrt_mcycle();
    jobs[job_id]((void *)&job->args);
    snrt_cluster_hw_barrier();
    if (snrt_is_dm_core()) {
        snrt_mcycle();
        return_to_cva6_accelerated(job->offload_id);
    }
#else
    job_t* remote_job = (job_t*)remote_job_addr;
    job_t* local_job = (job_t *)local_job_addr;
    if (snrt_is_dm_core()) {
        // Load job ID to lookup size of args
        local_job->id = remote_job->id;
        snrt_mcycle();
        // First cluster finds the data stored by CVA6 in its TCDM,
        // all other clusters fetch it from there
        if (snrt_cluster_idx() != 0)
            snrt_dma_start_1d(&local_job->args, &remote_job->args, job_args_size(local_job->id));
        snrt_dma_wait_all();
        snrt_mcycle();
    }
    snrt_cluster_hw_barrier();
    jobs[local_job->id]((void *)&local_job->args);
    if (snrt_is_dm_core()) snrt_mcycle();
    return_to_cva6(SYNC_ALL);
#endif
}

int main() {
    // Get user data pointer
    usr_data_ptr =
        (usr_data_t * volatile) get_communication_buffer()->usr_data_ptr;

    // Tell CVA6 where it can store the job ID
    local_job_addr = (uint32_t)snrt_l1_alloc_cluster_local(sizeof(job_t), 1);
    snrt_cluster_hw_barrier();
    if (snrt_is_dm_core()) {
        // Only one core sends the data for all clusters
        if (snrt_cluster_idx() == 0)
            usr_data_ptr->local_job_addr = local_job_addr;
    }
    snrt_cluster_hw_barrier();

#ifdef OFFLOAD_MONTECARLO
    mc_init();
#endif

    // Notify CVA6 when snRuntime initialization is done
    snrt_int_clr_mcip();
    return_to_cva6(SYNC_ALL);
    snrt_wfi();

#if !defined(SUPPORTS_MULTICAST) || !defined(USE_MULTICAST)
    // Get pointer to remote job in first cluster's TCDM
    remote_job_addr = usr_data_ptr->local_job_addr;
#endif

    // Job loop
    while (1) {
        snrt_mcycle();  // Clear interrupt
        snrt_int_clr_mcip_unsafe();

        snrt_mcycle();  // Retrieve job information (get job pointer)
        run_job();

        snrt_mcycle();  // Sleep
        snrt_wfi();
    }
}
