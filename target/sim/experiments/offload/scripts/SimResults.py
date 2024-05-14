# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

import functools
from pathlib import Path
import json


class SimRegion():
    """A region in the simulation results.
    
    A region is identified by a thread and a label. In case of multiple
    regions with the same label (as e.g. in a loop) you need to provide an
    additional index.
    """
    def __init__(self, thread, label, occurrence=0):
        self.thread = thread
        self.label = label
        self.occurrence = occurrence


class SimResults():

    def __init__(self, sim_dir):
        """Initializes a simulation results object from the run directory.
        """
        self.sim_dir = Path(sim_dir)
        self.roi_json = Path(self.sim_dir) / 'logs' / 'roi.json'

    @functools.cached_property
    def performance_data(self):
        """Returns all performance data logged during simulation."""
        with open(self.roi_json, 'r') as f:
            return json.load(f)

    def get_metric(self, region, metric):
        """Get a performance metric from a simulation region.

        Args:
            region: The region to extract the metric from. Should be an
                instance of the `SimRegion` class.
            metric: The name of the metric to extract.
        """
        # Get region index
        cnt = 0
        reg_idx = None
        for i, reg in enumerate(self.performance_data[region.thread]):
            if reg['label'] == region.label:
                if cnt == region.occurrence:
                    reg_idx = i
                    break
                else:
                    cnt += 1
        if reg_idx is None:
            raise ValueError(f"Region {region.label} (occurrence {region.occurrence}) not found "
                             f"in thread {region.thread}.")
        # Get metric
        if metric in ['tstart', 'tend']:
            return self.performance_data[region.thread][reg_idx][metric]
        else:
            return self.performance_data[region.thread][reg_idx]['attrs'][metric]

    def get_metrics(self, regions, metric):
        """Get a performance metric from multiple simulation regions.

        Args:
            regions: A list of regions to extract the metric from. Should
                be a list of `SimRegion` instances.
            metric: The name of the metric to extract.

        Returns:
            A list of metrics corresponding to each region in the input list.
        """
        metrics = []
        for region in regions:
            metrics.append(self.get_metric(region, metric))
        return metrics

    def get_timespan(self, start_region, end_region):
        """Get the timespan between two regions.

        Args:
            start_region: The region to start from.
            end_region: The region to end at.
        """
        start_time = self.get_metric(start_region, 'tstart')
        end_time = self.get_metric(end_region, 'tend')
        return end_time - start_time        
