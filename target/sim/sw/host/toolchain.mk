# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Compiler toolchain
HOST_RISCV_GCC_BINROOT ?= $(dir $(shell which riscv32-unknown-elf-gcc))
HOST_RISCV_CC           = $(HOST_RISCV_GCC_BINROOT)/riscv64-unknown-elf-gcc
HOST_RISCV_OBJCOPY      = $(HOST_RISCV_GCC_BINROOT)/riscv64-unknown-elf-objcopy
HOST_RISCV_OBJDUMP      = $(HOST_RISCV_GCC_BINROOT)/riscv64-unknown-elf-objdump
HOST_RISCV_READELF      = $(HOST_RISCV_GCC_BINROOT)/riscv64-unknown-elf-readelf

# Compiler flags
HOST_RISCV_CFLAGS  = -march=rv64imafdc
HOST_RISCV_CFLAGS += -mabi=lp64d
HOST_RISCV_CFLAGS += -mcmodel=medany
HOST_RISCV_CFLAGS += -ffast-math
HOST_RISCV_CFLAGS += -fno-builtin-printf
HOST_RISCV_CFLAGS += -fno-common
HOST_RISCV_CFLAGS += -O3
HOST_RISCV_CFLAGS += -ffunction-sections
HOST_RISCV_CFLAGS += -Wextra
HOST_RISCV_CFLAGS += -Werror
ifeq ($(DEBUG), ON)
HOST_RISCV_CFLAGS += -g
endif

# Linker flags
HOST_RISCV_LDFLAGS += -nostartfiles
HOST_RISCV_LDFLAGS += -lm
HOST_RISCV_LDFLAGS += -lgcc
