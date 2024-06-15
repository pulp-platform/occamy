// Copyright 2024 KU Leuven
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Yunhao Deng <yunhao.deng@kuleuven.be>

// Please avoid using initialized global variable and static variable (.data region) in C. This will lead to
// the loss of initial value, as they are allocated in spm instead of bootrom. 

// For global constant, use "const var"
// For values need to share between functions, use uninitialized global variable + initialization function

#include "uart.h"

#define SOH 0x01
#define STX 0x02
#define EOT 0x04
#define ACK 0x06
#define NAK 0x15
#define CAN 0x18
#define CTRL_Z 0x1A
#define DLE 0x10

#define bool uint8_t
#define true 1
#define false 0
#define size_t uint32_t

uint8_t compute_parity(const uint8_t *data, size_t length) {
    uint16_t parity = 0; // Initial value
    for (size_t i = 0; i < length; i++) {
        parity += (uint16_t)data[i]; // Calculate the sum
        parity = parity & 0x00FF;
    }
    return (uint8_t)parity;
}

void *memcpy(void *dest, const void *src, size_t n) {
    uint8_t *d = (uint8_t *)dest;
    const uint8_t *s = (const uint8_t *)src;

    for (size_t i = 0; i < n; i++) {
        d[i] = s[i];
    }

    return dest;
}

void delay_cycles(uint64_t cycle) {
    uint64_t target_cycle, current_cycle;


    __asm__ volatile(
                    "csrr %0, mcycle;"
                    : "=r"(target_cycle)
                    );
    target_cycle = target_cycle + cycle;
    while (current_cycle < target_cycle) {
    __asm__ volatile(
                    "csrr %0, mcycle;"
                    : "=r"(current_cycle)
                    );
    }
}

void uart_xmodem(uint64_t start_address) {
    uint32_t block_number = 1;
    uint8_t received_char;
    uint8_t expected_packet_number = 1;
    bool transmission_end = false;

    print_uart("\r\n\t Start to receive data in 10 second... ");
    delay_cycles(50000000 * 10);
    
    write_serial(NAK);  // Request for data

    while (!transmission_end) {
        uint8_t data[1024];
        uint8_t packet_number, packet_complement;
        uint8_t received_parity, calculated_parity;
        int index = 0;

        received_char = read_serial(); // Read the header
        if (received_char == EOT) { // End of transmission
            write_serial(ACK);
            print_uart("\r\n\t Load finished. \r\n\r\n");
            break;
        }

        if (received_char == SOH || received_char == STX) {
            packet_number = read_serial();
            packet_complement = read_serial();

            if (packet_number == ((~packet_complement) & 0xFF)) { // Packet number is correct
                while (index < (received_char == SOH ? 128 : 1024)) {
                    data[index++] = read_serial();
                }

                received_parity = read_serial();

                calculated_parity = compute_parity(data, index);

                if (received_parity == calculated_parity) {
                    // Copy data to memory
                    memcpy((void *)(start_address + (block_number - 1) * 128), data, index);
                    block_number++;
                    write_serial(ACK);
                } else {
                    write_serial(NAK); // CRC error, request retransmission
                }
            } else {
                write_serial(NAK); // Packet number error
            }
        } else {
            write_serial(CAN); // Unexpected byte received
        }
    }
}

// Boot modes.
enum boot_mode_t {JTAG, UART, PRINTMEM, NORMAL };

void main() {
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
        print_uart("\r\n\t 1. Load from JTAG\r\n\t 2. Load from UART\r\n\t 3. Print memory from 0x80000000\r\n\t 4. Continue to Boot from 0x80000000");
        boot_mode = read_serial() - '0' - 1;

        switch (boot_mode) {
            case JTAG:
                print_uart("\r\n\t Handover to debugger... \r\n\r\n");
                __asm__ volatile(
                    "csrr a0, mhartid;"
                    "ebreak;");
            break;

            case UART:
                uart_xmodem(start_address);
                print_uart("\r\n\t Load finished. \r\n\r\n");
            break;

            case PRINTMEM: 
                print_uart("\r\n\t Enter the size of the memory in byte: ");
                scan_uart(in_buf);
                char* cur = in_buf;
                end_address = 0;
                while (*cur != '\0') {
                    end_address = end_address * 10 + *cur - '0';
                    cur++;
                }
                print_uart("\r\n\t The memory from 0x80000000 is:");
                print_uart_hex((char*)start_address, end_address);
                print_uart("\r\n\r\n\t Print finished. ");
                read_serial();
            break;

            case NORMAL:
                print_uart("\r\n\t Booting at 0x80000000... \r\n\r\n");
                return;
            break;
        }
    }
}
