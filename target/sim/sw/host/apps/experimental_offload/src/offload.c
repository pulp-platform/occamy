// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "offload.h"
#include <stddef.h>
#include "host.c"
#include <math.h>

#include "axpy/data/data.h"
#define N_JOBS 2

#define WIDE_SPM_ADDR(X) \
    ((X) - (uint64_t)(&__wide_spm_start) + SPM_WIDE_BASE_ADDR)

#ifdef N_CLUSTERS_TO_USE
const int n_clusters_to_use = N_CLUSTERS_TO_USE;
#else
const int n_clusters_to_use = N_CLUSTERS;
#endif

extern volatile uint64_t __wide_spm_start;

usr_data_t usr_data __attribute__((section(".nc_spm")));

double pi __attribute__((section(".wide_spm")));

static inline void send_job_and_wakeup(job_t *job, uint64_t l1_job_ptr) {
    *((volatile uint32_t*)(CLINT_BASE_ADDR + CLINT_OFFLOAD0_REG_OFFSET)) =
        n_clusters_to_use;

    switch (job->id) {
        case J_AXPY: {
            axpy_args_t args = job->args.axpy;

#ifdef MULTICAST
            uint64_t mask = ((n_clusters_to_use - 1) << 18);
            enable_multicast(mask);
#endif
            *((volatile uint64_t *)(l1_job_ptr)) = job->id;
            *((volatile uint8_t *)(l1_job_ptr + offsetof(job_t, offload_id))) =
                job->offload_id;
            *((volatile uint32_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(axpy_args_t, l))) = args.l;
            *((volatile double *)(l1_job_ptr + offsetof(job_t, args) +
                                  offsetof(axpy_args_t, a))) = args.a;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(axpy_args_t, x_ptr))) = args.x_ptr;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(axpy_args_t, y_ptr))) = args.y_ptr;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(axpy_args_t, z_ptr))) = args.z_ptr;

            mcycle();  // Wakeup
#ifdef MULTICAST
            *((volatile uint32_t *)cluster_clint_set_addr(0)) = 511;
            disable_multicast();
#else
            wakeup_snitches();
#endif
            break;
        }
        case J_MONTECARLO: {
            mc_args_t args = job->args.mc;

#ifdef MULTICAST
            uint64_t mask = ((n_clusters_to_use - 1) << 18);
            enable_multicast(mask);
#endif
            *((volatile uint64_t *)(l1_job_ptr)) = job->id;
            *((volatile uint8_t *)(l1_job_ptr + offsetof(job_t, offload_id))) =
                job->offload_id;
            *((volatile uint32_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(mc_args_t, n_samples))) =
                args.n_samples;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(mc_args_t, result_ptr))) =
                args.result_ptr;

            mcycle();  // Wakeup
#ifdef MULTICAST
            *((volatile uint32_t *)cluster_clint_set_addr(0)) = 511;
            disable_multicast();
#else
            wakeup_snitches();
#endif
            break;
        }
    }
}

int main() {
    set_d_cache_enable(1);

    comm_buffer.usr_data_ptr = (uint32_t)(uint64_t)&usr_data;
    fence();

    axpy_args_t axpy_args = {
        l / n_clusters_to_use, a, WIDE_SPM_ADDR((uint64_t)x),
        WIDE_SPM_ADDR((uint64_t)y), WIDE_SPM_ADDR((uint64_t)z)};
    job_t axpy = {J_AXPY, 0, axpy_args};

    mc_args_t mc_args = {l / (8 * n_clusters_to_use),
                         WIDE_SPM_ADDR((uint64_t)&pi)};
    job_args_t job_args;
    job_args.mc = mc_args;
    job_t mc = {J_MONTECARLO, 0, job_args};

#if defined(OFFLOAD_AXPY)
    job_t jobs[N_JOBS] = {axpy, axpy};
#elif defined(OFFLOAD_MONTECARLO)
    job_t jobs[N_JOBS] = {mc, mc};
#endif

    volatile uint32_t n_jobs = N_JOBS;

    // Reset and ungate quadrant 0, deisolate
    reset_and_ungate_quadrants();
    deisolate_all();

    // Enable interrupts to receive notice of job termination
    enable_sw_interrupts();

    // Program Snitch entry point and communication buffer
    program_snitches();

    // Wakeup Snitches for snRuntime initialization
    // (memory fence ensures compiler does not reorder
    // this and previous function calls)
    asm volatile("" : : : "memory");
    wakeup_snitches();

    // Wait for snRuntime initialization to be over
    wait_snitches_done();

    // Retrieve destination for job information in cluster 0's TCDM
    uint64_t l1_job_ptr = (uint64_t)usr_data.l1_job_ptr;

    // Send jobs (first iteration just to heat up I$)
    for (uint32_t i = 0; i < n_jobs; i++) {
#ifndef OFFLOAD_NONE
        mcycle();  // Send job information
        send_job_and_wakeup(&jobs[i], l1_job_ptr);
#else
        mcycle();  // Wakeup
        wakeup_snitches();
#endif
        mcycle();  // Wait for job done
        wait_sw_interrupt();

        mcycle();  // Resume operation on host
#ifdef OFFLOAD_NONE
        clear_host_sw_interrupt_unsafe();
        mcycle();
        wait_host_sw_interrupt_clear();
#else
        clear_host_sw_interrupt_unsafe();
        mcycle();
#endif
    }

#if defined(OFFLOAD_AXPY)
    // Copy results from wide SPM to DRAM for verification
    sys_dma_blk_memcpy((uint64_t)z, WIDE_SPM_ADDR((uint64_t)z),
                       l * sizeof(double));
#elif defined(OFFLOAD_MONTECARLO)
    double pi_estimate = *((double*)mc_args.result_ptr);
    double err = fabs(pi_estimate - 3.14);
    if (err > 0.5) return 1;
#endif

    // Exit routine
    mcycle();

    return 0;
}
