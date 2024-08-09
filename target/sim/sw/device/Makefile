# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Add user applications to APPS variable automatically. This is located in the apps directory with depth of 2.

APPDIR  = $(shell find apps -mindepth 2 -maxdepth 2 -type d)
TARGET ?= all

RTDIR    = runtime
RTDIR   += math

RTDIR   += $(shell find snax -mindepth 1 -maxdepth 1 -type d)

.PHONY: all $(RTDIR) $(APPDIR)

all: $(APPDIR)

$(RTDIR):
	$(MAKE) -C $@ $(TARGET)

$(APPDIR): $(RTDIR)
	$(MAKE) -C $@ $(TARGET)
