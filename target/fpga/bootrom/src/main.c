// Copyright 2024 KU Leuven
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "uart.h"

// Boot modes.
enum boot_mode_t {JTAG, UART, NORMAL };

int main() {
    enum boot_mode_t boot_mode = JTAG;
    uint64_t start_address;
    uint64_t end_address;

    char in_buf[8]; 
    init_uart(50000000, 115200);

    while (1) {
        start_address = 0x80000000;
        print_uart("\033[2J");
        print_uart("\r\n\t\t Welcome to Occamy Bootrom");
        print_uart("\r\n");
        print_uart("\r\n\t Enter the number to select the mode: ");
        print_uart("\r\n\t 1. Load from JTAG\r\n\t 2. Load from UART\r\n\t 3. Continue to Boot from 0x80000000");
        boot_mode = read_serial() - '0' - 1;

        switch (boot_mode) {
            case JTAG:
                print_uart("\r\n\t Handover to debugger... \r\n\r\n");
                __asm__ volatile(
                    "csrr a0, mhartid;"
                    "ebreak;");
            break;

            case UART:
                print_uart("\r\n\t Enter the size of the binary in byte: ");
                scan_uart(in_buf);
                char *cur = in_buf;
                end_address = 0;
                while (*cur != '\0') {
                    end_address = end_address * 10 + *cur - '0';
                    cur++;
                }
                end_address = start_address + end_address;
                print_uart("\r\n\t Waiting for the data... ");
                for (uint64_t i = start_address; i < end_address; i++) *((uint8_t *)i) = read_serial();
                print_uart("\r\n\t Load finished. \r\n\r\n");
            break;

            case NORMAL:
                print_uart("\r\n\t Booting at 0x80000000... \r\n\r\n");
                __asm__ volatile(
                    "csrr a0, mhartid;" 
                    "jalr 0(%0);"
                    : 
                    : "r" (start_address)
                    : "a0"
                    );
            break;
        }
    }
}
