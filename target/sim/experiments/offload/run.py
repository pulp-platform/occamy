#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

import json
import json5
import os
from pathlib import Path
import signal
import subprocess
import sys
import yaml
import tempfile
from termcolor import cprint, colored
from mako.template import Template

sys.path.append(str(Path(__file__).parent / '../../../../deps/snitch_cluster/util/sim/'))
import sim_utils  # noqa: E402
from Simulator import QuestaSimulator  # noqa: E402

FILE_DIR = Path(__file__).parent.resolve()
TARGET_DIR = FILE_DIR / '../../'
AXPY_VERIFY_PY = TARGET_DIR / '../../deps/snitch_cluster/sw/blas/axpy/verify.py'
GEMM_VERIFY_PY = TARGET_DIR / '../../deps/snitch_cluster/sw/blas/gemm/verify.py'
APP = 'experimental_offload'
SOURCE_BUILD_DIR = TARGET_DIR / f'sw/host/apps/{APP}/build'
TARGET_BUILD_DIR = FILE_DIR / 'build'
DEVICE_ELF = TARGET_DIR / f'sw/device/apps/{APP}/build/{APP}.elf'
CFG_DIR = TARGET_DIR / 'cfg'
BIN_DIR = Path('bin')
VSIM_BUILDDIR = Path('work-vsim')
ROI_SPEC_TPL = FILE_DIR / 'roi_spec.json.tpl'


def run(cmd, env=None, dry_run=False):
    cmd = [str(arg) for arg in cmd]
    if dry_run:
        print(' '.join(cmd))
    else:
        p = subprocess.Popen(cmd, env=env)
        retcode = p.wait()
        if retcode != 0:
            sys.exit(retcode)


def extend_environment(env=None, **kwargs):
    if not env:
        env = os.environ.copy()
    env.update(kwargs)
    return env


def build_sw(tests, dry_run=False):
    # Use build/ as temporary build directory for every test, then move to unique
    # tmp/ subdirectory
    run(['make', '-C', TARGET_DIR, 'clean-sw'], dry_run=dry_run)
    for test in tests:
        prefix = test['prefix']
        build_dir = SOURCE_BUILD_DIR / prefix
        tmp_build_dir = Path('tmp', prefix)
        cprint(f'Build software {colored(build_dir, "cyan")}', attrs=["bold"])
        run(['make', '-C', TARGET_DIR, 'DEBUG=ON', f'CFG_OVERRIDE={test["hw_cfg"]}', 'sw', '-B'],
            env=test['env'], dry_run=dry_run)
        run(['mkdir', '-p', tmp_build_dir.parent], dry_run=dry_run)
        run(['mv', SOURCE_BUILD_DIR, tmp_build_dir], dry_run=dry_run)
        run(['cp', DEVICE_ELF, tmp_build_dir / 'device.elf'], dry_run=dry_run)
    # Rename tmp/ to build/
    run(['rm', '-rf', str(TARGET_BUILD_DIR)], dry_run=dry_run)
    run(['mv', 'tmp', str(TARGET_BUILD_DIR)], dry_run=dry_run)


def build_hw(tests, dry_run=False):
    for test in tests:
        hw_cfg = test['hw_cfg']
        sim_bin = test['sim_bin']
        bin_dir = Path(sim_bin).parent
        vsim_builddir = test['vsim_builddir']
        cprint(f'Build hardware {colored(sim_bin, "cyan")}', attrs=["bold"])
        run(['make', '-C', TARGET_DIR, f'CFG_OVERRIDE={hw_cfg}', 'rtl'], dry_run=dry_run)
        run(['make', '-C', TARGET_DIR, f'VSIM_BUILDDIR={vsim_builddir}', f'BIN_DIR={bin_dir}',
            sim_bin], dry_run=dry_run)


def post_process_traces(test, dry_run=False):
    n_clusters_to_use = test['n_clusters_to_use']
    logdir = test['run_dir'] / 'logs'
    device_elf = test['device_elf']
    hw_cfg = test['hw_cfg']
    roi_spec = logdir / 'roi_spec.json'
    # Read and render specification template JSON
    with open(ROI_SPEC_TPL, 'r') as f:
        spec_template = Template(f.read())
        rendered_spec = spec_template.render(nr_clusters=n_clusters_to_use)
        spec = json5.loads(rendered_spec)
    with open(roi_spec, 'w') as f:
        json.dump(spec, f, indent=4)
    # Build traces and benchmark
    cprint(f'Build traces {colored(logdir, "cyan")}', attrs=["bold"])
    run(['make', '-C', TARGET_DIR, f'LOGS_DIR={logdir}', f'BINARY={device_elf}', 'annotate', '-j'],
        dry_run=dry_run)
    run(['make', '-C', TARGET_DIR, f'LOGS_DIR={logdir}', f'ROI_SPEC={roi_spec}',
        f'CFG_OVERRIDE={hw_cfg}', 'trace-view'], dry_run=dry_run)


def get_gemm_cfg(n):
    filled_template = Template(filename=str(GEMM_CFG_TEMPLATE)).render(N=n)
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
        temp_file.write(filled_template)
        return temp_file.name


def get_gemm_cfg(n):
    filled_template = Template(filename=str(GEMM_CFG_TEMPLATE)).render(N=n)
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
        temp_file.write(filled_template)
        return temp_file.name


# Get tests from a test list file
def get_tests(testlist, run_dir, hw_cfg):

    # Get tests from test list file
    testlist_path = Path(testlist).absolute()
    with open(testlist_path, 'r') as f:
        tests = yaml.safe_load(f)['runs']

    # Derive information required for simulation
    for test in tests:

        # Alias test parameters
        length = test['length']
        n_clusters_to_use = test['n_clusters_to_use']
        multicast = test['multicast']
        app = test['app']

        # Resolve derived test parameters
        mcast_prefix = "M" if multicast else "U"
        prefix = f'{app}/L{length}/{mcast_prefix}/N{n_clusters_to_use}'
        full_hw_cfg = f'{mcast_prefix}-{hw_cfg}'
        hw_cfg_file = CFG_DIR / f'{full_hw_cfg}.hjson'
        vsim_builddir = VSIM_BUILDDIR / f'{full_hw_cfg}'
        unique_run_dir = Path(run_dir).resolve() / prefix
        unique_build_dir = TARGET_BUILD_DIR / prefix
        elf = unique_build_dir / f'{APP}.elf'
        device_elf = unique_build_dir / 'device.elf'
        sim_bin = TARGET_DIR / BIN_DIR / full_hw_cfg / 'occamy_top.vsim'
        cflags = f'-DN_CLUSTERS_TO_USE={n_clusters_to_use}'
        if multicast:
            cflags += ' -DUSE_MULTICAST'
        if app == 'axpy':
            cflags += ' -DOFFLOAD_AXPY'
        elif app == 'gemm':
            cflags += ' -DOFFLOAD_GEMM'
        elif app == 'mc':
            cflags += f' -DOFFLOAD_MONTECARLO -DMC_LENGTH={length}'
        env = extend_environment(
            RISCV_CFLAGS=cflags,
            LENGTH=f'{length}',
            SECTION=".wide_spm",
            OFFLOAD=app)
        if app == 'gemm':
            gemm_cfg_file = get_gemm_cfg(length)
            env = extend_environment(env, DATA_CFG=gemm_cfg_file)

        # Extend test with derived parameters
        test['sim_bin'] = sim_bin
        test['prefix'] = prefix
        test['elf'] = elf
        test['device_elf'] = device_elf
        if app == 'axpy':
            test['cmd'] = [str(AXPY_VERIFY_PY), str(sim_bin), str(elf)]
        elif app == 'gemm':
            test['cmd'] = [str(GEMM_VERIFY_PY), str(sim_bin), str(elf)]
        elif app == 'mc':
            test['sim_bin'] = sim_bin
        test['run_dir'] = unique_run_dir
        test['env'] = env
        test['cflags'] = cflags
        test['vsim_builddir'] = vsim_builddir
        test['hw_cfg'] = hw_cfg_file

    return tests


# Create simulation objects from the tests
def get_simulations(tests):
    simulations = [QuestaSimulator(test['sim_bin']).get_simulation(test) for test in tests]
    return simulations


def main():
    # Get args
    parser = sim_utils.parser()
    parser.add_argument(
        '--post-process-only',
        action='store_true',
        help='Does not run the simulations, only post-processes the traces')
    parser.add_argument(
        '--hw-cfg',
        default='Q8C4',
        help='Occamy configuration string e.g. Q6C4 for 6 quadrants 4 clusters')
    args = parser.parse_args()

    # Get tests from test list and create simulation objects
    tests = get_tests(args.testlist, args.run_dir, args.hw_cfg)
    simulations = get_simulations(tests)

    # Register SIGTERM handler, used to gracefully terminate all subprocesses
    signal.signal(signal.SIGTERM, lambda _, __: sim_utils.terminate_processes())

    # Build HW and SW for every test and run simulations
    if not args.post_process_only:
        build_sw(tests, dry_run=args.dry_run)
        build_hw(tests, dry_run=args.dry_run)
        status = sim_utils.run_simulations(simulations,
                                           n_procs=args.n_procs,
                                           dry_run=args.dry_run,
                                           early_exit=args.early_exit)
        if status:
            return status

    # Post process simulation logs
    [post_process_traces(test, dry_run=args.dry_run) for test in tests]

    return 0


if __name__ == '__main__':
    sys.exit(main())
