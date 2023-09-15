#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

import argparse
import os
from pathlib import Path
import subprocess
import sys

sys.path.append(str(Path(__file__).parent / '../../../../../../deps/snitch_cluster/util/sim/'))
import simulate

FILE_DIR = Path(__file__).parent.resolve()
RUN_DIR = FILE_DIR / 'runs'
VERIFY_PY = FILE_DIR / '../../../../../../deps/snitch_cluster/sw/blas/axpy/verify.py'
BUILD_DIR = FILE_DIR / 'build'
TARGET_DIR = FILE_DIR / '../../../../'
APP = 'experimental_offload'
DEVICE_ELF = FILE_DIR / f'../../../device/apps/{APP}/build/{APP}.elf'
CFG_DIR = TARGET_DIR / 'cfg'
BIN_DIR = Path('bin')
VSIM_BUILDDIR = Path('work-vsim')
CFG = 'Q8C4'


def run(cmd, env=None, dryrun=False):
    if dryrun:
        print(cmd)
    else:
        p = subprocess.Popen(cmd, env=env, shell=True)
        retcode = p.wait()
        if retcode != 0:
            sys.exit(retcode)


def extend_environment(**kwargs):
    env = os.environ.copy()
    env.update(kwargs)
    return env


def build_sw(tests, args):
    for test in tests:
        # Get test parameters
        length = test['length']
        n_clusters_to_use = test['n_clusters_to_use']
        multicast = test['multicast']
        app = test['app']

        # Derive other information from parameters
        flags = f'LENGTH={length}'
        mcast_prefix = "M" if multicast else "U"
        prefix = f'{app}/L{length}/{mcast_prefix}/N{n_clusters_to_use}'
        cflags = f'-DN_CLUSTERS_TO_USE={n_clusters_to_use}'
        if multicast:
            cflags += f' -DMULTICAST'
        if app == 'axpy':
            cflags += f' -DOFFLOAD_AXPY'
        elif app == 'mc':
            cflags += f' -DOFFLOAD_MONTECARLO'
        cfg = f'{mcast_prefix}-{CFG}'
        cfg_file = CFG_DIR / f'{cfg}.hjson'
        env = extend_environment(
            RISCV_CFLAGS=cflags,
            LENGTH=f'{length}')
        rundir = RUN_DIR / prefix
        elf = BUILD_DIR / f'{prefix}/{APP}.elf'
        sim_bin = TARGET_DIR / BIN_DIR / f'{cfg}' / 'occamy_top.vsim'
        
        # Build test binary
        if not args.post_process_only:
            temp_build_dir = Path(f'build2/{prefix}')
            run(f'make clean', env=env)
            run(f'cd ../../../../ && make DEBUG=ON CFG_OVERRIDE={cfg_file} sw', env=env)
            run(f'mkdir -p {temp_build_dir.parent} && mv build/ {temp_build_dir}')

        # Extend test with parameter-derived information
        test['elf'] = elf
        if app == 'axpy':
            test['cmd'] = f'{VERIFY_PY} {sim_bin} {elf} --symbols-bin {elf}'
        elif app == 'mc':
            test['sim_bin'] = sim_bin
        test['rundir'] = rundir

        # Create run directory
        if not args.post_process_only:
            run(f'mkdir -p {rundir}')
    
    # Move temporary build2 folder to usual build directory
    if not args.post_process_only:
        run('rm -rf build && mv build2 build')


def build_hw(tests):
    for test in tests:
        multicast = test['multicast']
        prefix = 'M' if multicast else 'U'
        cfg = f'{prefix}-{CFG}'
        cfg_file = CFG_DIR / f'{cfg}.hjson'
        bin_dir = BIN_DIR / cfg
        bin = bin_dir / 'occamy_top.vsim'
        work_vsim = VSIM_BUILDDIR / f'{cfg}'
        run(f'cd {TARGET_DIR} && make CFG_OVERRIDE={cfg_file} rtl')
        run(f'cd {TARGET_DIR} && make VSIM_BUILDDIR={work_vsim} BIN_DIR={bin_dir} {bin}')


def post_process_traces(test):
    logdir = test['rundir'] / 'logs'
    n_clusters_to_use = test['n_clusters_to_use']
    app = test['app']
    run(f'cd {TARGET_DIR} && make LOGS_DIR={logdir} traces -j')
    run(f'cd {TARGET_DIR} && make LOGS_DIR={logdir} BINARY={DEVICE_ELF} annotate -j')
    run(f'cd {TARGET_DIR} && make LOGS_DIR={logdir} perf-csv')
    run(f'cd {TARGET_DIR} && make LOGS_DIR={logdir} event-csv')
    if app == 'axpy':
        layout = 'layout.csv'
    elif app == 'mc':
        layout = 'layout_mc.csv'
    layout = FILE_DIR / layout
    if layout.exists():
        flags = f'LOGS_DIR={logdir}'
        flags += f' LAYOUT_EVENTS_FLAGS=--num-clusters={n_clusters_to_use}'
        flags += f' LAYOUT_FILE={layout}'
        run(f'cd {TARGET_DIR} && make {flags} layout')


def main():
    # Get args and tests as usual
    parser = simulate.parser()
    parser.add_argument(
        '--post-process-only',
        action='store_true',
        help='Does not run the simulations, only post-processes the traces')
    args = parser.parse_args()
    tests = simulate.get_tests(args.testlist)

    # Build SW for every configuration
    build_sw(tests, args)

    if not args.post_process_only:
        # Build HW for every configuration
        build_hw(tests)

        # Run tests as usual
        status = simulate.run_tests(tests, args)
        if status:
            return status

    # Post process simulation logs
    [post_process_traces(test) for test in tests]

    return 0


if __name__ == '__main__':
    sys.exit(main())
