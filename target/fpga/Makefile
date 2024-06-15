# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../..
CVA6_SDK    ?= ${ROOT}/../cva6-sdk
DEBUG       ?= 1
EXT_JTAG    ?= 1

VIVADO ?= vivado
NPROC  ?= $(shell nproc)

BENDER_TARGETS += -t cv64a6_imafdc_sv39 -t occamy -t snax_cluster

ifndef SNAX_MINIMAL
	BENDER_TARGETS += -t snax_streamer_gemm -t snax_streamer_simd -t snax_data_reshuffler
endif

default: all
all: occamy_vcu128

include $(ROOT)/util/Makefrag

vivado_ips/occamy_xilinx:
	${MAKE} -C vivado_ips occamy_xilinx

.PHONY:occamy_vcu128 sw

sw:
	${MAKE} -C sw sw

occamy_vcu128: vivado_ips/occamy_xilinx define_defines_includes_no_simset.tcl
	${VIVADO} -mode batch -source occamy_vcu128_2023.tcl -tclargs $(DEBUG) $(EXT_JTAG) $(NPROC)

define_defines_includes_no_simset.tcl: $(BENDER_FILES)
	${BENDER} script vivado $(BENDER_TARGETS) --only-defines --only-includes --no-simset > $@

clean:
	rm -rf .Xil occamy_vcu128 *.jou *.log *.str define_defines_includes_no_simset.tcl

.PHONY: program flash clean
