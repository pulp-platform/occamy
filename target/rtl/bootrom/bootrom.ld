/* Copyright 2024 KU Leuven. */


ENTRY(_start)

MEMORY
{
  bootrom (rx)  : ORIGIN = 0x01000000, LENGTH = 16K
  spm (rwx)     : ORIGIN = 0x70000000, LENGTH = 128K
}

SECTIONS
{
  .text : { *(.text._start) *(.text) } > bootrom
	.rodata : { *(.rodata) *(.rodata*) } > bootrom
	.srodata : { *(.srodata) *(.srodata*) } > bootrom
	.data : { *(.data) *(.sdata)  } > spm
	.bss : { *(.bss) } > spm

	/* .misc : { *(*) } > bootrom */
  /* /DISCARD/ : { *(.riscv.attributes) *(.comment) *(.debug*) } */

  /* Global and stack pointer */
  __global_pointer$ = ADDR(.rodata) + SIZEOF(.rodata) / 2;
  __stack_pointer$  = ORIGIN(spm) + LENGTH(spm) - 8;
  /* Quadrant Parameters */
  __quad_stride     = 0x10000;
  __quad_int_base   = 0x0b000000;
  /* Further addresses */
  __soc_ctrl_scratch0 = 0x02000014;
  __soc_ctrl_scratch1 = 0x02000018;
  __soc_ctrl_bootmode = 0x02000024;
  __soc_ctrl_nr_quads = 0x02000028;
  __clint_mtime       = 0x0400bff8;
  __base_uart_sym     = 0x02002000;
  __base_i2c_sym      = 0x02004000;
  __base_spi_sym      = 0x03000000;
  __base_spm_sym      = ORIGIN(spm);
}
