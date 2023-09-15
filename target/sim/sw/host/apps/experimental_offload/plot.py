#!/usr/bin/env python3

import argparse
import pandas as pd
import numpy as np
np.set_printoptions(formatter={'float': lambda x: "{0:0.3f}".format(x)})
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
plt.rcParams['font.size'] = 8
# plt.rcParams['font.family'] = 'Times New Roman'
# plt.rcParams['font.style'] = 'normal'
# LBR paper changes
# plt.rcParams['figure.figsize'] = [3, 2.5]
# plt.rcParams.update({'figure.autolayout': True})

MCAST = 0
NO_MCAST = 1
CONFIGS = [True, False]
N_CLUSTERS = [1, 2, 4, 8, 16, 32]
L = 256
POLLACK_FACTOR = 1.67

MARKERS = ['o', '^', 's', '*', 'd', 'X']
MARKER_SIZES = [6, 7, 6, 8, 6, 6]

LOGS_PREFIX = 'runs'

def parse_args():
    parser = argparse.ArgumentParser(description="Your program description here")
    parser.add_argument("app", type=str)
    parser.add_argument("--plot", default="phase_runtimes", type=str)
    return parser.parse_args()

def get_events(app='axpy', mcast=0, size=L, nr_clusters=1):
    logs = f'{LOGS_PREFIX}/{app}/L{size}'
    if mcast:
        logs = f'{logs}/M'
    else:
        logs = f'{logs}/U'
    logs = f'{logs}/N{nr_clusters}'

    file = f'{logs}/logs/event.csv'
    return pd.read_csv(file, index_col=0)

def get_send_job_information_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    return df.loc[0, '6_tend'] - df.loc[0, '6_tstart']

def get_send_interrupt_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    return df.loc[0, '7_tend']- df.loc[0, '7_tstart']

def get_wakeup_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    if app == 'axpy':
        vals = [df.loc[9*(i+1), '10_tend']- df.loc[0, '7_tstart'] for i in range(nr_clusters)]
    elif app == 'mc':
        vals = [df.loc[9*(i+1), '8_tend']- df.loc[0, '7_tstart'] for i in range(nr_clusters)]
    return np.min(vals), np.max(vals), np.average(vals)

def get_interrupt_clear_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    if app == 'axpy':
        vals = [df.loc[9*(i+1), '10_tend']- df.loc[9*(i+1), '10_tstart'] for i in range(nr_clusters)]
    elif app == 'mc':
        vals = [df.loc[9*(i+1), '8_tend']- df.loc[9*(i+1), '8_tstart'] for i in range(nr_clusters)]
    return np.min(vals), np.max(vals), np.average(vals)

def get_retrieve_job_pointer_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    if app == 'axpy':
        vals = [df.loc[9*(i+1), '11_tend'] - df.loc[9*(i+1), '11_tstart'] for i in range(nr_clusters)]
    elif app == 'mc':
        vals = [df.loc[9*(i+1), '9_tend'] - df.loc[9*(i+1), '9_tstart'] for i in range(nr_clusters)]
    
    return np.min(vals), np.max(vals), np.average(vals)

def get_retrieve_job_arguments_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    if app == 'axpy':
        vals = [df.loc[9*(i+1), '12_tend'] - df.loc[9*(i+1), '12_tstart'] for i in range(nr_clusters)]
    elif app == 'mc':
        vals = [df.loc[9*(i+1), '10_tend'] - df.loc[9*(i+1), '10_tstart'] for i in range(nr_clusters)]
    
    return np.min(vals), np.max(vals), np.average(vals)

def get_retrieve_job_operands_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    if app == 'axpy':
        vals = [df.loc[9*(i+1), '13_tend'] - df.loc[9*(i+1), '13_tstart'] for i in range(nr_clusters)]
    elif app == 'mc':
        vals = [df.loc[9*(i+1), '12_tend'] - df.loc[9*(i+1), '11_tstart'] for i in range(nr_clusters)]
    
    return np.min(vals), np.max(vals), np.average(vals)

def get_job_execution_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    if app == 'axpy':
        # Max in cluster
        vals = [np.max(df.loc[1+9*i:1+9*i+7, '14_tend']) - np.min(df.loc[1+9*i:1+9*i+7, '13_tstart']) for i in range(nr_clusters)]
        return np.min(vals), np.max(vals), np.average(vals)
    elif app == 'mc':
        vals = []
        for i in range(nr_clusters):
            if i == 0:
                core0_end = df.loc[1+9*i, '17_tend']
                core0_start = df.loc[1+9*i, '16_tstart']
            else:
                core0_end = df.loc[1+9*i, '16_tend']
                core0_start = df.loc[1+9*i, '15_tstart']

            cluster_end = max(core0_end, np.max(df.loc[1+9*i+1:1+9*i+8, '15_tend']))
            cluster_start = min(core0_start, np.min(df.loc[1+9*i+1:1+9*i+8, '14_tstart']))

            cluster_time = cluster_end - cluster_start
            vals.append(cluster_time)
        return np.min(vals), np.max(vals), np.average(vals)

def get_intra_cluster_reduce_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    if app == 'mc':
        vals  = [df.loc[1, '18_tend'] - df.loc[1, '18_tstart']]
        vals += [df.loc[1+i*9, '17_tend'] - df.loc[1+i*9, '17_tstart'] for i in range(1, nr_clusters)]
        return np.min(vals), np.max(vals), np.average(vals)

def get_psum_exchange_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    if app == 'mc':
        if nr_clusters == 1:
            vals = [0]
        else:
            vals = [df.loc[1+i*9, '18_tend'] - df.loc[1+i*9, '18_tstart'] for i in range(1, nr_clusters)]
        return np.min(vals), np.max(vals), np.average(vals)

def get_inter_cluster_reduce_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    if app == 'mc':
        val = df.loc[1, '20_tend'] - df.loc[1, '20_tstart']
        return val

def get_writeback_job_outputs_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    if app == 'axpy':
        start_times = [df.loc[9*(i+1), '16_tstart'] for i in range(nr_clusters)]
        end_times = [df.loc[9*(i+1), '16_tend'] for i in range(nr_clusters)]
        # max_end_time = np.amax(end_times)
        # last_cluster_to_start = np.argmax(start_times)
        # last_cluster_to_end = np.argwhere(end_times == max_end_time)
        # print('Last cluster to start DMA copy out:', last_cluster_to_start)
        # print('Last cluster to end DMA copy out:', last_cluster_to_end)
        vals = [end_times[i] - start_times[i] for i in range(len(start_times))]
        return np.min(vals), np.max(vals), np.average(vals)

def get_job_completion_notification_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    if app == 'axpy':
        # from last core arriving on the barrier to CVA6 waking up
        return df.loc[0, '9_tstart'] - np.max([df.loc[9*(i+1), '17_tstart'] for i in range(nr_clusters)])
    elif app == 'mc':
        # from core 0 of cluster 0 completing the reduction to CVA6 waking up
        return df.loc[0, '9_tstart'] - df.loc[1, '21_tstart']

def get_resume_operation_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    return df.loc[0, '9_tend'] - df.loc[0, '9_tstart']

def get_total_time(app, mcast=0, size=L, nr_clusters=1):
    df = get_events(app=app, mcast=mcast, size=size, nr_clusters=nr_clusters)

    # All
    val = df.loc[0, '9_tend'] - df.loc[0, '6_tstart']
    return val

def baseline_speedup(app, sizes):
    x = N_CLUSTERS
    # iso_speedup = [1 for i in range(len(N_CLUSTERS))]

    for i, l in enumerate(sizes):
        t_compute = [get_job_execution_time(app, mcast=0, size=l, nr_clusters=nr_clusters)[1] for nr_clusters in N_CLUSTERS]
        t_all = [get_total_time(app, mcast=0, size=l, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS]

        host_runtime = model_job_execution_host(app, l)

        speedup = [host_runtime / device_runtime for device_runtime in t_all]
        ideal_speedup = [host_runtime / ideal_device_runtime for ideal_device_runtime in t_compute]

        p = plt.plot(x, speedup, marker=MARKERS[i], markersize=MARKER_SIZES[i], linestyle='-', label=f'L={l}')
        plt.plot(x, ideal_speedup, marker=MARKERS[i], markersize=MARKER_SIZES[i], linestyle='--', color=p[0].get_color(), label=f'L={l}, ideal')

    # Plot iso-speedup line
    # plt.plot((0, 33), (1, 1), linestyle=(0, (5, 5)), linewidth=0.5, color='black')
    
    plt.xticks(x)
    # plt.yticks(list(plt.yticks()[0][1:-1]) + [1]) # Add tick for iso speedup
    plt.xlim([0, 33])
    # plt.ylim([0, plt.ylim()[1]])
    plt.yscale('log')
    plt.xlabel('Nr. clusters')
    plt.ylabel('Speedup')
    plt.legend()
    plt.grid(color='gainsboro', which='both')
    plt.show()

def runtime_comparison(app, size):
    x = N_CLUSTERS

    for i, mcast in enumerate(CONFIGS):
        label = 'w/ extensions' if mcast else 'baseline'
        y = [get_total_time(app, mcast=mcast, size=size, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS]
        plt.plot(x, y, marker=MARKERS[i], markersize=MARKER_SIZES[i], linestyle='-', label=label)

    plt.xticks(x)
    plt.xlim([0, 33])
    plt.xlabel('Nr. clusters')
    plt.ylabel('Runtime [ns]')
    plt.legend()
    plt.grid(color='gainsboro', which='both')
    plt.show()

def plot_runtime_vs_nr_clusters(data):
    x = N_CLUSTERS
    y = data
    plt.plot(x, y, marker='.', linestyle='-', color='black')
    # Annotate points
    for point in zip(x, y):
        plt.annotate(f'{point[1]:.2f}', point, xytext=(0, 3), textcoords='offset points',
            ha='center', va='bottom')
    plt.xticks(x)
    plt.xlabel('Nr. clusters')
    plt.ylabel('Runtime [ns]')
    plt.show()


def weak_scaling(app):
    x = N_CLUSTERS
    t_mcast = [get_total_time(app, mcast=1, size=1024, nr_clusters=nr_clusters) for nr_clusters in x]
    t_baseline = [get_total_time(app, mcast=0, size=1024, nr_clusters=nr_clusters) for nr_clusters in x]

    fig, ax1 = plt.subplots()

    ax1.plot(x, t_mcast, marker=MARKERS[0], markersize=MARKER_SIZES[0], label='Multicast', linestyle='-')
    ax1.plot(x, t_baseline, marker=MARKERS[1], markersize=MARKER_SIZES[1], label='Baseline', linestyle='-')

    ax1.set_xticks(x)
    ax1.set_xlabel('Nr. clusters')
    ax1.set_ylabel('Runtime [ns]')
    plt.legend(loc='upper left')

    y2 = [t_baseline[i] / t_mcast[i] for i in range(len(x))]

    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis

    ax2.set_ylabel('Speedup')  # we already handled the x-label with ax1
    ax2.plot(x, y2, label='Speedup', linestyle=(0, (5, 5)), linewidth=0.5, color='black')
    ax2.tick_params(axis='y')
    ax2.set_yticks(list(ax2.get_yticks()[1:-1]) + [1]) # Add tick for iso speedup

    fig.tight_layout()  # otherwise the right y-label is slightly clipped
    plt.legend(loc='upper right')

    plt.show()

def strong_scaling(app):
    x = N_CLUSTERS
    size_per_cluster = 32
    t_mcast = [get_total_time(app, mcast=1, size=size_per_cluster*nr_clusters, nr_clusters=nr_clusters) for nr_clusters in x]
    t_baseline = [get_total_time(app, mcast=0, size=size_per_cluster*nr_clusters, nr_clusters=nr_clusters) for nr_clusters in x]

    fig, ax1 = plt.subplots()

    ax1.plot(x, t_mcast, marker=MARKERS[0], markersize=MARKER_SIZES[0], label='Multicast', linestyle='-')
    ax1.plot(x, t_baseline, marker=MARKERS[1], markersize=MARKER_SIZES[1], label='Baseline', linestyle='-')

    ax1.set_xticks(x)
    ax1.set_xlabel('Nr. clusters')
    ax1.set_ylabel('Runtime [ns]')
    plt.legend(loc='upper left')

    y2 = [t_baseline[i] / t_mcast[i] for i in range(len(x))]

    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis

    ax2.set_ylabel('Speedup')  # we already handled the x-label with ax1
    ax2.plot(x, y2, label='Speedup', linestyle=(0, (5, 5)), linewidth=0.5, color='black')
    ax2.tick_params(axis='y')
    ax2.set_yticks(list(ax2.get_yticks()[1:-1]) + [1]) # Add tick for iso speedup

    fig.tight_layout()  # otherwise the right y-label is slightly clipped
    plt.legend(loc='upper right')

    plt.show()


def mcast_speedup(app):
    sizes_per_cluster = [32, 64, 128]#, 256]
    all_x = []
    for i, nr_clusters in enumerate([4, 8, 16, 32]):
        sizes = [size_per_cluster * nr_clusters for size_per_cluster in sizes_per_cluster]
        x = sizes
        t_mcast = [get_total_time(app, mcast=1, size=size, nr_clusters=nr_clusters) for size in sizes]
        t_baseline = [get_total_time(app, mcast=0, size=size, nr_clusters=nr_clusters) for size in sizes]

        speedup = [t_baseline[i] / t_mcast[i] for i in range(len(sizes))]

        plt.plot(x, speedup, marker=MARKERS[i], markersize=MARKER_SIZES[i], linestyle='-', label=f'{nr_clusters} clusters')
        all_x += x

    plt.xticks(list(set(all_x)), rotation=-45)
    # plt.xlim([0, 33])
    plt.ylim([1, plt.ylim()[1]])
    plt.xlabel('Problem size')
    plt.ylabel('Speedup')
    plt.legend()
    plt.grid(color='gainsboro')
    plt.show()

def simple_phase_plot(ax, data, title):
    x = N_CLUSTERS
    ax.plot(x, data[0], marker='.', linestyle='-', label='Baseline')
    ax.plot(x, data[1], marker='.', linestyle='-', label='Multicast')
    # # Annotate points
    # for point in zip(x, data[0]):
    #     plt.annotate(f'{point[1]:.2f}', point, xytext=(0, 3), textcoords='offset points',
    #         ha='center', va='bottom')
    # for point in zip(x, data[1]):
    #     plt.annotate(f'{point[1]:.2f}', point, xytext=(0, 3), textcoords='offset points',
    #         ha='center', va='bottom')
    ax.set_xticks(x)
    ax.set_xlabel('Nr. clusters')
    ax.set_ylabel('Runtime [ns]')
    ax.set_title(title)
    ax.legend()

def statistic_phase_plot(ax, data, title):
    data = np.array(data)
    data = data.swapaxes(1, 2)
    x = N_CLUSTERS
    ax.plot(x, data[0][2], marker='.', linestyle='-', label='Baseline')
    ax.plot(x, data[1][2], marker='.', linestyle='-', label='Multicast')
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
    ax.set_xlabel('Nr. clusters')
    ax.set_ylabel('Runtime [ns]')
    ax.set_title(title)
    # ax.legend()

def breakdown(app):
    if app == 'axpy':
        t_send_job_information   = [[get_send_job_information_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_wakeup                 = [[get_wakeup_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_retrieve_job_pointer   = [[get_retrieve_job_pointer_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_retrieve_job_arguments = [[get_retrieve_job_arguments_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_retrieve_job_operands  = [[get_retrieve_job_operands_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_job_execution          = [[get_job_execution_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_writeback_job_outputs  = [[get_writeback_job_outputs_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_notify_job_completion  = [[get_job_completion_notification_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_resume_operation       = [[get_resume_operation_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_total                  = [[get_total_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]

        print("A", t_send_job_information[1])
        print("B", t_wakeup[1])
        print("C", t_retrieve_job_pointer[1])
        print("D", t_retrieve_job_arguments[1])
        print("E", t_retrieve_job_operands[1])
        print("F", t_job_execution[1])
        print("G", t_writeback_job_outputs[1])
        print("H", t_notify_job_completion[1])
        print("I", t_resume_operation[1])

        fig, ax = plt.subplots(3, 3, layout="constrained")
        fig.set_figheight(6)
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

    elif app == 'mc':
        t_send_job_information   = [[get_send_job_information_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_wakeup                 = [[get_wakeup_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_retrieve_job_pointer   = [[get_retrieve_job_pointer_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_retrieve_job_arguments = [[get_retrieve_job_arguments_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_retrieve_job_operands  = [[get_retrieve_job_operands_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_job_execution          = [[get_job_execution_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_intra_cluster_reduce   = [[get_intra_cluster_reduce_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_psum_exchange          = [[get_psum_exchange_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_inter_cluster_reduce   = [[get_inter_cluster_reduce_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_notify_job_completion  = [[get_job_completion_notification_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_resume_operation       = [[get_resume_operation_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]
        t_total                  = [[get_total_time(app, mcast=mcast, size=L, nr_clusters=nr_clusters) for nr_clusters in N_CLUSTERS] for mcast in [0, 1]]

        print("A", t_send_job_information[1])
        print("B", t_wakeup[1])
        print("C", t_retrieve_job_pointer[1])
        print("D", t_retrieve_job_arguments[1])
        print("E", t_retrieve_job_operands[1])
        print("F", t_job_execution[1])
        print("G", t_intra_cluster_reduce[1])
        print("H", t_psum_exchange[1])
        print("I", t_inter_cluster_reduce[1])
        print("J", t_notify_job_completion[1])
        print("K", t_resume_operation[1])

        fig, ax = plt.subplots(6, 2, layout="constrained")
        fig.set_figheight(11.7)
        fig.set_figwidth(8.3)
        simple_phase_plot(ax[0][0], t_send_job_information, "A) Send job information")
        statistic_phase_plot(ax[0][1], t_wakeup, "B) Cluster wakeup")
        statistic_phase_plot(ax[1][0], t_retrieve_job_pointer, "C) Retrieve job pointer")
        statistic_phase_plot(ax[1][1], t_retrieve_job_arguments, "D) Retrieve job arguments")
        statistic_phase_plot(ax[2][0], t_retrieve_job_operands, "E) Retrieve job operands")
        statistic_phase_plot(ax[2][1], t_job_execution, "F) Job execution")
        statistic_phase_plot(ax[3][0], t_intra_cluster_reduce, "G) Intra-cluster reduce")
        statistic_phase_plot(ax[3][1], t_psum_exchange, "H) Partial sum exchange")
        simple_phase_plot(ax[4][0], t_inter_cluster_reduce, "I) Inter-cluster reduce")
        simple_phase_plot(ax[4][1], t_notify_job_completion, "J) Notify job completion")
        simple_phase_plot(ax[5][0], t_resume_operation, "K) Resume operation on host")
        simple_phase_plot(ax[5][1], t_total, "Total")


    pdf = PdfPages('breakdown.pdf')
    pdf.savefig(fig, bbox_inches='tight')#, pad_inches=1)

    pdf.close()

def model_retrieve_job_operands(l):
    return 90 + l/4

def model_job_execution_host(app, l):
    if app == 'axpy':
        return (48 + (1.6*l)) / POLLACK_FACTOR
    elif app == 'mc':
        return (61 + (34*l)) / POLLACK_FACTOR

def model_job_execution(app, n, l):
    if app == 'axpy':
        return 48 + (1.6*l)/(n*8)
    elif app == 'mc':
        return 61 + (34*l)/(n*8)

def model_psum_exchange(n):
    if n == 1:
        return 0
    elif n > 1 and n <= 4:
        return (48 - 3) + (n - 1) * 3 + 18
    elif n > 4:
        return (115 - 3) + (n - 5) * 3 + 33

def model_inter_cluster_reduce(n):
    if n == 1:
        return 7
    else:
        return 7 + n * 4.5

def model_writeback_job_outputs(n, l):
    return 70 + l/(n*8)

def model_total(app, n, l):
    if app == 'axpy':
        return 29 + 59 + 23 + 1 + model_retrieve_job_operands(l) + \
        model_job_execution(app, n, l) + model_writeback_job_outputs(n, l) + 44 + 3
    elif app == 'mc':
        return 18 + 48 + 48 + 1 + 11 + \
        model_job_execution(app, n, l) + 31 + model_psum_exchange(n) + model_inter_cluster_reduce(n) + 40 + 3 

def mape(app, n, l):

    true = np.array([get_total_time(app, mcast=1, size=l, nr_clusters=nr_clusters) for nr_clusters in n])
    pred = np.array([model_total(app, nr_clusters, l) for nr_clusters in n])
    error = "Relative error: " + " ".join([f"{err:0.1f}%" for err in 100*np.abs((true - pred) / true)])

    # # For debug only
    # print(f"=== {l} ===")
    # print(f"True: {true}")
    # print(f"Pred: {pred}")
    # print(error)
    # true_E = np.array([get_psum_exchange_time(app, mcast=1, size=l, nr_clusters=nr_clusters)[1] for nr_clusters in n])
    # true_F = np.array([get_job_execution_time(app, mcast=1, size=l, nr_clusters=nr_clusters)[1] for nr_clusters in n])
    # true_G = np.array([get_inter_cluster_reduce_time(app, mcast=1, size=l, nr_clusters=nr_clusters) for nr_clusters in n])
    # pred_E = np.array([model_psum_exchange(nr_clusters) for nr_clusters in n])
    # pred_F = np.array([model_job_execution(app, nr_clusters, l) for nr_clusters in n])
    # pred_G = np.array([model_inter_cluster_reduce(nr_clusters) for nr_clusters in n])
    # error_E = "Relative error E: " + " ".join([f"{err:0.1f}%" for err in 100*np.abs((true_E - pred_E) / true_E)])
    # error_F = "Relative error F: " + " ".join([f"{err:0.1f}%" for err in 100*np.abs((true_F - pred_F) / true_F)])
    # error_G = "Relative error G: " + " ".join([f"{err:0.1f}%" for err in 100*np.abs((true_G - pred_G) / true_G)])
    # print(f"True E: {true_E}")
    # print(f"Pred E: {pred_E}")
    # print(error_E)
    # print(f"True F: {true_F}")
    # print(f"Pred F: {pred_F}")
    # print(error_F)
    # print(f"True G: {true_G}")
    # print(f"Pred G: {pred_G}")
    # print(error_G)

    mape = 100 * np.mean(np.abs((true - pred) / true))
    print(f"MAPE: {mape:0.1f}%")


def main():
    args = parse_args()
    app = args.app
    plot = args.plot
    print(f"App: {app}")
    print(f"Plot: {plot}")

    if plot == 'baseline_speedup':
        baseline_speedup('axpy', [1024, 2048])
        baseline_speedup('mc', [256, 512])
    elif plot == 'runtime_comparison':
        runtime_comparison('axpy', size=1024)
        runtime_comparison('mc', size=256)
    elif plot == 'weak_scaling':
        weak_scaling(app)
    elif plot == 'strong_scaling':
        strong_scaling(app)
    elif plot == 'mcast_speedup':
        mcast_speedup(app)
    elif plot == 'breakdown':
        breakdown(app)
    elif plot == 'mape':
        mape(app, [1, 2, 4, 8], 256)
        mape(app, [1, 2, 4, 8, 16], 512)
        mape(app, [1, 2, 4, 8, 16, 32], 768)
        mape(app, [1, 2, 4, 8, 16, 32], 1024)


if __name__ == '__main__':
    main()
