# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

APP              := axpy
$(APP)_BUILD_DIR := $(SW_DIR)/device/apps/blas/$(APP)/build
SRC_DIR          := $(SNITCH_ROOT)/sw/blas/$(APP)/src
SRCS             := $(SRC_DIR)/main.c

include $(SNITCH_ROOT)/sw/apps/common.mk
include $(SW_DIR)/device/apps/common.mk
