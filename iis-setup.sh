#!/usr/bin/env bash
# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

export BENDER=bender-0.27.1
$BENDER checkout

source deps/snitch_cluster/iis-setup.sh

# Define required environment variables
export CLANG_FORMAT=clang-format-10.0.1
export RISCV_GCC_BINROOT=/usr/pack/riscv-1.0-kgf/riscv64-gcc-12.2.0/bin

# Install verible
mkdir -p tools/verible
chmod 777 tools/verible
cd tools/verible
curl -Ls -o verible.tar.gz https://github.com/chipsalliance/verible/releases/download/v0.0-3222-gb19cdf44/verible-v0.0-3222-gb19cdf44-CentOS-7.9.2009-Core-x86_64.tar.gz
tar -xzf verible.tar.gz --strip-components=1
export PATH=$(pwd)/bin:$PATH
cd -