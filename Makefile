.PHONY: clean bootrom sw rtl occamy_ip_vcu128 occamy_ip_vcu128_gui occamy_system_vcu128 occamy_system_vcu128_gui
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR := $(dir $(MKFILE_PATH))

CFG ?= snax_two_clusters.hjson

clean:
	make -C ./target/fpga/ clean
	make -C ./target/fpga/vivado_ips/ clean
	make -C ./target/fpga_chip/hemaia_chip/ clean
	make -C ./target/fpga_chip/hemaia_system/ clean
	make -C ./target/sim/ clean
	make -C ./target/rtl/ clean
	make -C ./target/fpga/sw clean
	make -C ./target/fpga/bootrom clean

# Software Generation
bootrom: # In Occamy Docker
# The bootrom used for simulation (light-weight bootrom)
	make -C ./target/sim bootrom CFG_OVERRIDE=../rtl/cfg/occamy_cfg/$(CFG)

# The bootrom used for FPGA protoyping (emulated eeprom, full-functional bootrom)
	make -C ./target/fpga/bootrom bootrom

# The bootrom used for tapeout (embedded real rom, full-functional bootrom with different frequency settings)
	make -C ./target/rtl/bootrom bootrom

sw: # In Occamy Docker
	make -C ./target/sim sw CFG_OVERRIDE=../rtl/cfg/occamy_cfg/$(CFG)

# The software from simulation and FPGA prototyping comes from one source. If we intend to download the sodtware to FPGA, elf2bin should be done by objcopy in Occamy docker. 

# Hardware Generation
rtl: # In SNAX Docker
	make -C ./target/rtl/ rtl CFG_OVERRIDE=cfg/occamy_cfg/$(CFG)

# FPGA Workflow
occamy_system_vivado_preparation: # In SNAX Docker
	make -C ./target/fpga/ define_defines_includes_no_simset.tcl
	make -C ./target/fpga/vivado_ips/ define-sources.tcl

occamy_ip_vcu128:	# In ESAT Server
	#                                                                                          debug  jtag  (put 1 or 0)
	sh -c "cd ./target/fpga/vivado_ips/;vivado -mode batch -source occamy_xilinx.tcl -tclargs      1     1"

occamy_ip_vcu128_gui: # In ESAT Server
	sh -c "cd ./target/fpga/vivado_ips/occamy_xilinx/;vivado occamy_xilinx.xpr"

occamy_system_vcu128: occamy_ip_vcu128 # In ESAT Server
	#                                                                                          debug  jtag  (put 1 or 0)
	sh -c "cd ./target/fpga;vivado -mode batch -source occamy_vcu128_2023.tcl -tclargs             1     1"

occamy_system_vcu128_gui: # In ESAT Server
	sh -c "cd ./target/fpga/occamy_vcu128_2023/;vivado occamy_vcu128_2023.xpr"

occamy_system_download_sw: # In ESAT Server; this procedure will only inject the bootrom at present; however, it can also inject the software.
	make -C ./target/fpga/sw download_sw

open_terminal:	# It opens ttyUSB1 without locking it, and set baudrate at 1Mbps
	sh minicom -D /dev/ttyUSB1 -b 1000000 -o


# FPGA Workflow (with no Xilinx IP - tapeout configuration)
# Please be attention that in this configuration, injecting any binary files by Xilinx Vivado are not possible anymore; please use JTAG or embedded bootrom to load the binary
hemaia_system_vivado_preparation: # In SNAX Docker
	make -C ./target/fpga_chip/hemaia_system/ define_defines_includes_no_simset.tcl
	make -C ./target/fpga_chip/hemaia_chip/ define-sources.tcl

hemaia_chip_vcu128:	# In ESAT Server
	#                                                                                          			debug  jtag  (put 1 or 0)
	sh -c "cd ./target/fpga_chip/hemaia_chip/;vivado -mode batch -source hemaia_chip.tcl -tclargs     		1     1"

hemaia_chip_vcu128_gui: # In ESAT Server
	sh -c "cd ./target/fpga/fpga_chip/hemaia_chip/hemaia_chip/;vivado hemaia_chip.xpr"

hemaia_system_vcu128: hemaia_chip_vcu128 # In ESAT Server
	#                                                                                         						debug  jtag  (put 1 or 0)   
	sh -c "cd ./target/fpga_chip/hemaia_system/;vivado -mode batch -source hemaia_system_vcu128.tcl -tclargs           	1     1"

hemaia_system_vcu128_gui: # In ESAT Server
	sh -c "cd ./target/fpga_chip/hemaia_system/hemaia_system_vcu128/;vivado hemaia_system_vcu128.xpr"

# Questasim Workflow
occamy_system_vsim_preparation: # In SNAX Docker
	make -C ./target/sim work/lib/libfesvr.a
	make -C ./target/sim tb
	make -C ./target/sim work-vsim/compile.vsim.tcl

occamy_system_vsim: # In ESAT Server
	make -C ./target/sim bin/occamy_top.vsim
