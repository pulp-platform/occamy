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
SNITCH_DIR = TARGET_DIR / '../../deps/snitch_cluster'
APP = 'experimental_offload'
SOURCE_BUILD_DIR = TARGET_DIR / f'sw/host/apps/{APP}/build'
TARGET_BUILD_DIR = FILE_DIR / 'build'
DEVICE_ELF = TARGET_DIR / f'sw/device/apps/{APP}/build/{APP}.elf'
CFG_DIR = TARGET_DIR / 'cfg'
BIN_DIR = Path('bin')
VSIM_BUILDDIR = Path('work-vsim')

#############
# Utilities #
#############

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

###########
# Targets #
###########

def build_sw(tests, dry_run=False):
    # Use build/ as temporary build directory for every test, then move to unique
    # tmp/ subdirectory
    run(['make', '-C', TARGET_DIR, 'clean-sw'], dry_run=dry_run)
    run(['rm', '-rf', 'tmp/'], dry_run=dry_run)
    for test in tests:
        prefix = test['prefix']
        source_build_dir = SOURCE_BUILD_DIR / prefix
        target_build_dir = TARGET_BUILD_DIR / prefix
        tmp_build_dir = Path('tmp', prefix)
        cprint(f'Build software {colored(source_build_dir, "cyan")}', attrs=["bold"])
        run(['make', '-C', TARGET_DIR, 'DEBUG=ON', f'CFG_OVERRIDE={test["hw_cfg"]}', 'sw', '-B'],
            env=test['env'], dry_run=dry_run)
        run(['mkdir', '-p', tmp_build_dir.parent], dry_run=dry_run)
        run(['mv', SOURCE_BUILD_DIR, tmp_build_dir], dry_run=dry_run)
        run(['cp', DEVICE_ELF, tmp_build_dir / 'device.elf'], dry_run=dry_run)
        # Move from tmp/ to build/
        run(['rm', '-rf', str(target_build_dir)], dry_run=dry_run)
        run(['mkdir', '-p', str(target_build_dir.parent)], dry_run=dry_run)
        run(['mv', str(tmp_build_dir), str(target_build_dir)], dry_run=dry_run)


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
    multicast = test['multicast']
    run_dir = test['run_dir']
    logdir = run_dir / 'logs'
    device_elf = test['device_elf']
    hw_cfg = test['hw_cfg']
    roi_spec = logdir / 'roi_spec.json'
    app = test['app']
    # Read and render specification template JSON
    roi_spec_tpl = FILE_DIR / 'roi' / f'{app}.json.tpl'
    with open(roi_spec_tpl, 'r') as f:
        spec_template = Template(f.read())
        rendered_spec = spec_template.render(nr_clusters=n_clusters_to_use, multicast=multicast)
        spec = json5.loads(rendered_spec)
    with open(roi_spec, 'w') as f:
        json.dump(spec, f, indent=4)
    # Build traces and benchmark
    cprint(f'Build traces {colored(logdir, "cyan")}', attrs=["bold"])
    run(['make', '-C', TARGET_DIR, f'SIM_DIR={run_dir}', f'BINARY={device_elf}', 'annotate', '-j'],
        dry_run=dry_run)
    run(['make', '-C', TARGET_DIR, f'SIM_DIR={run_dir}', f'ROI_SPEC={roi_spec}',
        f'CFG_OVERRIDE={hw_cfg}', f'BINARY={device_elf}', 'visual-trace'], dry_run=dry_run)

###############
# Experiments #
###############

def get_data_cfg(test):
    app = test['app']
    cfg_template = str(FILE_DIR / 'data' / f'{app}.json.tpl')
    filled_template = Template(filename=cfg_template).render(**test)
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
        temp_file.write(filled_template)
        return temp_file.name


def get_data_cfg_prefix(test):
    app = test['app']
    if app in ['kmeans', 'montecarlo']:
        return f'L{test["n_samples"]}'
    elif app in ['atax', 'gemm']:
        return f'L{test["N"]}'
    elif app in ['correlation', 'covariance']:
        return f'L{test["M"]}'
    elif app in ['axpy']:
        return f'L{test["n"]}'


# Get tests from a test list file
def get_tests(testlist, run_dir, hw_cfg):

    # Get tests from test list file
    testlist_path = Path(testlist).absolute()
    with open(testlist_path, 'r') as f:
        tests = yaml.safe_load(f)['runs']

    # Derive information required for simulation
    for test in tests:

        # Alias test parameters
        n_clusters_to_use = test['n_clusters_to_use']
        multicast = test['multicast']
        app = test['app']

        # Resolve derived test parameters
        mcast_prefix = "M" if multicast else "U"
        prefix = f'{app}/{get_data_cfg_prefix(test)}/{mcast_prefix}/N{n_clusters_to_use}'
        name = f'{APP}-{prefix.replace("/", "-")}'
        full_hw_cfg = f'{mcast_prefix}-{hw_cfg}'
        hw_cfg_file = CFG_DIR / f'{full_hw_cfg}.hjson'
        vsim_builddir = VSIM_BUILDDIR / f'{full_hw_cfg}'
        unique_run_dir = Path(run_dir).resolve() / prefix
        unique_build_dir = TARGET_BUILD_DIR / prefix
        elf = unique_build_dir / f'{APP}.elf'
        device_elf = unique_build_dir / 'device.elf'
        sim_bin = TARGET_DIR / BIN_DIR / full_hw_cfg / 'occamy_top.vsim'
        cflags = f'-DN_CLUSTERS_TO_USE={n_clusters_to_use}'
        cflags += f' -DOFFLOAD_{app.upper()}'
        if multicast:
            cflags += ' -DUSE_MULTICAST'
        env = extend_environment(
            RISCV_CFLAGS=cflags,
            SECTION=".wide_spm",
            OFFLOAD=app)
        if app in ['axpy', 'gemm', 'atax', 'correlation', 'covariance', 'montecarlo']:
            data_cfg = get_data_cfg(test)
            env = extend_environment(env, DATA_CFG=data_cfg)
        elif app == 'kmeans':
            data_cfg = get_data_cfg(test)
            env = extend_environment(env, KMEANS_DATA_CFG=data_cfg)

        # Extend test with derived parameters
        test['name'] = name
        test['sim_bin'] = sim_bin
        test['prefix'] = prefix
        test['elf'] = elf
        test['device_elf'] = device_elf
        if app in ['axpy', 'gemm']:
            verify_py = str(SNITCH_DIR / f'sw/blas/{app}/scripts/verify.py')
            test['cmd'] = [verify_py, str(sim_bin), str(elf)]
        elif app in ['kmeans', 'atax', 'correlation', 'covariance']:
            verify_py = str(SNITCH_DIR / f'sw/apps/{app}/scripts/verify.py')
            test['cmd'] = [verify_py, str(sim_bin), str(elf)]
            if app == 'kmeans':
                test['cmd'].append('--no-gui')
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
