# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
set errs 0
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_1] -address 00000000 -len 32 -type write -data 00000000_00000000_ffdff06f_10500073_000280e7_04c2e283_00000297_30539073_01838393_00000397_fa810113_6f020117_04f18193_00000197_fc5ff06f_000280e7_0002a283_fe428293_01000297_10500073_30429073_00828293_000802b7_30046073_30529073_02028293_00000297_0a858593_00000597_f1402573_0402c263_301022f3
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_1] -address 00000000 -len 32 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp 0000000000000000ffdff06f10500073000280e704c2e28300000297305390730183839300000397fa8101136f02011704f1819300000197fc5ff06f000280e70002a283fe42829301000297105000733042907300828293000802b7300460733052907302028293000002970a85859300000597f14025730402c263301022f3
if {$exp ne $resp} { puts Error; incr errs }
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_1] -address 00000080 -len 13 -type write -data 80000000_00000030_7032645f_30703266_5f307032_615f3070_326d5f30_70326934_36767205_00000023_01007663_73697200_00002d41
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_1] -address 00000080 -len 13 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp 80000000000000307032645f307032665f307032615f3070326d5f30703269343676720500000023010076637369720000002d41
if {$exp ne $resp} { puts Error; incr errs }
puts "Errors: $errs"
