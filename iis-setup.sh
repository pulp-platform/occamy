#!/usr/bin/env bash
# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

export BENDER=bender-0.27.1
$BENDER checkout

cd deps/snitch_cluster
source iis-setup.sh
cd -

# Define required environment variables
export CLANG_FORMAT=clang-format-10.0.1
export HOST_RISCV_GCC_BINROOT=/usr/pack/riscv-1.0-kgf/riscv64-gcc-12.2.0/bin
