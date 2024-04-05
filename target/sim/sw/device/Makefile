# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Add user applications to APPS variable
# APPS  = blas/axpy
# APPS += blas/gemm
# APPS += kmeans
# APPS += mcast
APPS = experimental_offload

TARGET ?= all

APP_SUBDIRS = $(addprefix apps/,$(APPS))

SUBDIRS  = runtime
SUBDIRS += $(APP_SUBDIRS)

.PHONY: all $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(TARGET)

# Explicit dependency of apps on runtime
$(APP_SUBDIRS): runtime
