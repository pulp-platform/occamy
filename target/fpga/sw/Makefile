MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
TARGET 		:= $(MKFILE_DIR)../..
ROOT        := ${MKFILE_DIR}../../..

VIVADO	  := vivado

BOOTROM		?= $(TARGET)/rtl/test/bootrom.bin
APP		?= target/sim/sw/host/apps/hello_world/build/hello_world.elf
BIN2JTAG	?= $(ROOT)/util/bin2jtag.py

.PHONY: sw download_sw clean

sw: bootrom.tcl app.tcl

bootrom.tcl:
	$(BIN2JTAG) -c32 -b 0 -d hw_axi_1 $(BOOTROM) > $@

app.bin: 
	riscv64-unknown-elf-objcopy -O binary $(ROOT)/$(APP) $@

app.tcl: app.bin
	$(BIN2JTAG) -c32 -b 80000000 -d hw_axi_2 $< > $@

download_sw: bootrom.tcl app.tcl
	${VIVADO} -mode batch -source download_sw.tcl

clean:
	@rm -f app.bin app.tcl bootrom.tcl *.log *.jou
