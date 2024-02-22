# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

BENDER ?= bender
SNITCH_ROOT = $(shell $(BENDER) path snitch_cluster)
RISCV_CFLAGS += --sysroot=$(HERO_INSTALL)/rv32imafd-ilp32d/riscv32-unknown-elf -target riscv32-unknown-elf
RISCV_LDFLAGS += -L$(HERO_INSTALL)/lib/clang/15.0.0/rv32imafdvzfh-ilp32d/lib/
include $(SNITCH_ROOT)/target/snitch_cluster/sw/toolchain.mk
