# Copyright 2024 KU Leuven
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yunhao Deng <yunhao.deng@kuleuven.be>

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := ${MKFILE_DIR}../../..

include $(ROOT)/util/Makefrag

CROSS_COMPILE = riscv64-unknown-elf-
INCLUDES = -I./ -I./src
SRCS_C = src/main.c 
OBJS_C = $(SRCS_C:.c=.o)

CC = $(CROSS_COMPILE)gcc
OBJDUMP = $(CROSS_COMPILE)objdump
OBJCOPY = $(CROSS_COMPILE)objcopy

CFLAGS 	= -Os -g -Werror -ffreestanding -fno-strict-aliasing
CFLAGS += -static -nostartfiles -nostartfiles
CFLAGS += -fno-omit-frame-pointer -fno-optimize-sibling-calls -fno-stack-protector
CFLAGS += -mno-save-restore -mstrict-align
CFLAGS += -mabi=lp64d -march=rv64imafd
CFLAGS += -mcmodel=medany

.PHONY: bootrom clean
bootrom: bootrom.elf bootrom.dump bootrom.bin

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
	@echo "CC    <= $<"

bootrom.elf bootrom.dump bootrom.bin: bootrom.S src/bootrom.o bootrom.ld
	$(CC) $(CFLAGS) $(INCLUDES) -Tbootrom.ld $< src/bootrom.o -o bootrom.elf
	$(OBJDUMP) -d bootrom.elf > bootrom.dump
	$(OBJCOPY) -j .text -j .rodata -j .srodata -O binary bootrom.elf bootrom.bin

clean:
	rm -rf *.bin *.dump *.elf src/*.o
