# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>

#######################
# Makefile invocation #
#######################

DEBUG        ?= OFF # ON to turn on debugging symbols
CFG_OVERRIDE ?=     # Override default config file

.DEFAULT_GOAL := help
.PHONY: all clean
all: rtl sw addrmap
clean: clean-bender clean-rtl clean-sw clean-addrmap clean-vcs clean-logs

############
# Makefrag #
############

# Common definitions used by included Makefiles

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := $(realpath $(MKFILE_DIR)../..)
SNITCH_ROOT := $(shell bender path snitch_cluster)

TARGET = occamy_top

CVA6_TXT_TRACE       = $(LOGS_DIR)/trace_hart_00000.txt
CVA6_PERF_DUMP       = $(LOGS_DIR)/hart_00000_perf.json
CVA6_ANNOTATED_TRACE = $(LOGS_DIR)/trace_hart_00000.s
CVA6_BINARY         ?= $(shell cat $(SIM_DIR)/.rtlbinary)
TXT_TRACES          += $(CVA6_TXT_TRACE)
PERF_DUMPS          += $(CVA6_PERF_DUMP)
ANNOTATED_TRACES    += $(CVA6_ANNOTATED_TRACE)

include $(SNITCH_ROOT)/target/common/common.mk

############
# Programs #
############

REGGEN     ?= $(shell $(BENDER) path register_interface)/vendor/lowrisc_opentitan/util/regtool.py
OCCAMYGEN  ?= $(ROOT)/util/occamygen/occamygen.py
ADDRMAPGEN ?= $(ROOT)/util/addrmap/addrmapgen.py

CLANG_FORMAT ?= $(shell which clang-format-10.0.1)

#########################
# Files and directories #
#########################

BIN_DIR              ?= bin
PLATFORM_HEADERS_DIR ?= sw/shared/platform/generated
TARGET_ADDRMAP_DIR   ?= $(abspath addrmap)
SOURCE_ADDRMAP_DIR   ?= $(ROOT)/util/addrmap
DOCS_DIR             ?= $(ROOT)/docs
TARGET_SRC_DIR       ?= $(ROOT)/target/sim/src
TARGET_PLIC_DIR      ?= $(ROOT)/target/sim/src/rv_plic
TARGET_CLINT_DIR     ?= $(ROOT)/target/sim/src/clint
TARGET_SOCCTRL_DIR   ?= $(ROOT)/target/sim/src/soc_ctrl
TARGET_HBMCTRL_DIR   ?= $(ROOT)/target/sim/src/hbm_xbar_ctrl
TARGET_QUADCTRL_DIR  ?= $(ROOT)/target/sim/src/quadrant_s1_ctrl
SOURCE_OCCAMY_DIR    ?= $(ROOT)/hw/occamy
SOURCE_SOCCTRL_DIR   ?= $(ROOT)/hw/occamy/soc_ctrl
SOURCE_HBMCTRL_DIR   ?= $(ROOT)/hw/occamy/hbm_xbar_ctrl
SOURCE_QUADCTRL_DIR  ?= $(ROOT)/hw/occamy/quadrant_s1_ctrl
SNITCH_TEST_DIR      ?= $(SNITCH_ROOT)/target/common/test
TARGET_TEST_DIR      ?= $(ROOT)/target/sim/test
CVA6_TRACE            = trace_hart_0.log

# If the configuration file is overriden on the command-line (through
# CFG_OVERRIDE) and this file differs from the least recently used
# (LRU) config, all targets depending on the configuration file have
# to be rebuilt. This file is used to express this condition as a
# prerequisite for other rules.
DEFAULT_CFG = cfg/full.hjson
CFG         = cfg/lru.hjson

#####################
# Simulator options #
#####################

VSIM_BENDER += -t cv64a6_imafdc_sv39 -t occamy_sim -t snitch_cluster

VSIM_FLAGS += -t 1ps
VSIM_FLAGS += -voptargs=+acc
VSIM_FLAGS += -do "log -r /*; run -a"
# Downgraded from error as VSIM *wrongly* reports illegal enum assignments in riscv_dbg 4-phase CDCs
# TODO: Workaround; revise
VSIM_FLAGS += -warning 8386

VCS_FLAGS += +nospecify
VCS_FLAGS += -Mdir=work-vcs
VCS_FLAGS += -Mlib=work-vcs
VCS_FLAGS += -full64
# Multi-core
VCS_FLAGS += -fgp
# Debug Options
VCS_FLAGS += -assert disable_cover
VCS_FLAGS += -kdb
VCS_FLAGS += +vcs+fsdbon
VCS_FLAGS += +lint=TFIPC-L
VCS_FLAGS += -debug_access+all

VLOG_FLAGS += -svinputport=compat
VLOG_FLAGS += -override_timescale 1ns/1ps
VLOG_FLAGS += -suppress 2583
VLOG_FLAGS += -suppress 13314
VLOG_FLAGS += ${QUESTA_64BIT}
VLOG_FLAGS += -timescale 1ns/1ps

###############
# C testbench #
###############

TB_CC_SOURCES  = $(SNITCH_TEST_DIR)/bootrom.cc
TB_CC_SOURCES += $(SNITCH_TEST_DIR)/ipc.cc
TB_CC_SOURCES += $(SNITCH_TEST_DIR)/rtl_lib.cc
TB_CC_SOURCES += $(SNITCH_TEST_DIR)/common_lib.cc
TB_CC_SOURCES += $(TARGET_TEST_DIR)/bootdata.cc
TB_CC_SOURCES += $(TARGET_TEST_DIR)/uartdpi/uartdpi.c

TB_CC_FLAGS  = -std=c++14
TB_CC_FLAGS +=-I$(MKFILE_DIR)
TB_CC_FLAGS +=-I$(MKFILE_DIR)/test
TB_CC_FLAGS +=-I$(FESVR)/include
TB_CC_FLAGS +=-I$(SNITCH_TEST_DIR)
TB_CC_FLAGS +=-I$(TARGET_TEST_DIR)/uartdpi

#################
# Prerequisites #
#################

# This target is always evaluated and creates a symlink to the least
# recently used config file. Because it is a symlink, targets to which it is a
# prerequisite will only be updated if the symlink target is newer than the
# depending targets, regardless of the symlink timestamp itself. The symlink
# timestamp can be taken into account by using the `make -L` flag on the
# command-line, however for simplicity we touch the symlink targets so it can
# be used without.
$(CFG): FORCE
	@# If the LRU config file doesn't exist, we use the default config.
	@if [ ! -e "$@" ] ; then \
		echo "Using default config file: $(DEFAULT_CFG)"; \
		ln -s --relative $(DEFAULT_CFG) $@; \
		touch $(DEFAULT_CFG); \
	fi
	@# If a config file is provided on the command-line and the LRU
	@# config file doesn't point to it already, then we make it point to it
	@if [ $(CFG_OVERRIDE) ] ; then \
		echo "Overriding config file with: $(CFG_OVERRIDE)"; \
		target=$$(readlink -f $@); \
		if [ "$$target" = "$(abspath $(CFG_OVERRIDE))" ] ; then \
			echo "LRU config file already points to $(CFG_OVERRIDE). Nothing to be done."; \
		else \
			rm -f $@; \
			ln -s --relative $(CFG_OVERRIDE) $@; \
			touch $(CFG_OVERRIDE); \
		fi \
	fi
FORCE:

############
# Boot ROM #
############

BOOTROM_TARGETS  = $(TARGET_TEST_DIR)/bootrom.elf
BOOTROM_TARGETS += $(TARGET_TEST_DIR)/bootrom.dump
BOOTROM_TARGETS += $(TARGET_TEST_DIR)/bootrom.bin

.PHONY: bootrom clean-bootrom

bootrom: $(BOOTROM_TARGETS)

clean-bootrom:
	rm -rf $(BOOTROM_TARGETS)

$(TARGET_TEST_DIR)/bootrom.elf: $(TARGET_TEST_DIR)/bootrom.S $(TARGET_TEST_DIR)/bootrom.ld
	$(RISCV_GCC_BINROOT)/riscv64-unknown-elf-gcc -mabi=lp64d -march=rv64imafd -static -nostartfiles -T$(TARGET_TEST_DIR)/bootrom.ld $< -o $(TARGET_TEST_DIR)/bootrom.elf
$(TARGET_TEST_DIR)/bootrom.dump: $(TARGET_TEST_DIR)/bootrom.elf
	$(RISCV_GCC_BINROOT)/riscv64-unknown-elf-objdump -D $< > $@
$(TARGET_TEST_DIR)/bootrom.bin: $(TARGET_TEST_DIR)/bootrom.elf
	$(RISCV_GCC_BINROOT)/riscv64-unknown-elf-objcopy -O binary $< $@

###############
# RTL sources #
###############

.PHONY: rtl clint plic socctrl hbmctrl quadctrl soc tb
.PHONY: clean-rtl clean-clint clean-plic clean-socctrl clean-hbmctrl clean-quadctrl clean-soc clean-tb

rtl: clint plic socctrl hbmctrl quadctrl soc tb
clean-rtl: clean-clint clean-plic clean-socctrl clean-hbmctrl clean-quadctrl clean-soc clean-tb

MISC_OCCAMYGEN_SV_TEMPLATES  = $(SOURCE_OCCAMY_DIR)/occamy_top.sv.tpl
MISC_OCCAMYGEN_SV_TEMPLATES += $(SOURCE_OCCAMY_DIR)/occamy_soc.sv.tpl
MISC_OCCAMYGEN_SV_TEMPLATES += $(SOURCE_OCCAMY_DIR)/occamy_pkg.sv.tpl
MISC_OCCAMYGEN_SV_TEMPLATES += $(SOURCE_OCCAMY_DIR)/occamy_quadrant_s1.sv.tpl
MISC_OCCAMYGEN_SV_TEMPLATES += $(SOURCE_OCCAMY_DIR)/occamy_quadrant_s1_ctrl.sv.tpl
MISC_OCCAMYGEN_SV_TEMPLATES += $(SOURCE_OCCAMY_DIR)/occamy_xilinx.sv.tpl
MISC_OCCAMYGEN_SV_TEMPLATES += $(SOURCE_OCCAMY_DIR)/occamy_cva6.sv.tpl

MISC_OCCAMYGEN_SV_TARGETS  = $(addprefix $(TARGET_SRC_DIR)/,$(notdir $(basename $(MISC_OCCAMYGEN_SV_TEMPLATES))))
MISC_OCCAMYGEN_SV_TARGETS += $(TARGET_SRC_DIR)/occamy_cluster_wrapper.sv

MISC_OCCAMYGEN_TARGETS  = $(MISC_OCCAMYGEN_SV_TARGETS)
MISC_OCCAMYGEN_TARGETS += $(TARGET_SRC_DIR)/occamy_memories.json

soc: $(MISC_OCCAMYGEN_TARGETS)
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
		--cva6-sv          $(SOURCE_OCCAMY_DIR)/occamy_cva6.sv.tpl
	@$(VERIBLE_FMT) --inplace $(MISC_OCCAMYGEN_SV_TARGETS)
	@touch $@

tb: $(TARGET_TEST_DIR)/testharness.sv
clean-tb:
	rm -rf $(TARGET_TEST_DIR)/testharness.sv

$(TARGET_TEST_DIR)/testharness.sv: $(TARGET_TEST_DIR)/testharness.sv.tpl $(CFG)
	@echo "[OCCAMYGEN] Generate $@"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir test --testharness-sv $<
	@$(VERIBLE_FMT) --inplace $@

# TODO
# 	@$(OCCAMYGEN) --cfg $(CFG) \
# 		--bootdata       ../../ip/snitch_cluster/test/bootdata.cc.tpl
# 	@echo "[SOLDER] Device Tree"
# 	@$(OCCAMYGEN) --cfg $(CFG) --outdir . --dts test/occamy.dts

$(TARGET_PLIC_DIR) $(TARGET_CLINT_DIR) $(TARGET_SOCCTRL_DIR) $(TARGET_HBMCTRL_DIR) $(TARGET_QUADCTRL_DIR):
	@mkdir -p $@

CLINTROOT = $(shell $(BENDER) path clint)
CLINT_OCCAMYGEN_TARGETS = $(addprefix $(TARGET_CLINT_DIR)/,clint.sv clint.hjson)
CLINT_REGGEN_TARGETS = $(addprefix $(TARGET_CLINT_DIR)/,clint_reg_pkg.sv clint_reg_top.sv)

clint: $(CLINT_OCCAMYGEN_TARGETS) $(CLINT_REGGEN_TARGETS)
clean-clint:
	rm -rf $(CLINT_OCCAMYGEN_TARGETS) $(CLINT_REGGEN_TARGETS) .clint_reggen_targets_group

$(TARGET_CLINT_DIR)/clint.%: $(CLINTROOT)/data/clint.%.tpl $(CFG) | $(TARGET_CLINT_DIR)
	@echo "[OCCAMYGEN] Generate $@"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir $(TARGET_CLINT_DIR) --chip $<

# We simulate grouped targets (supported only in make>=4.3) in the following way
# $(CLINT_REGGEN_TARGETS) &: $(TARGET_CLINT_DIR)/clint.hjson | $(TARGET_CLINT_DIR)
# 	@echo "[REGGEN] Generate $(CLINT_REGGEN_TARGETS)"
# 	@$(REGGEN) -r -t $(TARGET_CLINT_DIR) $<
# 	@$(VERIBLE_FMT) --inplace $(CLINT_REGGEN_TARGETS)
$(CLINT_REGGEN_TARGETS): .clint_reggen_targets_group
.clint_reggen_targets_group: $(TARGET_CLINT_DIR)/clint.hjson | $(TARGET_CLINT_DIR)
	@echo "[REGGEN] Generate $(CLINT_REGGEN_TARGETS)"
	@$(REGGEN) -r -t $(TARGET_CLINT_DIR) $<
	@$(VERIBLE_FMT) --inplace $(CLINT_REGGEN_TARGETS)
	@touch $@

PLICROOT = $(ROOT)/hw/vendor/pulp_platform_opentitan_peripherals/src/rv_plic
PLICGEN = $(PLICROOT)/util/reg_rv_plic.py
PLIC_PLICGEN_TARGETS = $(addprefix $(TARGET_PLIC_DIR)/,rv_plic.sv rv_plic.hjson)
PLIC_REGGEN_TARGETS = $(addprefix $(TARGET_PLIC_DIR)/,rv_plic_reg_pkg.sv rv_plic_reg_top.sv)

plic: $(PLIC_PLICGEN_TARGETS) $(PLIC_REGGEN_TARGETS)
clean-plic:
	rm -rf $(PLIC_PLICGEN_TARGETS) $(PLIC_REGGEN_TARGETS) .plic_reggen_targets_group

$(TARGET_PLIC_DIR)/rv_plic.%: $(PLICROOT)/data/rv_plic.%.tpl | $(TARGET_PLIC_DIR)
	@echo "[PLICGEN] Generate $@"
	@$(PLICGEN) -s 73 -t 2 -p 6 $< > $@

# We simulate grouped targets (supported only in make>=4.3) in the following way
# $(PLIC_REGGEN_TARGETS) &: $(TARGET_PLIC_DIR)/rv_plic.hjson | $(TARGET_PLIC_DIR)
# 	@echo "[REGGEN] Generate $(PLIC_REGGEN_TARGETS)"
# 	@$(REGGEN) -r -t $(TARGET_PLIC_DIR) $<
# 	@$(VERIBLE_FMT) --inplace $(PLIC_REGGEN_TARGETS)
$(PLIC_REGGEN_TARGETS): .plic_reggen_targets_group
.plic_reggen_targets_group: $(TARGET_PLIC_DIR)/rv_plic.hjson | $(TARGET_PLIC_DIR)
	@echo "[REGGEN] Generate $(PLIC_REGGEN_TARGETS)"
	@$(REGGEN) -r -t $(TARGET_PLIC_DIR) $<
	@$(VERIBLE_FMT) --inplace $(PLIC_REGGEN_TARGETS)
	@touch $@

SOCCTRL_OCCAMYGEN_TARGETS = $(TARGET_SOCCTRL_DIR)/occamy_soc_reg.hjson
SOCCTRL_REGGEN_TARGETS = $(addprefix $(TARGET_SOCCTRL_DIR)/,occamy_soc_reg_pkg.sv occamy_soc_reg_top.sv)

socctrl: $(SOCCTRL_OCCAMYGEN_TARGETS) $(SOCCTRL_REGGEN_TARGETS)
clean-socctrl:
	rm -rf $(SOCCTRL_OCCAMYGEN_TARGETS) $(SOCCTRL_REGGEN_TARGETS) .socctrl_reggen_targets_group

$(TARGET_SOCCTRL_DIR)/occamy_soc_reg.hjson: $(SOURCE_SOCCTRL_DIR)/occamy_soc_reg.hjson.tpl $(CFG) | $(TARGET_SOCCTRL_DIR)
	@echo "[OCCAMYGEN] Generate $@"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir $(TARGET_SOCCTRL_DIR) --chip $<

# We simulate grouped targets (supported only in make>=4.3) in the following way
# $(SOCCTRL_REGGEN_TARGETS) &: $(TARGET_SOCCTRL_DIR)/occamy_soc_reg.hjson | $(TARGET_SOCCTRL_DIR)
# 	@echo "[REGGEN] Generate $(SOCCTRL_REGGEN_TARGETS)"
# 	@$(REGGEN) -r -t $(TARGET_SOCCTRL_DIR) $<
# 	@$(VERIBLE_FMT) --inplace $(SOCCTRL_REGGEN_TARGETS)
$(SOCCTRL_REGGEN_TARGETS): .socctrl_reggen_targets_group
.socctrl_reggen_targets_group: $(TARGET_SOCCTRL_DIR)/occamy_soc_reg.hjson | $(TARGET_SOCCTRL_DIR)
	@echo "[REGGEN] Generate $(SOCCTRL_REGGEN_TARGETS)"
	@$(REGGEN) -r -t $(TARGET_SOCCTRL_DIR) $<
	@$(VERIBLE_FMT) --inplace $(SOCCTRL_REGGEN_TARGETS)
	@touch $@

HBMCTRL_OCCAMYGEN_TARGETS = $(TARGET_HBMCTRL_DIR)/occamy_hbm_xbar_reg.hjson
HBMCTRL_REGGEN_TARGETS = $(addprefix $(TARGET_HBMCTRL_DIR)/,occamy_hbm_xbar_reg_pkg.sv occamy_hbm_xbar_reg_top.sv)

hbmctrl: $(HBMCTRL_OCCAMYGEN_TARGETS) $(HBMCTRL_REGGEN_TARGETS)
clean-hbmctrl:
	rm -rf $(HBMCTRL_OCCAMYGEN_TARGETS) $(HBMCTRL_REGGEN_TARGETS) .hbmctrl_reggen_targets_group

$(TARGET_HBMCTRL_DIR)/occamy_hbm_xbar_reg.hjson: $(SOURCE_HBMCTRL_DIR)/occamy_hbm_xbar_reg.hjson.tpl $(CFG) | $(TARGET_HBMCTRL_DIR)
	@echo "[OCCAMYGEN] Generate $@"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir $(TARGET_HBMCTRL_DIR) --chip $<

# We simulate grouped targets (supported only in make>=4.3) in the following way
# $(HBMCTRL_REGGEN_TARGETS) &: $(TARGET_HBMCTRL_DIR)/occamy_hbm_xbar_reg.hjson | $(TARGET_HBMCTRL_DIR)
# 	@echo "[REGGEN] Generate $(HBMCTRL_REGGEN_TARGETS)"
# 	@$(REGGEN) -r -t $(TARGET_HBMCTRL_DIR) $<
# 	@$(VERIBLE_FMT) --inplace $(HBMCTRL_REGGEN_TARGETS)
$(HBMCTRL_REGGEN_TARGETS): .hbmctrl_reggen_targets_group
.hbmctrl_reggen_targets_group: $(TARGET_HBMCTRL_DIR)/occamy_hbm_xbar_reg.hjson | $(TARGET_HBMCTRL_DIR)
	@echo "[REGGEN] Generate $(HBMCTRL_REGGEN_TARGETS)"
	@$(REGGEN) -r -t $(TARGET_HBMCTRL_DIR) $<
	@$(VERIBLE_FMT) --inplace $(HBMCTRL_REGGEN_TARGETS)
	@touch $@

QUADCTRL_OCCAMYGEN_TARGETS = $(TARGET_QUADCTRL_DIR)/occamy_quadrant_s1_reg.hjson
QUADCTRL_REGGEN_TARGETS = $(addprefix $(TARGET_QUADCTRL_DIR)/,occamy_quadrant_s1_reg_pkg.sv occamy_quadrant_s1_reg_top.sv)

quadctrl: $(QUADCTRL_OCCAMYGEN_TARGETS) $(QUADCTRL_REGGEN_TARGETS)
clean-quadctrl:
	rm -rf $(QUADCTRL_OCCAMYGEN_TARGETS) $(QUADCTRL_REGGEN_TARGETS) .quadctrl_reggen_targets_group

$(TARGET_QUADCTRL_DIR)/occamy_quadrant_s1_reg.hjson: $(SOURCE_QUADCTRL_DIR)/occamy_quadrant_s1_reg.hjson.tpl $(CFG) | $(TARGET_QUADCTRL_DIR)
	@echo "[OCCAMYGEN] Generate $@"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir $(TARGET_QUADCTRL_DIR) --chip $<

# We simulate grouped targets (supported only in make>=4.3) in the following way
# $(QUADCTRL_REGGEN_TARGETS) &: $(TARGET_QUADCTRL_DIR)/occamy_quadrant_s1_reg.hjson | $(TARGET_QUADCTRL_DIR)
# 	@echo "[REGGEN] Generate $(QUADCTRL_REGGEN_TARGETS)"
# 	@$(REGGEN) -r -t $(TARGET_QUADCTRL_DIR) $<
# 	@$(VERIBLE_FMT) --inplace $(QUADCTRL_REGGEN_TARGETS)
$(QUADCTRL_REGGEN_TARGETS): .quadctrl_reggen_targets_group
.quadctrl_reggen_targets_group: $(TARGET_QUADCTRL_DIR)/occamy_quadrant_s1_reg.hjson | $(TARGET_QUADCTRL_DIR)
	@echo "[REGGEN] Generate $(QUADCTRL_REGGEN_TARGETS)"
	@$(REGGEN) -r -t $(TARGET_QUADCTRL_DIR) $<
	@$(VERIBLE_FMT) --inplace $(QUADCTRL_REGGEN_TARGETS)
	@touch $@

###############
# Address Map #
###############

ADDRMAP_CSV     = $(TARGET_ADDRMAP_DIR)/addrmap.csv
ADDRMAP_DOT     = $(TARGET_ADDRMAP_DIR)/addrmap.dot
ADDRMAP_TEX     = $(TARGET_ADDRMAP_DIR)/addrmap.tex
ADDRMAP_TEX_TPL = $(SOURCE_ADDRMAP_DIR)/addrmap.tex.tpl
ADDRMAP_PNG     = $(TARGET_ADDRMAP_DIR)/addrmap.png
ADDRMAP_MD      = $(DOCS_DIR)/rm/2_addrmap.md
ADDRMAP_PDF     = $(TARGET_ADDRMAP_DIR)/addrmap.pdf

ADDRMAP_TARGETS  = $(ADDRMAP_DOT)
ADDRMAP_TARGETS += $(ADDRMAP_CSV)
ADDRMAP_TARGETS += $(ADDRMAP_TEX)
ADDRMAP_TARGETS += $(ADDRMAP_MD)
ADDRMAP_TARGETS += $(ADDRMAP_PNG)
ADDRMAP_TARGETS += $(ADDRMAP_PDF)

.PHONY: addrmap clean-addrmap

# Generate address map in all formats
addrmap: $(ADDRMAP_TARGETS)

clean-addrmap:
	rm -rf $(TARGET_ADDRMAP_DIR)

$(TARGET_ADDRMAP_DIR):
	mkdir $@

ADDRMAP_OCCAMYGEN_TARGETS = $(ADDRMAP_DOT) $(ADDRMAP_CSV)
$(ADDRMAP_OCCAMYGEN_TARGETS): .addrmap_occamygen_targets_group
.addrmap_occamygen_targets_group: $(CFG) | $(TARGET_ADDRMAP_DIR)
	@echo "[OCCAMYGEN] Generate $(ADDRMAP_OCCAMYGEN_TARGETS)"
	@$(OCCAMYGEN) --cfg $(CFG) --outdir $(TARGET_ADDRMAP_DIR) \
		--graph  $(ADDRMAP_DOT) \
		--am-csv $(ADDRMAP_CSV)
	@touch $@

$(ADDRMAP_PNG): $(ADDRMAP_DOT) | $(TARGET_ADDRMAP_DIR)
	dot -Tpng $(ADDRMAP_DOT) > $(ADDRMAP_PNG)

$(ADDRMAP_TEX): $(ADDRMAP_CSV) $(ADDRMAP_TEX_TPL) | $(TARGET_ADDRMAP_DIR)
	@$(ADDRMAPGEN) --file $(ADDRMAP_CSV) --outdir $(dir $@) --tex $(ADDRMAP_TEX_TPL)

$(ADDRMAP_MD): $(ADDRMAP_CSV) | $(TARGET_ADDRMAP_DIR)
	@$(ADDRMAPGEN) --file $(ADDRMAP_CSV) --outdir $(dir $@) --md $(notdir $@)

$(ADDRMAP_PDF): $(ADDRMAP_TEX) | $(TARGET_ADDRMAP_DIR)
	cd $(TARGET_ADDRMAP_DIR) && latexmk -quiet -pdf $(notdir $(ADDRMAP_TEX))

############
# Software #
############

IDMAROOT = $(shell $(BENDER) path idma)

PLATFORM_HEADERS  = $(PLATFORM_HEADERS_DIR)/occamy_cfg.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/occamy_base_addr.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/clint.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/occamy_soc_ctrl.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_cluster_peripheral.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_quad_peripheral.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_hbm_xbar_peripheral.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/idma.h

.PHONY: sw clean-headers clean-sw

sw: $(PLATFORM_HEADERS)
	$(MAKE) -C sw/ all

clean-headers:
	rm -f $(PLATFORM_HEADERS)

clean-sw: clean-headers
	$(MAKE) -C sw/ clean

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

##########
# Traces #
##########

traces: $(CVA6_TXT_TRACE) $(CVA6_PERF_DUMP)
annotate: $(CVA6_ANNOTATED_TRACE)

$(CVA6_TXT_TRACE): $(SIM_DIR)/trace_hart_0.log
	cp $< $@

# CVA6 traces require different handling
$(CVA6_PERF_DUMP): $(CVA6_TXT_TRACE) $(EVENTS_PY)
	$(PYTHON) $(EVENTS_PY) -f cva6 $< -o $@
$(CVA6_ANNOTATED_TRACE): $(CVA6_TXT_TRACE) $(ANNOTATE_PY)
	$(PYTHON) $(ANNOTATE_PY) $(ANNOTATE_FLAGS) -o $@ $(CVA6_BINARY) $<

############
# Questasim #
############

include $(SNITCH_ROOT)/target/common/vsim.mk

# Add dependency on bootrom
$(BIN_DIR)/$(TARGET).vsim: $(TARGET_TEST_DIR)/bootrom.bin

#######
# VCS #
#######

# Build compilation script and compile all sources for VCS simulation
$(BIN_DIR)/$(TARGET).vcs: work-vcs/compile.sh work/lib/libfesvr.a ${TB_CC_SOURCES} $(TARGET_TEST_DIR)/bootrom.bin
	mkdir -p bin
	vcs $(VCS_FLAGS) -o $(BIN_DIR)/$(TARGET).vcs tb_bin -cc $(CC) -cpp $(CXX) \
		$(TB_CC_SOURCES) -CFLAGS "$(TB_CC_FLAGS)" -LDFLAGS "-L${FESVR}/lib" -lfesvr -lutil

# Clean all build directories and temporary files for VCS simulation
.PHONY: clean-vcs
clean-vcs: clean-work
	rm -rf AN.DB
	rm -rf work-vcs
	rm -f $(BIN_DIR)/$(TARGET).vcs

########
# FPGA #
########

# Build a small Occamy version (CVA6 + 1 cluster) for the VCU128 FPGA board
.PHONY: fpga
fpga:
	${MAKE} -C fpga occamy_vcu128

########
# Util #
########

.PHONY: clean-work clean-bender clean-logs help

clean-work:
	rm -rf work

clean-bender:
	rm -rf $(ROOT)/.bender/ $(ROOT)/deps

clean-logs:
	rm -rf $(LOGS_DIR)/

# Help command
Blue=\033[1;34m
Black=\033[0m
help:
	@echo -e "${Blue}Makefile Targets${Black} for the ${Blue}Snitch Cluster${Black}"
	@echo -e "Use 'make <target>' where <target> is one of:"
	@echo -e ""
	@echo -e "${Blue}help           ${Black}Show an overview of all Makefile targets."
	@echo -e ""
	@echo -e "${Blue}bin/$(TARGET).vcs  ${Black}Build compilation script and compile all sources for VCS simulation. @IIS: vcs-2020.12 make bin/$(TARGET).vcs"
	@echo -e "${Blue}bin/$(TARGET).vsim ${Black}Build compilation script and compile all sources for Questasim simulation. @IIS: QUESTA_HOME=/usr/pack/modelsim-10.7b-kgf/questasim/ CC=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/gcc CXX=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/g++ LD=$(QUESTA_HOME)/gcc-5.3.0-linux_x86_64/bin/ld make bin/$(TARGET).vsim"
	@echo -e ""
	@echo -e "${Blue}all            ${Black}Update all SW and HW related sources (by, e.g., re-generating the RegGen registers and their c-header files)."
	@echo -e "${Blue}fpga           ${Black}Build a small Occamy version (CVA6 + 1xcluster) for the VCU128 FPGA board."
	@echo -e ""
	@echo -e "${Blue}addrmap        ${Black}Generate the addressmap in the following formats: MD, PNG, TEX, PDF."
	@echo -e ""
	@echo -e "${Blue}clean          ${Black}Clean everything except traces in logs directory."
	@echo -e "${Blue}clean-bender   ${Black}Clean all Bender generated files."
	@echo -e "${Blue}clean-sw       ${Black}Clean all software."
	@echo -e "${Blue}clean-addrmap  ${Black}Delete all addrmap outputs."
	@echo -e "${Blue}clean-logs     ${Black}Delete all traces in logs directory."
	@echo -e "${Blue}clean-vcs      ${Black}Clean all build directories and temporary files for VCS simulation."
	@echo -e "${Blue}clean-vsim     ${Black}Clean all build directories and temporary files for Questasim simulation."
	@echo -e ""
	@echo -e "${Blue}sw             ${Black}Build all software."
	@echo -e "${Blue}rtl            ${Black}Build all auto-generated RTL sources."
	@echo -e ""
	@echo -e "Additional useful targets from the included Makefrag:"
	@echo -e "${Blue}traces         ${Black}Generate the better readable traces in .logs/trace_hart_<hart_id>.txt with spike-dasm."
	@echo -e "${Blue}annotate       ${Black}Annotate the better readable traces in .logs/trace_hart_<hart_id>.s with the source code related with the retired instructions."