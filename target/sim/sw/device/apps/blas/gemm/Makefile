# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

include $(abspath ../../common.mk)

APP              := gemm
$(APP)_BUILD_DIR ?= $(SNITCH_ROOT)/target/snitch_cluster/sw/apps/blas/$(APP)/build
SRC_DIR          := $(SNITCH_ROOT)/sw/blas/$(APP)/src
SRCS             := $(SRC_DIR)/main.c
$(APP)_INCDIRS   := $(SNITCH_ROOT)/sw/blas

include $(SNITCH_ROOT)/sw/apps/common.mk
include $(SNITCH_ROOT)/target/snitch_cluster/sw/apps/common.mk

