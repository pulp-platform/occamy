MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
TARGET 		:= $(MKFILE_DIR)../..
ROOT        := ${MKFILE_DIR}../../..

VIVADO	  := vivado

BOOTROM		?= $(TARGET)/fpga/bootrom/bootrom.bin
APP		?= $(TARGET)/sim/sw/host/apps/hello_world/build/hello_world.elf
BIN2JTAG	?= $(ROOT)/util/bin2jtag.py
BIN_VERIFY	?= $(ROOT)/util/bin2jtag_only_verify.py

.PHONY: sw download_sw clean verify_sw

sw: bootrom.coe bootrom.tcl app.tcl app_verify.tcl

bootrom.coe: $(BOOTROM)
	bin2coe -i $< -w 32 -o $@

bootrom.tcl: $(BOOTROM)
	$(BIN2JTAG) -c32 -b 0 -d hw_axi_1 $< > $@

app.bin: 
	riscv64-unknown-elf-objcopy -O binary $(APP) $@

app.tcl: app.bin
	$(BIN2JTAG) -c32 -b 80000000 -d hw_axi_2 $< > $@

app_verify.tcl: app.bin
	$(BIN_VERIFY) -c32 -b 80000000 -d hw_axi_2 $< > $@

download_sw: 
	${VIVADO} -mode batch -source download_sw.tcl

verify_sw:
	${VIVADO} -mode batch -source verify_sw.tcl

clean:
	@rm -f app.bin app.tcl bootrom.tcl *.log *.jou
