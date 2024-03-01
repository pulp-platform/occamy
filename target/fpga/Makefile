# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../../..
CVA6_SDK    ?=
DEBUG       ?= 0
EXT_JTAG    ?= 0
FPGA_PATH   := $(XILINX_FPGA_PATH)
HW_SERVER   := $(XILINX_HOST):$(XILINX_PORT)
BENDER      ?= bender
VIVADO      ?= vitis-2020.2 vivado
# Do not proceed with implem (CI)
XILINX_SYNTHESIS_ONLY ?= 0

VIVADO ?= vivado
VIVADO_ARGS := XILINX_SYNTHESIS_ONLY=$(XILINX_SYNTHESIS_ONLY)
MKIMAGE ?= $(CURDIR)/br2_external/install/bin/mkimage
NPROC  ?= $(shell nproc)

# U-boot and OpenSBI wrapped in an mkimage wrapper
UBOOT_ITB ?= ${CVA6_SDK}/u-boot/u-boot.itb
# U-boot compatible Linux image
LINUX_UIMAGE ?= ${CVA6_SDK}/uImage

DTB = bootrom/occamy.dtb

BENDER_TARGETS += -t cv64a6_imafdc_sv39 -t occamy
ifeq ($(EXT_JTAG), 0)
	BENDER_TARGETS += -t bscane
endif

default: all
all: occamy_vcu128

vivado_ips/occamy_xilinx:
	${MAKE} -C vivado_ips occamy_xilinx DEBUG=$(DEBUG) EXT_JTAG=$(EXT_JTAG)

bootrom/bootrom-spl.coe:
	${MAKE} -C bootrom

occamy_vcu128: vivado_ips/occamy_xilinx bootrom/bootrom-spl.coe define_defines_includes_no_simset.tcl
	$(VIVADO_ARGS) ${VIVADO} -mode gui -source occamy_vcu128.tcl -tclargs $(DEBUG) $(EXT_JTAG) $(NPROC) ${MKFILE_DIR}/bootrom/bootrom-spl.coe

define_defines_includes_no_simset.tcl: $(BENDER_FILES)
	${BENDER} script vivado $(BENDER_TARGETS) --only-defines --only-includes --no-simset > $@

program:
	${VIVADO} -mode batch -source occamy_vcu128_program.tcl -tclargs ${VCU}

flash: ${FILE}
	${VIVADO} -mode batch -source occamy_vcu128_flash.tcl -tclargs ${HW_SERVER} ${FPGA_PATH} flash.mcs ${OFFSET} ${FILE}
	rm flash.mcs

# Flash only uboot (made for TFTP bootmode), overwrite the bootrom, and reset the board
flashrun: ${UBOOT_ITB}
	${VIVADO} -mode batch -source occamy_vcu128_flashrun.tcl -tclargs ${HW_SERVER} ${FPGA_PATH} flash.mcs 6000000 ${UBOOT_ITB}
	rm flash.mcs

flash-u-boot:
	${MAKE} flash FILE=${UBOOT_ITB} OFFSET=0x6000000

# Flash Linux at some 
flash-uimage:
	${MAKE} flash FILE=${LINUX_UIMAGE} OFFSET=0x6100000

clean:
	rm -rf .Xil occamy_vcu128 *.jou *.log *.str define_defines_includes_no_simset.tcl

.PHONY: program flash clean
