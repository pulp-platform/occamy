// Copyright 2021 ETH Zurich, University of Bologna; Copyright 2024 KU Leuven.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include "uart.h"

void _putchar(char character) {
    while (is_transmit_empty() == 0) {
    };

    write_reg_u8(UART_THR, character);
}