
################################################################
# This is a generated script based on design: hemaia_system_vcu128
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2023.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source hemaia_system_vcu128_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvu37p-fsvh2892-2L-e
   set_property BOARD_PART xilinx.com:vcu128:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name hemaia_system_vcu128

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:util_vector_logic:2.0\
xilinx.com:ip:util_reduced_logic:2.0\
xilinx.com:ip:vio:3.0\
xilinx.com:ip:xlslice:1.0\
MICAS_KUL:user:occamy_chip:1.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set default_100mhz_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 default_100mhz_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $default_100mhz_clk


  # Create ports
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset
  set uart_rx_i_0 [ create_bd_port -dir I uart_rx_i_0 ]
  set uart_tx_o_0 [ create_bd_port -dir O uart_tx_o_0 ]
  set jtag_vdd_o [ create_bd_port -dir O -from 0 -to 0 jtag_vdd_o ]
  set jtag_gnd_o [ create_bd_port -dir O -from 0 -to 0 jtag_gnd_o ]
  set jtag_tdo_o [ create_bd_port -dir O jtag_tdo_o ]
  set jtag_tdi_i [ create_bd_port -dir I jtag_tdi_i ]
  set jtag_tms_i [ create_bd_port -dir I jtag_tms_i ]
  set jtag_tck_i [ create_bd_port -dir I -type clk -freq_hz 5000000 jtag_tck_i ]
  set uart_cts_ni_0 [ create_bd_port -dir I uart_cts_ni_0 ]
  set uart_rts_no_0 [ create_bd_port -dir O uart_rts_no_0 ]
  set spim_sck_o [ create_bd_port -dir O spim_sck_o ]
  set spim_sd_io [ create_bd_port -dir IO -from 3 -to 0 spim_sd_io ]
  set gpio_d_o [ create_bd_port -dir O -from 7 -to 0 gpio_d_o ]
  set spim_csb_o [ create_bd_port -dir O -from 1 -to 0 spim_csb_o ]
  set i2c_sda_io [ create_bd_port -dir IO i2c_sda_io ]
  set i2c_scl_io [ create_bd_port -dir IO i2c_scl_io ]

  # Create instance: c_high, and set properties
  set c_high [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 c_high ]

  # Create instance: c_low, and set properties
  set c_low [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 c_low ]
  set_property CONFIG.CONST_VAL {0} $c_low


  # Create instance: clk_wiz, and set properties
  set clk_wiz [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz ]
  set_property -dict [list \
    CONFIG.AXI_DRP {false} \
    CONFIG.CLKOUT1_DRIVES {Buffer} \
    CONFIG.CLKOUT1_JITTER {132.683} \
    CONFIG.CLKOUT1_PHASE_ERROR {87.180} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50} \
    CONFIG.CLKOUT2_JITTER {180.712} \
    CONFIG.CLKOUT2_PHASE_ERROR {87.180} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {12.5} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_JITTER {112.035} \
    CONFIG.CLKOUT3_PHASE_ERROR {87.180} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {120} \
    CONFIG.CLKOUT3_REQUESTED_PHASE {0} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLKOUT4_JITTER {112.035} \
    CONFIG.CLKOUT4_PHASE_ERROR {87.180} \
    CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.CLKOUT4_USED {false} \
    CONFIG.CLK_IN1_BOARD_INTERFACE {default_100mhz_clk} \
    CONFIG.CLK_OUT1_PORT {clk_core} \
    CONFIG.CLK_OUT2_PORT {clk_rtc} \
    CONFIG.CLK_OUT3_PORT {clk_hbm} \
    CONFIG.CLK_OUT4_PORT {clk_out4} \
    CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {12.000} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {24.000} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {96} \
    CONFIG.MMCM_CLKOUT2_DIVIDE {10} \
    CONFIG.MMCM_CLKOUT2_PHASE {0.000} \
    CONFIG.MMCM_CLKOUT3_DIVIDE {1} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.NUM_OUT_CLKS {3} \
    CONFIG.OPTIMIZE_CLOCKING_STRUCTURE_EN {true} \
    CONFIG.PHASE_DUTY_CONFIG {false} \
    CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
    CONFIG.RESET_BOARD_INTERFACE {reset} \
    CONFIG.USE_BOARD_FLOW {true} \
    CONFIG.USE_DYN_RECONFIG {false} \
    CONFIG.USE_LOCKED {false} \
    CONFIG.USE_RESET {false} \
  ] $clk_wiz


  # Create instance: concat_rst_core, and set properties
  set concat_rst_core [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_rst_core ]

  # Create instance: rst_core_inv, and set properties
  set rst_core_inv [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 rst_core_inv ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $rst_core_inv


  # Create instance: rst_or_core, and set properties
  set rst_or_core [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic:2.0 rst_or_core ]
  set_property -dict [list \
    CONFIG.C_OPERATION {or} \
    CONFIG.C_SIZE {2} \
  ] $rst_or_core


  # Create instance: vio_sys, and set properties
  set vio_sys [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_sys ]
  set_property -dict [list \
    CONFIG.C_NUM_PROBE_IN {0} \
    CONFIG.C_NUM_PROBE_OUT {2} \
    CONFIG.C_PROBE_OUT1_WIDTH {2} \
    CONFIG.C_PROBE_OUT2_WIDTH {2} \
    CONFIG.C_PROBE_OUT3_INIT_VAL {0x03} \
    CONFIG.C_PROBE_OUT3_WIDTH {6} \
  ] $vio_sys


  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property CONFIG.DIN_FROM {7} $xlslice_1


  # Create instance: occamy_chip_0, and set properties
  set occamy_chip_0 [ create_bd_cell -type ip -vlnv MICAS_KUL:user:occamy_chip:1.0 occamy_chip_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net default_100mhz_clk_1 [get_bd_intf_ports default_100mhz_clk] [get_bd_intf_pins clk_wiz/CLK_IN1_D]

  # Create port connections
  connect_bd_net -net Net [get_bd_ports spim_sd_io] [get_bd_pins occamy_chip_0/spim_sd_io]
  connect_bd_net -net Net1 [get_bd_ports i2c_sda_io] [get_bd_pins occamy_chip_0/i2c_sda_io]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets Net1]
  connect_bd_net -net Net2 [get_bd_ports i2c_scl_io] [get_bd_pins occamy_chip_0/i2c_scl_io]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets Net2]
  connect_bd_net -net c_high_dout [get_bd_pins c_high/dout] [get_bd_ports jtag_vdd_o] [get_bd_pins occamy_chip_0/jtag_trst_ni]
  connect_bd_net -net clk_wiz_clk_core [get_bd_pins clk_wiz/clk_core] [get_bd_pins vio_sys/clk] [get_bd_pins occamy_chip_0/clk_i] [get_bd_pins occamy_chip_0/clk_periph_i]
  connect_bd_net -net clk_wiz_clk_rtc [get_bd_pins clk_wiz/clk_rtc] [get_bd_pins occamy_chip_0/rtc_i]
  connect_bd_net -net const_low_dout [get_bd_pins c_low/dout] [get_bd_ports jtag_gnd_o] [get_bd_pins occamy_chip_0/test_mode_i] [get_bd_pins occamy_chip_0/gpio_d_i] [get_bd_pins occamy_chip_0/ext_irq_i]
  connect_bd_net -net jtag_tck_i_1 [get_bd_ports jtag_tck_i] [get_bd_pins occamy_chip_0/jtag_tck_i]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets jtag_tck_i_1]
  connect_bd_net -net jtag_tdi_i_1 [get_bd_ports jtag_tdi_i] [get_bd_pins occamy_chip_0/jtag_tdi_i]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets jtag_tdi_i_1]
  connect_bd_net -net jtag_tms_i_1 [get_bd_ports jtag_tms_i] [get_bd_pins occamy_chip_0/jtag_tms_i]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets jtag_tms_i_1]
  connect_bd_net -net occamy_chip_0_gpio_d_o [get_bd_pins occamy_chip_0/gpio_d_o] [get_bd_pins xlslice_1/Din]
  connect_bd_net -net occamy_chip_0_jtag_tdo_o [get_bd_pins occamy_chip_0/jtag_tdo_o] [get_bd_ports jtag_tdo_o]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets occamy_chip_0_jtag_tdo_o]
  connect_bd_net -net occamy_chip_0_spim_csb_o [get_bd_pins occamy_chip_0/spim_csb_o] [get_bd_ports spim_csb_o]
  connect_bd_net -net occamy_chip_0_spim_sck_o [get_bd_pins occamy_chip_0/spim_sck_o] [get_bd_ports spim_sck_o]
  connect_bd_net -net occamy_chip_0_uart_rts_no [get_bd_pins occamy_chip_0/uart_rts_no] [get_bd_ports uart_rts_no_0]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets occamy_chip_0_uart_rts_no]
  connect_bd_net -net occamy_chip_0_uart_tx_o [get_bd_pins occamy_chip_0/uart_tx_o] [get_bd_ports uart_tx_o_0]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets occamy_chip_0_uart_tx_o]
  connect_bd_net -net occamy_rst [get_bd_pins rst_or_core/Res] [get_bd_pins rst_core_inv/Op1]
  connect_bd_net -net occamy_rst_vio [get_bd_pins vio_sys/probe_out0] [get_bd_pins concat_rst_core/In1]
  connect_bd_net -net occamy_rstn [get_bd_pins rst_core_inv/Res] [get_bd_pins occamy_chip_0/rst_ni] [get_bd_pins occamy_chip_0/rst_periph_ni]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins concat_rst_core/In0]
  connect_bd_net -net uart_cts_ni_0_1 [get_bd_ports uart_cts_ni_0] [get_bd_pins occamy_chip_0/uart_cts_ni]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets uart_cts_ni_0_1]
  connect_bd_net -net uart_rx_i_0_1 [get_bd_ports uart_rx_i_0] [get_bd_pins occamy_chip_0/uart_rx_i]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets uart_rx_i_0_1]
  connect_bd_net -net vio_sys_probe_out1 [get_bd_pins vio_sys/probe_out1] [get_bd_pins occamy_chip_0/boot_mode_i]
  connect_bd_net -net xlconcat_2_dout [get_bd_pins concat_rst_core/dout] [get_bd_pins rst_or_core/Op1]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins xlslice_1/Dout] [get_bd_ports gpio_d_o]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


common::send_gid_msg -ssname BD::TCL -id 2053 -severity "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

