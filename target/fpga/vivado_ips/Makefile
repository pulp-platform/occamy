# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../..
DEBUG       ?= 0

VIVADO ?= vivado
BENDER ?= bender

BENDER_TARGETS = $(shell cat $(MKFILE_DIR)../../rtl/src/bender_targets.tmp)
BENDER_TARGETS += -t xilinx

ifeq ($(EXT_JTAG), 0)
	BENDER_TARGETS += -t bscane
endif

include $(ROOT)/util/Makefrag

occamy_xilinx: define-sources.tcl
	# $(MAKE) -C ../../ update-source
	# $(MAKE) -C ../../sim rtl

	${VIVADO} -mode batch -source occamy_xilinx.tcl -tclargs $(DEBUG) $(EXT_JTAG)

define-sources.tcl:
	echo $(BENDER_TARGETS)
	${BENDER} script vivado $(BENDER_TARGETS) > $@

clean:
	rm -rf .Xil occamy_xilinx vivado* define-sources.tcl component.xml xgui *.jou *.log
