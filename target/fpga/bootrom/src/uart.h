// Copyright 2021 ETH Zurich, University of Bologna, and KU Leuven.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <stdint.h>

#define UART_BASE_ADDR 0x02002000

#define UART_RBR UART_BASE_ADDR + 0
#define UART_THR UART_BASE_ADDR + 0
#define UART_INTERRUPT_ENABLE UART_BASE_ADDR + 4
#define UART_INTERRUPT_IDENT UART_BASE_ADDR + 8
#define UART_FIFO_CONTROL UART_BASE_ADDR + 8
#define UART_LINE_CONTROL UART_BASE_ADDR + 12
#define UART_MODEM_CONTROL UART_BASE_ADDR + 16
#define UART_LINE_STATUS UART_BASE_ADDR + 20
#define UART_MODEM_STATUS UART_BASE_ADDR + 24
#define UART_DLAB_LSB UART_BASE_ADDR + 0
#define UART_DLAB_MSB UART_BASE_ADDR + 4

inline static void write_reg_u8(uintptr_t addr, uint8_t value) {
    volatile uint8_t *loc_addr = (volatile uint8_t *)addr;
    *loc_addr = value;
}

inline static uint8_t read_reg_u8(uintptr_t addr) {
    return *(volatile uint8_t *)addr;
}

inline static int is_data_ready() {
    return read_reg_u8(UART_LINE_STATUS) & 0x01;
}

inline static int is_data_overrun() {
    return read_reg_u8(UART_LINE_STATUS) & 0x02;
}

inline static int is_transmit_empty() {
    return read_reg_u8(UART_LINE_STATUS) & 0x20;
}

inline static int is_transmit_done() {
    return read_reg_u8(UART_LINE_STATUS) & 0x40;
}

inline static void write_serial(char a) {
    while (is_transmit_empty() == 0) {
    };

    write_reg_u8(UART_THR, a);
}

inline static uint8_t read_serial() {
    while (is_data_ready() == 0) {
    };

    return read_reg_u8(UART_RBR);
}
inline static void init_uart(uint32_t freq, uint32_t baud) {
    uint32_t divisor = freq / (baud << 4);

    write_reg_u8(UART_INTERRUPT_ENABLE, 0x00);  // Disable all interrupts
    write_reg_u8(UART_LINE_CONTROL,
                 0x80);  // Enable DLAB (set baud rate divisor)
    write_reg_u8(UART_DLAB_LSB, divisor);                // divisor (lo byte)
    write_reg_u8(UART_DLAB_MSB, (divisor >> 8) & 0xFF);  // divisor (hi byte)
    write_reg_u8(UART_LINE_CONTROL, 0x03);  // 8 bits, no parity, one stop bit
    write_reg_u8(UART_FIFO_CONTROL,
                 0xC7);  // Enable FIFO, clear them, with 14-byte threshold
    write_reg_u8(UART_MODEM_CONTROL, 0x20);  // Autoflow mode
}

inline static void print_uart(const char *str) {
    const char *cur = &str[0];
    while (*cur != '\0') {
        write_serial((uint8_t)*cur);
        ++cur;
    }
    while (!is_transmit_done());
}

inline static void scan_uart(char *str) {
    char *cur = &str[0];
    while (1) {
        *cur = read_serial();
        if (*cur == '\r') {
            *cur = '\0';
            return;
        }
        else cur++;
    }
}
