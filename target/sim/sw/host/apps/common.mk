# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

######################
# Invocation options #
######################

DEBUG ?= OFF # ON to turn on debugging symbols

###################
# Build variables #
###################

# Usage of absolute paths is required to externally include this Makefile
MK_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

include $(MK_DIR)/../toolchain.mk

# Directories
BUILDDIR    = $(abspath build)
HOST_DIR    = $(abspath ../../)
RUNTIME_DIR = $(abspath $(HOST_DIR)/runtime)
DEVICE_DIR  = $(abspath $(HOST_DIR)/../device)

# Dependencies
INCDIRS += $(RUNTIME_DIR)
INCDIRS += $(HOST_DIR)/../shared/platform/generated
INCDIRS += $(HOST_DIR)/../shared/platform
INCDIRS += $(HOST_DIR)/../shared/runtime
SRCS    += $(RUNTIME_DIR)/start.S

# Device binary
ifeq ($(INCL_DEVICE_BINARY),true)
DEVICE_BUILDDIR = $(DEVICE_DIR)/apps/$(APP)/build
DEVICE_BINARY   = $(DEVICE_BUILDDIR)/$(APP).bin
ORIGIN_LD       = $(DEVICE_BUILDDIR)/origin.ld
FINAL_CFLAGS    = -DDEVICEBIN=\"$(DEVICE_BINARY)\"
endif

###########
# Outputs #
###########

PARTIAL_ELF     = $(abspath $(BUILDDIR)/$(APP).part.elf)
ELF             = $(abspath $(BUILDDIR)/$(APP).elf)
DEP             = $(abspath $(BUILDDIR)/$(APP).d)
PARTIAL_DUMP    = $(abspath $(BUILDDIR)/$(APP).part.dump)
DUMP            = $(abspath $(BUILDDIR)/$(APP).dump)
DWARF           = $(abspath $(BUILDDIR)/$(APP).dwarf)
PARTIAL_OUTPUTS = $(PARTIAL_ELF) $(PARTIAL_DUMP) $(ORIGIN_LD)
FINAL_OUTPUTS   = $(ELF) $(DUMP) $(DWARF)

#########
# Rules #
#########

.PHONY: partial-build
partial-build: $(PARTIAL_OUTPUTS)

.PHONY: finalize-build
finalize-build: $(FINAL_OUTPUTS)

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)
	rm -f $(OFFSET_LD)

$(BUILDDIR):
	mkdir -p $@

$(DEVICE_BUILDDIR):
	mkdir -p $@

$(DEP): $(SRCS) | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -MM -MT '$(PARTIAL_ELF)' $< > $@
	$(RISCV_CC) $(RISCV_CFLAGS) -MM -MT '$(ELF)' $< >> $@

# Partially linked object
$(PARTIAL_ELF): $(DEP) $(LD_SRCS) | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) $(RISCV_LDFLAGS) $(SRCS) -o $@

$(PARTIAL_DUMP): $(PARTIAL_ELF) | $(BUILDDIR)
	$(RISCV_OBJDUMP) -D $< > $@

# Device object relocation address
$(ORIGIN_LD): $(PARTIAL_ELF) | $(DEVICE_BUILDDIR)
	@RELOC_ADDR=$$($(RISCV_OBJDUMP) -t $< | grep snitch_main | cut -c9-16); \
	echo "Writing device object relocation address 0x$$RELOC_ADDR to $@"; \
	echo "L3_ORIGIN = 0x$$RELOC_ADDR;" > $@

$(ELF): $(DEP) $(LD_SRCS) $(DEVICE_BINARY) | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) $(FINAL_CFLAGS) $(RISCV_LDFLAGS) $(SRCS) -o $@

$(DUMP): $(ELF) | $(BUILDDIR)
	$(RISCV_OBJDUMP) -D $< > $@

$(DWARF): $(ELF) | $(BUILDDIR)
	$(RISCV_READELF) --debug-dump $< > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(DEP)
endif
