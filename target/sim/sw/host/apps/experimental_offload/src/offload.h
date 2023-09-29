// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

typedef struct {
    volatile uint32_t l3_job_ptr;
    volatile uint32_t l1_job_ptr;
} usr_data_t;

typedef enum { J_AXPY = 0, J_GEMM = 1, J_MONTECARLO = 2 } job_id_t;

//////////
// AXPY //
//////////

typedef struct {
    uint32_t l;
    double a;
    uint64_t x_ptr;
    uint64_t y_ptr;
    uint64_t z_ptr;
} axpy_args_t;

typedef struct {
    uint32_t l;
    double a;
    uint64_t x_l3_ptr;
    uint64_t y_l3_ptr;
    uint64_t z_l3_ptr;
    double* x;
    double* y;
    double* z;
} axpy_local_args_t;

typedef struct {
    job_id_t id;
    uint8_t offload_id;
    axpy_args_t args;
} axpy_job_t;

typedef struct {
    job_id_t id;
    uint8_t offload_id;
    axpy_local_args_t args;
} axpy_local_job_t;

//////////
// GEMM //
//////////

typedef struct {
    uint32_t m;
    uint32_t n;
    uint32_t k;
    uint64_t a_ptr;
    uint64_t b_ptr;
    uint64_t c_ptr;
} gemm_args_t;

typedef struct {
    uint32_t m;
    uint32_t n;
    uint32_t k;
    uint64_t a_l3_ptr;
    uint64_t b_l3_ptr;
    uint64_t c_l3_ptr;
    double* a;
    double* b;
    double* c;
} gemm_local_args_t;

typedef struct {
    job_id_t id;
    uint8_t offload_id;
    gemm_args_t args;
} gemm_job_t;

typedef struct {
    job_id_t id;
    uint8_t offload_id;
    gemm_local_args_t args;
} gemm_local_job_t;

/////////////////
// Monte Carlo //
/////////////////

typedef struct {
    uint32_t n_samples;
    uint64_t result_ptr;
} mc_args_t;

typedef struct {
    job_id_t id;
    uint8_t offload_id;
    mc_args_t args;
} mc_job_t;

/////////////
// Generic //
/////////////

typedef struct {
    uint64_t job_ptr;
} user_data_t;

typedef union {
    axpy_args_t axpy;
    gemm_args_t gemm;
    mc_args_t mc;
} job_args_t;

typedef struct {
    job_id_t id;
    uint8_t offload_id;
    job_args_t args;
} job_t;
