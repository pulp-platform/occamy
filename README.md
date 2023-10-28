![CI](https://github.com/pulp-platform/occamy/actions/workflows/ci.yml/badge.svg)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# Occamy

This repository hosts the hardware and software for the Occamy system-on-chip and its generator. Occamy is a high-efficiency system-on-chip coupling a CVA6 Linux-capable manager core with a many-core accelerator for compute-intensive floating-point workloads, building on the [Snitch cluster](https://github.com/pulp-platform/occamy) architecture. It is developed as part of the PULP project, a joint effort between ETH Zurich and the University of Bologna.

## Getting Started

To get started, check out the [getting started guide](https://pulp-platform.github.io/occamy/ug/getting_started.html).

## Content

What can you expect to find in this repository?

- The Occamy system-on-chip generator and hardware sources.
- A runtime and example applications for Occamy.
- An RTL simulation environment for Questa Advanced Simulator.

This code was previously hosted in the [Snitch monorepo](https://github.com/pulp-platform/snitch) and was spun off into its own repository to simplify maintenance and dependency handling. The [Snitch cluster](https://github.com/pulp-platform/occamy), on which the Occamy accelerator is based upon, has also moved to its own repo.

## License

Occamy is being made available under permissive open source licenses.

The following files are released under Apache License 2.0 (`Apache-2.0`) see `LICENSE`:

- `sw/`
- `util/`

The following files are released under Solderpad v0.51 (`SHL-0.51`) see `hw/LICENSE`:

- `hw/`sdfsdfs
