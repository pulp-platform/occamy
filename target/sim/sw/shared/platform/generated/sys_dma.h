// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Generated register defines for idma_reg64_frontend

#ifndef _IDMA_REG64_FRONTEND_REG_DEFS_
#define _IDMA_REG64_FRONTEND_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif

// Number of dimensions available
#define IDMA_REG64_1D_PARAM_NUM_DIMS 1

// Register width
#define IDMA_REG64_1D_PARAM_REG_WIDTH 32

// Source Address
#define IDMA_REG64_FRONTEND_SRC_ADDR_REG_OFFSET 0xd8

// Destination Address
#define IDMA_REG64_FRONTEND_DST_ADDR_REG_OFFSET 0xd0

// Number of bytes
#define IDMA_REG64_FRONTEND_NUM_BYTES_REG_OFFSET 0xe0

// Configuration Register for DMA settings
#define IDMA_REG64_FRONTEND_CONF_REG_OFFSET 0
#define IDMA_REG64_FRONTEND_CONF_REG_DECOUPLE_AW_BIT 0
#define IDMA_REG64_FRONTEND_CONF_REG_DECOUPLE_RW_BIT 1
#define IDMA_REG64_FRONTEND_CONF_REG_SRC_REDUCE_LEN_BIT 2
#define IDMA_REG64_FRONTEND_CONF_REG_DST_REDUCE_LEN_BIT 3
#define IDMA_REG64_FRONTEND_CONF_REG_SRC_MAX_LLEN_MASK 0x7
#define IDMA_REG64_FRONTEND_CONF_REG_SRC_MAX_LLEN_OFFSET 4
#define IDMA_REG64_FRONTEND_CONF_REG_SRC_MAX_LLEN_FIELD \
  ((bitfield_field32_t) { .mask = IDMA_REG64_FRONTEND_CONF_REG_SRC_MAX_LLEN_MASK, .index = IDMA_REG64_FRONTEND_CONF_REG_SRC_MAX_LLEN_OFFSET })
#define IDMA_REG64_FRONTEND_CONF_REG_DST_MAX_LLEN_MASK 0x7
#define IDMA_REG64_FRONTEND_CONF_REG_DST_MAX_LLEN_OFFSET 7
#define IDMA_REG64_FRONTEND_CONF_REG_DST_MAX_LLEN_FIELD \
  ((bitfield_field32_t) { .mask = IDMA_REG64_FRONTEND_CONF_REG_DST_MAX_LLEN_MASK, .index = IDMA_REG64_FRONTEND_CONF_REG_DST_MAX_LLEN_OFFSET })
#define IDMA_REG64_FRONTEND_CONF_REG_ENABLE_ND_BIT 10


// DMA Status
#define IDMA_REG64_FRONTEND_STATUS_REG_OFFSET 0x4
#define IDMA_REG64_FRONTEND_STATUS_BUSY_BIT 0

// Next ID, launches transfer, returns 0 if transfer not set up properly.
#define IDMA_REG64_FRONTEND_NEXT_ID_REG_OFFSET 0x44

// Get ID of finished transactions.
#define IDMA_REG64_FRONTEND_DONE_REG_OFFSET 0x84

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _IDMA_REG64_FRONTEND_REG_DEFS_
// End generated register defines for idma_reg64_frontend

#include <stdint.h>

#include "occamy_memory_map.h"

#define IDMA_SRC_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_SRC_ADDR_REG_OFFSET)
#define IDMA_DST_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_DST_ADDR_REG_OFFSET)
#define IDMA_NUMBYTES_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_NUM_BYTES_REG_OFFSET)
#define IDMA_CONF_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_CONF_REG_OFFSET)
#define IDMA_STATUS_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_STATUS_REG_OFFSET)
#define IDMA_NEXTID_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_NEXT_ID_REG_OFFSET)
#define IDMA_DONE_ADDR \
    (SYS_IDMA_CFG_BASE_ADDR + IDMA_REG64_FRONTEND_DONE_REG_OFFSET)

#define IDMA_CONF_DECOUPLE_AW 0
#define IDMA_CONF_DECOUPLE_RW 0
#define IDMA_CONF_REDUCE_LLEN 0

inline volatile uint64_t *sys_dma_src_ptr(void) {
    return (volatile uint64_t *)IDMA_SRC_ADDR;
}
inline volatile uint64_t *sys_dma_dst_ptr(void) {
    return (volatile uint64_t *)IDMA_DST_ADDR;
}
inline volatile uint64_t *sys_dma_num_bytes_ptr(void) {
    return (volatile uint64_t *)IDMA_NUMBYTES_ADDR;
}
inline volatile uint64_t *sys_dma_conf_ptr(void) {
    return (volatile uint64_t *)IDMA_CONF_ADDR;
}
inline volatile uint64_t *sys_dma_status_ptr(void) {
    return (volatile uint64_t *)IDMA_STATUS_ADDR;
}
inline volatile uint64_t *sys_dma_nextid_ptr(void) {
    return (volatile uint64_t *)IDMA_NEXTID_ADDR;
}
inline volatile uint64_t *sys_dma_done_ptr(void) {
    return (volatile uint64_t *)IDMA_DONE_ADDR;
}

inline uint64_t sys_dma_memcpy(uint64_t dst, uint64_t src, uint64_t size) {
    *(sys_dma_src_ptr()) = (uint64_t)src;
    *(sys_dma_dst_ptr()) = (uint64_t)dst;
    *(sys_dma_num_bytes_ptr()) = size;
    *(sys_dma_conf_ptr()) =
        (IDMA_CONF_DECOUPLE_AW << IDMA_REG64_FRONTEND_CONF_REG_DECOUPLE_AW_BIT) |
        (IDMA_CONF_DECOUPLE_RW << IDMA_REG64_FRONTEND_CONF_REG_DECOUPLE_RW_BIT) |
        (IDMA_CONF_REDUCE_LLEN << IDMA_REG64_FRONTEND_CONF_REG_SRC_REDUCE_LEN_BIT) |
        (IDMA_CONF_REDUCE_LLEN << IDMA_REG64_FRONTEND_CONF_REG_DST_REDUCE_LEN_BIT);
    return *(sys_dma_nextid_ptr());
}

inline void sys_dma_blk_memcpy(uint64_t dst, uint64_t src, uint64_t size) {
    volatile uint64_t tf_id = sys_dma_memcpy(dst, src, size);

    while (*(sys_dma_done_ptr()) != tf_id) {
        asm volatile("nop");
    }
}
