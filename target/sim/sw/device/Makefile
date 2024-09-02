# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Add user applications to APPS variable
APPS  = blas/axpy
APPS += blas/gemm

TARGET ?= sw

APP_SUBDIRS = $(addprefix apps/,$(APPS))

SUBDIRS  = runtime
SUBDIRS += $(APP_SUBDIRS)

SUBMK_FLAGS = SNRT_TARGET_DIR=$(abspath runtime)

.PHONY: sw $(SUBDIRS)

sw: $(SUBDIRS)

$(SUBDIRS):
	$(SUBMK_FLAGS) $(MAKE) -C $@ $(TARGET)

# Explicit dependency of apps on runtime
$(APP_SUBDIRS): runtime
