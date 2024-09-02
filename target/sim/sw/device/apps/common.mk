# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Usage of absolute paths is required to externally include
# this Makefile from multiple different locations
MK_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
ROOT = $(abspath $(MK_DIR)/../../../../../)

SNITCH_ROOT = $(shell bender path snitch_cluster)
include $(SNITCH_ROOT)/target/snitch_cluster/sw/toolchain.mk

SNRT_DIR      = $(SNITCH_ROOT)/sw/snRuntime
SW_DIR        = $(ROOT)/target/sim/sw
SNRT_BUILDDIR = $(SW_DIR)/device/runtime/build
# Path relative to the app including this Makefile
BUILDDIR = $(abspath build)

RISCV_CFLAGS += -I$(SNRT_DIR)/src
RISCV_CFLAGS += -I$(SNRT_DIR)/api
RISCV_CFLAGS += -I$(SNRT_DIR)/src/omp
RISCV_CFLAGS += -I$(SNRT_DIR)/api/omp
RISCV_CFLAGS += -I$(SNRT_DIR)/vendor/riscv-opcodes
RISCV_CFLAGS += -I$(SW_DIR)/device/runtime/src
RISCV_CFLAGS += -I$(SW_DIR)/shared/platform/generated
RISCV_CFLAGS += -I$(SW_DIR)/shared/platform
RISCV_CFLAGS += -I$(SW_DIR)/shared/runtime

# Linker paths
MEMORY_LD      = $(SW_DIR)/device/apps/memory.ld
$(info memory.ld path: $(MEMORY_LD))
ORIGIN_LD      = $(BUILDDIR)/origin.ld
RISCV_LDFLAGS += -L$(dir $(ORIGIN_LD))
