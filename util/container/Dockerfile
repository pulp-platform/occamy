# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Docker container for Occamy development.

# 1. Stage
FROM ghcr.io/pulp-platform/snitch_cluster:main AS occamy
ARG HOST_RISCV_GCC_VERSION=8.3.0-2020.04.0

LABEL version="0.1"
LABEL description="Occamy container for hardware and software development."
LABEL maintainer="colluca@iis.ee.ethz.ch"
LABEL org.opencontainers.image.source https://github.com/pulp-platform/occamy


WORKDIR /tools

# Get the CVA6 GCC toolchain
RUN curl -Ls -o riscv-gcc.tar.gz https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-${HOST_RISCV_GCC_VERSION}-x86_64-linux-ubuntu14.tar.gz && \
    mkdir -p /tools/riscv && chmod 777 /tools/riscv && \
    tar -C /tools/riscv -xf riscv-gcc.tar.gz --strip-components=1
ENV HOST_RISCV_GCC_BINROOT="/tools/riscv/bin"
