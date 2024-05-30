
.PHONY: rtl clean vivado

rtl:
	make -C ./target/rtl/ rtl CFG_OVERRIDE=cfg/single-cluster-single-core-syns.hjson
	make -C ./target/rtl/ rtl CFG_OVERRIDE=cfg/snax_two_clusters.hjson
	make -C ./target/fpga/ define_defines_includes_no_simset.tcl
	make -C ./target/fpga/vivado_ips/ define-sources.tcl
	#                                                                                          debug  jtag  (put 1 or 0)
	sh -c "cd ./target/fpga/vivado_ips/;vivado -mode batch -source occamy_xilinx.tcl -tclargs      0     0"

clean:
	make -C ./target/fpga/ clean
	make -C ./target/fpga/vivado_ips/ clean
	make -C ./target/sim/ clean
	make -C ./target/rtl/ clean

vivado:
	sh -c "cd ./target/fpga/vivado_ips/occamy_xilinx/;vivado ooc_synth_constraints.xdc"
