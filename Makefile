
.PHONY: clean bootrom sw rtl occamy_ip_vcu128 occamy_ip_vcu128_gui occamy_system_vcu128 occamy_system_vcu128_gui
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR := $(dir $(MKFILE_PATH))

clean:
	make -C ./target/fpga/ clean
	make -C ./target/fpga/vivado_ips/ clean
	make -C ./target/sim/ clean
	make -C ./target/rtl/ clean
	rm -f ./target/fpga/vivado_ips/vivado.jou
	rm -f ./target/fpga/vivado_ips/vivado.log
	rm -f ./target/fpga/vivado_ips/*.backup.log

# Software Generation

bootrom: # In Occamy Docker
	make -C ./target/sim bootrom

sw: # In Occamy Docker
	make -C ./target/sim sw

# Hardware Generation

rtl: # In SNAX Docker
	# make -C ./target/rtl/ rtl CFG_OVERRIDE=cfg/single-cluster-single-core-syns.hjson
	make -C ./target/rtl/ soc CFG_OVERRIDE=cfg/single-cluster-single-core-syns.hjson
	make -C ./target/rtl/ rtl CFG_OVERRIDE=cfg/snax_two_clusters.hjson


# FPGA Workflow

occamy_system_vivado_preparation: # In SNAX Docker
	make -C ./target/fpga/ define_defines_includes_no_simset.tcl
	make -C ./target/fpga/vivado_ips/ define-sources.tcl

occamy_ip_vcu128:	# In ESAT Server
	#                                                                                          debug  jtag  (put 1 or 0)
	sh -c "cd ./target/fpga/vivado_ips/;vivado -mode batch -source occamy_xilinx.tcl -tclargs      1     1"

occamy_ip_vcu128_gui: # In ESAT Server
	sh -c "cd ./target/fpga/vivado_ips/occamy_xilinx/;vivado occamy_xilinx.xpr"

occamy_system_vcu128: # In ESAT Server
	#                                                                                          debug  jtag  (put 1 or 0)   threads  
	# sh -c "cd ./target/fpga;vivado -mode batch -source occamy_vcu128_2023.tcl -tclargs             1     1                      16 ${MKFILE_DIR}target/fpga/bootrom/bootrom-spl.coe"
	sh -c "cd ./target/fpga;vivado -mode batch -source occamy_vcu128_2023.tcl -tclargs             1     1                      16 ${MKFILE_DIR}target/fpga/bootrom/bootrom-spl.coe"

occamy_system_vcu128_gui: # In ESAT Server
	sh -c "cd ./target/fpga/occamy_vcu128_2023/;vivado occamy_vcu128_2023.xpr"

# Questasim Workflow

occamy_system_vsim_preparation: # In SNAX Docker
	make -C ./target/sim work/lib/libfesvr.a
	make -C ./target/sim tb
	make -C ./target/sim work-vsim/compile.vsim.tcl

occamy_system_vsim: # In ESAT Server
	make -C ./target/sim bin/occamy_top.vsim