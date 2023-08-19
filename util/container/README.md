# Docker container

This directory contains the [Docker file](Dockerfile) used to build the `occamy` Docker container.

<!--start-docs-->

The Occamy Docker container is based on the [latest Snitch cluster container image](https://github.com/pulp-platform/snitch_cluster/pkgs/container/snitch_cluster) and comes with all free development tools for Snitch/Occamy pre-installed. The environment is also already configured, such that no additional steps are required to work in the container after installation.

Instructions to install the Snitch cluster container can be found in [this README](https://github.com/pulp-platform/snitch_cluster/blob/main/util/container/README.md) and are readily adapted to the Occamy container by replacing references to the Snitch container `ghcr.io/pulp-platform/snitch_cluster` with the Occamy container reference `ghcr.io/pulp-platform/occamy`.
