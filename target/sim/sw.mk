# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

###################
# General targets #
###################

.PHONY: sw clean-sw

all: sw
clean: clean-sw

####################
# Platform headers #
####################

IDMAROOT = $(shell $(BENDER) path idma)

PLATFORM_HEADERS  = $(PLATFORM_HEADERS_DIR)/occamy_cfg.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/occamy_base_addr.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/clint.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/occamy_soc_ctrl.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_cluster_peripheral.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_quad_peripheral.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_hbm_xbar_peripheral.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/idma.h

# REGGEN headers
$(PLATFORM_HEADERS_DIR)/clint.h: $(TARGET_CLINT_DIR)/clint.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/occamy_soc_ctrl.h: $(TARGET_SOCCTRL_DIR)/occamy_soc_reg.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/snitch_cluster_peripheral.h: $(SNITCH_ROOT)/hw/snitch_cluster/src/snitch_cluster_peripheral/snitch_cluster_peripheral_reg.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/snitch_quad_peripheral.h: $(TARGET_QUADCTRL_DIR)/occamy_quadrant_s1_reg.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/snitch_hbm_xbar_peripheral.h: $(TARGET_HBMCTRL_DIR)/occamy_hbm_xbar_reg.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/idma.h: $(IDMAROOT)/target/rtl/idma_reg64_1d.hjson
	$(call reggen_generate_header,$@,$<)

# OCCAMYGEN headers
$(PLATFORM_HEADERS_DIR)/occamy_cfg.h: $(PLATFORM_HEADERS_DIR)/occamy_cfg.h.tpl $(CFG)
	@echo "[OCCAMYGEN] Generating $@"
	@$(OCCAMYGEN) -c $(CFG) --outdir $(PLATFORM_HEADERS_DIR) --cheader $<
$(PLATFORM_HEADERS_DIR)/occamy_base_addr.h: $(CFG)
	@echo "[OCCAMYGEN] Generating $@"
	@$(OCCAMYGEN) -c $(CFG) --outdir $(PLATFORM_HEADERS_DIR) -D $@

.PHONY: clean-headers
clean-sw: clean-headers
clean-headers:
	rm -f $(PLATFORM_HEADERS)

##################
# Subdirectories #
##################

include $(SNITCH_ROOT)/target/snitch_cluster/sw/toolchain.mk
include sw/host/toolchain.mk
include sw/device/runtime/runtime.mk

HOST_APPS  = sw/host/apps/hello_world
HOST_APPS += sw/host/apps/test_sys_dma
HOST_APPS += sw/host/apps/offload

DEVICE_APPS  = sw/device/apps/blas/axpy
DEVICE_APPS += sw/device/apps/blas/gemm

# Include Makefile from each app subdirectory
$(foreach app,$(DEVICE_APPS) $(HOST_APPS), \
	$(eval include $(app)/app.mk) \
)
