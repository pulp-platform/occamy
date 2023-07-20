# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Usage of absolute paths is required to externally include
# this Makefile from multiple different locations
MK_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

######################
# Invocation options #
######################

DEBUG ?= OFF # ON to turn on debugging symbols

###################
# Build variables #
###################

# Compiler toolchain
RISCV_CC      = riscv64-unknown-elf-gcc
RISCV_OBJCOPY = riscv64-unknown-elf-objcopy
RISCV_OBJDUMP = riscv64-unknown-elf-objdump
RISCV_READELF = riscv64-unknown-elf-readelf

# Directories
BUILDDIRS   = $(foreach LIB, $(LIBS), $(abspath $(MK_DIR)/$(APP)/build/$(LIB)))
BUILDDIR    = $(abspath $(MK_DIR)/$(APP)/build)
HOST_DIR    = $(abspath $(MK_DIR)/../)
RUNTIME_DIR = $(abspath $(HOST_DIR)/runtime)
DEVICE_DIR  = $(abspath $(HOST_DIR)/../device)

# Library names
LIBS = sndnn
LIBS += blas

# Dependencies
INCDIRS += $(RUNTIME_DIR)
INCDIRS += $(HOST_DIR)/../shared/platform/generated
INCDIRS += $(HOST_DIR)/../shared/platform
INCDIRS += $(HOST_DIR)/../shared/runtime
SRCS    += $(RUNTIME_DIR)/start.S

# Compiler flags
RISCV_CFLAGS += $(addprefix -I,$(INCDIRS))
RISCV_CFLAGS += -march=rv64imafdc
RISCV_CFLAGS += -mabi=lp64d
RISCV_CFLAGS += -mcmodel=medany
RISCV_CFLAGS += -ffast-math
RISCV_CFLAGS += -fno-builtin-printf
RISCV_CFLAGS += -fno-common
RISCV_CFLAGS += -O3
RISCV_CFLAGS += -ffunction-sections
RISCV_CFLAGS += -Wextra
RISCV_CFLAGS += -Werror
ifeq ($(DEBUG), ON)
RISCV_CFLAGS += -g
endif

# Linking sources
LINKER_SCRIPT = $(abspath $(HOST_DIR)/runtime/host.ld)
LD_SRCS       = $(LINKER_SCRIPT)

# Linker flags
RISCV_LDFLAGS += -nostartfiles
RISCV_LDFLAGS += -lm
RISCV_LDFLAGS += -lgcc
RISCV_LDFLAGS += -T$(LINKER_SCRIPT)

# Device binary
DEVICE_BUILDDIR = $(foreach DEVICE_APP, $(DEVICE_APPS), $(DEVICE_DIR)/apps/$(DEVICE_APP)/build)
DEVICE_BINARY   = $(foreach DEVICE_APP, $(DEVICE_APPS), $(DEVICE_DIR)/apps/$(DEVICE_APP)/build/$(basename $(notdir $(DEVICE_APP))).bin)
ORIGIN_LD       = $(foreach DEVICE_APP, $(DEVICE_APPS), $(DEVICE_DIR)/apps/$(DEVICE_APP)/build/origin.ld)

###########
# Outputs #
###########

PARTIAL_ELF     = $(abspath $(BUILDDIR)/$(APP).part.elf)
# ELF             = $(foreach DEVICE_APP, $(DEVICE_APPS), $(abspath $(BUILDDIR)/$(basename $(notdir $(DEVICE_APP))).elf))
# DEP             = $(foreach DEVICE_APP, $(DEVICE_APPS), $(abspath $(BUILDDIR)/$(basename $(notdir $(DEVICE_APP))).d))
ELF             = $(foreach DEVICE_APP, $(DEVICE_APPS), $(abspath $(BUILDDIR)/$(DEVICE_APP).elf))
DEP             = $(foreach DEVICE_APP, $(DEVICE_APPS), $(abspath $(BUILDDIR)/$(DEVICE_APP).d))
PARTIAL_DUMP    = $(abspath $(BUILDDIR)/$(APP).part.dump)
DUMP            = $(foreach DEVICE_APP, $(DEVICE_APPS), $(abspath $(BUILDDIR)/$(DEVICE_APP).dump))
DWARF           = $(foreach DEVICE_APP, $(DEVICE_APPS), $(abspath $(BUILDDIR)/$(DEVICE_APP).dwarf))
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
	rm -rf $(BUILDDIRS)
	rm -f $(OFFSET_LD)

$(BUILDDIRS):
	mkdir -p $@

$(DEVICE_BUILDDIR):
	mkdir -p $@

$(DEP): $(SRCS) | $(BUILDDIRS)
	$(RISCV_CC) $(RISCV_CFLAGS) -MM -MT '$(PARTIAL_ELF)' $< > $@
	$(RISCV_CC) $(RISCV_CFLAGS) -MM -MT '$(ELF)' $< >> $@

# Partially linked object
$(PARTIAL_ELF): $(DEP) $(LD_SRCS) | $(BUILDDIRS)
	$(RISCV_CC) $(RISCV_CFLAGS) $(RISCV_LDFLAGS) $(SRCS) -o $@

$(PARTIAL_DUMP): $(PARTIAL_ELF) | $(BUILDDIRS)
	$(RISCV_OBJDUMP) -D $< > $@

# Device object relocation address
$(ORIGIN_LD): $(PARTIAL_ELF) | $(DEVICE_BUILDDIR)
	@RELOC_ADDR=$$($(RISCV_OBJDUMP) -t $< | grep snitch_main | cut -c9-16); \
	echo "Writing device object relocation address 0x$$RELOC_ADDR to $@"; \
	echo "L3_ORIGIN = 0x$$RELOC_ADDR;" > $@

$(ELF): $(DEP) $(LD_SRCS) $(DEVICE_BINARY) | $(BUILDDIRS)
	$(eval CUR_APP_NAME:=$(basename $(notdir $@)))
	$(eval CUR_DIR_NAME:=$(basename $(basename $(dir $@))))
	$(eval CUR_LIB=$(strip $(foreach LIB,$(LIBS),$(findstring $(LIB),$(CUR_DIR_NAME)))))
	$(eval FINAL_CFLAGS := -DDEVICEBIN=\"$(DEVICE_DIR)/apps/$(CUR_LIB)/$(CUR_APP_NAME)/build/$(CUR_APP_NAME).bin\")
	$(RISCV_CC) $(RISCV_CFLAGS) $(FINAL_CFLAGS) $(RISCV_LDFLAGS) $(SRCS) -o $@

$(DUMP): $(ELF) | $(BUILDDIRS)
	$(RISCV_OBJDUMP) -D $< > $@

$(DWARF): $(ELF) | $(BUILDDIRS)
	$(RISCV_READELF) --debug-dump $< > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(DEP)
endif
