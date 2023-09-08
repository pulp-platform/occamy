// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "host.c"

// Frequency at which the UART peripheral is clocked
#define PERIPH_FREQ 1000000000

int main() {
    init_uart(PERIPH_FREQ, 115200);
    asm volatile("fence" : : : "memory");
    print_uart("Hello world!\r\n");
    // Artificial delay to ensure last symbol has been transmitted
    // (just waiting for the UART TSR register to be empty is not sufficient)
    for (int i = 0; i < 5000; i++) asm volatile("nop" : : : "memory");
    return 0;
}
