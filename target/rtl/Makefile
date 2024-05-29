# The dependencies in this file are below the targets, in reverse order. (for you to read them easier)


# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := $(MKFILE_DIR)../..
TARGET_SRC_DIR       ?= src

SOURCE_OCCAMY_DIR    ?= $(ROOT)/hw/occamy

SOURCE_QUADCTRL_DIR  ?= $(ROOT)/hw/occamy/quadrant_s1_ctrl
TARGET_QUADCTRL_DIR  ?= $(TARGET_SRC_DIR)/quadrant_s1_ctrl

SOURCE_HBMCTRL_DIR   ?= $(ROOT)/hw/occamy/hbm_xbar_ctrl
TARGET_HBMCTRL_DIR   ?= $(TARGET_SRC_DIR)/hbm_xbar_ctrl


SOURCE_SOCCTRL_DIR   ?= $(ROOT)/hw/occamy/soc_ctrl
TARGET_SOCCTRL_DIR   ?= $(TARGET_SRC_DIR)/soc_ctrl

SOURCE_PLIC_DIR       = $(ROOT)/hw/vendor/pulp_platform_opentitan_peripherals/src/rv_plic
TARGET_PLIC_DIR      ?= $(TARGET_SRC_DIR)/rv_plic

SOURCE_CLINT_DIR      = $(shell $(BENDER) path clint)
TARGET_CLINT_DIR     ?= $(TARGET_SRC_DIR)/clint

TARGET_DTS_DIR       ?= $(ROOT)/target/fpga/bootrom

############
# Programs #
############

BENDER       ?= bender
#VERIBLE_FMT  ?= verible-verilog-format

OCCAMYGEN  ?= $(ROOT)/util/occamygen/occamygen.py
REGGEN     ?= $(shell $(BENDER) path register_interface)/vendor/lowrisc_opentitan/util/regtool.py
PLICGEN     = $(SOURCE_PLIC_DIR)/util/reg_rv_plic.py

#######################
# Config prerequisite #
#######################

# If the configuration file is overriden on the command-line (through
# CFG_OVERRIDE) and this file differs from the least recently used
# (LRU) config, all targets depending on the configuration file have
# to be rebuilt. This file is used to express this condition as a
# prerequisite for other rules.
CFG = cfg/lru.hjson

$(CFG): FORCE
	@# If the LRU config file doesn't exist, we use the default config.
	@if [ ! -e $@ ] ; then \
		DEFAULT_CFG="cfg/full.hjson"; \
		echo "Using default config file: $$DEFAULT_CFG"; \
		cp $$DEFAULT_CFG $@; \
	fi
	@# If a config file is provided on the command-line and it differs
	@# from the LRU config file then we override the LRU file with it
	@if [ $(CFG_OVERRIDE) ] ; then \
		echo "Overriding config file with: $(CFG_OVERRIDE)"; \
		if cmp -s $(CFG_OVERRIDE) $@ ; then \
			echo "Override and LRU config files are equivalent. Nothing to be done."; \
		else \
			cp $(CFG_OVERRIDE) $@; \
		fi \
	fi
FORCE:

.PHONY: all clean
all: rtl
clean: clean-bender clean-rtl

########
# Util #
########

.PHONY: clean-bender

clean-bender:
	rm -rf $(ROOT)/Bender.lock $(ROOT)/.bender/ $(ROOT)/deps

###############
# RTL sources #
###############

.PHONY: rtl clint plic socctrl hbmctrl quadctrl soc tb
.PHONY: clean-rtl clean-clint clean-plic clean-socctrl clean-hbmctrl clean-quadctrl clean-soc clean-tb

rtl: clint plic socctrl hbmctrl quadctrl soc tb
clean-rtl: clean-clint clean-plic clean-socctrl clean-hbmctrl clean-quadctrl clean-soc clean-tb

$(TARGET_PLIC_DIR) $(TARGET_CLINT_DIR) $(TARGET_SOCCTRL_DIR) $(TARGET_HBMCTRL_DIR) $(TARGET_QUADCTRL_DIR):
	@mkdir -p $@

######
# TB #
######

tb: test/testharness.sv
clean-tb:
	rm -rf test/testharness.sv

test/testharness.sv: test/testharness.sv.tpl $(CFG)
	@echo "[OCCAMYGEN] Generate $@"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir test --testharness-sv $<
#why?	@$(VERIBLE_FMT) --inplace $@

	# @$(OCCAMYGEN) --cfg $(CFG) \
 	# 	--bootdata       ../../ip/snitch_cluster/test/bootdata.cc.tpl
	@echo "[SOLDER] Device Tree"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir . --dts test/occamy.dts


#######
# SOC #
#######

MISC_OCCAMYGEN_SV_TEMPLATES  = $(SOURCE_OCCAMY_DIR)/occamy_*.sv.tpl
MISC_OCCAMYGEN_SV_TARGETS  = $(TARGET_SRC_DIR)/occamy_*.sv
#$(warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!MISC_OCCAMYGEN_SV_TEMPLATES=$(MISC_OCCAMYGEN_SV_TEMPLATES) !!!!!!11! $(MISC_OCCAMYGEN_SV_TARGETS))
MISC_OCCAMYGEN_SV_TARGETS += $(TARGET_SRC_DIR)/occamy_cluster_wrapper.sv
MISC_OCCAMYGEN_SV_TARGETS += $(TARGET_SRC_DIR)/snax_cluster_wrapper.sv

MISC_OCCAMYGEN_TARGETS  = $(MISC_OCCAMYGEN_SV_TARGETS)
MISC_OCCAMYGEN_TARGETS += $(TARGET_SRC_DIR)/occamy_memories.json


soc: $(MISC_OCCAMYGEN_TARGETS) chisel_targets
clean-soc:
	rm -rf $(MISC_OCCAMYGEN_TARGETS) .misc_occamygen_targets_group

$(MISC_OCCAMYGEN_TARGETS): .misc_occamygen_targets_group
.misc_occamygen_targets_group: $(CFG) $(MISC_OCCAMYGEN_SV_TEMPLATES)
	@echo "[OCCAMYGEN] Generate $(MISC_OCCAMYGEN_TARGETS)"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir $(TARGET_SRC_DIR)\
		--wrapper \
		--memories \
		--top-sv           $(SOURCE_OCCAMY_DIR)/occamy_top.sv.tpl \
		--soc-sv           $(SOURCE_OCCAMY_DIR)/occamy_soc.sv.tpl \
		--pkg-sv           $(SOURCE_OCCAMY_DIR)/occamy_pkg.sv.tpl \
		--quadrant-s1      $(SOURCE_OCCAMY_DIR)/occamy_quadrant_s1.sv.tpl \
		--quadrant-s1-ctrl $(SOURCE_OCCAMY_DIR)/occamy_quadrant_s1_ctrl.sv.tpl \
		--xilinx-sv        $(SOURCE_OCCAMY_DIR)/occamy_xilinx.sv.tpl \
		--cva6-sv          $(SOURCE_OCCAMY_DIR)/occamy_cva6.sv.tpl \
		--dts 			   $(TARGET_DTS_DIR)/occamy.dts
#why?	@$(VERIBLE_FMT) --inplace $(MISC_OCCAMYGEN_SV_TARGETS)
# File included by occamy_xilinx needs to be put in the same folder
	cp -f $(SOURCE_OCCAMY_DIR)/axi_flat.sv $(TARGET_SRC_DIR)
	cp -f $(SOURCE_OCCAMY_DIR)/apb_flat.sv $(TARGET_SRC_DIR)
	@touch $@

.PHONY: chisel_targets
chisel_targets:
# Temporary solution; this should be considered to be finished when bender is triggered. This can be done by the plugin in the bender.yml inside each accelerator
# Place all Chisel files that need to be generated header
# Todo in the future for module desginer: please consider using relative path in the Makefile
	# $(MAKE) -C `bender path snax-streamer-simd-dev` rtl/streamer-simd/streamer_simd_wrapper.sv
	$(MAKE) -C `bender path snax-data-reshuffler-dev` `bender path snax-data-reshuffler-dev`/tests/tb/tb_stream_dev_reshuffler.sv
	$(MAKE) -C `bender path snax-streamer-gemm-dev` `bender path snax-streamer-gemm-dev`/rtl/streamer-gemm/streamer_gemm_wrapper.sv
############
# QUADCTRL #
############

QUADCTRL_OCCAMYGEN_TARGETS = $(TARGET_QUADCTRL_DIR)/occamy_quadrant_s1_reg.hjson
QUADCTRL_REGGEN_TARGETS = $(addprefix $(TARGET_QUADCTRL_DIR)/,occamy_quadrant_s1_reg_pkg.sv occamy_quadrant_s1_reg_top.sv)

quadctrl: $(QUADCTRL_OCCAMYGEN_TARGETS) $(QUADCTRL_REGGEN_TARGETS)
clean-quadctrl:
	rm -rf $(QUADCTRL_OCCAMYGEN_TARGETS) $(QUADCTRL_REGGEN_TARGETS) .quadctrl_reggen_targets_group

$(QUADCTRL_REGGEN_TARGETS): .quadctrl_reggen_targets_group
.quadctrl_reggen_targets_group: $(TARGET_QUADCTRL_DIR)/occamy_quadrant_s1_reg.hjson | $(TARGET_QUADCTRL_DIR)
	@echo "[REGGEN] Generate $(QUADCTRL_REGGEN_TARGETS)"
	@$(REGGEN) -r -t $(TARGET_QUADCTRL_DIR) $<
#why?	@$(VERIBLE_FMT) --inplace $(QUADCTRL_REGGEN_TARGETS)
	@touch $@

$(TARGET_QUADCTRL_DIR)/occamy_quadrant_s1_reg.hjson: $(SOURCE_QUADCTRL_DIR)/occamy_quadrant_s1_reg.hjson.tpl | $(TARGET_QUADCTRL_DIR)
	@echo "[OCCAMYGEN] Generate $@"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir $(TARGET_QUADCTRL_DIR) --chip $<

###########
# HBMCTRL #
###########

HBMCTRL_OCCAMYGEN_TARGETS = $(TARGET_HBMCTRL_DIR)/occamy_hbm_xbar_reg.hjson
HBMCTRL_REGGEN_TARGETS = $(addprefix $(TARGET_HBMCTRL_DIR)/,occamy_hbm_xbar_reg_pkg.sv occamy_hbm_xbar_reg_top.sv)

hbmctrl: $(HBMCTRL_OCCAMYGEN_TARGETS) $(HBMCTRL_REGGEN_TARGETS)
clean-hbmctrl:
	rm -rf $(HBMCTRL_OCCAMYGEN_TARGETS) $(HBMCTRL_REGGEN_TARGETS) .hbmctrl_reggen_targets_group

$(HBMCTRL_REGGEN_TARGETS): .hbmctrl_reggen_targets_group
.hbmctrl_reggen_targets_group: $(TARGET_HBMCTRL_DIR)/occamy_hbm_xbar_reg.hjson | $(TARGET_HBMCTRL_DIR)
	@echo "[REGGEN] Generate $(HBMCTRL_REGGEN_TARGETS)"
	@$(REGGEN) -r -t $(TARGET_HBMCTRL_DIR) $<
#why?	@$(VERIBLE_FMT) --inplace $(HBMCTRL_REGGEN_TARGETS)
	@touch $@

$(TARGET_HBMCTRL_DIR)/occamy_hbm_xbar_reg.hjson: $(SOURCE_HBMCTRL_DIR)/occamy_hbm_xbar_reg.hjson.tpl | $(TARGET_HBMCTRL_DIR)
	@echo "[OCCAMYGEN] Generate $@"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir $(TARGET_HBMCTRL_DIR) --chip $<

###########
# SOCCTRL #
###########

SOCCTRL_OCCAMYGEN_TARGETS = $(TARGET_SOCCTRL_DIR)/occamy_soc_reg.hjson
SOCCTRL_REGGEN_TARGETS = $(addprefix $(TARGET_SOCCTRL_DIR)/,occamy_soc_reg_pkg.sv occamy_soc_reg_top.sv)

socctrl: $(SOCCTRL_OCCAMYGEN_TARGETS) $(SOCCTRL_REGGEN_TARGETS)
clean-socctrl:
	rm -rf $(SOCCTRL_OCCAMYGEN_TARGETS) $(SOCCTRL_REGGEN_TARGETS) .socctrl_reggen_targets_group

$(SOCCTRL_REGGEN_TARGETS): .socctrl_reggen_targets_group
.socctrl_reggen_targets_group: $(TARGET_SOCCTRL_DIR)/occamy_soc_reg.hjson | $(TARGET_SOCCTRL_DIR)
	@echo "[REGGEN] Generate $(SOCCTRL_REGGEN_TARGETS)"
	@$(REGGEN) -r -t $(TARGET_SOCCTRL_DIR) $<
#why?	@$(VERIBLE_FMT) --inplace $(SOCCTRL_REGGEN_TARGETS)
	@touch $@

$(TARGET_SOCCTRL_DIR)/occamy_soc_reg.hjson: $(SOURCE_SOCCTRL_DIR)/occamy_soc_reg.hjson.tpl | $(TARGET_SOCCTRL_DIR)
	@echo "[OCCAMYGEN] Generate $@"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir $(TARGET_SOCCTRL_DIR) --chip $<

########
# PLIC #
########

PLIC_PLICGEN_TARGETS = $(addprefix $(TARGET_PLIC_DIR)/,rv_plic.sv rv_plic.hjson)
PLIC_REGGEN_TARGETS = $(addprefix $(TARGET_PLIC_DIR)/,rv_plic_reg_pkg.sv rv_plic_reg_top.sv)

plic: $(PLIC_PLICGEN_TARGETS) $(PLIC_REGGEN_TARGETS)
clean-plic:
	rm -rf $(PLIC_PLICGEN_TARGETS) $(PLIC_REGGEN_TARGETS) .plic_reggen_targets_group

$(PLIC_REGGEN_TARGETS): .plic_reggen_targets_group
.plic_reggen_targets_group: $(TARGET_PLIC_DIR)/rv_plic.hjson | $(TARGET_PLIC_DIR)
	@echo "[REGGEN] Generate $(PLIC_REGGEN_TARGETS)"
	@$(REGGEN) -r -t $(TARGET_PLIC_DIR) $<
#why?	@$(VERIBLE_FMT) --inplace $(PLIC_REGGEN_TARGETS)
	@touch $@

$(TARGET_PLIC_DIR)/rv_plic.%: $(SOURCE_PLIC_DIR)/data/rv_plic.%.tpl | $(TARGET_PLIC_DIR)
	@echo "[PLICGEN] Generate $@"
	@$(PLICGEN) -s 73 -t 2 -p 6 $< > $@

#########
# CLINT #
#########

CLINT_OCCAMYGEN_TARGETS = $(addprefix $(TARGET_CLINT_DIR)/,clint.sv clint.hjson)
CLINT_REGGEN_TARGETS = $(addprefix $(TARGET_CLINT_DIR)/,clint_reg_pkg.sv clint_reg_top.sv)

clint: $(CLINT_OCCAMYGEN_TARGETS) $(CLINT_REGGEN_TARGETS)
clean-clint:
	rm -rf $(CLINT_OCCAMYGEN_TARGETS) $(CLINT_REGGEN_TARGETS) .clint_reggen_targets_group

$(CLINT_REGGEN_TARGETS): .clint_reggen_targets_group
.clint_reggen_targets_group: $(TARGET_CLINT_DIR)/clint.hjson | $(TARGET_CLINT_DIR)
	@echo "[REGGEN] Generate $(CLINT_REGGEN_TARGETS)"
	@$(REGGEN) -r -t $(TARGET_CLINT_DIR) $<
#why?	@$(VERIBLE_FMT) --inplace $(CLINT_REGGEN_TARGETS)
	@touch $@

$(TARGET_CLINT_DIR)/clint.%: $(SOURCE_CLINT_DIR)/data/clint.%.tpl $(CFG) | $(TARGET_CLINT_DIR)
	@echo "[OCCAMYGEN] Generate $@"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir $(TARGET_CLINT_DIR) --chip $<
