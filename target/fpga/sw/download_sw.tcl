# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Parse arguments

proc snax_target {} {
  global snax_hw_server
  global snax_target_serial
  global snax_hw_device
  set snax_hw_server localhost:3121
  set snax_target_serial 000012963c2901
  set snax_hw_device xcvu37p_0
}

proc snax_connect {} {
    global snax_hw_server
    global snax_target_serial
    global snax_hw_device
    open_hw_manager
    connect_hw_server -url ${snax_hw_server} -allow_non_jtag
    current_hw_target [get_hw_targets */xilinx_tcf/Xilinx/${snax_target_serial}]
    # set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Xilinx/${snax_target_serial}]
    open_hw_target
    set_property PROBES.FILE {../probes.ltx} [get_hw_devices ${snax_hw_device}]
    current_hw_device [get_hw_devices ${snax_hw_device}]
    refresh_hw_device [lindex [get_hw_devices ${snax_hw_device}] 0]
}

proc snax_write_vio {regexp_vio regexp_probe val} {
    global snax_hw_device
    puts "\[write_vio $regexp_vio $regexp_probe\]"
    set vio_sys [get_hw_vios -of_objects [get_hw_devices ${snax_hw_device}] -regexp $regexp_vio]
    puts "\[write_vio $regexp_vio $regexp_probe\]"
    set_property OUTPUT_VALUE $val [get_hw_probes -of_objects $vio_sys -regexp $regexp_probe]
    puts "\[write_vio $regexp_vio $regexp_probe\]"
    commit_hw_vio [get_hw_probes -of_objects $vio_sys -regexp $regexp_probe]
}

proc snax_download_sw {} {
    global snax_hw_device
    # Reset peripherals and CPU
    snax_write_vio "hw_vio_1" ".*rst.*" 1
    after 100
    # Wake up peripherals to write bootrom
    snax_write_vio "hw_vio_1" ".*glbl_rst.*" 0
    after 100
    # Overwrite bootrom
    refresh_hw_device [lindex [get_hw_devices ${snax_hw_device}] 0]
    source bootrom.tcl
    source app.tcl
    after 100
    # Wake up CPU
    snax_write_vio "hw_vio_1" ".*rst.*" 0
}


snax_target

snax_connect

snax_download_sw

close_hw_manager
