#!/usr/bin/env bash
# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

export BENDER=bender-0.27.1
$BENDER checkout

source deps/snitch_cluster/iis-setup.sh

# TODO: uncomment if needed else remove
# export CLANG=/usr/pack/riscv-1.0-kgf/pulp-llvm-0.12.0/bin/clang
export CLANG_FORMAT=clang-format-10.0.1

# Install CVA6 compiler toolchain
RISCV_GCC_VERSION=8.3.0-2020.04.0
mkdir -p tools/riscv
chmod 777 tools/riscv
cd tools/riscv
curl -Ls -o riscv-gcc.tar.gz https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-$RISCV_GCC_VERSION-x86_64-linux-ubuntu14.tar.gz
tar -xf riscv-gcc.tar.gz --strip-components=1
export PATH=$(pwd)/bin:$PATH
cd -

# Install verible
mkdir -p tools/verible
chmod 777 tools/verible
cd tools/verible
curl -Ls -o verible.tar.gz https://github.com/chipsalliance/verible/releases/download/v0.0-3222-gb19cdf44/verible-v0.0-3222-gb19cdf44-CentOS-7.9.2009-Core-x86_64.tar.gz
tar -xzf verible.tar.gz --strip-components=1
export PATH=$(pwd)/bin:$PATH
cd -