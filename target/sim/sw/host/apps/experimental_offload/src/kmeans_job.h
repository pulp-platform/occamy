// Copyright 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Author: Luca Colagrande <colluca@iis.ee.ethz.ch>

#define ALIGN_UP(addr, size) (((addr) + (size)-1) & ~((size)-1))

void kmeans_host(uint64_t device_l1_base, kmeans_args_t* args) {
    // Aliases
    uint32_t n_features = args->n_features;
    uint32_t n_clusters = args->n_clusters;
    volatile double *centroids = (volatile double *)(args->centroids_addr);

    // Retrieve partial_centroids and partial_membership_cnt base addresses
    size_t args_size = sizeof(kmeans_args_t);
    uint64_t partial_centroids_addr = ALIGN_UP(device_l1_base + args_size, sizeof(double));
    size_t partial_centroids_size = 8 * n_clusters * n_features * sizeof(double);
    uint64_t partial_membership_cnt_addr = ALIGN_UP(partial_centroids_addr + partial_centroids_size, sizeof(uint32_t));

    // Initialize accumulators
    uint32_t membership_cnt[n_clusters];
    for (uint32_t centroid_idx = 0; centroid_idx < n_clusters; centroid_idx++) {
        membership_cnt[centroid_idx] = 0;
        for (uint32_t feature_idx = 0; feature_idx < n_features; feature_idx++) {
            centroids[centroid_idx * n_features + feature_idx] = 0;
        }
    }

    // Reduce partial_centroids and partial_membership_cnt from all clusters
    for (volatile uint32_t cluster_idx = 0; cluster_idx < n_clusters_to_use; cluster_idx++) {
        
        // Pointers to variables of remote cluster
        volatile uint32_t *partial_membership_cnt = (volatile uint32_t *)(partial_membership_cnt_addr + cluster_idx * cluster_offset);
        volatile double *partial_centroids = (volatile double *)(partial_centroids_addr + cluster_idx * cluster_offset);
        
        for (uint32_t centroid_idx = 0; centroid_idx < n_clusters; centroid_idx++) {
        
            // Accumulate membership counters
            membership_cnt[centroid_idx] += partial_membership_cnt[centroid_idx];
        
            // Accumulate centroid features
            for (uint32_t feature_idx = 0; feature_idx < n_features; feature_idx++) {
                centroids[centroid_idx * n_features + feature_idx] +=
                    partial_centroids[centroid_idx * n_features + feature_idx];
            }
        }
    }

    // Normalize results
    for (uint32_t centroid_idx = 0; centroid_idx < n_clusters; centroid_idx++) {
        for (uint32_t feature_idx = 0; feature_idx < n_features; feature_idx++) {
            centroids[centroid_idx * n_features + feature_idx] /= membership_cnt[centroid_idx];
        }
    }
}