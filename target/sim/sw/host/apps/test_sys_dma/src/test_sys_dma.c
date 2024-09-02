// Copyright 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "host.c"

#define LENGTH 32

// Allocate buffers in main memory which we will use to copy data around
// with the DMA.
volatile uint32_t dst_buffer[LENGTH];
volatile uint32_t src_buffer[LENGTH];

int main() {
    uint32_t errors = LENGTH * 3;

    // Populate buffers.
    for (uint32_t i = 0; i < LENGTH; i++) {
        dst_buffer[i] = 0x55555555;
        src_buffer[i] = i + 1;
    }

    // Flush values out of cache.
    fence();

    // Check that the buffers are properly initialized.
    for (uint32_t i = 0; i < LENGTH; i++) {
        errors -= dst_buffer[i] == 0x55555555;
        errors -= src_buffer[i] == i + 1;
    }

    // Flush values out of cache.
    fence();

    // Copy data to main memory.
    sys_dma_blk_memcpy((uint64_t)dst_buffer, (uint64_t)src_buffer,
                       sizeof(src_buffer));

    // Flush values out of cache.
    fence();

    // Check that the main memory buffer contains the correct data.
    for (uint32_t i = 0; i < LENGTH; i++) {
        errors -= dst_buffer[i] == (i + 1);
    }

    return errors;
}
