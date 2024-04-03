// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Parameters for a GEMM

{
    M: 256,
    N: ${N},
    K: 4,
    beta: 0,
    ta: false,
    tb: true, // must be true for SIMD
    prec: 64,
    expand: 0
}
