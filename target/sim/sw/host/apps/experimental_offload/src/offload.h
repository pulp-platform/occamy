// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

typedef struct {
    volatile uint32_t l3_job_ptr;
    volatile uint32_t l1_job_ptr;
} usr_data_t;

typedef enum { J_AXPY = 0, J_MONTECARLO = 1 } job_id_t;

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
    mc_args_t mc;
} job_args_t;

typedef struct {
    job_id_t id;
    uint8_t offload_id;
    job_args_t args;
} job_t;
