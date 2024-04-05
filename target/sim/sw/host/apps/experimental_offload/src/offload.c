// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "offload.h"
#include <math.h>
#include <stddef.h>
#include "host.c"

#ifdef N_CLUSTERS_TO_USE
const int n_clusters_to_use = N_CLUSTERS_TO_USE;
#else
const int n_clusters_to_use = N_CLUSTERS;
#endif

#if defined(OFFLOAD_AXPY)
#include "axpy/data/data.h"
#elif defined(OFFLOAD_GEMM)
#include "gemm/data/data.h"
#elif defined(OFFLOAD_KMEANS)
#include "kmeans/data/data.h"
#include "kmeans_job.h"
#endif

#ifdef OFFLOAD_KMEANS
#define N_JOBS n_iter
#else
#define N_JOBS 2
#endif

#define WIDE_SPM_ADDR(X) \
    ((X) - (uint64_t)(&__wide_spm_start) + SPM_WIDE_BASE_ADDR)

extern volatile uint64_t __wide_spm_start;

usr_data_t usr_data __attribute__((section(".nc_spm")));

double pi __attribute__((section(".wide_spm")));

static inline void send_job_and_wakeup(job_t *job, uint64_t l1_job_ptr) {
    *((volatile uint32_t *)(CLINT_BASE_ADDR + CLINT_OFFLOAD0_REG_OFFSET)) =
        n_clusters_to_use;

    switch (job->id) {
        case J_AXPY: {
            axpy_args_t args = job->args.axpy;

#if defined(SUPPORTS_MULTICAST) && defined(USE_MULTICAST)
            uint64_t mask = ((n_clusters_to_use - 1) << 18);
            enable_multicast(mask);
#endif
            *((volatile uint64_t *)(l1_job_ptr)) = job->id;
            *((volatile uint8_t *)(l1_job_ptr + offsetof(job_t, offload_id))) =
                job->offload_id;
            *((volatile uint32_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(axpy_args_t, n))) = args.n;
            *((volatile double *)(l1_job_ptr + offsetof(job_t, args) +
                                  offsetof(axpy_args_t, a))) = args.a;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(axpy_args_t, x_addr))) = args.x_addr;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(axpy_args_t, y_addr))) = args.y_addr;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(axpy_args_t, z_addr))) = args.z_addr;

            mcycle();  // Wakeup
#if defined(SUPPORTS_MULTICAST) && defined(USE_MULTICAST)
            *((volatile uint32_t *)cluster_clint_set_addr(0)) = 511;
            disable_multicast();
#else
            wakeup_snitches();
#endif
            break;
        }
        case J_GEMM: {
            gemm_args_t args = job->args.gemm;

#if defined(SUPPORTS_MULTICAST) && defined(USE_MULTICAST)
            uint64_t mask = ((n_clusters_to_use - 1) << 18);
            enable_multicast(mask);
#endif
            *((volatile uint64_t *)(l1_job_ptr)) = job->id;
            *((volatile uint8_t *)(l1_job_ptr + offsetof(job_t, offload_id))) =
                job->offload_id;
            *((volatile uint32_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(gemm_args_t, m))) = args.m;
            *((volatile uint32_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(gemm_args_t, n))) = args.n;
            *((volatile uint32_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(gemm_args_t, k))) = args.k;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(gemm_args_t, a_ptr))) = args.a_ptr;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(gemm_args_t, b_ptr))) = args.b_ptr;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(gemm_args_t, c_ptr))) = args.c_ptr;

            mcycle();  // Wakeup
#if defined(SUPPORTS_MULTICAST) && defined(USE_MULTICAST)
            *((volatile uint32_t *)cluster_clint_set_addr(0)) = 511;
            disable_multicast();
#else
            wakeup_snitches();
#endif
            break;
        }
        case J_MONTECARLO: {
            mc_args_t args = job->args.mc;

#if defined(SUPPORTS_MULTICAST) && defined(USE_MULTICAST)
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
#if defined(SUPPORTS_MULTICAST) && defined(USE_MULTICAST)
            *((volatile uint32_t *)cluster_clint_set_addr(0)) = 511;
            disable_multicast();
#else
            wakeup_snitches();
#endif
            break;
        }
        case J_KMEANS: {
            kmeans_args_t args = job->args.kmeans;

#if defined(SUPPORTS_MULTICAST) && defined(USE_MULTICAST)
            uint64_t mask = ((n_clusters_to_use - 1) << 18);
            enable_multicast(mask);
#endif
            *((volatile uint64_t *)(l1_job_ptr)) = job->id;
            *((volatile uint8_t *)(l1_job_ptr + offsetof(job_t, offload_id))) =
                job->offload_id;
            *((volatile uint32_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(kmeans_args_t, n_samples))) = args.n_samples;
            *((volatile uint32_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(kmeans_args_t, n_features))) = args.n_features;
            *((volatile uint32_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(kmeans_args_t, n_clusters))) = args.n_clusters;
            *((volatile uint32_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(kmeans_args_t, n_iter))) = args.n_iter;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(kmeans_args_t, samples_addr))) = args.samples_addr;
            *((volatile uint64_t *)(l1_job_ptr + offsetof(job_t, args) +
                                    offsetof(kmeans_args_t, centroids_addr))) = args.centroids_addr;

            mcycle();  // Wakeup
#if defined(SUPPORTS_MULTICAST) && defined(USE_MULTICAST)
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

// Define jobs to offload
#if defined(OFFLOAD_AXPY)
    axpy_args_t axpy_args = {
        n / n_clusters_to_use, a, WIDE_SPM_ADDR((uint64_t)x),
        WIDE_SPM_ADDR((uint64_t)y), WIDE_SPM_ADDR((uint64_t)z)};
    job_t axpy = {J_AXPY, 0, axpy_args};
    job_t jobs[N_JOBS] = {axpy, axpy};
#elif defined(OFFLOAD_GEMM)
    gemm_args_t gemm_args = {M / n_clusters_to_use,
                             N,
                             K,
                             WIDE_SPM_ADDR((uint64_t)a),
                             WIDE_SPM_ADDR((uint64_t)b),
                             WIDE_SPM_ADDR((uint64_t)c)};
    job_args_t job_args;
    job_args.gemm = gemm_args;
    job_t gemm = {J_GEMM, 0, job_args};
    job_t jobs[N_JOBS] = {gemm, gemm};
#elif defined(OFFLOAD_MONTECARLO)
    mc_args_t mc_args = {MC_LENGTH / (8 * n_clusters_to_use),
                         WIDE_SPM_ADDR((uint64_t)&pi)};
    job_args_t job_args;
    job_args.mc = mc_args;
    job_t mc = {J_MONTECARLO, 0, job_args};
    job_t jobs[N_JOBS] = {mc, mc};
#elif defined(OFFLOAD_KMEANS)
    kmeans_args_t kmeans_first_iter_args = {
        n_samples, n_features, n_clusters, 0,
        WIDE_SPM_ADDR((uint64_t)samples),
        WIDE_SPM_ADDR((uint64_t)centroids)
    };
    kmeans_args_t kmeans_succ_iter_args = {
        n_samples, n_features, n_clusters, 1,
        WIDE_SPM_ADDR((uint64_t)samples),
        WIDE_SPM_ADDR((uint64_t)centroids)
    };
    job_args_t first_job_args, succ_job_args;
    first_job_args.kmeans = kmeans_first_iter_args;
    succ_job_args.kmeans = kmeans_succ_iter_args;
    job_t first_iter_kmeans = {J_KMEANS, 0, first_job_args};
    job_t succ_iter_kmeans = {J_KMEANS, 0, succ_job_args};
    job_t jobs[N_JOBS];
    jobs[0] = first_iter_kmeans;
    for (uint32_t i = 1; i < N_JOBS; i++) jobs[i] = succ_iter_kmeans;
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

    // Retrieve destination for job information in first cluster's TCDM
    uint64_t l1_job_ptr = (uint64_t)usr_data.local_job_addr;

    // Send jobs (first iteration just to heat up I$)
    for (uint32_t i = 0; i < n_jobs; i++) {
        mcycle();  // Send job information
        send_job_and_wakeup(&jobs[i], l1_job_ptr);

        mcycle();  // Wait for job done
        wait_sw_interrupt();

        mcycle();  // Resume operation on host
        clear_host_sw_interrupt_unsafe();

#ifdef OFFLOAD_KMEANS
        mcycle();
        kmeans_host(l1_job_ptr, (kmeans_args_t *)&(jobs[i].args));
#endif
    }
    mcycle();

#if defined(OFFLOAD_AXPY)
    // Copy results from wide SPM to DRAM for verification
    sys_dma_blk_memcpy((uint64_t)z, WIDE_SPM_ADDR((uint64_t)z),
                       n * sizeof(double));
#elif defined(OFFLOAD_GEMM)
    // Copy results from wide SPM to DRAM for verification
    sys_dma_blk_memcpy((uint64_t)c, WIDE_SPM_ADDR((uint64_t)c),
                       M * N * sizeof(double));
#elif defined(OFFLOAD_KMEANS)
    // Copy results from wide SPM to DRAM for verification
    sys_dma_blk_memcpy((uint64_t)centroids, WIDE_SPM_ADDR((uint64_t)centroids),
                       n_clusters * n_features * sizeof(double));
#elif defined(OFFLOAD_MONTECARLO)
    double pi_estimate = *((double *)mc_args.result_ptr);
    double err = fabs(pi_estimate - 3.14);
    if (err > 0.5) return 1;
#endif

    // Exit routine
    mcycle();

    return 0;
}
