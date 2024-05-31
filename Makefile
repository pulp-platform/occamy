
.PHONY: rtl clean vivado
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR := $(dir $(MKFILE_PATH))


rtl:
	# make -C ./target/rtl/ rtl CFG_OVERRIDE=cfg/single-cluster-single-core-syns.hjson
	make -C ./target/rtl/ soc CFG_OVERRIDE=cfg/single-cluster-single-core-syns.hjson
	make -C ./target/rtl/ rtl CFG_OVERRIDE=cfg/snax_three_clusters.hjson
	make -C ./target/fpga/ define_defines_includes_no_simset.tcl
	make -C ./target/fpga/vivado_ips/ define-sources.tcl

clean:
	make -C ./target/fpga/ clean
	make -C ./target/fpga/vivado_ips/ clean
	make -C ./target/sim/ clean
	make -C ./target/rtl/ clean

occamy_ip_vcu128:
	#                                                                                          debug  jtag  (put 1 or 0)
	sh -c "cd ./target/fpga/vivado_ips/;vivado -mode batch -source occamy_xilinx.tcl -tclargs      1     1"

occamy_ip_vcu128_gui:
	sh -c "cd ./target/fpga/vivado_ips/occamy_xilinx/;vivado occamy_xilinx.xpr"

occamy_system_vcu128:
	#                                                                                          debug  jtag  (put 1 or 0)   threads  
	# sh -c "cd ./target/fpga;vivado -mode batch -source occamy_vcu128_2023.tcl -tclargs             1     1                      16 ${MKFILE_DIR}target/fpga/bootrom/bootrom-spl.coe"
	sh -c "cd ./target/fpga;vivado -mode batch -source occamy_vcu128_2023.tcl -tclargs             1     1                      16 ${MKFILE_DIR}target/fpga/bootrom/bootrom-spl.coe"

occamy_system_vcu128_gui:
	sh -c "cd ./target/fpga/occamy_vcu128_2023/;vivado occamy_vcu128_2023.xpr"
