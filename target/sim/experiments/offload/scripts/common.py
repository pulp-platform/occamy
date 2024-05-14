# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>


def get_mcast_prefix(mcast):
    return "M" if mcast else "U"


def get_data_cfg_prefix(test):
    app = test['app']
    if app in ['kmeans', 'montecarlo']:
        return f'L{test["n_samples"]}'
    elif app in ['atax']:
        return f'L{test["M"]}'
    elif app in ['gemm', 'correlation', 'covariance']:
        return f'M{test["M"]}/N{test["N"]}'
    elif app in ['axpy']:
        return f'L{test["n"]}'


def get_prefix(test):
    prefix = f'{test["app"]}/'
    prefix += f'{get_data_cfg_prefix(test)}/'
    prefix += f'{get_mcast_prefix(test["multicast"])}/'
    prefix += f'N{test["n_clusters_to_use"]}'
    return prefix
