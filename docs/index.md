# Occamy

The Occamy project is an open-source RISC-V hardware research project of ETH Zurich and University of Bologna targeting highest possible energy-efficiency. The system is designed around a cluster of versatile and small integer cores, which we call Snitch cluster. The system is designed to be highly parameterizable and suitable for many use-cases.

## Getting Started

See our dedicated [getting started guide](ug/getting_started.md).

## Documentation

The documentation is built from the latest master and hosted at github pages: [https://pulp-platform.github.io/occamy](https://pulp-platform.github.io/occamy).

## About this Repository

The original repository [https://github.com/pulp-platform/snitch](https://github.com/pulp-platform/snitch) was developed as a monorepo hosting both the base Snitch IPs and the Occamy system. For easier integration of the Snitch cluster IP into other systems, the original repo was split into two new repos:

- the [Snitch cluster repository](https://github.com/pulp-platform/snitch_cluster) providing the Snitch cluster IP
- [this repository](https://github.com/pulp-platform/occamy) hosting the Occamy system

The dependency of the Occamy system on the Snitch cluster IP is handled behind the scenes with [Bender](https://github.com/pulp-platform/bender).

## Licensing

Occamy is made available under permissive open source licenses. See the `README.md` for a more detailed break-down.