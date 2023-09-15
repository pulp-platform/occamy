# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

BLAS_DIR = $(shell bender path snitch_cluster)/sw/blas

APP  = experimental_offload
SRCS = src/offload.c
INCDIRS = $(BLAS_DIR)
INCL_DEVICE_BINARY = true

# Define application and number of clusters to use
RISCV_CFLAGS ?= -DOFFLOAD_AXPY -DN_CLUSTERS_TO_USE=1

SECTION = .wide_spm

include $(BLAS_DIR)/axpy/Makefile
include ../common.mk

# Create data.h dependency
$(DEP): $(DATA_DIR)/data.h
