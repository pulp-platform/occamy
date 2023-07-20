# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>
# Gianna Paulin <pauling@iis.ee.ethz.ch>

# Usage of absolute paths is required to externally include
# this Makefile from multiple different locations
MK_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
include $(MK_DIR)/../../toolchain.mk

SNITCH_ROOT := $(realpath $(MK_DIR)/../../../../../../deps/snitch_cluster/)

###################
# Build variables #
###################

#############
# snRuntime #
#############
# Directories

CUR_DIR     := $(realpath $(MK_DIR)/.)
SNRT_DIR    := $(realpath $(SNITCH_ROOT)/sw/snRuntime)
SNRT_DIR    := $(shell bender path snitch_cluster)/sw/snRuntime
SNDNN_DIR   := $(shell bender path snitch_cluster)/sw/snDNN

# SNRT_DIR    := $(realpath $(MK_DIR)/../../../../../sw/snRuntime)
# ifeq (SELECT_RUNTIME, banshee)
RUNTIME_DIR := $(realpath $(MK_DIR)/../../runtime)
# else
# RUNTIME_DIR := $(realpath $(MK_DIR)/../../runtime/rtl)
# endif

# Dependencies
INCDIRS += $(RUNTIME_DIR)/src
# INCDIRS += $(RUNTIME_DIR)/../../shared
INCDIRS += $(RUNTIME_DIR)/../../shared/platform
INCDIRS += $(RUNTIME_DIR)/../../shared/platform/generated
INCDIRS += $(RUNTIME_DIR)/../../shared/runtime
INCDIRS += $(SNRT_DIR)/api
INCDIRS += $(SNRT_DIR)/api/omp
INCDIRS += $(SNRT_DIR)/src
INCDIRS += $(SNRT_DIR)/src/omp
INCDIRS += $(SNRT_DIR)/vendor/riscv-opcodes

# Directories
BUILDDIR = $(abspath $(CUR_DIR)/build/)
SRC_DIR  = $(abspath $(CUR_DIR)/src/)
SW_DIR   = $(abspath $(CUR_DIR)/../../)
# SNRT_DIR = $(shell bender path snitch_cluster)/sw/snRuntime
# SNDNN_DIR  = $(shell bender path snitch_cluster)/sw/snDNN

# Dependencies
# INCDIRS += $(SNRT_DIR)/src
# INCDIRS += $(SNRT_DIR)/src/omp
# INCDIRS += $(SNRT_DIR)/api
# INCDIRS += $(SNRT_DIR)/api/omp
# INCDIRS += $(SNRT_DIR)/vendor/riscv-opcodes
# INCDIRS += $(SW_DIR)/shared/platform
# INCDIRS += $(SW_DIR)/shared/platform/generated
# INCDIRS += $(SW_DIR)/shared/runtime
# SRCS += $(SRC_DIR)/occamy_start.S
# SRCS += $(SRC_DIR)/snrt.c

#########
# snDNN #
#########
# Directories
BUILDDIR      = $(abspath build/)
# SNDNN_DIR     = $(realpath $(SNITCH_ROOT)/sw/snDNN)
SRC_DIR       = $(SNDNN_DIR)/src
SRC_DIR_LAYER = $(CUR_DIR)/src

# Dependencies
INCDIRS += $(SNDNN_DIR)/src
INCDIRS += $(SNDNN_DIR)/include
INCDIRS += $(CUR_DIR)/src/

SRCS += $(CUR_DIR)/src/sndnn.c

###########
# Outputs #
###########

OBJS        = $(addprefix $(BUILDDIR)/,$(addsuffix .o,$(basename $(notdir $(SRCS)))))
DEPS        = $(addprefix $(BUILDDIR)/,$(addsuffix .d,$(basename $(notdir $(SRCS)))))
LIB         = $(BUILDDIR)/libsnDNN.a
DUMP        = $(BUILDDIR)/libsnDNN.dump
ALL_OUTPUTS = $(LIB) $(DUMP)

#########
# Rules #
#########

.PHONY: all
all: $(ALL_OUTPUTS)

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)

$(BUILDDIR):
	mkdir -p $@

$(BUILDDIR)/%.o: $(SRC_DIR_LAYER)/%.S | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -c $< -o $@

$(BUILDDIR)/%.o: $(SRC_DIR_LAYER)/%.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -c $< -o $@

$(BUILDDIR)/%.d: $(SRC_DIR_LAYER)/%.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -MM -MT '$(@:.d=.o)' $< > $@

###########
# Library #
###########
$(LIB): $(OBJS) | $(BUILDDIR)
	$(RISCV_AR) $(RISCV_ARFLAGS) $@ $^

$(DUMP): $(LIB) | $(BUILDDIR)
	$(RISCV_OBJDUMP) -D $< > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif
