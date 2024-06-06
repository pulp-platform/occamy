# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
set errs 0
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_2] -address 80000000 -len 32 -type write -data cb958f95_8da18793_8d218693_10500073_0ff0000f_00a2a023_88a18293_00156513_05063b20_00ef09e0_00ef0620_00ef0260_00efc301_81930000_1197fc21_01130007_01174f81_4f014e81_4e014d81_4d014c81_4c014b81_4b014a81_4a014981_49014881_48014781_47014681_46014581_45014481_44014381_43014281_42014181_41014081
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_2] -address 80000000 -len 32 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp cb958f958da187938d218693105000730ff0000f00a2a02388a182930015651305063b2000ef09e000ef062000ef026000efc301819300001197fc210113000701174f814f014e814e014d814d014c814c014b814b014a814a014981490148814801478147014681460145814501448144014381430142814201418141014081
if {$exp ne $resp} { puts Error; incr errs }
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_2] -address 80000080 -len 32 -type write -data 30079073_8fd96709_300027f3_80828082_0141fef7_1de367a2_7a980001_110006b7_00f70963_67a27b18_e43e1141_771c0007_3c23eb1c_e7147100_06b7e314_11000737_cb958f95_8da18793_8da18693_80828082_0141fef7_1de367a2_7a980001_110006b7_00f70963_67a27b18_e43e1141_771c0007_3c23eb1c_e714e310_16021100_07374605
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_2] -address 80000080 -len 32 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp 300790738fd96709300027f3808280820141fef71de367a27a980001110006b700f7096367a27b18e43e1141771c00073c23eb1ce714710006b7e31411000737cb958f958da187938da18693808280820141fef71de367a27a980001110006b700f7096367a27b18e43e1141771c00073c23eb1ce714e3101602110007374605
if {$exp ne $resp} { puts Error; incr errs }
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_2] -address 80000100 -len 32 -type write -data 0c5722af_4285fe02_9ee30007_2283873e_8d218793_8082e31c_07850400_4737ff87_b7830400_c7b73047_9073f7f7_f7933040_27f3d7ed_0807f793_344027f3_10500073_cb810807_f7933040_27f3a031_30479073_0807e793_304027f3_0ff0000f_e31c078d_04004737_ff87b783_0400c7b7_8082fe02_9ee30c55_22af4285_80827015_10738082
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_2] -address 80000100 -len 32 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp 0c5722af4285fe029ee300072283873e8d2187938082e31c078504004737ff87b7830400c7b730479073f7f7f793304027f3d7ed0807f793344027f310500073cb810807f793304027f3a031304790730807e793304027f30ff0000fe31c078d04004737ff87b7830400c7b78082fe029ee30c5522af42858082701510738082
if {$exp ne $resp} { puts Error; incr errs }
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_2] -address 80000180 -len 32 -type write -data 0064133b_00a60f3b_03d58c63_2e854701_887297b6_82f91682_c3980107_67332801_0007a803_a8395ffd_44054701_4e81fff5_829b01f5_7313e422_1141cdb5_93811782_0027979b_010787bb_0055581b_010007b7_fe029ee3_0c57a2af_4285fe02_9ee30007_a28387c6_8d218893_80820a07_a02fc298_1fe76713_27014298_040006b7_fe029ee3
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_2] -address 80000180 -len 32 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp 0064133b00a60f3b03d58c632e854701887297b682f91682c3980107673328010007a803a8395ffd440547014e81fff5829b01f57313e4221141cdb5938117820027979b010787bb0055581b010007b7fe029ee30c57a2af4285fe029ee30007a28387c68d21889380820a07a02fc2981fe7671327014298040006b7fe029ee3
if {$exp ne $resp} { puts Error; incr errs }
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_2] -address 80000200 -len 32 -type write -data 151b8082_0a07a02f_c2980227_67132701_42980400_06b7fe02_9ee30c57_22af4285_fe029ee3_00072283_873e8d21_87938082_0a06a02f_c3988f51_260186c6_47014390_80820141_64220a06_a02fc398_8f512601_86c64390_bf7d01f7_a023fbf7_1de3fc03_8ae3fdd2_8ce301ff_7313000f_051b0006_839b2701_410e06bb_00676733_005f5e1b
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_2] -address 80000200 -len 32 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp 151b80820a07a02fc2980227671327014298040006b7fe029ee30c5722af4285fe029ee300072283873e8d21879380820a06a02fc3988f51260186c6470143908082014164220a06a02fc3988f51260186c64390bf7d01f7a023fbf71de3fc038ae3fdd28ce301ff7313000f051b0006839b2701410e06bb00676733005f5e1b
if {$exp ne $resp} { puts Error; incr errs }
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_2] -address 80000280 -len 32 -type write -data 171b9f3d_010007b7_0055571b_8082ffed_8ba13440_27f38082_30479073_9bdd3040_27f38082_30479073_f7f7f793_304027f3_80823047_90730807_e7933040_27f38082_30079073_0087e793_300027f3_8082f7ed_0807f793_304027f3_e7910807_f7933440_27f31050_00738082_c10c00b7_95bb4785_953e9101_18078793_100207b7_15020125
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_2] -address 80000280 -len 32 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp 171b9f3d010007b70055571b8082ffed8ba1344027f38082304790739bdd304027f3808230479073f7f7f793304027f38082304790730807e793304027f38082300790730087e793300027f38082f7ed0807f793304027f3e7910807f793344027f3105000738082c10c00b795bb4785953e910118078793100207b715020125
if {$exp ne $resp} { puts Error; incr errs }
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_2] -address 80000300 -len 32 -type write -data 27f31050_0073cb81_0807f793_304027f3_a0313047_90730807_e7933040_27f30ff0_000fe388_040047b7_953eff87_b7830400_c7b702f5_55337357_8793679d_8082e31c_07850400_4737ff87_b7830400_c7b78082_e3880400_47b7953e_ff87b783_0400c7b7_02f55533_73578793_679d8082_ffed8fe9_2781431c_00a7953b_93014785_17020027
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_2] -address 80000300 -len 32 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp 27f310500073cb810807f793304027f3a031304790730807e793304027f30ff0000fe388040047b7953eff87b7830400c7b702f5553373578793679d8082e31c078504004737ff87b7830400c7b78082e388040047b7953eff87b7830400c7b702f5553373578793679d8082ffed8fe92781431c00a7953b9301478517020027
if {$exp ne $resp} { puts Error; incr errs }
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_2] -address 80000380 -len 32 -type write -data c3984705_020077b7_80824505_80824501_fee51be3_270500f6_07638bbd_429ca029_470100f6_0d638bbd_429c96be_928107b1_0b0007b7_16820105_969bc515_80820ff0_000fc10c_8ddd2781_411c953e_910107a1_0b0007b7_15020105_151b8082_e31c0785_04004737_ff87b783_0400c7b7_30479073_f7f7f793_304027f3_d7ed0807_f7933440
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_2] -address 80000380 -len 32 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp c3984705020077b78082450580824501fee51be3270500f607638bbd429ca029470100f60d638bbd429c96be928107b10b0007b716820105969bc51580820ff0000fc10c8ddd2781411c953e910107a10b0007b715020105151b8082e31c078504004737ff87b7830400c7b730479073f7f7f793304027f3d7ed0807f7933440
if {$exp ne $resp} { puts Error; incr errs }
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_2] -address 80000400 -len 32 -type write -data 37fd0001_38878793_6785dfe5_0407f793_01474783_02002737_f6f50006_46830605_00d70023_dfe50207_f7930147_47830200_27370480_06930766_06130000_06170ff0_000f00e7_88230200_071300e7_8423fc70_071300e7_8623470d_00e78223_470900e7_80234779_00e78623_f8000713_00078223_020027b7_8082c398_47050200_77b78082
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_2] -address 80000400 -len 32 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp 37fd0001388787936785dfe50407f7930147478302002737f6f500064683060500d70023dfe50207f79301474783020027370480069307660613000006170ff0000f00e788230200071300e78423fc70071300e78623470d00e78223470900e78023477900e78623f800071300078223020027b78082c3984705020077b78082
if {$exp ne $resp} { puts Error; incr errs }
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_2] -address 80000480 -len 32 -type write -data 00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000a0d_21646c72_6f77206f_6c6c6548_00000000_02001000_00000000_02001400_00000000_02001800_00000000_0400bff8_00000000_04004000_0000000f_00000000_00008082_4501fff5
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_2] -address 80000480 -len 32 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0d21646c726f77206f6c6c6548000000000200100000000000020014000000000002001800000000000400bff800000000040040000000000f00000000000080824501fff5
if {$exp ne $resp} { puts Error; incr errs }
create_hw_axi_txn -cache 0 -force txn [get_hw_axis hw_axi_2] -address 80000500 -len 18 -type write -data 00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000
run_hw_axi txn
create_hw_axi_txn -cache 0 -force wb [get_hw_axis hw_axi_2] -address 80000500 -len 18 -type read
run_hw_axi wb
set resp [get_property DATA [get_hw_axi_txns wb]]
set exp 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
if {$exp ne $resp} { puts Error; incr errs }
puts "Errors: $errs"
