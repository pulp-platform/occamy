// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// #include "offload_general.h"

#include "host.c"

// Other variables
// __thread volatile comm_buffer_t* comm_buffer;

#define N_JOBS 1

int main() {
    // Reset and ungate quadrant 0, deisolate
    reset_and_ungate_quad(0);
    deisolate_quad(0, ISO_MASK_ALL);

    // Enable interrupts to receive notice of job termination
    enable_sw_interrupts();

    // Program Snitch entry point and communication buffer
    program_snitches();

    // Wakeup Snitches for snRuntime initialization
    wakeup_snitches_cl();

    int32_t snitch_return_value = -1;

    // Wait for snRuntime initialization to be over
    wait_snitches_done();

    // Send jobs
    // for (int i = 0; i < N_JOBS; i++) {
        // Start Snitches
        // mcycle();
        wakeup_snitches_cl();

        // Wait for job done
        wait_sw_interrupt();
        // Clear interrupt
        clear_sw_interrupt(0);
        // wait_snitches_done();
        snitch_return_value = ((int32_t)comm_buffer.usr_data_ptr);
    // }
    // Exit routine
    // mcycle();
    return snitch_return_value;
}
