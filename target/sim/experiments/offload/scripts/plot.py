#!/usr/bin/env python3
# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# flake8: noqa

import argparse
import matplotlib.pyplot as plt
from SimResults import SimResults, SimRegion
import numpy as np
import pandas as pd
import common


# TODO: make sure there are no gaps in the regions from the traces.
#       Otherwise we might be missing some computation time, if we
#       add region times, or simply if we take the start (end) of
#       a region in place of the end (start) of the previous (next).

# Experiment parameters
ALL_NR_CLUSTER_CFGS = [1, 2, 4, 8, 16, 32]
ALL_MCAST_CFGS = [False, True]

# Plot parameters
MARKERS = ['o', '^', 's', '*', 'd', 'X']
MARKER_SIZES = [3, 3, 3, 3, 3, 3]


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("plot", default="fig8", nargs='?', type=str)
    return parser.parse_args()


def get_app_label(app):
    APP_LABELS = {
        'axpy': 'AXPY',
        'montecarlo': 'Monte Carlo',
        'gemm': 'Matmul',
        'atax': 'ATAX',
        'covariance': 'Covariance',
        'correlation': 'Correlation',
    }
    return APP_LABELS[app]


def get_mcast_label(mcast):
    MCAST_LABELS = {False: 'Baseline', True: 'Optimized'}
    return MCAST_LABELS[mcast]


class OffloadSimResults(SimResults):

    def __init__(self, app, mcast, size, nr_clusters):
        self.app = app
        self.mcast = mcast
        self.size = size
        self.nr_clusters = nr_clusters
        if app == 'covariance':
            super().__init__(f'runs/{app}/M{size}/N256/{common.get_mcast_prefix(mcast)}/N{nr_clusters}')
        elif app == 'gemm':
            super().__init__(f'runs/{app}/M256/N{size}/{common.get_mcast_prefix(mcast)}/N{nr_clusters}')
        else:
            super().__init__(f'runs/{app}/L{size}/{common.get_mcast_prefix(mcast)}/N{nr_clusters}')

    def get_send_job_information_time(self):
        return self.get_timespan(
            SimRegion('hart_0', 'prepare data', occurrence=1),
            SimRegion('hart_0', 'prepare data', occurrence=1)
        )

    def get_wakeup_time(self):
        send_interrupt_region = SimRegion('hart_0', 'send interrupt', occurrence=1)
        cluster_wakeup_regions = [
            SimRegion(f'hart_{1+9*i+8}', 'clr interrupt', occurrence=1)
            for i in range(self.nr_clusters)
        ]
        send_interrupt_time = self.get_metric(send_interrupt_region, 'tstart')
        cluster_wakeup_times = self.get_metrics(cluster_wakeup_regions, 'tstart')
        vals = [t - send_interrupt_time for t in cluster_wakeup_times]
        return np.min(vals), np.max(vals), np.average(vals)

    def get_retrieve_job_pointer_time(self):
        vals = [
            self.get_metric(SimRegion(f'hart_{1+9*i+8}', 'get job ptr', occurrence=1), 'cycles')
            for i in range(self.nr_clusters)
        ]
        return np.min(vals), np.max(vals), np.average(vals)

    def get_retrieve_job_arguments_time(self):
        vals = [
            self.get_metric(SimRegion(f'hart_{1+9*i+8}', 'get job args', occurrence=1), 'cycles')
            for i in range(self.nr_clusters)
        ]
        return np.min(vals), np.max(vals), np.average(vals)

    def get_retrieve_job_operands_time(self):
        vals = [
            self.get_metric(SimRegion(f'hart_{1+9*i+8}', 'copy data in', occurrence=1), 'cycles')
            for i in range(self.nr_clusters)
        ]
        return np.min(vals), np.max(vals), np.average(vals)

    def get_job_execution_time(self):
        vals = []
        for i in range(self.nr_clusters):
            # Cluster execution time is calculated from the start of the first core
            # to the end of the last
            if self.app in ['axpy', 'gemm']:
                regions = [
                    SimRegion(f'hart_{1+9*i+j}', 'compute', occurrence=1)
                    for j in range(8)
                ]
                start_times = self.get_metrics(regions, 'tstart')
                end_times = self.get_metrics(regions, 'tend')
            elif self.app == 'montecarlo':
                # TODO: add inter-cluster reduction
                start_regions = [
                    SimRegion(f'hart_{1+9*i+j}', 'compute psum', occurrence=1)
                    for j in range(8)
                ]
                end_regions = [SimRegion(f'hart_{1+9*i}', 'intra-cluster reduction', occurrence=1)]
                start_times = self.get_metrics(start_regions, 'tstart')
                end_times = self.get_metrics(end_regions, 'tend')
            elif self.app == 'atax':
                start_regions = [
                    SimRegion(f'hart_{1+9*i+j}', 'Ax', occurrence=1)
                    for j in range(8)
                ]
                end_regions = [
                    SimRegion(f'hart_{1+9*i+j}', 'AtAx', occurrence=1)
                    for j in range(8)
                ]
                start_times = self.get_metrics(start_regions, 'tstart')
                end_times = self.get_metrics(end_regions, 'tend')
            vals.append(np.max(end_times) - np.min(start_times))
        return np.min(vals), np.max(vals), np.average(vals)

    def get_writeback_job_outputs_time(self):
        vals = [
            self.get_metric(SimRegion(f'hart_{1+9*i+8}', 'copy data out', occurrence=1), 'cycles')
            for i in range(self.nr_clusters)
        ]
        return np.min(vals), np.max(vals), np.average(vals)

    def get_notify_job_completion_time(self):
        # From last core arriving on the barrier to CVA6 waking up
        return_regions = [
            SimRegion(f'hart_{1+9*i+8}', 'return', occurrence=1)
            for i in range(self.nr_clusters)
        ]
        wakeup_time = self.get_metric(SimRegion('hart_0', 'clr interrupt', occurrence=1), 'tstart')
        send_interrupt_time = np.max(self.get_metrics(return_regions, 'tend'))
        return wakeup_time - send_interrupt_time

    def get_resume_operation_time(self):
        return self.get_timespan(
            SimRegion('hart_0', 'clr interrupt', occurrence=1),
            SimRegion('hart_0', 'clr interrupt', occurrence=1)
        )

    def get_total_time(self):
        return self.get_timespan(
            SimRegion('hart_0', 'prepare data', occurrence=1),
            SimRegion('hart_0', 'clr interrupt', occurrence=1))

    def get_ideal_time(self):
        """Get the total job time w/o offload overheads.
        
        This does not consider the retrieve job operands and writeback
        phases as offload overheads.
        """
        assert self.mcast == True, 'Ideal time only for multicast sims'
        # TODO: add assertions to verify that all start times are the same
        #       across clusters/cores (in the case of multicast sims).
        if self.app == 'montecarlo':
            start_times = [
                self.get_metric(SimRegion(f'hart_{1+9*i+j}', 'compute psum', occurrence=1), 'tstart')
                for i in range(self.nr_clusters) for j in range(8)
            ]
            end_times = self.get_metric(
                SimRegion(f'hart_1', 'inter-cluster reduction', occurrence=1), 'tend')
        else:
            start_times = [
                self.get_metric(SimRegion(f'hart_{1+9*i+8}', 'copy data in', occurrence=1), 'tstart')
                for i in range(self.nr_clusters)
            ]
            if self.app == 'covariance':
                end_times = [self.get_metric(SimRegion('hart_9', 'copy data out', occurrence=1), 'tend')]
            else:
                end_times = [
                    self.get_metric(SimRegion(f'hart_{1+9*i+8}', 'copy data out', occurrence=1), 'tend')
                    for i in range(self.nr_clusters)
                ]
        return np.max(end_times) - np.min(start_times)


def fig8(data):
    apps, sizes = zip(*data.items())

    # Create subplots
    fig, ax = plt.subplots(1, len(apps), layout="constrained")
    fig.set_figwidth(3.8)

    # Make sure ax is a list even when there is only one subplot
    if not hasattr(ax, '__len__'):
        ax = [ax]

    # Fill different subplots with different apps
    for i, app in enumerate(apps):

        # Create different curves for different sizes
        for j, l in enumerate(sizes[i]):

            # Get data
            x_data = ALL_NR_CLUSTER_CFGS
            base_sims = [OffloadSimResults(app, False, l, x) for x in x_data]
            ideal_sims = [OffloadSimResults(app, True, l, x) for x in x_data]
            t_ideal = [sim.get_ideal_time() for sim in ideal_sims]
            t_all = [sim.get_total_time() for sim in base_sims]

            # Plot different curves for ideal runtime and actual runtime 
            p = ax[i].plot(
                x_data,
                t_all,
                marker=MARKERS[j],
                markersize=MARKER_SIZES[j],
                linestyle='-',
                linewidth=1,
                label=f'L={l}'
            )
            ax[i].plot(
                x_data,
                t_ideal,
                marker=MARKERS[j],
                markersize=MARKER_SIZES[j],
                linestyle='--',
                linewidth=1,
                color=p[0].get_color(),
                label=f'L={l}, ideal'
            )
        
        # Set subplot parameters
        ax[i].set_xticks(x_data)
        ax[i].set_xlim([0, 33])
        # ax[i].set_yscale('log')
        ax[i].set_title(get_app_label(app))
        ax[i].legend()
        ax[i].grid(color='gainsboro', which='both', linewidth=0.5)
    
    # Set figure parameters
    fig.supxlabel('Nr. clusters')
    fig.supylabel('Runtime [ns]')
    plt.show()


def fig8v2(sizes):
    apps = sizes.keys()

    # Get data
    data = {}
    for app in apps:
        data[app] = {}
        for nr_clusters in ALL_NR_CLUSTER_CFGS:
            base_sim = OffloadSimResults(app, False, sizes[app], nr_clusters)
            ideal_sim = OffloadSimResults(app, True, sizes[app], nr_clusters)
            data[app][nr_clusters] = base_sim.get_total_time() - ideal_sim.get_ideal_time()
    df = pd.DataFrame(data)
    df.rename(columns=get_app_label, inplace=True)

    # Plotting
    ax = df.plot(kind='bar', figsize=(10, 6), width=0.7)
    ax.set_xlabel('Nr. clusters')
    ax.set_ylabel('Offloading overhead [ns]')
    # ax.set_xticks(x_data)
    # ax.set_xlim([0, 33])
    # ax.set_yscale('log')
    ax.legend()
    ax.set_axisbelow(True)
    ax.grid(color='gainsboro', which='both', linewidth=0.5)
    ax.tick_params(axis='x', labelrotation=0)
    plt.show()


def fig9(sizes):
    apps = sizes.keys()

    # Create subplots
    fig, ax = plt.subplots(1, len(apps), layout="constrained")

    # Make sure ax is a list even when there is only one subplot
    if not hasattr(ax, '__len__'):
        ax = [ax]

    # Fill different subplots with different apps
    for i, app in enumerate(apps):

        # Get data
        x_coords = ALL_NR_CLUSTER_CFGS
        base_sims = [OffloadSimResults(app, False, sizes[app], x) for x in x_coords]
        mcast_sims = [OffloadSimResults(app, True, sizes[app], x) for x in x_coords]
        data = {
            get_mcast_label(False):
                {sim.nr_clusters: sim.get_total_time() for sim in base_sims},
            get_mcast_label(True):
                {sim.nr_clusters: sim.get_total_time() for sim in mcast_sims},
            'Ideal':
                {sim.nr_clusters: sim.get_ideal_time() for sim in mcast_sims},
        }
        df = pd.DataFrame(data)

        # Plot data
        df.plot(ax=ax[i], marker='o', markersize=3)
        # ax[i].set_xticks(x_data)
        # ax[i].set_xlim([0, 33])
        ax[i].set_title(get_app_label(app))
        ax[i].legend()
        ax[i].grid(color='gainsboro', which='both', linewidth=0.5)
    
    # Set figure parameters
    fig.supxlabel('Nr. clusters')
    fig.supylabel('Runtime [ns]')
    plt.show()


def fig10a(sizes):
    apps = sizes.keys()

    # Get data
    data = {}
    ideal = {}
    perc = []
    for nr_clusters in [8, 16, 32]:
        data[nr_clusters] = {}
        ideal[nr_clusters] = {}
        for app in apps:
            base_sim = OffloadSimResults(app, False, sizes[app], nr_clusters)
            mcast_sim = OffloadSimResults(app, True, sizes[app], nr_clusters)
            speedup = base_sim.get_total_time() / mcast_sim.get_total_time()
            ideal_speedup = base_sim.get_total_time() / mcast_sim.get_ideal_time()
            data[nr_clusters][app] = speedup
            ideal[nr_clusters][app] = ideal_speedup
            perc.append(100 * speedup / ideal_speedup)
    df = pd.DataFrame(data)
    df.rename(columns=lambda x: f'{x} clusters', inplace=True)
    df.rename(index=get_app_label, inplace=True)

    # Plot fill bars
    ax = df.plot(kind='bar', linewidth=0.5, edgecolor='black', zorder=3, width=0.8)

    # Plot edge bars
    df = pd.DataFrame(ideal)
    df.rename(index=get_app_label, inplace=True)
    df.plot(ax=ax, kind='bar', width=0.8, linewidth=0.5, edgecolor='black', facecolor='white', zorder=2)

    # Add iso-speedup line
    ax.axhline(y=1, color='black', linestyle='-', linewidth=0.5, zorder=1)

    # Configure plot
    ax.set_ylabel('Speedup')
    ax.set_axisbelow(True)
    ax.grid(color='gainsboro', which='both', linewidth=0.5, zorder=0)
    ax.tick_params(axis='x', labelrotation=0)

    # Show only legend handles for fill bars
    h, l = ax.get_legend_handles_labels()
    ax.legend(h[0:3], l[0:3])

    # Add custom labels on top of each bar
    print(ax.patches)
    for i, p in enumerate(ax.patches[len(apps)*3:]):
        ax.annotate(f'{perc[i]:.0f}%', 
                    (p.get_x() + p.get_width() / 2., p.get_height()), 
                    ha='center', va='center', xytext=(0, 10), 
                    textcoords='offset points')

    # Extend range of y axis to make bar labels visible
    ylim = ax.get_ylim()
    ax.set_ylim(ylim[0], ylim[1] * 1.05)

    plt.show()


def fig10b(data):
    apps, sizes_per_cluster = zip(*data.items())

    # Create subplots
    fig, ax = plt.subplots(len(apps), 1, layout="constrained")

    # Make sure ax is a list even when there is only one subplot
    if not hasattr(ax, '__len__'):
        ax = [ax]

    # Fill different subplots with different apps
    for j, app in enumerate(apps):
    
        all_x = []

        # Create different curves for different nr clusters
        for i, nr_clusters in enumerate(ALL_NR_CLUSTER_CFGS[2:]):

            # Get full problem size, from the size per cluster
            x_data = [
                size_per_cluster * nr_clusters
                for size_per_cluster in sizes_per_cluster[j]
            ]

            # Get data
            sims = [
                [OffloadSimResults(app, mcast, x, nr_clusters) for x in x_data]
                for mcast in ALL_MCAST_CFGS
            ]
            t_baseline = [sim.get_total_time() for sim in sims[0]]
            t_mcast = [sim.get_total_time() for sim in sims[1]]
            speedup = [a / b for a, b in zip(t_baseline, t_mcast)]

            # Plot speedup
            ax[j].plot(
                x_data,
                speedup,
                marker=MARKERS[i],
                markersize=MARKER_SIZES[i],
                linestyle='-',
                linewidth=1,
                label=f'{nr_clusters} clusters'
            )

            # Get all x values as combination of x values found in all curves
            all_x += x_data

        # Set subplot parameters
        all_x = list(set(all_x))
        ax[j].set_xticks(all_x, [str(x) for x in all_x], rotation=-45)
        ax[j].set_ylim([1, ax[j].get_ylim()[1]])
        ax[j].legend()
        ax[j].set_title(get_app_label(app))
        ax[j].grid(color='gainsboro', linewidth=0.5)

    # Set figure parameters
    fig.supxlabel('Problem size')
    fig.supylabel('Speedup')
    plt.show()


def simple_phase_plot(ax, data, title):
    x = ALL_NR_CLUSTER_CFGS
    ax.plot(x, data[0], marker='.', linestyle='-', label='baseline')
    ax.plot(x, data[1], marker='.', linestyle='-', label='w/ extensions')
    # # Annotate points
    # for point in zip(x, data[0]):
    #     plt.annotate(f'{point[1]:.2f}', point, xytext=(0, 3), textcoords='offset points',
    #         ha='center', va='bottom')
    # for point in zip(x, data[1]):
    #     plt.annotate(f'{point[1]:.2f}', point, xytext=(0, 3), textcoords='offset points',
    #         ha='center', va='bottom')
    ax.set_xticks(x)
    ax.set_title(title)
    ax.grid(color='gainsboro', which='both', linewidth=0.5)
    ax.legend()


def statistic_phase_plot(ax, data, title):
    data = np.array(data)
    data = data.swapaxes(1, 2)
    x = ALL_NR_CLUSTER_CFGS
    ax.grid(color='gainsboro', which='both', linewidth=0.5)
    ax.plot(x, data[0][2], marker='.', linestyle='-', label='baseline')
    ax.plot(x, data[1][2], marker='.', linestyle='-', label='w/ extensions')
    ax.fill_between(x, data[0][0], data[0][1], alpha=0.3)
    ax.fill_between(x, data[1][0], data[1][1], alpha=0.3)
    # # Annotate points
    # for point in zip(x, data[0][0]):
    #     ax.annotate(f'{point[1]:.2f}', point, xytext=(0, 3), textcoords='offset points',
    #         ha='center', va='bottom')
    # for point in zip(x, data[1][0]):
    #     ax.annotate(f'{point[1]:.2f}', point, xytext=(0, 3), textcoords='offset points',
    #         ha='center', va='bottom')
    ax.set_xticks(x)
    ax.set_title(title)
    ax.legend()


def recursive_map(func, data):
    """Apply a function to a nested list.
    
    Similar to the built-in map() function, but preserves the
    structure of the nested list.
    """
    # Check if the data is a list
    if isinstance(data, list):
        return [recursive_map(func, item) for item in data]
    else:
        return func(data)


def fig11(data):
    app, size = next(iter(data.items()))

    # Only AXPY supported atm
    assert app == 'axpy', 'Only AXPY supported'

    # Get simulation results
    sims = [
        [OffloadSimResults(app, mcast, size, nr_clusters) for nr_clusters in ALL_NR_CLUSTER_CFGS]
        for mcast in ALL_MCAST_CFGS
    ]

    # Get data
    t_send_job_information   = recursive_map(OffloadSimResults.get_send_job_information_time, sims)
    t_wakeup                 = recursive_map(OffloadSimResults.get_wakeup_time, sims)
    t_retrieve_job_pointer   = recursive_map(OffloadSimResults.get_retrieve_job_pointer_time, sims)
    t_retrieve_job_arguments = recursive_map(OffloadSimResults.get_retrieve_job_arguments_time, sims)
    t_retrieve_job_operands  = recursive_map(OffloadSimResults.get_retrieve_job_operands_time, sims)
    t_job_execution          = recursive_map(OffloadSimResults.get_job_execution_time, sims)
    t_writeback_job_outputs  = recursive_map(OffloadSimResults.get_writeback_job_outputs_time, sims)
    t_notify_job_completion  = recursive_map(OffloadSimResults.get_notify_job_completion_time, sims)
    t_resume_operation       = recursive_map(OffloadSimResults.get_resume_operation_time, sims)
    t_total                  = recursive_map(OffloadSimResults.get_total_time, sims)

    # print("A", t_send_job_information[1])
    # print("B", t_wakeup[1])
    # print("C", t_retrieve_job_pointer[1])
    # print("D", t_retrieve_job_arguments[1])
    # print("E", t_retrieve_job_operands[1])
    # print("F", t_job_execution[1])
    # print("G", t_writeback_job_outputs[1])
    # print("H", t_notify_job_completion[1])
    # print("I", t_resume_operation[1])

    fig, ax = plt.subplots(4, 3, layout="constrained")
    fig.set_figwidth(8.3)
    simple_phase_plot(ax[0][0], t_send_job_information, "A) Send job information")
    statistic_phase_plot(ax[0][1], t_wakeup, "B) Cluster wakeup")
    statistic_phase_plot(ax[0][2], t_retrieve_job_pointer, "C) Retrieve job pointer")
    statistic_phase_plot(ax[1][0], t_retrieve_job_arguments, "D) Retrieve job arguments")
    statistic_phase_plot(ax[1][1], t_retrieve_job_operands, "E) Retrieve job operands")
    statistic_phase_plot(ax[1][2], t_job_execution, "F) Job execution")
    statistic_phase_plot(ax[2][0], t_writeback_job_outputs, "G) Writeback job outputs")
    simple_phase_plot(ax[2][1], t_notify_job_completion, "H) Notify job completion")
    simple_phase_plot(ax[2][2], t_resume_operation, "I) Resume operation on host")
    simple_phase_plot(ax[3][0], t_total, "Total")

    fig.supxlabel('Nr. clusters')
    fig.supylabel('Runtime [ns]')
    plt.show()


def main():

    # Parse arguments
    args = parse_args()
    plot = args.plot

    # Plot
    if plot == 'fig8':
        data = {
            'axpy': [512, 1024],
            'montecarlo': [512],
            # 'atax': [1, 2],
            'covariance': [1],
            'gemm': [1],
            # 'kmeans': [256],
        }
        fig8(data)
    elif plot == 'fig8v2':
        sizes = {
            'axpy': 1024,
            'montecarlo': 512,
            # 'atax': 1,
            'covariance': 1,
            'gemm': 1
        }
        fig8v2(sizes)
    elif plot == 'fig9':
        sizes = {
            'axpy': 1024,
            'montecarlo': 512,
            # 'atax': 1,
            'covariance': 1,
            'gemm': 1
        }
        fig9(sizes)
    elif plot == 'fig10a':
        sizes = {
            'axpy': 1024,
            'montecarlo': 512,
            # 'atax': 1,
            'covariance': 1,
            'gemm': 1
        }
        fig10a(sizes)
    elif plot == 'fig10b':
        data = {
            'axpy': [32, 64, 128],
            'montecarlo': [32, 64, 128],
            # 'gemm': [32, 64, 128],
        }
        fig10b(data)
    elif plot == 'fig11':
        data = {'axpy': 1024}
        fig11(data)


if __name__ == '__main__':
    main()
