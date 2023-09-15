// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "offload.h"
#include "snrt.h"

#define N_JOB_TYPES 2

// Other variables
__thread usr_data_t* volatile usr_data_ptr;
__thread uint32_t l1_job_ptr;
__thread uint32_t remote_job_ptr;

#include "axpy_job.h"
#include "montecarlo_job.h"

// Job function type
typedef void (*job_func_t)(job_t* job);

// Job function arrays
__thread job_func_t jobs_dm_core[N_JOB_TYPES] = {
    axpy_job_dm_core, mc_job_dm_core};
__thread job_func_t jobs_compute_core[N_JOB_TYPES] = {
    axpy_job_compute_core, mc_job_compute_core};

static inline void run_job() {
    // Force compiler to assign fallthrough path of the branch to
    // the DM core. This way the cache miss latency due to the branch
    // is incurred by the compute cores, and overlaps with the data
    // movement performed by the DM core.
    asm goto("bnez %0, %l[run_job_compute_core]"
             :
             : "r"(snrt_is_compute_core())
             :
             : run_job_compute_core);

#ifndef OFFLOAD_NONE
    // Retrieve job data pointer
#ifdef MULTICAST
    job_t* job = (job_t*)l1_job_ptr;
#else
    job_t* job = (job_t*)remote_job_ptr;
#endif

    // Invoke job
    uint32_t job_id = job->id;
    jobs_dm_core[job_id](job);

#else
    return_to_cva6(SYNC_ALL);
#endif

    goto run_job_end;

run_job_compute_core:;

#ifndef OFFLOAD_NONE
    // Get pointer to local copy of job
    job_t* job_local = (job_t*)l1_job_ptr;

#ifndef MULTICAST
    // Synchronize with DM core such that it knows
    // it can update the l1 alloc pointer, and we know
    // job information is locally available
    snrt_cluster_hw_barrier();
#endif

    // Invoke job
    jobs_compute_core[job_local->id](job_local);
#else
    snrt_cluster_hw_barrier();
    snrt_int_wait_mcip_clr();
#endif

run_job_end:;
}

int main() {
    // Get user data pointer
    usr_data_ptr =
        (usr_data_t * volatile) get_communication_buffer()->usr_data_ptr;

    // Tell CVA6 where it can store the job ID
    l1_job_ptr = (uint32_t)snrt_l1_next();
    snrt_cluster_hw_barrier();
    if (snrt_is_dm_core()) {
        // Only one core sends the data for all clusters
#ifdef MULTICAST
        if (snrt_cluster_idx() == 0)
#else
        if (snrt_cluster_idx() == (N_CLUSTERS_TO_USE - 1))
#endif
            usr_data_ptr->l1_job_ptr = l1_job_ptr;
    }
    snrt_cluster_hw_barrier();

#ifdef OFFLOAD_MONTECARLO
    if (snrt_is_compute_core()) mc_init();
#endif

    // Notify CVA6 when snRuntime initialization is done
    snrt_int_clr_mcip();
    return_to_cva6(SYNC_ALL);
    snrt_wfi();

#ifndef MULTICAST
    // Get pointer to remote job in cluster 0's TCDM
    remote_job_ptr = usr_data_ptr->l1_job_ptr;
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
