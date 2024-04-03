#define KMEANS_REDUCTION_ON_HOST
#include "kmeans/src/kmeans.h"

__thread uint32_t n_samples_per_cluster, n_samples_per_core;
__thread double *local_samples, *local_centroids, *final_centroids, *partial_centroids;
__thread uint32_t *membership, *partial_membership_cnt;

void kmeans_iteration_job(job_args_t* job_args) {
    kmeans_args_t *args = (kmeans_args_t *)job_args;

    // Aliases
    uint32_t n_samples = args->n_samples;
    uint32_t n_features = args->n_features;
    uint32_t n_clusters = args->n_clusters;
    uint32_t first_iter = args->n_iter == 0;
    void *samples = (void *)(args->samples_addr);
    void *centroids = (void *)(args->centroids_addr);

    snrt_mcycle();

    // Initialize variables only on first iteration
    if (first_iter) {
        // Distribute work
        n_samples_per_cluster = n_samples / snrt_cluster_num();
        n_samples_per_core = n_samples_per_cluster / snrt_cluster_compute_core_num();

        // Dynamically allocate space in TCDM
        // First core's partial centroids will store final centroids
        partial_centroids = snrt_l1_alloc_compute_core_local(
            n_clusters * n_features * sizeof(double), sizeof(double));
        final_centroids = snrt_compute_core_local_ptr(
            partial_centroids,
            0,
            n_clusters * n_features * sizeof(double)
        );
        final_centroids = snrt_remote_l1_ptr(final_centroids, snrt_cluster_idx(), 0);
        partial_membership_cnt = snrt_l1_alloc_compute_core_local(
            n_clusters * sizeof(uint32_t), sizeof(uint32_t));
        local_samples = snrt_l1_alloc_cluster_local(
            n_samples_per_cluster * n_features * sizeof(double), sizeof(double));
        local_centroids = snrt_l1_alloc_cluster_local(
            n_clusters * n_features * sizeof(double), sizeof(double));
        membership = snrt_l1_alloc_cluster_local(
            n_samples_per_cluster * sizeof(uint32_t), sizeof(uint32_t));

        snrt_mcycle();
    }

    // Transfer samples and initial centroids with DMA
    size_t size;
    size_t offset;
    if (snrt_is_dm_core()) {
        // Samples are transferred only on first iteration
        if (first_iter) {
            size = n_samples_per_cluster * n_features * sizeof(double);
            offset = snrt_cluster_idx() * size;
            snrt_dma_start_1d((void*)local_samples, (void*)samples + offset, size);
        }
        size = n_clusters * n_features * sizeof(double);
        snrt_dma_start_1d((void*)local_centroids, (void*)centroids, size);
        snrt_dma_wait_all();
    }

    snrt_cluster_hw_barrier();

    snrt_mcycle();

    kmeans_iteration(n_samples_per_core, n_clusters, n_features, local_samples, membership, partial_membership_cnt, local_centroids, partial_centroids);
}