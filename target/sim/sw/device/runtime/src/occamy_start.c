// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#define SNRT_INIT_TLS
#define SNRT_INIT_BSS
#define SNRT_CRT0_CALLBACK3
#define SNRT_INIT_LIBS
#define SNRT_CRT0_PRE_BARRIER
#define SNRT_INVOKE_MAIN
#define SNRT_CRT0_POST_BARRIER
#define SNRT_CRT0_EXIT
#define SNRT_CRT0_ALTERNATE_EXIT

static inline void snrt_crt0_callback3() {
    _snrt_cluster_hw_barrier = cluster_hw_barrier_addr(snrt_cluster_idx());
}

static inline uint32_t* snrt_exit_code_destination() {
    return soc_ctrl_scratch_ptr(3);
}

static inline void snrt_exit_default(int exit_code);

void snrt_exit(int exit_code) {
    snrt_exit_default(exit_code);
    if (snrt_global_core_idx() == 0) set_host_sw_interrupt();
}

#include "start.c"
