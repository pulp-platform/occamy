// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
// Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Stefan Mach <smach@iis.ee.ethz.ch>
// Thomas Benz <tbenz@iis.ee.ethz.ch>
// Paul Scheffler <paulsc@iis.ee.ethz.ch>
// Wolfgang Roenninger <wroennin@iis.ee.ethz.ch>
//
// AUTOMATICALLY GENERATED by bin2sv.py; edit the script instead.

module bootrom #(
    parameter int unsigned AddrWidth = 32,
    parameter int unsigned DataWidth = 32
)(
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 req_i,
    input  logic [AddrWidth-1:0] addr_i,
    output logic [DataWidth-1:0] data_o
);
    localparam unsigned NumWords = 512;
    logic [$clog2(NumWords)-1:0] word;

    assign word = addr_i / (DataWidth / 8);

    always_comb begin
        data_o = '0;
        unique case (word)
        000: data_o = 32'h301022f3 /* 0x0000 */;
            001: data_o = 32'h0202ce63 /* 0x0004 */;
            002: data_o = 32'hf1402573 /* 0x0008 */;
            003: data_o = 32'h00000297 /* 0x000c */;
            004: data_o = 32'h02028293 /* 0x0010 */;
            005: data_o = 32'h30529073 /* 0x0014 */;
            006: data_o = 32'h30046073 /* 0x0018 */;
            007: data_o = 32'h000802b7 /* 0x001c */;
            008: data_o = 32'h00828293 /* 0x0020 */;
            009: data_o = 32'h30429073 /* 0x0024 */;
            010: data_o = 32'h10500073 /* 0x0028 */;
            011: data_o = 32'h01000297 /* 0x002c */;
            012: data_o = 32'hfec28293 /* 0x0030 */;
            013: data_o = 32'h0002a283 /* 0x0034 */;
            014: data_o = 32'h000280e7 /* 0x0038 */;
            015: data_o = 32'hfcdff06f /* 0x003c */;
            016: data_o = 32'h00000197 /* 0x0040 */;
            017: data_o = 32'h64018193 /* 0x0044 */;
            018: data_o = 32'h6f020117 /* 0x0048 */;
            019: data_o = 32'hfb010113 /* 0x004c */;
            020: data_o = 32'h00000317 /* 0x0050 */;
            021: data_o = 32'h01c30313 /* 0x0054 */;
            022: data_o = 32'h30531073 /* 0x0058 */;
            023: data_o = 32'h2bc000ef /* 0x005c */;
            024: data_o = 32'h0010029b /* 0x0060 */;
            025: data_o = 32'h01f29293 /* 0x0064 */;
            026: data_o = 32'h000280e7 /* 0x0068 */;
            027: data_o = 32'h10500073 /* 0x006c */;
            028: data_o = 32'hffdff06f /* 0x0070 */;
            029: data_o = 32'hff010113 /* 0x0074 */;
            030: data_o = 32'h00813423 /* 0x0078 */;
            031: data_o = 32'h01010413 /* 0x007c */;
            032: data_o = 32'h01002717 /* 0x0080 */;
            033: data_o = 32'hf9470713 /* 0x0084 */;
            034: data_o = 32'h00074783 /* 0x0088 */;
            035: data_o = 32'h0207f793 /* 0x008c */;
            036: data_o = 32'hfe078ce3 /* 0x0090 */;
            037: data_o = 32'h00813403 /* 0x0094 */;
            038: data_o = 32'h01002797 /* 0x0098 */;
            039: data_o = 32'hf6a78423 /* 0x009c */;
            040: data_o = 32'h01010113 /* 0x00a0 */;
            041: data_o = 32'h00008067 /* 0x00a4 */;
            042: data_o = 32'hff010113 /* 0x00a8 */;
            043: data_o = 32'h00813423 /* 0x00ac */;
            044: data_o = 32'h01010413 /* 0x00b0 */;
            045: data_o = 32'h01002717 /* 0x00b4 */;
            046: data_o = 32'hf6070713 /* 0x00b8 */;
            047: data_o = 32'h00074783 /* 0x00bc */;
            048: data_o = 32'h0017f793 /* 0x00c0 */;
            049: data_o = 32'hfe078ce3 /* 0x00c4 */;
            050: data_o = 32'h00813403 /* 0x00c8 */;
            051: data_o = 32'h01002797 /* 0x00cc */;
            052: data_o = 32'hf3478793 /* 0x00d0 */;
            053: data_o = 32'h0007c503 /* 0x00d4 */;
            054: data_o = 32'h01010113 /* 0x00d8 */;
            055: data_o = 32'h00008067 /* 0x00dc */;
            056: data_o = 32'hfe010113 /* 0x00e0 */;
            057: data_o = 32'h00813823 /* 0x00e4 */;
            058: data_o = 32'h00913423 /* 0x00e8 */;
            059: data_o = 32'h00113c23 /* 0x00ec */;
            060: data_o = 32'h02010413 /* 0x00f0 */;
            061: data_o = 32'h00050493 /* 0x00f4 */;
            062: data_o = 32'h0004c503 /* 0x00f8 */;
            063: data_o = 32'h02051663 /* 0x00fc */;
            064: data_o = 32'h01002717 /* 0x0100 */;
            065: data_o = 32'hf1470713 /* 0x0104 */;
            066: data_o = 32'h00074783 /* 0x0108 */;
            067: data_o = 32'h0407f793 /* 0x010c */;
            068: data_o = 32'hfe078ce3 /* 0x0110 */;
            069: data_o = 32'h01813083 /* 0x0114 */;
            070: data_o = 32'h01013403 /* 0x0118 */;
            071: data_o = 32'h00813483 /* 0x011c */;
            072: data_o = 32'h02010113 /* 0x0120 */;
            073: data_o = 32'h00008067 /* 0x0124 */;
            074: data_o = 32'hf4dff0ef /* 0x0128 */;
            075: data_o = 32'h00148493 /* 0x012c */;
            076: data_o = 32'hfc9ff06f /* 0x0130 */;
            077: data_o = 32'hff010113 /* 0x0134 */;
            078: data_o = 32'h00813423 /* 0x0138 */;
            079: data_o = 32'h01010413 /* 0x013c */;
            080: data_o = 32'h00000713 /* 0x0140 */;
            081: data_o = 32'h00000793 /* 0x0144 */;
            082: data_o = 32'h0007069b /* 0x0148 */;
            083: data_o = 32'h00b6ea63 /* 0x014c */;
            084: data_o = 32'h00813403 /* 0x0150 */;
            085: data_o = 32'h00078513 /* 0x0154 */;
            086: data_o = 32'h01010113 /* 0x0158 */;
            087: data_o = 32'h00008067 /* 0x015c */;
            088: data_o = 32'h00e506b3 /* 0x0160 */;
            089: data_o = 32'h0006c683 /* 0x0164 */;
            090: data_o = 32'h00170713 /* 0x0168 */;
            091: data_o = 32'h00d787b3 /* 0x016c */;
            092: data_o = 32'h0ff7f793 /* 0x0170 */;
            093: data_o = 32'hfd5ff06f /* 0x0174 */;
            094: data_o = 32'hff010113 /* 0x0178 */;
            095: data_o = 32'h00813423 /* 0x017c */;
            096: data_o = 32'h01010413 /* 0x0180 */;
            097: data_o = 32'h00000793 /* 0x0184 */;
            098: data_o = 32'h0007871b /* 0x0188 */;
            099: data_o = 32'h00c76863 /* 0x018c */;
            100: data_o = 32'h00813403 /* 0x0190 */;
            101: data_o = 32'h01010113 /* 0x0194 */;
            102: data_o = 32'h00008067 /* 0x0198 */;
            103: data_o = 32'h00f58733 /* 0x019c */;
            104: data_o = 32'h00074683 /* 0x01a0 */;
            105: data_o = 32'h00f50733 /* 0x01a4 */;
            106: data_o = 32'h00178793 /* 0x01a8 */;
            107: data_o = 32'h00d70023 /* 0x01ac */;
            108: data_o = 32'hfd9ff06f /* 0x01b0 */;
            109: data_o = 32'hff010113 /* 0x01b4 */;
            110: data_o = 32'h00813423 /* 0x01b8 */;
            111: data_o = 32'h01010413 /* 0x01bc */;
            112: data_o = 32'hb00027f3 /* 0x01c0 */;
            113: data_o = 32'h00a787b3 /* 0x01c4 */;
            114: data_o = 32'h00f76863 /* 0x01c8 */;
            115: data_o = 32'h00813403 /* 0x01cc */;
            116: data_o = 32'h01010113 /* 0x01d0 */;
            117: data_o = 32'h00008067 /* 0x01d4 */;
            118: data_o = 32'hb0002773 /* 0x01d8 */;
            119: data_o = 32'hfedff06f /* 0x01dc */;
            120: data_o = 32'hbc010113 /* 0x01e0 */;
            121: data_o = 32'h42113c23 /* 0x01e4 */;
            122: data_o = 32'h42813823 /* 0x01e8 */;
            123: data_o = 32'h41313c23 /* 0x01ec */;
            124: data_o = 32'h41413823 /* 0x01f0 */;
            125: data_o = 32'h41513423 /* 0x01f4 */;
            126: data_o = 32'h41613023 /* 0x01f8 */;
            127: data_o = 32'h44010413 /* 0x01fc */;
            128: data_o = 32'h42913423 /* 0x0200 */;
            129: data_o = 32'h43213023 /* 0x0204 */;
            130: data_o = 32'h00050b13 /* 0x0208 */;
            131: data_o = 32'h02faf537 /* 0x020c */;
            132: data_o = 32'h08050513 /* 0x0210 */;
            133: data_o = 32'hfa1ff0ef /* 0x0214 */;
            134: data_o = 32'h01500513 /* 0x0218 */;
            135: data_o = 32'he59ff0ef /* 0x021c */;
            136: data_o = 32'h00000993 /* 0x0220 */;
            137: data_o = 32'h00400a93 /* 0x0224 */;
            138: data_o = 32'h00100a13 /* 0x0228 */;
            139: data_o = 32'he7dff0ef /* 0x022c */;
            140: data_o = 32'h00050913 /* 0x0230 */;
            141: data_o = 32'h05551063 /* 0x0234 */;
            142: data_o = 32'h00600513 /* 0x0238 */;
            143: data_o = 32'he39ff0ef /* 0x023c */;
            144: data_o = 32'h00000517 /* 0x0240 */;
            145: data_o = 32'h36050513 /* 0x0244 */;
            146: data_o = 32'he99ff0ef /* 0x0248 */;
            147: data_o = 32'h43813083 /* 0x024c */;
            148: data_o = 32'h43013403 /* 0x0250 */;
            149: data_o = 32'h42813483 /* 0x0254 */;
            150: data_o = 32'h42013903 /* 0x0258 */;
            151: data_o = 32'h41813983 /* 0x025c */;
            152: data_o = 32'h41013a03 /* 0x0260 */;
            153: data_o = 32'h40813a83 /* 0x0264 */;
            154: data_o = 32'h40013b03 /* 0x0268 */;
            155: data_o = 32'h44010113 /* 0x026c */;
            156: data_o = 32'h00008067 /* 0x0270 */;
            157: data_o = 32'hfff9079b /* 0x0274 */;
            158: data_o = 32'h0ff7f793 /* 0x0278 */;
            159: data_o = 32'h01800513 /* 0x027c */;
            160: data_o = 32'h06fa6863 /* 0x0280 */;
            161: data_o = 32'he25ff0ef /* 0x0284 */;
            162: data_o = 32'h00050493 /* 0x0288 */;
            163: data_o = 32'he1dff0ef /* 0x028c */;
            164: data_o = 32'hfff54513 /* 0x0290 */;
            165: data_o = 32'h0ff57513 /* 0x0294 */;
            166: data_o = 32'h06951c63 /* 0x0298 */;
            167: data_o = 32'h40000493 /* 0x029c */;
            168: data_o = 32'h01491463 /* 0x02a0 */;
            169: data_o = 32'h08000493 /* 0x02a4 */;
            170: data_o = 32'h00000913 /* 0x02a8 */;
            171: data_o = 32'h0009079b /* 0x02ac */;
            172: data_o = 32'h0497c463 /* 0x02b0 */;
            173: data_o = 32'hdf5ff0ef /* 0x02b4 */;
            174: data_o = 32'h0004849b /* 0x02b8 */;
            175: data_o = 32'h00050913 /* 0x02bc */;
            176: data_o = 32'h00048593 /* 0x02c0 */;
            177: data_o = 32'hbc040513 /* 0x02c4 */;
            178: data_o = 32'he6dff0ef /* 0x02c8 */;
            179: data_o = 32'h04a91263 /* 0x02cc */;
            180: data_o = 32'h02099513 /* 0x02d0 */;
            181: data_o = 32'h02055513 /* 0x02d4 */;
            182: data_o = 32'h00048613 /* 0x02d8 */;
            183: data_o = 32'hbc040593 /* 0x02dc */;
            184: data_o = 32'h01650533 /* 0x02e0 */;
            185: data_o = 32'he95ff0ef /* 0x02e4 */;
            186: data_o = 32'h013489bb /* 0x02e8 */;
            187: data_o = 32'h00600513 /* 0x02ec */;
            188: data_o = 32'hd85ff0ef /* 0x02f0 */;
            189: data_o = 32'hf39ff06f /* 0x02f4 */;
            190: data_o = 32'hdb1ff0ef /* 0x02f8 */;
            191: data_o = 32'hbc040793 /* 0x02fc */;
            192: data_o = 32'h012787b3 /* 0x0300 */;
            193: data_o = 32'h00a78023 /* 0x0304 */;
            194: data_o = 32'h00190913 /* 0x0308 */;
            195: data_o = 32'hfa1ff06f /* 0x030c */;
            196: data_o = 32'h01500513 /* 0x0310 */;
            197: data_o = 32'hfddff06f /* 0x0314 */;
            198: data_o = 32'hf8010113 /* 0x0318 */;
            199: data_o = 32'h06813823 /* 0x031c */;
            200: data_o = 32'h07213023 /* 0x0320 */;
            201: data_o = 32'h05313c23 /* 0x0324 */;
            202: data_o = 32'h05413823 /* 0x0328 */;
            203: data_o = 32'h05513423 /* 0x032c */;
            204: data_o = 32'h05613023 /* 0x0330 */;
            205: data_o = 32'h03713c23 /* 0x0334 */;
            206: data_o = 32'h03813823 /* 0x0338 */;
            207: data_o = 32'h06113c23 /* 0x033c */;
            208: data_o = 32'h06913423 /* 0x0340 */;
            209: data_o = 32'h03913423 /* 0x0344 */;
            210: data_o = 32'h03a13023 /* 0x0348 */;
            211: data_o = 32'h08010413 /* 0x034c */;
            212: data_o = 32'h01002797 /* 0x0350 */;
            213: data_o = 32'hca078a23 /* 0x0354 */;
            214: data_o = 32'hf8000793 /* 0x0358 */;
            215: data_o = 32'h01002717 /* 0x035c */;
            216: data_o = 32'hcaf70823 /* 0x0360 */;
            217: data_o = 32'h00300793 /* 0x0364 */;
            218: data_o = 32'h01002717 /* 0x0368 */;
            219: data_o = 32'hc8f70c23 /* 0x036c */;
            220: data_o = 32'h01002717 /* 0x0370 */;
            221: data_o = 32'hc8070a23 /* 0x0374 */;
            222: data_o = 32'h01002717 /* 0x0378 */;
            223: data_o = 32'hc8f70a23 /* 0x037c */;
            224: data_o = 32'hfc700793 /* 0x0380 */;
            225: data_o = 32'h01002717 /* 0x0384 */;
            226: data_o = 32'hc8f70223 /* 0x0388 */;
            227: data_o = 32'h00100913 /* 0x038c */;
            228: data_o = 32'h02200793 /* 0x0390 */;
            229: data_o = 32'h01002717 /* 0x0394 */;
            230: data_o = 32'hc6f70e23 /* 0x0398 */;
            231: data_o = 32'h00000997 /* 0x039c */;
            232: data_o = 32'h21c98993 /* 0x03a0 */;
            233: data_o = 32'h00000a17 /* 0x03a4 */;
            234: data_o = 32'h21ca0a13 /* 0x03a8 */;
            235: data_o = 32'h00000a97 /* 0x03ac */;
            236: data_o = 32'h234a8a93 /* 0x03b0 */;
            237: data_o = 32'h00000b17 /* 0x03b4 */;
            238: data_o = 32'h234b0b13 /* 0x03b8 */;
            239: data_o = 32'h00000b97 /* 0x03bc */;
            240: data_o = 32'h25cb8b93 /* 0x03c0 */;
            241: data_o = 32'h01f91c13 /* 0x03c4 */;
            242: data_o = 32'h00200493 /* 0x03c8 */;
            243: data_o = 32'h00300c93 /* 0x03cc */;
            244: data_o = 32'h00098513 /* 0x03d0 */;
            245: data_o = 32'hd0dff0ef /* 0x03d4 */;
            246: data_o = 32'h000a0513 /* 0x03d8 */;
            247: data_o = 32'hd05ff0ef /* 0x03dc */;
            248: data_o = 32'h000a8513 /* 0x03e0 */;
            249: data_o = 32'hcfdff0ef /* 0x03e4 */;
            250: data_o = 32'h000b0513 /* 0x03e8 */;
            251: data_o = 32'hcf5ff0ef /* 0x03ec */;
            252: data_o = 32'h000b8513 /* 0x03f0 */;
            253: data_o = 32'hcedff0ef /* 0x03f4 */;
            254: data_o = 32'hcb1ff0ef /* 0x03f8 */;
            255: data_o = 32'hfcf5051b /* 0x03fc */;
            256: data_o = 32'h07250863 /* 0x0400 */;
            257: data_o = 32'h02a94063 /* 0x0404 */;
            258: data_o = 32'hfc0514e3 /* 0x0408 */;
            259: data_o = 32'h00000517 /* 0x040c */;
            260: data_o = 32'h29450513 /* 0x0410 */;
            261: data_o = 32'hccdff0ef /* 0x0414 */;
            262: data_o = 32'hf1402573 /* 0x0418 */;
            263: data_o = 32'h00100073 /* 0x041c */;
            264: data_o = 32'hfa9ff06f /* 0x0420 */;
            265: data_o = 32'h06950263 /* 0x0424 */;
            266: data_o = 32'hfb9514e3 /* 0x0428 */;
            267: data_o = 32'h00000517 /* 0x042c */;
            268: data_o = 32'h30c50513 /* 0x0430 */;
            269: data_o = 32'hcadff0ef /* 0x0434 */;
            270: data_o = 32'h07813083 /* 0x0438 */;
            271: data_o = 32'h07013403 /* 0x043c */;
            272: data_o = 32'h06813483 /* 0x0440 */;
            273: data_o = 32'h06013903 /* 0x0444 */;
            274: data_o = 32'h05813983 /* 0x0448 */;
            275: data_o = 32'h05013a03 /* 0x044c */;
            276: data_o = 32'h04813a83 /* 0x0450 */;
            277: data_o = 32'h04013b03 /* 0x0454 */;
            278: data_o = 32'h03813b83 /* 0x0458 */;
            279: data_o = 32'h03013c03 /* 0x045c */;
            280: data_o = 32'h02813c83 /* 0x0460 */;
            281: data_o = 32'h02013d03 /* 0x0464 */;
            282: data_o = 32'h08010113 /* 0x0468 */;
            283: data_o = 32'h00008067 /* 0x046c */;
            284: data_o = 32'h01f91513 /* 0x0470 */;
            285: data_o = 32'hd6dff0ef /* 0x0474 */;
            286: data_o = 32'h00000517 /* 0x0478 */;
            287: data_o = 32'h12850513 /* 0x047c */;
            288: data_o = 32'hc61ff0ef /* 0x0480 */;
            289: data_o = 32'hf45ff06f /* 0x0484 */;
            290: data_o = 32'h00000517 /* 0x0488 */;
            291: data_o = 32'h24050513 /* 0x048c */;
            292: data_o = 32'hf8840c93 /* 0x0490 */;
            293: data_o = 32'hc4dff0ef /* 0x0494 */;
            294: data_o = 32'h000c8493 /* 0x0498 */;
            295: data_o = 32'h00d00d13 /* 0x049c */;
            296: data_o = 32'hc09ff0ef /* 0x04a0 */;
            297: data_o = 32'h00ac8023 /* 0x04a4 */;
            298: data_o = 32'h09a51063 /* 0x04a8 */;
            299: data_o = 32'h00048793 /* 0x04ac */;
            300: data_o = 32'h000c8023 /* 0x04b0 */;
            301: data_o = 32'h00000493 /* 0x04b4 */;
            302: data_o = 32'h00a00693 /* 0x04b8 */;
            303: data_o = 32'h0007c703 /* 0x04bc */;
            304: data_o = 32'h06071863 /* 0x04c0 */;
            305: data_o = 32'h00000517 /* 0x04c4 */;
            306: data_o = 32'h23450513 /* 0x04c8 */;
            307: data_o = 32'hc15ff0ef /* 0x04cc */;
            308: data_o = 32'h00000797 /* 0x04d0 */;
            309: data_o = 32'h29078793 /* 0x04d4 */;
            310: data_o = 32'h0007b783 /* 0x04d8 */;
            311: data_o = 32'h0004849b /* 0x04dc */;
            312: data_o = 32'h00000d13 /* 0x04e0 */;
            313: data_o = 32'hf8f43823 /* 0x04e4 */;
            314: data_o = 32'h00000797 /* 0x04e8 */;
            315: data_o = 32'h28078793 /* 0x04ec */;
            316: data_o = 32'h0007b783 /* 0x04f0 */;
            317: data_o = 32'hf8f43c23 /* 0x04f4 */;
            318: data_o = 32'h000d079b /* 0x04f8 */;
            319: data_o = 32'h0497e463 /* 0x04fc */;
            320: data_o = 32'h01002717 /* 0x0500 */;
            321: data_o = 32'hb1470713 /* 0x0504 */;
            322: data_o = 32'h00074783 /* 0x0508 */;
            323: data_o = 32'h0407f793 /* 0x050c */;
            324: data_o = 32'hfe078ce3 /* 0x0510 */;
            325: data_o = 32'h00000517 /* 0x0514 */;
            326: data_o = 32'h20c50513 /* 0x0518 */;
            327: data_o = 32'hbc5ff0ef /* 0x051c */;
            328: data_o = 32'hb89ff0ef /* 0x0520 */;
            329: data_o = 32'hea5ff06f /* 0x0524 */;
            330: data_o = 32'h001c8c93 /* 0x0528 */;
            331: data_o = 32'hf75ff06f /* 0x052c */;
            332: data_o = 32'h02d484b3 /* 0x0530 */;
            333: data_o = 32'h00178793 /* 0x0534 */;
            334: data_o = 32'hfd048493 /* 0x0538 */;
            335: data_o = 32'h009704b3 /* 0x053c */;
            336: data_o = 32'hf7dff06f /* 0x0540 */;
            337: data_o = 32'h00f7f793 /* 0x0544 */;
            338: data_o = 32'h00079a63 /* 0x0548 */;
            339: data_o = 32'h00d00513 /* 0x054c */;
            340: data_o = 32'hb25ff0ef /* 0x0550 */;
            341: data_o = 32'h00a00513 /* 0x0554 */;
            342: data_o = 32'hb1dff0ef /* 0x0558 */;
            343: data_o = 32'h01ac07b3 /* 0x055c */;
            344: data_o = 32'h0007cc83 /* 0x0560 */;
            345: data_o = 32'hfa040713 /* 0x0564 */;
            346: data_o = 32'h001d0d13 /* 0x0568 */;
            347: data_o = 32'h004cd793 /* 0x056c */;
            348: data_o = 32'h00f707b3 /* 0x0570 */;
            349: data_o = 32'hff07c503 /* 0x0574 */;
            350: data_o = 32'h00fcfc93 /* 0x0578 */;
            351: data_o = 32'haf9ff0ef /* 0x057c */;
            352: data_o = 32'hfa040793 /* 0x0580 */;
            353: data_o = 32'h01978cb3 /* 0x0584 */;
            354: data_o = 32'hff0cc503 /* 0x0588 */;
            355: data_o = 32'hae9ff0ef /* 0x058c */;
            356: data_o = 32'h02000513 /* 0x0590 */;
            357: data_o = 32'hae1ff0ef /* 0x0594 */;
            358: data_o = 32'hf61ff06f /* 0x0598 */;
            359: data_o = 32'h00000000 /* 0x059c */;
            360: data_o = 32'h20090a0d /* 0x05a0 */;
            361: data_o = 32'h64616f4c /* 0x05a4 */;
            362: data_o = 32'h6e696620 /* 0x05a8 */;
            363: data_o = 32'h65687369 /* 0x05ac */;
            364: data_o = 32'h0d202e64 /* 0x05b0 */;
            365: data_o = 32'h000a0d0a /* 0x05b4 */;
            366: data_o = 32'h4a325b1b /* 0x05b8 */;
            367: data_o = 32'h00000000 /* 0x05bc */;
            368: data_o = 32'h09090a0d /* 0x05c0 */;
            369: data_o = 32'h6c655720 /* 0x05c4 */;
            370: data_o = 32'h656d6f63 /* 0x05c8 */;
            371: data_o = 32'h206f7420 /* 0x05cc */;
            372: data_o = 32'h6163634f /* 0x05d0 */;
            373: data_o = 32'h4220796d /* 0x05d4 */;
            374: data_o = 32'h72746f6f /* 0x05d8 */;
            375: data_o = 32'h00006d6f /* 0x05dc */;
            376: data_o = 32'h00000a0d /* 0x05e0 */;
            377: data_o = 32'h00000000 /* 0x05e4 */;
            378: data_o = 32'h20090a0d /* 0x05e8 */;
            379: data_o = 32'h65746e45 /* 0x05ec */;
            380: data_o = 32'h68742072 /* 0x05f0 */;
            381: data_o = 32'h756e2065 /* 0x05f4 */;
            382: data_o = 32'h7265626d /* 0x05f8 */;
            383: data_o = 32'h206f7420 /* 0x05fc */;
            384: data_o = 32'h656c6573 /* 0x0600 */;
            385: data_o = 32'h74207463 /* 0x0604 */;
            386: data_o = 32'h6d206568 /* 0x0608 */;
            387: data_o = 32'h3a65646f /* 0x060c */;
            388: data_o = 32'h00000020 /* 0x0610 */;
            389: data_o = 32'h00000000 /* 0x0614 */;
            390: data_o = 32'h20090a0d /* 0x0618 */;
            391: data_o = 32'h4c202e31 /* 0x061c */;
            392: data_o = 32'h2064616f /* 0x0620 */;
            393: data_o = 32'h6d6f7266 /* 0x0624 */;
            394: data_o = 32'h41544a20 /* 0x0628 */;
            395: data_o = 32'h090a0d47 /* 0x062c */;
            396: data_o = 32'h202e3220 /* 0x0630 */;
            397: data_o = 32'h64616f4c /* 0x0634 */;
            398: data_o = 32'h6f726620 /* 0x0638 */;
            399: data_o = 32'h4155206d /* 0x063c */;
            400: data_o = 32'h74205452 /* 0x0640 */;
            401: data_o = 32'h7830206f /* 0x0644 */;
            402: data_o = 32'h30303038 /* 0x0648 */;
            403: data_o = 32'h30303030 /* 0x064c */;
            404: data_o = 32'h20090a0d /* 0x0650 */;
            405: data_o = 32'h50202e33 /* 0x0654 */;
            406: data_o = 32'h746e6972 /* 0x0658 */;
            407: data_o = 32'h6d656d20 /* 0x065c */;
            408: data_o = 32'h2079726f /* 0x0660 */;
            409: data_o = 32'h6d6f7266 /* 0x0664 */;
            410: data_o = 32'h38783020 /* 0x0668 */;
            411: data_o = 32'h30303030 /* 0x066c */;
            412: data_o = 32'h0d303030 /* 0x0670 */;
            413: data_o = 32'h3420090a /* 0x0674 */;
            414: data_o = 32'h6f43202e /* 0x0678 */;
            415: data_o = 32'h6e69746e /* 0x067c */;
            416: data_o = 32'h74206575 /* 0x0680 */;
            417: data_o = 32'h6f42206f /* 0x0684 */;
            418: data_o = 32'h6620746f /* 0x0688 */;
            419: data_o = 32'h206d6f72 /* 0x068c */;
            420: data_o = 32'h30387830 /* 0x0690 */;
            421: data_o = 32'h30303030 /* 0x0694 */;
            422: data_o = 32'h00003030 /* 0x0698 */;
            423: data_o = 32'h00000000 /* 0x069c */;
            424: data_o = 32'h20090a0d /* 0x06a0 */;
            425: data_o = 32'h646e6148 /* 0x06a4 */;
            426: data_o = 32'h7265766f /* 0x06a8 */;
            427: data_o = 32'h206f7420 /* 0x06ac */;
            428: data_o = 32'h75626564 /* 0x06b0 */;
            429: data_o = 32'h72656767 /* 0x06b4 */;
            430: data_o = 32'h202e2e2e /* 0x06b8 */;
            431: data_o = 32'h0a0d0a0d /* 0x06bc */;
            432: data_o = 32'h00000000 /* 0x06c0 */;
            433: data_o = 32'h00000000 /* 0x06c4 */;
            434: data_o = 32'h20090a0d /* 0x06c8 */;
            435: data_o = 32'h65746e45 /* 0x06cc */;
            436: data_o = 32'h68742072 /* 0x06d0 */;
            437: data_o = 32'h69732065 /* 0x06d4 */;
            438: data_o = 32'h6f20657a /* 0x06d8 */;
            439: data_o = 32'h68742066 /* 0x06dc */;
            440: data_o = 32'h656d2065 /* 0x06e0 */;
            441: data_o = 32'h79726f6d /* 0x06e4 */;
            442: data_o = 32'h206e6920 /* 0x06e8 */;
            443: data_o = 32'h65747962 /* 0x06ec */;
            444: data_o = 32'h0000203a /* 0x06f0 */;
            445: data_o = 32'h00000000 /* 0x06f4 */;
            446: data_o = 32'h20090a0d /* 0x06f8 */;
            447: data_o = 32'h20656854 /* 0x06fc */;
            448: data_o = 32'h6f6d656d /* 0x0700 */;
            449: data_o = 32'h66207972 /* 0x0704 */;
            450: data_o = 32'h206d6f72 /* 0x0708 */;
            451: data_o = 32'h30387830 /* 0x070c */;
            452: data_o = 32'h30303030 /* 0x0710 */;
            453: data_o = 32'h69203030 /* 0x0714 */;
            454: data_o = 32'h00003a73 /* 0x0718 */;
            455: data_o = 32'h00000000 /* 0x071c */;
            456: data_o = 32'h0a0d0a0d /* 0x0720 */;
            457: data_o = 32'h72502009 /* 0x0724 */;
            458: data_o = 32'h20746e69 /* 0x0728 */;
            459: data_o = 32'h696e6966 /* 0x072c */;
            460: data_o = 32'h64656873 /* 0x0730 */;
            461: data_o = 32'h0000202e /* 0x0734 */;
            462: data_o = 32'h20090a0d /* 0x0738 */;
            463: data_o = 32'h746f6f42 /* 0x073c */;
            464: data_o = 32'h20676e69 /* 0x0740 */;
            465: data_o = 32'h30207461 /* 0x0744 */;
            466: data_o = 32'h30303878 /* 0x0748 */;
            467: data_o = 32'h30303030 /* 0x074c */;
            468: data_o = 32'h2e2e2e30 /* 0x0750 */;
            469: data_o = 32'h0d0a0d20 /* 0x0754 */;
            470: data_o = 32'h0000000a /* 0x0758 */;
            471: data_o = 32'h00000000 /* 0x075c */;
            472: data_o = 32'h33323130 /* 0x0760 */;
            473: data_o = 32'h37363534 /* 0x0764 */;
            474: data_o = 32'h42413938 /* 0x0768 */;
            475: data_o = 32'h46454443 /* 0x076c */;
            476: data_o = 32'h00000000 /* 0x0770 */;
            477: data_o = 32'h00000000 /* 0x0774 */;
            478: data_o = 32'h00000000 /* 0x0778 */;
            479: data_o = 32'h00000000 /* 0x077c */;
            480: data_o = 32'h00000000 /* 0x0780 */;
            481: data_o = 32'h00000000 /* 0x0784 */;
            482: data_o = 32'h00000000 /* 0x0788 */;
            483: data_o = 32'h00000000 /* 0x078c */;
            484: data_o = 32'h00000000 /* 0x0790 */;
            485: data_o = 32'h00000000 /* 0x0794 */;
            486: data_o = 32'h00000000 /* 0x0798 */;
            487: data_o = 32'h00000000 /* 0x079c */;
            488: data_o = 32'h00000000 /* 0x07a0 */;
            489: data_o = 32'h00000000 /* 0x07a4 */;
            490: data_o = 32'h00000000 /* 0x07a8 */;
            491: data_o = 32'h00000000 /* 0x07ac */;
            492: data_o = 32'h00000000 /* 0x07b0 */;
            493: data_o = 32'h00000000 /* 0x07b4 */;
            494: data_o = 32'h00000000 /* 0x07b8 */;
            495: data_o = 32'h00000000 /* 0x07bc */;
            496: data_o = 32'h00000000 /* 0x07c0 */;
            497: data_o = 32'h00000000 /* 0x07c4 */;
            498: data_o = 32'h00000000 /* 0x07c8 */;
            499: data_o = 32'h00000000 /* 0x07cc */;
            500: data_o = 32'h00000000 /* 0x07d0 */;
            501: data_o = 32'h00000000 /* 0x07d4 */;
            502: data_o = 32'h00000000 /* 0x07d8 */;
            503: data_o = 32'h00000000 /* 0x07dc */;
            504: data_o = 32'h00000000 /* 0x07e0 */;
            505: data_o = 32'h00000000 /* 0x07e4 */;
            506: data_o = 32'h00000000 /* 0x07e8 */;
            507: data_o = 32'h00000000 /* 0x07ec */;
            508: data_o = 32'h00000000 /* 0x07f0 */;
            509: data_o = 32'h00000000 /* 0x07f4 */;
            510: data_o = 32'h00000000 /* 0x07f8 */;
            511: data_o = 32'h00000000 /* 0x07fc */;
            default: data_o = '0;
        endcase
    end

endmodule
