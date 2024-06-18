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
clean: clean-bender clean-rtl clean-sw clean-addrmap clean-vlt clean-vcs clean-logs clean-work

############
# Makefrag #
############

# Common definitions used by included Makefiles

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
SIM_MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := $(SIM_MKFILE_DIR)../..
SNITCH_ROOT := $(shell bender path snitch_cluster)

TARGET = occamy_top

CVA6_TXT_TRACE       = $(LOGS_DIR)/trace_hart_00000.txt
CVA6_PERF_DUMP       = $(LOGS_DIR)/hart_00000_perf.json
CVA6_ANNOTATED_TRACE = $(LOGS_DIR)/trace_hart_00000.s
TXT_TRACES          += $(CVA6_TXT_TRACE)
PERF_DUMPS          += $(CVA6_PERF_DUMP)
ANNOTATED_TRACES    += $(CVA6_ANNOTATED_TRACE)

include ../../deps/snitch_cluster/target/common/common.mk

include $(ROOT)/target/rtl/Makefile

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
TARGET_PLIC_DIR      ?= $(TARGET_SRC_DIR)/rv_plic
TARGET_CLINT_DIR     ?= $(TARGET_SRC_DIR)/clint
TARGET_SOCCTRL_DIR   ?= $(TARGET_SRC_DIR)/soc_ctrl
TARGET_HBMCTRL_DIR   ?= $(TARGET_SRC_DIR)/hbm_xbar_ctrl
TARGET_QUADCTRL_DIR  ?= $(TARGET_SRC_DIR)/quadrant_s1_ctrl
SOURCE_OCCAMY_DIR    ?= $(ROOT)/hw/occamy
SOURCE_SOCCTRL_DIR   ?= $(ROOT)/hw/occamy/soc_ctrl
SOURCE_HBMCTRL_DIR   ?= $(ROOT)/hw/occamy/hbm_xbar_ctrl
SOURCE_QUADCTRL_DIR  ?= $(ROOT)/hw/occamy/quadrant_s1_ctrl
SNITCH_TEST_DIR      ?= $(SNITCH_ROOT)/target/common/test
TARGET_TEST_DIR      ?= $(ROOT)/target/rtl/test
TARGET_DTS_DIR		 ?= $(ROOT)/target/fpga/bootrom
CVA6_TRACE            = trace_hart_0.log

# If the configuration file is overriden on the command-line (through
# CFG_OVERRIDE) and this file differs from the least recently used
# (LRU) config, all targets depending on the configuration file have
# to be rebuilt. This file is used to express this condition as a
# prerequisite for other rules.
# CFG = ../rtl/cfg/lru.hjson

#####################
# Simulator options #
#####################


# We need to change the Bender.yml of the snax_gemm repo
# The original target: snax-gemm will trigger the questasim error
# So i change it to snax_gemm
# VSIM_BENDER += -t snax_gemm
# This target is to match the header of the snax_gemm_wrapper.sv
# VSIM_BENDER += -t SYNTHESIS_SNAX_DEV_ONLY
# This target is to snax-streamer-gemm

VSIM_BENDER += -t cv64a6_imafdc_sv39 
VSIM_BENDER += -t occamy

VLT_BENDER  += -t cv64a6_imafdc_sv39 
VLT_BENDER  += -t occamy 

VLT_BENDER  += -t SYNTHESIS_SNAX_DEV_ONLY

ifdef SNAX_XIAOLING
	VSIM_BENDER += -t snax_streamer_gemm -t snax_streamer_simd -t snax_data_reshuffler -t snax_xiaoling
	VLT_BENDER  += -t snax_streamer_gemm -t snax_streamer_simd -t snax_data_reshuffler -t snax_xiaoling
endif

ifdef SNAX_MINIMAL
	VSIM_BENDER += -t snax_minimal
	VLT_BENDER += -t snax_minimal
endif

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

# Verilated and compiled Occamy system
VLT_AR     = ${VLT_BUILDDIR}/Vtestharness__ALL.a

VLT_FLAGS += -Wno-SYMRSVDWORD -Wno-BLKLOOPINIT
VLT_FLAGS += --trace       # Enable VCD dumping
VLT_FLAGS += --prof-cfuncs # Enable code profiling

###############
# C testbench #
###############

TB_CC_SOURCES  = $(SNITCH_TEST_DIR)/bootrom.cc
TB_CC_SOURCES += $(SNITCH_TEST_DIR)/ipc.cc
TB_CC_SOURCES += $(SNITCH_TEST_DIR)/rtl_lib.cc
TB_CC_SOURCES += $(SNITCH_TEST_DIR)/common_lib.cc
TB_CC_SOURCES += $(TARGET_TEST_DIR)/bootdata.cc
TB_CC_SOURCES += $(TARGET_TEST_DIR)/uartdpi/uartdpi.c

FESVR = $(SIM_MKFILE_DIR)/work

TB_CC_FLAGS  = -std=c++14
TB_CC_FLAGS +=-I$(SIM_MKFILE_DIR)
TB_CC_FLAGS +=-I$(SIM_MKFILE_DIR)/test
TB_CC_FLAGS +=-I$(FESVR)/include
TB_CC_FLAGS +=-I$(SNITCH_TEST_DIR)
TB_CC_FLAGS +=-I$(TARGET_TEST_DIR)/uartdpi

# Required C sources for the verilator TB that are linked against the verilated model
VLT_COBJ  = $(VLT_BUILDDIR)/tb/bootrom.o
VLT_COBJ += $(VLT_BUILDDIR)/tb/ipc.o
VLT_COBJ += $(VLT_BUILDDIR)/tb/common_lib.o
VLT_COBJ += $(VLT_BUILDDIR)/tb/verilator_lib.o
VLT_COBJ += $(VLT_BUILDDIR)/tb/tb_bin.o
VLT_COBJ += $(VLT_BUILDDIR)/test/uartdpi/uartdpi.o
VLT_COBJ += $(VLT_BUILDDIR)/test/bootdata.o
# Sources from verilator root
VLT_COBJ += $(VLT_BUILDDIR)/vlt/verilated.o
VLT_COBJ += $(VLT_BUILDDIR)/vlt/verilated_dpi.o
VLT_COBJ += $(VLT_BUILDDIR)/vlt/verilated_vcd_c.o

############
# Boot ROM #
############

BOOTROM_TARGETS = test/bootrom.elf test/bootrom.dump test/bootrom.bin test/bootdata.cc

.PHONY: bootrom clean-bootrom

bootrom: $(BOOTROM_TARGETS)

clean-bootrom:
	rm -rf $(BOOTROM_TARGETS)
	
test/bootdata.cc:
	@$(OCCAMYGEN) --cfg $(CFG) --bootdata test/bootdata.cc.tpl -o test/
test/bootrom.elf: test/bootrom.S test/bootrom.ld
	riscv64-unknown-elf-gcc -mabi=lp64d -march=rv64imafd -static -nostartfiles -Ttest/bootrom.ld $< -o test/bootrom.elf
test/bootrom.dump: test/bootrom.elf
	riscv64-unknown-elf-objdump -D $< > $@
test/bootrom.bin: test/bootrom.elf
	riscv64-unknown-elf-objcopy -O binary $< $@


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

PLATFORM_HEADERS  = $(PLATFORM_HEADERS_DIR)/occamy_cfg.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/occamy_base_addr.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/clint.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/occamy_soc_ctrl.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_cluster_peripheral.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_quad_peripheral.h
PLATFORM_HEADERS += $(PLATFORM_HEADERS_DIR)/snitch_hbm_xbar_peripheral.h

.PHONY: sw clean-headers clean-sw

sw: $(PLATFORM_HEADERS)
	$(MAKE) -C sw/ all

clean-headers:
	rm -f $(PLATFORM_HEADERS)

clean-sw: clean-headers
	$(MAKE) -C sw/ clean

# REGGEN headers
$(PLATFORM_HEADERS_DIR)/clint.h: $(TARGET_SRC_DIR)/clint/clint.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/occamy_soc_ctrl.h: $(TARGET_SOCCTRL_DIR)/occamy_soc_reg.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/snitch_cluster_peripheral.h: $(SNITCH_ROOT)/hw/snitch_cluster/src/snitch_cluster_peripheral/snitch_cluster_peripheral_reg.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/snitch_quad_peripheral.h: $(TARGET_QUADCTRL_DIR)/occamy_quadrant_s1_reg.hjson
	$(call reggen_generate_header,$@,$<)
$(PLATFORM_HEADERS_DIR)/snitch_hbm_xbar_peripheral.h: $(TARGET_HBMCTRL_DIR)/occamy_hbm_xbar_reg.hjson
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

CVA6_BINARY ?= $(shell cat $(LOGS_DIR)/.rtlbinary)

CVA6_TXT_TRACE       = $(LOGS_DIR)/trace_hart_00000.txt
CVA6_PERF_TRACE      = $(LOGS_DIR)/hart_00000_perf.json
CVA6_ANNOTATED_TRACE = $(LOGS_DIR)/trace_hart_00000.s
CVA6_DIFF_TRACE      = $(LOGS_DIR)/trace_hart_00000.diff

TXT_TRACES       += $(CVA6_TXT_TRACE)
PERF_TRACES      += $(CVA6_PERF_TRACE)
ANNOTATED_TRACES += $(CVA6_ANNOTATED_TRACE)
DIFF_TRACES      += $(CVA6_DIFF_TRACE)

traces: $(CVA6_TXT_TRACE) $(CVA6_PERF_TRACE)
annotate: $(CVA6_ANNOTATED_TRACE)

# CVA6 traces require different handling
$(CVA6_PERF_TRACE): $(CVA6_TXT_TRACE) $(EVENTS_PY)
	$(PYTHON) $(EVENTS_PY) -f cva6 $< -o $@
$(CVA6_ANNOTATED_TRACE): $(CVA6_TXT_TRACE) $(ANNOTATE_PY)
	$(PYTHON) $(ANNOTATE_PY) $(ANNOTATE_FLAGS) -o $@ $(CVA6_BINARY) $<
$(CVA6_DIFF_TRACE): $(CVA6_TXT_TRACE) $(ANNOTATE_PY)
	$(PYTHON) $(ANNOTATE_PY) $(ANNOTATE_FLAGS) -o $@ $(CVA6_BINARY) $< -d

#############
# Verilator #
#############

${VLT_AR}: ${VLT_SOURCES} ${TB_SRCS}
	$(call VERILATE,testharness)

# Quick sanity check, not really meant for simulation.
verilate: ${VLT_AR}

# Build targets for verilator TB
$(VLT_BUILDDIR)/tb/%.o: $(TB_DIR)/%.cc $(VLT_AR) ${VLT_BUILDDIR}/lib/libfesvr.a
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(VLT_CFLAGS) -c $< -o $@
$(VLT_BUILDDIR)/vlt/%.o: $(VLT_ROOT)/include/%.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(VLT_CFLAGS) -c $< -o $@
$(VLT_BUILDDIR)/test/%.o: test/%.cc ${VLT_BUILDDIR}/lib/libfesvr.a
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(VLT_CFLAGS) -c $< -o $@

$(VLT_BUILDDIR)/test/uartdpi/uartdpi.o: test/uartdpi/uartdpi.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(VLT_CFLAGS) -c $< -o $@

# Link verilated archive wich $(VLT_COBJ)
$(BIN_DIR)/$(TARGET).vlt: $(VLT_AR) $(VLT_COBJ) ${VLT_BUILDDIR}/lib/libfesvr.a
	mkdir -p $(dir $@)
	$(CXX) $(LDFLAGS) -std=c++14 -L ${VLT_BUILDDIR}/lib -o $@ $(VLT_COBJ) $(VLT_AR) -lfesvr -lpthread -lutil

# Clean all build directories and temporary files for Verilator simulation
.PHONY: clean-vlt
clean-vlt: clean-work
	rm -rf work-vlt
	rm -f $(BIN_DIR)/$(TARGET).vlt

#############
# Questasim #
#############

# include $(SNITCH_ROOT)/target/common/vsim.mk

$(VSIM_BUILDDIR):
	mkdir -p $@

$(VSIM_BUILDDIR)/compile.vsim.tcl: $(BENDER_LOCK) | $(VSIM_BUILDDIR)
	$(BENDER) script vsim $(VSIM_BENDER) --vlog-arg="$(VLOG_FLAGS) -work $(dir $@) " > $@
	echo '$(VLOG) -work $(dir $@) $(TB_CC_SOURCES) -vv -ccflags "$(TB_CC_FLAGS)"' >> $@
	echo 'return 0' >> $@

$(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/occamy_top.vsim: $(VSIM_BUILDDIR)/compile.vsim.tcl |$(BIN_DIR)
	touch $@
	vsim -c -do "source $<; quit" | tee $(dir $<)vlog.log
	@! grep -P "Errors: [1-9]*," $(dir $<)vlog.log
	vopt $(VOPT_FLAGS) -work $(VSIM_BUILDDIR) tb_bin -o tb_bin_opt | tee $(dir $<)vopt.log
	@! grep -P "Errors: [1-9]*," $(dir $<)vopt.log
	@echo "#!/bin/bash" > $@
	@echo 'binary=$$(realpath $$1)' >> $@
	@echo 'echo $$binary > .rtlbinary' >> $@
	@echo 'vsim +permissive $(VSIM_FLAGS) $$3 -work $(SIM_MKFILE_DIR)/$(VSIM_BUILDDIR) -c \
				-ldflags "-Wl,-rpath,$(FESVR)/lib -L$(FESVR)/lib -lfesvr -lutil" \
				tb_bin_opt +permissive-off ++$$binary ++$$2' >> $@
	@# Rename CVA6 trace to align with Snitch trace names
	@echo "mv ${CVA6_TRACE} $(LOGS_DIR)/trace_hart_00000.txt" >> $@
	@# Move all other traces to logs folder as well
	@echo "mv *trace*.log $(LOGS_DIR)/" >> $@
	@chmod +x $@
	@echo "#!/bin/bash" > $@.gui
	@echo 'binary=$$(realpath $$1)' >> $@.gui
	@echo 'echo $$binary > .rtlbinary' >> $@.gui
	@echo 'vsim +permissive $(VSIM_FLAGS) -work $(SIM_MKFILE_DIR)/$(VSIM_BUILDDIR) \
				-ldflags "-Wl,-rpath,$(FESVR)/lib -L$(FESVR)/lib -lfesvr -lutil" \
				tb_bin_opt +permissive-off ++$$binary ++$$2' >> $@.gui
	@echo "mv ${CVA6_TRACE} $(LOGS_DIR)/trace_hart_00000.txt" >> $@.gui
	@echo "mv *trace*.log $(LOGS_DIR)/" >> $@.gui
	@chmod +x $@.gui

clean-vsim: clean-work
	rm -rf $(BIN_DIR)/$(TARGET).vsim $(BIN_DIR)/$(TARGET).vsim.gui $(VSIM_BUILDDIR) vsim.wlf
# Add dependency on bootrom
$(BIN_DIR)/$(TARGET).vsim: test/bootrom.bin

#######
# VCS #
#######

# Build compilation script and compile all sources for VCS simulation
$(BIN_DIR)/$(TARGET).vcs: work-vcs/compile.sh work/lib/libfesvr.a ${TB_CC_SOURCES} test/bootrom.bin
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
fpga: rtl
	${MAKE} -C ../fpga occamy_vcu128

########
# Util #
########

.PHONY: clean-work clean-bender clean-logs help

clean-work:
	rm -rf work
	rm -rf work-vsim

clean-bender:
	rm -rf $(ROOT)/Bender.lock $(ROOT)/.bender/ $(ROOT)/deps

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
	@echo -e "${Blue}bin/$(TARGET).vlt  ${Black}Build compilation script and compile all sources for Verilator simulation."
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
	@echo -e "${Blue}clean-vlt      ${Black}Clean all build directories and temporary files for Verilator simulation."
	@echo -e "${Blue}clean-vsim     ${Black}Clean all build directories and temporary files for Questasim simulation."
	@echo -e ""
	@echo -e "${Blue}sw             ${Black}Build all software."
	@echo -e "${Blue}rtl            ${Black}Build all auto-generated RTL sources."
	@echo -e ""
	@echo -e "Additional useful targets from the included Makefrag:"
	@echo -e "${Blue}traces         ${Black}Generate the better readable traces in .logs/trace_hart_<hart_id>.txt with spike-dasm."
	@echo -e "${Blue}annotate       ${Black}Annotate the better readable traces in .logs/trace_hart_<hart_id>.s with the source code related with the retired instructions."
