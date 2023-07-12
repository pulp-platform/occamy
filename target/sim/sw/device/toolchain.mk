# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

######################
# Invocation options #
######################

DEBUG ?= OFF # ON to turn on debugging symbols

###################
# Build variables #
###################

# Compiler toolchain
LLVM_BINROOT    ?= $(dir $(shell which riscv32-unknown-elf-clang))
RISCV_CC        ?= $(LLVM_BINROOT)/clang
RISCV_LD        ?= $(LLVM_BINROOT)/ld.lld
RISCV_AR        ?= $(LLVM_BINROOT)/llvm-ar
RISCV_OBJCOPY   ?= $(LLVM_BINROOT)/llvm-objcopy
RISCV_OBJDUMP   ?= $(LLVM_BINROOT)/llvm-objdump
RISCV_DWARFDUMP ?= $(LLVM_BINROOT)/llvm-dwarfdump
RISCV_READELF   ?= $(LLVM_BINROOT)/llvm-readelf
# RISCV_CC      = riscv32-unknown-elf-gcc
# RISCV_AR      = riscv32-unknown-elf-ar
# RISCV_OBJCOPY = riscv32-unknown-elf-objcopy
# RISCV_OBJDUMP = riscv32-unknown-elf-objdump
# RISCV_READELF = riscv32-unknown-elf-readelf

# Compiler flags
RISCV_CFLAGS += $(addprefix -I,$(INCDIRS))
ifeq ($(RISCV_CC), riscv32-unknown-elf-gcc)
RISCV_CFLAGS += -march=rv32imafd
RISCV_CFLAGS += -mno-fdiv
else
RISCV_CFLAGS += -mcpu=snitch
RISCV_CFLAGS += -menable-experimental-extensions
endif
RISCV_CFLAGS += -mabi=ilp32d
RISCV_CFLAGS += -mcmodel=medany
RISCV_CFLAGS += -ffast-math
RISCV_CFLAGS += -fno-builtin-printf
RISCV_CFLAGS += -fno-common
RISCV_CFLAGS += -O3
ifeq ($(DEBUG), ON)
RISCV_CFLAGS += -g
endif

# Archiver flags
RISCV_ARFLAGS = rcs
