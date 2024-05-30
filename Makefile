
.PHONY: rtl clean vivado

rtl:
	# make -C ./target/rtl/ rtl CFG_OVERRIDE=cfg/single-cluster-single-core-syns.hjson
	make -C ./target/rtl/ soc CFG_OVERRIDE=cfg/single-cluster-single-core-syns.hjson
	make -C ./target/rtl/ rtl CFG_OVERRIDE=cfg/snax_two_clusters.hjson
	make -C ./target/fpga/ define_defines_includes_no_simset.tcl
	make -C ./target/fpga/vivado_ips/ define-sources.tcl

clean:
	make -C ./target/fpga/ clean
	make -C ./target/fpga/vivado_ips/ clean
	make -C ./target/sim/ clean
	make -C ./target/rtl/ clean

vivado-ips:
	#                                                                                          debug  jtag  (put 1 or 0)
	sh -c "cd ./target/fpga/vivado_ips/;vivado -mode batch -source occamy_xilinx.tcl -tclargs      1     1"

vivado-ips-gui:
	sh -c "cd ./target/fpga/vivado_ips/occamy_xilinx/;vivado occamy_xilinx.xpr"
