# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Usage of absolute paths is required to externally include
# this Makefile from multiple different locations
MK_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
include $(MK_DIR)/../toolchain.mk

###################
# Build variables #
###################

# Fixed paths in repository tree
ROOT        = $(abspath $(MK_DIR)/../../../../..)
# Directories
APPSDIR     = $(abspath $(MK_DIR)/)
# RUNTIME_DIR = $(abspath ../../runtime)
RUNTIME_DIR = $(abspath $(MK_DIR)/../runtime)
SNRT_DIR    = $(shell bender path snitch_cluster)/sw/snRuntime
# SW_DIR      = $(abspath ../../../)
SW_DIR      = $(abspath $(MK_DIR)/../../)

#################
# SNDNN_LIBRARY #
#################
ifdef USE_SNDNN_LIBRARY
SNDNN_DIR    := $(shell bender path snitch_cluster)/sw/snDNN
SNDNN_LIB_DIR := $(abspath $(MK_DIR)/../libraries/snDNN)
SNDNN_LIB_NAME = snDNN

# Dependencies
INCDIRS += $(SNDNN_LIB_DIR)/src
INCDIRS += $(SNDNN_DIR)/src
INCDIRS += $(SNDNN_DIR)/include
# Linker script
# RISCV_LDFLAGS += -L$(abspath $(SNDNN_LIB_DIR))
# Link snRuntime library
RISCV_LDFLAGS += -L$(abspath $(SNDNN_LIB_DIR)/build/)
RISCV_LDFLAGS += -l$(SNDNN_LIB_NAME)
BUILDDIR    = $(abspath $(MK_DIR)/sndnn/$(APP)/build)
SNDNN_LIB   = $(realpath $(SNDNN_LIB_DIR)/build/lib$(SNDNN_LIB_NAME).a)
LD_SRCS    += $(SNDNN_LIB)
else
BUILDDIR    = $(abspath $(MK_DIR)/$(APP)/build)
endif

# Dependencies
INCDIRS += $(RUNTIME_DIR)/src
INCDIRS += $(SNRT_DIR)/api
INCDIRS += $(SNRT_DIR)/src
INCDIRS += $(SNRT_DIR)/vendor/riscv-opcodes
INCDIRS += $(SW_DIR)/shared/platform/generated
INCDIRS += $(SW_DIR)/shared/platform
INCDIRS += $(SW_DIR)/shared/runtime

# Linking sources
BASE_LD       = $(abspath $(SNRT_DIR)/base.ld)
MEMORY_LD     = $(abspath $(APPSDIR)/memory.ld)
ORIGIN_LD     = $(abspath $(BUILDDIR)/origin.ld)
BASE_LD       = $(abspath $(SNRT_DIR)/base.ld)
SNRT_LIB_DIR  = $(abspath $(RUNTIME_DIR)/build/)
SNRT_LIB_NAME = snRuntime
SNRT_LIB      = $(realpath $(SNRT_LIB_DIR)/lib$(SNRT_LIB_NAME).a)
LD_SRCS       = $(BASE_LD) $(MEMORY_LD) $(ORIGIN_LD) $(SNRT_LIB)

# Linker flags
RISCV_LDFLAGS += -nostartfiles
RISCV_LDFLAGS += -lm
# RISCV_LDFLAGS += -lgcc
# Linker script
RISCV_LDFLAGS += -L$(APPSDIR)
RISCV_LDFLAGS += -L$(BUILDDIR)
RISCV_LDFLAGS += -T$(BASE_LD)
# Link snRuntime library
RISCV_LDFLAGS += -L$(SNRT_LIB_DIR)
RISCV_LDFLAGS += -l$(SNRT_LIB_NAME)

# Objcopy flags
OBJCOPY_FLAGS  = -O binary
OBJCOPY_FLAGS += --remove-section=.comment
OBJCOPY_FLAGS += --remove-section=.riscv.attributes
OBJCOPY_FLAGS += --remove-section=.debug_info
OBJCOPY_FLAGS += --remove-section=.debug_abbrev
OBJCOPY_FLAGS += --remove-section=.debug_line
OBJCOPY_FLAGS += --remove-section=.debug_str
OBJCOPY_FLAGS += --remove-section=.debug_aranges

###########
# Outputs #
###########

ELF         = $(abspath $(BUILDDIR)/$(APP).elf)
DEP         = $(abspath $(BUILDDIR)/$(APP).d)
BIN         = $(abspath $(BUILDDIR)/$(APP).bin)
DUMP        = $(abspath $(BUILDDIR)/$(APP).dump)
DWARF       = $(abspath $(BUILDDIR)/$(APP).dwarf)
ALL_OUTPUTS = $(BIN) $(DUMP) $(DWARF)

#########
# Rules #
#########

.PHONY: all
all: $(ALL_OUTPUTS)

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)

$(BUILDDIR):
	mkdir -p $@

$(DEP): $(SRCS) | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) -MM -MT '$(ELF)' $< > $@

$(ELF): $(DEP) $(LD_SRCS) | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) $(SRCS) $(RISCV_LDFLAGS) -o $@

$(BIN): $(ELF) | $(BUILDDIR)
	$(RISCV_OBJCOPY) $(OBJCOPY_FLAGS) $< $@

$(DUMP): $(ELF) | $(BUILDDIR)
	$(RISCV_OBJDUMP) -D $< > $@

$(DWARF): $(ELF) | $(BUILDDIR)
#	$(RISCV_READELF) --debug-dump $< > $@
	$(RISCV_DWARFDUMP) $< > $@
ifneq ($(MAKECMDGOALS),clean)
-include $(DEP)
endif
