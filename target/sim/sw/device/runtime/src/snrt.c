// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#define UART_PRINTF

#include "snrt.h"

#include "alloc.c"
#include "cls.c"
#include "cluster_interrupts.c"
#include "dma.c"
#include "global_interrupts.c"
#include "occamy_device.c"
#include "occamy_memory.c"
#include "occamy_start.c"
#include "printf.c"
#ifdef UART_PRINTF
    #include "putchar_chip.c"
#else
    #include "putchar_sim.c"
#endif
#include "sync.c"
#include "sys_dma.c"
#include "team.c"
