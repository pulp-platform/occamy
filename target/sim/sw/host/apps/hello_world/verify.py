#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

import argparse
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).parent / '../../../../../../deps/snitch_cluster/util/sim/'))
from sim_utils import run_simulations  # noqa: E402
from Simulator import QuestaSimulator  # noqa: E402

UART_LOG = 'uart0.log'
EXPECTED_OUTPUT = "Hello world!\r\n"


def parse_args():
    # Argument parsing
    parser = argparse.ArgumentParser(allow_abbrev=True)
    parser.add_argument(
        'sim_bin',
        help='The simulator binary to be used to start the simulation',
    )
    parser.add_argument(
        'snitch_bin',
        help='The Snitch binary to be executed by the simulated Snitch hardware')
    return parser.parse_args()


def main():
    args = parse_args()
    simulator = QuestaSimulator(args.sim_bin)
    simulation = simulator.get_simulation({'elf': args.snitch_bin})
    result = run_simulations([simulation])

    actual_output = ''
    with open(UART_LOG, 'rb') as file:
        actual_output = file.read().decode('ascii')
    if result == 0:
        if actual_output == EXPECTED_OUTPUT:
            print(f"[{Path(__file__).name}] UART output matches expected output"
                  f" \"{ascii(EXPECTED_OUTPUT)}\"")
            return 0
        else:
            print(f"[{Path(__file__).name}] UART output \"{ascii(actual_output)}\""
                  f" does not match expected output \"{ascii(EXPECTED_OUTPUT)}\"")
            return 1
    else:
        return result


if __name__ == '__main__':
    sys.exit(main())
