
.PHONY: rtl clean vivado-ips vivado-ips-gui

rtl:
	make -C ./target/rtl/ rtl CFG_OVERRIDE=cfg/snax_two_clusters.hjson
	make -C ./target/fpga/ define_defines_includes_no_simset.tcl
	make -C ./target/fpga/vivado_ips/ define-sources.tcl

clean:
	make -C ./target/fpga/ clean
	make -C ./target/fpga/vivado_ips/ clean
	make -C ./target/sim/ clean
	make -C ./target/rtl/ clean
	rm -f ./target/fpga/vivado_ips/vivado.jou
	rm -f ./target/fpga/vivado_ips/vivado.log
	rm -f ./target/fpga/vivado_ips/*.backup.log

vivado-ips: rtl
	#                                                                                          debug  jtag  (put 1 or 0)
	sh -c "cd ./target/fpga/vivado_ips/;vivado -mode batch -source occamy_xilinx.tcl -tclargs      1     1"

vivado-ips-gui:
	sh -c "cd ./target/fpga/vivado_ips/;vivado occamy_xilinx/occamy_xilinx.xpr"
