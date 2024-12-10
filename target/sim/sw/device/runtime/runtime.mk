# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

SNRT_TARGET_DIR   = $(SW_DIR)/device/runtime
SNRT_HAL_HDRS_DIR = $(PLATFORM_HEADERS_DIR)
SNRT_HAL_HDRS     = $(PLATFORM_HEADERS)
SNRT_INCDIRS      = $(SW_DIR)/shared/runtime

include $(SNITCH_ROOT)/target/snitch_cluster/sw/runtime/runtime.mk
