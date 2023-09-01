# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Usage of absolute paths is required to externally include this Makefile
MK_DIR   := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SRC_DIR  := $(realpath $(MK_DIR)/src)

APP     ?= sanity
SRCS    ?= $(SRC_DIR)/sanity.c

include ../common.mk

$(DEP): $(DATA_H)
