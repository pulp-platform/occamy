# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Cyril Koenig <cykoenig@iis.ee.ethz.ch>

# Usage of absolute paths is required to externally include this Makefile
MK_DIR   := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SRC_DIR  := $(realpath $(MK_DIR)/src)

APP     ?= omptarget_device
SRCS    ?= $(SRC_DIR)/main.c
INCDIRS += $(SRC_DIR)

.PHONY: clean
clean:

include ../common.mk

OBJS    := $(subst $(SRC_DIR), $(BUILDDIR), $(SRCS:.c=.o))
LIB     := $(BUILDDIR)/libomptarget_device.a

$(BUILDDIR)/origin.ld: | $(BUILDDIR)
	echo "L3_ORIGIN = 0x80000000;" > $(BUILDDIR)/origin.ld

$(LIB): $(OBJS) | $(BUILDDIR)
	$(RISCV_AR) $(RISCV_ARFLAGS) $@ $^

# For this target, only build the library
all: $(LIB)
