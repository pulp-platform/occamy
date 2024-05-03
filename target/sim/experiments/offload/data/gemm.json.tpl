// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

{
    M: 256,
    N: ${N},
    K: 4,
    beta: 0,
    ta: false,
    tb: true, // must be true for SIMD
    prec: "FP64",
    expand: 0,
    m_tiles: 32, // number of tiles in M dimension
    k_tiles: 1, // number of tiles in K dimension
    n_tiles: 1, // number of tiles in N dimension
    parallelize_k: 0,
    parallelize_m: 1,
    baseline: false
}
