# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

$(APP)_RISCV_CFLAGS  += -I$(SW_DIR)/shared/runtime
MEMORY_LD             = $(SW_DIR)/device/apps/memory.ld
offload_BUILDDIR	  = $(SW_DIR)/host/apps/offload/build
ORIGIN_LD             = $(offload_BUILDDIR)/origin.ld
$(APP)_RISCV_LDFLAGS += -L$(dir $(ORIGIN_LD))
LD_DEPS               = $(ORIGIN_LD)

include $(SNITCH_ROOT)/target/snitch_cluster/sw/apps/common.mk

RISCV_OBJCOPY_FLAGS  = -O binary
RISCV_OBJCOPY_FLAGS += --remove-section=.comment
RISCV_OBJCOPY_FLAGS += --remove-section=.riscv.attributes
RISCV_OBJCOPY_FLAGS += --remove-section=.debug_info
RISCV_OBJCOPY_FLAGS += --remove-section=.debug_abbrev
RISCV_OBJCOPY_FLAGS += --remove-section=.debug_line
RISCV_OBJCOPY_FLAGS += --remove-section=.debug_str
RISCV_OBJCOPY_FLAGS += --remove-section=.debug_aranges

BIN = $(abspath $(addprefix $($(APP)_BUILD_DIR)/,$(addsuffix .bin,$(APP))))

$(BIN): $(ELF) | $($(APP)_BUILD_DIR)
	$(RISCV_OBJCOPY) $(RISCV_OBJCOPY_FLAGS) $< $@

$(APP): $(BIN)
