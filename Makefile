
.PHONY: rtl clean

rtl:
	cd ./target/rtl/
	make rtl CFG_OVERRIDE=cfg/single-cluster-single-core-syns.hjson
	make rtl CFG_OVERRIDE=cfg/four_cluster_two_gemm_reshuffler_dma.hjson
	cd ../..
	cd ./target/fpga/
	make define_defines_includes_no_simset.tcl
	cd ./vivado_ips/
	make define-sources.tcl
	#                                                      debug  jtag  (put 1 or 0)
	vivado -mode batch -source occamy_xilinx.tcl -tclargs      0     0
	cd ..
	cd ../..

clean:
	cd ./target/rtl/
	make clean
	cd ../..
	cd ./target/fpga/
	make clean
	cd ./vivado_ips/
	make clean
	cd ..
	cd ../..
