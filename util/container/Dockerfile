# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Docker container for Occamy development.

# 1. Stage
FROM ubuntu:18.04 AS builder

COPY apt-requirements.txt /tmp/apt-requirements.txt
RUN apt-get update && \
    sed 's/#.*//' /tmp/apt-requirements.txt \
        | xargs apt-get install -y && \
    apt-get install -y \
        build-essential \
        curl \
        git \
        gnupg2 \
        lsb-release \
        software-properties-common \
        unzip \
        wget \
        zlib1g-dev

# Get LLVM 12
RUN wget https://apt.llvm.org/llvm.sh
RUN chmod +x llvm.sh
RUN ./llvm.sh 12

# Build Rust tools
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH "/root/.cargo/bin:${PATH}"

# Install Bender
RUN cargo install bender --version 0.23.2
RUN export SNITCH_CLUSTER_ROOT=$(bender path snitch_cluster)
# ENV SNITCH_CLUSTER_ROOT $(bender path snitch_cluster)

WORKDIR /tools

# Install a newer version of cmake (we need this for banshee)
# RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz && \
#     tar -x -f cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz --strip-components=1 -C . && \
#     rm -rf cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz
# ENV PATH "/tools/bin:${PATH}"

# Install `banshee` (needs cmake)
# RUN git clone https://github.com/pulp-platform/banshee.git /tmp/banshee --recurse-submodules
# RUN cargo install --path /tmp/banshee

# Install Python requirements
COPY $SNITCH_CLUSTER_ROOT/python-requirements.txt /tmp/python-requirements.txt
COPY $SNITCH_CLUSTER_ROOT/docs/requirements.txt /tmp/docs/requirements.txt
# COPY SNITCH_CLUSTER_ROOT/sw/snDNN/requirements.txt /tmp/sw/snDNN/requirements.txt
RUN pip3 install -r /tmp/python-requirements.txt


# 2. Stage
FROM ubuntu:18.04 AS occamy
ARG SNITCH_LLVM_VERSION=latest
ARG RISCV_GCC_VERSION=8.3.0-2020.04.0
ARG VERIBLE_VERSION=0.0-776-g09e0b87
ARG VERILATOR_VERSION=4.100

LABEL version="0.1"
LABEL description="Occamy container for hardware and software development."
LABEL maintainer="zarubaf@iis.ee.ethz.ch"
LABEL org.opencontainers.image.source https://github.com/pulp-platform/occamy


WORKDIR /tools

# Install (and cleanup) required packages (from apt-requirements.txt)
# The list of extra packages is leftover from before this Dockerfile used
# apt-requirements.txt
#
COPY apt-requirements.txt /tmp/apt-requirements.txt
RUN apt-get update && \
    sed 's/#.*//' /tmp/apt-requirements.txt \
        | xargs apt-get install -y && \
    apt-get install -y --no-install-recommends \
        gnupg2 \
        curl \
        wget \
        git && \
    apt-get clean ; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Install Verilator
RUN echo 'deb http://download.opensuse.org/repositories/home:/phiwag:/edatools/xUbuntu_18.04/ /' | tee /etc/apt/sources.list.d/home:phiwag:edatools.list && \
    curl -fsSL https://download.opensuse.org/repositories/home:phiwag:edatools/xUbuntu_18.04/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home_phiwag_edatools.gpg > /dev/null && \
    apt-get update && apt-get install -y verilator-${VERILATOR_VERSION} && \
    apt-get clean ; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Get the precompiled LLVM toolchain
RUN latest_tag=`curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/pulp-platform/llvm-project/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'` && \
    echo "SNITCH_LLVM_VERSION=${SNITCH_LLVM_VERSION} LLVM_TAR=${LLVM_TAR} latest_tag=${latest_tag}" && \
    test "${SNITCH_LLVM_VERSION}" = "latest" && SNITCH_LLVM_VERSION=${latest_tag} || : ; \
    LLVM_TAR=riscv32-pulp-llvm-ubuntu1804-$(echo $SNITCH_LLVM_VERSION | cut -d '-' -f3-).tar.gz && \
    mkdir -p riscv-llvm && \
    echo "SNITCH_LLVM_VERSION=${SNITCH_LLVM_VERSION} LLVM_TAR=${LLVM_TAR} latest_tag=${latest_tag}" && \
    wget -qO- https://github.com/pulp-platform/llvm-project/releases/download/${SNITCH_LLVM_VERSION}/${LLVM_TAR} | \
    tar xvz --strip-components=1 -C riscv-llvm
ENV LLVM_BINROOT "/tools/riscv-llvm/bin"

# Get the CVA6 GCC toolchain
RUN curl -Ls -o riscv-gcc.tar.gz https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-${RISCV_GCC_VERSION}-x86_64-linux-ubuntu14.tar.gz && \
    mkdir -p /tools/riscv && chmod 777 /tools/riscv && \
    tar -C /tools/riscv -xf riscv-gcc.tar.gz --strip-components=1
ENV PATH="/tools/riscv/bin:${PATH}"

# Install Verible
RUN wget https://github.com/google/verible/releases/download/v${VERIBLE_VERSION}/verible-v${VERIBLE_VERSION}-Ubuntu-18.04-bionic-x86_64.tar.gz && \
    tar -x -f verible-v${VERIBLE_VERSION}-Ubuntu-18.04-bionic-x86_64.tar.gz --strip-components=1 -C . && \
    rm -rf verible-v${VERIBLE_VERSION}-Ubuntu-18.04-bionic-x86_64.tar.gz
ENV PATH "/tools/bin:${PATH}"

# Install git>=2.18, required by Github checkout action to recurse submodules
RUN apt-get update && apt-get install software-properties-common -y && \
    add-apt-repository -y ppa:git-core/ppa && \
    apt-get update && \
    apt-get install git -y

# Copy artifacts from stage 1.
COPY --from=builder /root/.cargo/bin/bender bin/

# Set locale to UTF-8, required because Python 3.6 defaults on ASCII encoding.
# See https://click.palletsprojects.com/en/8.1.x/unicode-support/
ENV LC_ALL "C.UTF-8"
ENV LANG   "C.UTF-8"
