# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

SNITCH_CLUSTER_DIR = $(shell bender path snitch_cluster)

APP      = experimental_offload
SRCS     = src/offload.c
INCDIRS  = ../../../host/apps/experimental_offload/src
INCDIRS += $(SNITCH_CLUSTER_DIR)/sw/blas/axpy/src
INCDIRS += $(SNITCH_CLUSTER_DIR)/sw/apps/prng
INCDIRS += $(SNITCH_CLUSTER_DIR)/sw/apps/montecarlo/pi_estimation

# Define application and number of clusters to use
RISCV_CFLAGS ?= -DOFFLOAD_AXPY -DN_CLUSTERS_TO_USE=1

include ../common.mk
