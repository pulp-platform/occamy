# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

APP     = hello_world
SRC_DIR = $(SW_DIR)/host/apps/$(APP)/src
SRCS    = $(SRC_DIR)/main.c

include $(SW_DIR)/host/apps/common.mk
