// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef SNRT_H
#define SNRT_H

#include <stddef.h>
#include <stdint.h>

// Occamy specific definitions
#include "occamy_defs.h"
#include "occamy_memory_map.h"
#include "sys_dma.h"

// Forward declarations
#include "alloc_decls.h"
#include "cls_decls.h"
#include "cluster_interrupt_decls.h"
#include "global_interrupt_decls.h"
#include "memory_decls.h"
#include "start_decls.h"
#include "sync_decls.h"
#include "team_decls.h"

// Implementation
#include "alloc.h"
#include "alloc_v2.h"
#include "cls.h"
#include "cluster_interrupts.h"
#include "dma.h"
#include "dump.h"
#include "global_interrupts.h"
#include "mcast.h"
#include "occamy_device.h"
#include "occamy_memory.h"
#include "occamy_start.h"
#include "printf.h"
#include "riscv.h"
#include "ssr.h"
#include "sync.h"
#include "team.h"
#include "types.h"

#endif  // SNRT_H
