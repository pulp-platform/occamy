// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

#include "idma.h"
#include "occamy_memory_map.h"

inline void sys_dma_write_reg64(uint64_t offset, uint64_t value) {
    *(volatile uint64_t *)(SYS_IDMA_CFG_BASE_ADDR + offset) = value;
}

inline uint64_t sys_dma_read_reg64(uint64_t offset) {
    return *(volatile uint64_t *)(SYS_IDMA_CFG_BASE_ADDR + offset);
}

inline void sys_dma_write_reg32(uint32_t offset, uint32_t value) {
    *(volatile uint32_t *)(uintptr_t)(SYS_IDMA_CFG_BASE_ADDR + offset) = value;
}

inline uint32_t sys_dma_read_reg32(uint32_t offset) {
    return *(volatile uint32_t *)(uintptr_t)(SYS_IDMA_CFG_BASE_ADDR + offset);
}

inline uint32_t sys_dma_memcpy(uint64_t dst, uint64_t src, uint64_t size) {
    sys_dma_write_reg32(IDMA_REG64_1D_SRC_ADDR_LOW_REG_OFFSET, src);
    sys_dma_write_reg32(IDMA_REG64_1D_SRC_ADDR_HIGH_REG_OFFSET, src >> 32);
    sys_dma_write_reg32(IDMA_REG64_1D_DST_ADDR_LOW_REG_OFFSET, dst);
    sys_dma_write_reg32(IDMA_REG64_1D_DST_ADDR_HIGH_REG_OFFSET, dst >> 32);
    sys_dma_write_reg32(IDMA_REG64_1D_LENGTH_LOW_REG_OFFSET, size);
    sys_dma_write_reg32(IDMA_REG64_1D_LENGTH_HIGH_REG_OFFSET, size >> 32);
    return sys_dma_read_reg32(IDMA_REG64_1D_NEXT_ID_0_REG_OFFSET);
}

inline void sys_dma_blk_memcpy(uint64_t dst, uint64_t src, uint64_t size) {
    volatile uint32_t tf_id = sys_dma_memcpy(dst, src, size);

    while (sys_dma_read_reg32(IDMA_REG64_1D_DONE_ID_0_REG_OFFSET) != tf_id)
        ;
}
