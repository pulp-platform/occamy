// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

extern void sys_dma_write_reg64(uint64_t offset, uint64_t value);
extern uint64_t sys_dma_read_reg64(uint64_t offset);
extern void sys_dma_write_reg32(uint32_t offset, uint32_t value);
extern uint32_t sys_dma_read_reg32(uint32_t offset);

extern uint32_t sys_dma_memcpy(uint64_t dst, uint64_t src, uint64_t size);
extern void sys_dma_blk_memcpy(uint64_t dst, uint64_t src, uint64_t size);
