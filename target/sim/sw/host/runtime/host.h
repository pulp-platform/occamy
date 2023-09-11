// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stddef.h>
#include <stdint.h>

#define CLUSTER_BCAST_MASK ((N_CLUSTERS - 1) << 18)

void delay_ns(uint64_t delay);

static inline volatile uint32_t* get_shared_lock();

static inline void set_sw_interrupt(uint32_t hartid);

static inline void wait_sw_interrupt();

static inline void enable_multicast(uint64_t mask);

static inline void disable_multicast();

static inline void multicast(uint64_t addr, uint64_t mask, uint64_t value);

static inline void multicast_to_clusters(uint64_t addr, uint64_t value);
