// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "host.c"

int main() {
    // Reset and ungate all quadrants, deisolate
    reset_and_ungate_quadrants();
    deisolate_all();

    // Enable interrupts to receive notice of job termination
    enable_sw_interrupts();

    // Program Snitch entry point and communication buffer
    program_snitches();

    // Start Snitches
    wakeup_snitches_cl();

    // Wait for job done
    wait_snitches_done();

    // Exit routine
    mcycle();
}
