# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

###################
# Build variables #
###################

HOST_DIR         = $(SW_DIR)/host
$(APP)_BUILDDIR  = $(HOST_DIR)/apps/$(APP)/build
HOST_RUNTIME_DIR = $(HOST_DIR)/runtime

HOST_INCDIRS  = $(HOST_RUNTIME_DIR)
HOST_INCDIRS += $(PLATFORM_HEADERS_DIR)
HOST_INCDIRS += $(SW_DIR)/shared/runtime
SRCS         += $(HOST_RUNTIME_DIR)/start.S
HEADERS      += $(PLATFORM_HEADERS)

$(APP)_HOST_RISCV_CFLAGS += $(HOST_RISCV_CFLAGS)
$(APP)_HOST_RISCV_CFLAGS += $(addprefix -I,$(HOST_INCDIRS))

HOST_LINKER_SCRIPT  = $(HOST_RUNTIME_DIR)/host.ld

$(APP)_HOST_RISCV_LDFLAGS += $(HOST_RISCV_LDFLAGS)
$(APP)_HOST_RISCV_LDFLAGS += -T$(HOST_LINKER_SCRIPT)

LD_DEPS = $(HOST_LINKER_SCRIPT)

###########
# Outputs #
###########

ELF                 = $($(APP)_BUILDDIR)/$(APP).elf
DEP                 = $($(APP)_BUILDDIR)/$(APP).d
DUMP                = $($(APP)_BUILDDIR)/$(APP).dump
ORIGIN_LD           = $($(APP)_BUILDDIR)/origin.ld
HETEROGENEOUS_APPS  = $(addprefix $(APP)-,$(notdir $($(APP)_DEVICE_APPS)))
HETEROGENEOUS_ELFS  = $(addsuffix .elf, $(addprefix $($(APP)_BUILDDIR)/, $(HETEROGENEOUS_APPS)))
HETEROGENEOUS_DUMPS = $(addsuffix .dump, $(addprefix $($(APP)_BUILDDIR)/$(APP)-, $(notdir $($(APP)_DEVICE_APPS))))
ALL_OUTPUTS         = $(ELF) $(HETEROGENEOUS_ELFS) $(ORIGIN_LD)

ifeq ($(DEBUG), ON)
ALL_OUTPUTS += $(DUMP) $(HETEROGENEOUS_DUMPS)
endif

#########
# Rules #
#########

.PHONY: $(APP) $(HETEROGENEOUS_APPS) clean-$(APP)

sw: $(APP) $(HETEROGENEOUS_APPS)
clean-sw: clean-$(APP)

$(APP): $(ALL_OUTPUTS)
$(HETEROGENEOUS_APPS): $(APP)-%: $($(APP)_BUILDDIR)/$(APP)-%.elf %
ifeq ($(DEBUG), ON)
$(HETEROGENEOUS_APPS): $(APP)-%: $($(APP)_BUILDDIR)/$(APP)-%.dump
endif

clean-$(APP): BUILDDIR := $($(APP)_BUILDDIR)
clean-$(APP): DEVICE_APPS := $($(APP)_DEVICE_APPS)
clean-$(APP):
	rm -rf $(BUILDDIR)
	rm -rf $(foreach device,$(DEVICE_APPS),$($(notdir $(device))_BUILD_DIR))

$($(APP)_BUILDDIR):
	mkdir -p $@

$(DEP): ELF := $(ELF)
$(ELF): SRCS := $(SRCS)
# Guarantee that variables used in rule recipes (thus subject to deferred expansion)
# have unique values, despite depending on variables with the same name across
# applications, but which could have different values (e.g. the APP variable itself)
$(DEP) $(ELF): HOST_RISCV_CFLAGS := $($(APP)_HOST_RISCV_CFLAGS)
$(ELF): HOST_RISCV_LDFLAGS := $($(APP)_HOST_RISCV_LDFLAGS)

$(DEP): $(SRCS) $(HEADERS) | $($(APP)_BUILDDIR)
	$(HOST_RISCV_CC) $(HOST_RISCV_CFLAGS) -MM -MT '$(ELF)' $< >> $@

# Device object relocation address
$(ORIGIN_LD): $(ELF) | $($(APP)_BUILDDIR)
	@RELOC_ADDR=$$($(HOST_RISCV_OBJDUMP) -t $< | grep snitch_main | cut -c9-16); \
	echo "Writing device object relocation address 0x$$RELOC_ADDR to $@"; \
	echo "L3_ORIGIN = 0x$$RELOC_ADDR;" > $@

$(ELF): $(DEP) $(LD_DEPS) | $($(APP)_BUILDDIR)
	$(HOST_RISCV_CC) $(HOST_RISCV_CFLAGS) $(HOST_RISCV_LDFLAGS) $(SRCS) -o $@

$(DUMP): $(ELF) | $($(APP)_BUILDDIR)
	$(HOST_RISCV_OBJDUMP) -D $< > $@

# Generates a rule which looks somewhat like:
#
# $($(APP)_BUILDDIR)/$(APP)-%.elf: $(DEVICE_APP)/build/%.bin $(DEP) $(LD_SRCS) | $($(APP)_BUILDDIR)
# 	$(RISCV_CC) $(RISCV_CFLAGS) -DDEVICEBIN=\"$<\" $(RISCV_LDFLAGS) $(SRCS) -o $@
#
# This approach is required cause you can't use multiple %-signs in a prerequisite
define elf_rule_template =
    $$($(APP)_BUILDDIR)/$$(APP)-$(notdir $(1)).elf: SRCS := $$(SRCS)
    $$($(APP)_BUILDDIR)/$$(APP)-$(notdir $(1)).elf: HOST_RISCV_CFLAGS := $$($$(APP)_HOST_RISCV_CFLAGS)
    $$($(APP)_BUILDDIR)/$$(APP)-$(notdir $(1)).elf: HOST_RISCV_LDFLAGS := $$($$(APP)_HOST_RISCV_LDFLAGS)
    $$($(APP)_BUILDDIR)/$$(APP)-$(notdir $(1)).elf: $(abspath $($(notdir $(1))_BUILD_DIR))/$(notdir $(1)).bin $$(ELF) $$(LD_DEPS) | $$($(APP)_BUILDDIR)
	    $$(HOST_RISCV_CC) $$(HOST_RISCV_CFLAGS) -DDEVICEBIN=\"$$<\" $$(HOST_RISCV_LDFLAGS) $$(SRCS) -o $$@
endef
$(foreach f,$($(APP)_DEVICE_APPS),$(eval $(call elf_rule_template,$(f))))

$(HETEROGENEOUS_DUMPS): $($(APP)_BUILDDIR)/$(APP)-%.dump: $($(APP)_BUILDDIR)/$(APP)-%.elf | $($(APP)_BUILDDIR)
	$(HOST_RISCV_OBJDUMP) -D $< > $@

ifneq ($(filter sw $(APP) $(HETEROGENEOUS_APPS) $(ALL_OUTPUTS),$(MAKECMDGOALS)),)
-include $(DEP)
endif
