/* Copyright 2020 ETH Zurich and University of Bologna. */
/* Solderpad Hardware License, Version 0.51, see LICENSE for details. */
/* SPDX-License-Identifier: SHL-0.51 */

ENTRY(_start)

MEMORY
{
    /* In the debug region, we store some metadata in the ELF
       (e.g. section lengths) for use by the test environment */
    META (rwxa) : ORIGIN = 0x00000000, LENGTH = 0x1000
    /* Upper 448 KiB of SPM for stage 1 loader or small app */
    APPL (rwxa) : ORIGIN = 0x70010000, LENGTH = 0x70000
    DRAM (rwxa) : ORIGIN = 0x80000000, LENGTH = 0x80000000
}

SECTIONS
{
  /* Scratch 0 register used for return code */
  __soc_ctrl_scratch0 = 0x02000014;

  /* Metadata section: stores info on application section */
  .meta : {*(.meta)} > META
  __meta_appl_addr  = ADDR(.appl);
  __meta_appl_len   = SIZEOF(.appl);

  /* The program code and data goes into SPM */
  .appl : {
    __stack_pointer$  = . + 0x70000;
    *(.text.startup)
    *(.text .text.*)
    __SDATA_BEGIN__ = .;
    __global_pointer$ = . + 0x7f0;
    *(.sdata)
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    *(.data)
    *(.rodata .rodata.*)
    *(.devicebin)
  } > APPL

  .bss (NOLOAD) :
  {
    . = ALIGN(8);
    __bss_start = . ;
    *(.sbss .sbss.*)
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(8);
    __bss_end = . ;
  } > APPL

  /* Discard sections */
  /DISCARD/ : { *(.riscv.attributes) *(.comment) }
}
