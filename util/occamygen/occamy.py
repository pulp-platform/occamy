# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

import sys
from pathlib import Path
import hjson
from jsonref import JsonRef
sys.path.append(str(Path(__file__).parent / '../../deps/snitch_cluster/util/clustergen'))
from cluster import Generator, PMA, PMACfg, SnitchCluster, clog2  # noqa: E402

def read_json_file(file):
    try:
        srcfull = file.read()
        obj = hjson.loads(srcfull, use_decimal=True)
        obj = JsonRef.replace_refs(obj)
    except ValueError:
        raise SystemExit(sys.exc_info()[1])
    return obj

def generate_pma_cfg(occamy_cfg):
    pma_cfg = PMACfg()
    addr_width = occamy_cfg["addr_width"]
    # Make Wide SPM cacheable
    pma_cfg.add_region_length(PMA.CACHED,
                                occamy_cfg["spm_wide"]["address"],
                                occamy_cfg["spm_wide"]["length"],
                                addr_width)
    # Make the SPM cacheable
    pma_cfg.add_region_length(PMA.CACHED,
                                occamy_cfg["spm_narrow"]["address"],
                                occamy_cfg["spm_narrow"]["length"],
                                addr_width)
    # Make the boot ROM cacheable
    pma_cfg.add_region_length(PMA.CACHED,
                                occamy_cfg["peripherals"]["rom"]["address"],
                                occamy_cfg["peripherals"]["rom"]["length"],
                                addr_width)
    return pma_cfg  

def check_occamy_cfg(occamy_cfg):
    occamy_root = (Path(__file__).parent / "../../").resolve()
    snitch_root = (Path(__file__).parent / "../../deps/snitch_cluster").resolve()
    schema = occamy_root / "docs/schema/occamy.schema.json"
    remote_schemas = [occamy_root / "docs/schema/axi_xbar.schema.json",
                        occamy_root / "docs/schema/axi_tlb.schema.json",
                        occamy_root / "docs/schema/address_range.schema.json",
                        occamy_root / "docs/schema/peripherals.schema.json",
                        snitch_root / "docs/schema/snitch_cluster.schema.json"]
    generator_obj = Generator(schema,remote_schemas)
    generator_obj.validate(occamy_cfg)


def get_cluster_generators(occamy_cfg, cluster_cfg_dir):
    cluster_generators = list()
    pma_cfg = generate_pma_cfg(occamy_cfg)
    cluster_name_list = occamy_cfg["clusters"]
    for cluster_name in cluster_name_list:
        cluster_cfg_path = cluster_cfg_dir / f"{cluster_name}.hjson"
        with open(cluster_cfg_path,'r') as file:
            cluster_cfg = read_json_file(file)
        # Now cluster_cfg has three field
        # cluster, dram, clint
        # We only need the cluster
        cluster_cfg = cluster_cfg["cluster"]
        # Add some field
        cluster_processing(cluster_cfg, occamy_cfg)
        cluster_obj = SnitchCluster(cluster_cfg ,pma_cfg)
        cluster_add_mem(cluster_obj, occamy_cfg)
        cluster_generators.append(cluster_obj)
    return cluster_generators


def generate_wrappers(cluster_generators,out_dir):
    for cluster_generator in cluster_generators:
        cluster_name = cluster_generator.cfg["name"]
        with open(out_dir / f"{cluster_name}_wrapper.sv", "w") as f:
            f.write(cluster_generator.render_wrapper())

def generate_memories(cluster_generators,out_dir):
    for cluster_generator in cluster_generators:
        cluster_name = cluster_generator.cfg["name"]
        with open(out_dir / f"{cluster_name}_memories.json", "w") as f:
            f.write(cluster_generator.memory_cfg())


def cluster_processing(cluster_cfg, occamy_cfg):
    # in snith_cluster_wrapper.sv.tpl
    #% if not cfg['tie_ports']:
    #   //-----------------------------
    #   // Cluster base addressing
    #   //-----------------------------
    #   input  logic [9:0]                             hart_base_id_i,
    #   input  logic [${cfg['addr_width']-1}:0]        cluster_base_addr_i,
    # % endif
    # This is to make sure the hartid is exposed to wrapper
    cluster_cfg["tie_ports"] = False

    # Overwrite boot address with base of bootrom
    cluster_cfg["boot_addr"] = occamy_cfg["peripherals"]["rom"]["address"]

    cluster_cfg["cluster_base_expose"] = True
    # Set the cluster base addr as 0x1000_0000
    cluster_cfg["cluster_base_addr"] = 268435456
    # Set the cluster base offset as 0x0004_000
    cluster_cfg["cluster_base_offset"] = 262144
    # Set the cluster base id as 1
    cluster_cfg["cluster_base_hartid"] = 1
    # Set the enable_debug to false, since we do not need snitch debugging in occamy
    cluster_cfg["enable_debug"] = False
    # Set the vm_support to false, since do not need snitch (core-internal) virtual memory support
    cluster_cfg["vm_support"] = False



def cluster_add_mem(cluster_obj, occamy_cfg):

    # Add Cache to cluster mem
    if "ro_cache_cfg" in occamy_cfg["s1_quadrant"]:
        ro_cache = occamy_cfg["s1_quadrant"]["ro_cache_cfg"]
        ro_tag_width = occamy_cfg["addr_width"] - clog2(
            ro_cache['width'] // 8) - clog2(ro_cache['count']) + 3
        cluster_obj.add_mem(ro_cache["count"],
                            ro_cache["width"],
                            desc="ro cache data",
                            byte_enable=False,
                            speed_optimized=True,
                            density_optimized=True)
        cluster_obj.add_mem(ro_cache["count"],
                            ro_tag_width,
                            desc="ro cache tag",
                            byte_enable=False,
                            speed_optimized=True,
                            density_optimized=True)
    cluster_obj.add_mem(occamy_cfg["spm_narrow"]["length"] // 8,
                        64,
                        desc="SPM Narrow",
                        speed_optimized=False,
                        density_optimized=True)

    cluster_obj.add_mem(occamy_cfg["spm_wide"]["length"] // 64,
                        512,
                        desc="SPM Wide",
                        speed_optimized=False,
                        density_optimized=True)

    # CVA6
    cluster_obj.add_mem(256,
                        128,
                        desc="cva6 data cache array",
                        byte_enable=True,
                        speed_optimized=True,
                        density_optimized=False)
    cluster_obj.add_mem(256,
                        128,
                        desc="cva6 instruction cache array",
                        byte_enable=True,
                        speed_optimized=True,
                        density_optimized=False)
    cluster_obj.add_mem(256,
                        44,
                        desc="cva6 data cache tag",
                        byte_enable=True,
                        speed_optimized=True,
                        density_optimized=False)
    cluster_obj.add_mem(256,
                        45,
                        desc="cva6 instruction cache tag",
                        byte_enable=True,
                        speed_optimized=True,
                        density_optimized=False)
    cluster_obj.add_mem(256,
                        64,
                        desc="cva6 data cache valid and dirty",
                        byte_enable=True,
                        speed_optimized=True,
                        density_optimized=False)
# class Occamy(Generator):
#     """
#     Generate an Occamy system.
#     """
#     def __init__(self, cfg):
#         occamy_root = (Path(__file__).parent / "../../").resolve()
#         snitch_root = (Path(__file__).parent / "../../deps/snitch_cluster").resolve()
#         schema = occamy_root / "docs/schema/occamy.schema.json"
#         remote_schemas = [occamy_root / "docs/schema/axi_xbar.schema.json",
#                           occamy_root / "docs/schema/axi_tlb.schema.json",
#                           occamy_root / "docs/schema/address_range.schema.json",
#                           occamy_root / "docs/schema/peripherals.schema.json",
#                           snitch_root / "docs/schema/snitch_cluster.schema.json"]
#         super().__init__(schema, remote_schemas)
#         # Validate the schema.
#         self.validate(cfg)
#         # from here we know that we have a valid object.
#         # and construct a new Occamy object.
#         self.cfg = cfg
#         # PMA Configuration for Snitch clusters only; for CVA6, see its SV template.
#         pma_cfg = PMACfg()
#         addr_width = cfg["cluster"]['addr_width']
#         # Make the entire HBM, but not HBI cacheable
#         pma_cfg.add_region_length(PMA.CACHED,
#                                   cfg["hbm"]["address_0"],
#                                   cfg["hbm"]["nr_channels_address_0"] * cfg["hbm"]["channel_size"],
#                                   addr_width)
#         pma_cfg.add_region_length(PMA.CACHED,
#                                   cfg["hbm"]["address_1"],
#                                   cfg["hbm"]["nr_channels_total"] * cfg["hbm"]["channel_size"],
#                                   addr_width)
#         # Make the SPM cacheable
#         pma_cfg.add_region_length(PMA.CACHED,
#                                   cfg["spm_narrow"]["address"],
#                                   cfg["spm_narrow"]["length"],
#                                   addr_width)
#         # Make the boot ROM cacheable
#         pma_cfg.add_region_length(PMA.CACHED,
#                                   cfg["peripherals"]["rom"]["address"],
#                                   cfg["peripherals"]["rom"]["length"],
#                                   addr_width)

#         # Store Snitch cluster config in separate variable
#         self.cluster = SnitchCluster(cfg["cluster"], pma_cfg)
#         # Overwrite boot address with base of bootrom
#         self.cluster.cfg["boot_addr"] = self.cfg["peripherals"]["rom"]["address"]

#         self.cluster.cfg['cluster_base_expose'] = True

#         if "ro_cache_cfg" in self.cfg["s1_quadrant"]:
#             ro_cache = self.cfg["s1_quadrant"]["ro_cache_cfg"]
#             ro_tag_width = self.cluster.cfg['addr_width'] - clog2(
#                 ro_cache['width'] // 8) - clog2(ro_cache['count']) + 3
#             self.cluster.add_mem(ro_cache["count"],
#                                  ro_cache["width"],
#                                  desc="ro cache data",
#                                  byte_enable=False,
#                                  speed_optimized=True,
#                                  density_optimized=True)
#             self.cluster.add_mem(ro_cache["count"],
#                                  ro_tag_width,
#                                  desc="ro cache tag",
#                                  byte_enable=False,
#                                  speed_optimized=True,
#                                  density_optimized=True)

#         self.cluster.add_mem(cfg["spm_narrow"]["length"] // 8,
#                              64,
#                              desc="SPM Narrow",
#                              speed_optimized=False,
#                              density_optimized=True)

#         self.cluster.add_mem(cfg["spm_wide"]["length"] // 64,
#                              512,
#                              desc="SPM Wide",
#                              speed_optimized=False,
#                              density_optimized=True)

#         # CVA6
#         self.cluster.add_mem(256,
#                              128,
#                              desc="cva6 data cache array",
#                              byte_enable=True,
#                              speed_optimized=True,
#                              density_optimized=False)
#         self.cluster.add_mem(256,
#                              128,
#                              desc="cva6 instruction cache array",
#                              byte_enable=True,
#                              speed_optimized=True,
#                              density_optimized=False)
#         self.cluster.add_mem(256,
#                              44,
#                              desc="cva6 data cache tag",
#                              byte_enable=True,
#                              speed_optimized=True,
#                              density_optimized=False)
#         self.cluster.add_mem(256,
#                              45,
#                              desc="cva6 instruction cache tag",
#                              byte_enable=True,
#                              speed_optimized=True,
#                              density_optimized=False)
#         self.cluster.add_mem(256,
#                              64,
#                              desc="cva6 data cache valid and dirty",
#                              byte_enable=True,
#                              speed_optimized=True,
#                              density_optimized=False)
#         # HBM
#         self.cluster.add_mem(2**6,
#                              16,
#                              byte_enable=False,
#                              desc="HBM Re-order",
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**6,
#                              14,
#                              byte_enable=False,
#                              desc="HBM Fifo",
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**4,
#                              32,
#                              byte_enable=False,
#                              desc="HBM WR Fifo",
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**4,
#                              102,
#                              byte_enable=False,
#                              desc="HBM RD Fifo",
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**6,
#                              48,
#                              byte_enable=False,
#                              desc="HBM Test",
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**4,
#                              576,
#                              byte_enable=False,
#                              desc="HBM Test/W Data",
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**4,
#                              64,
#                              byte_enable=False,
#                              desc="HBM Test",
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**4,
#                              204,
#                              byte_enable=False,
#                              desc="HBM Analyzer",
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)

#         self.cluster.add_mem(2**3,
#                              56,
#                              desc="HBM RD CMD",
#                              byte_enable=False,
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**4,
#                              74,
#                              desc="HBM WR CMD",
#                              byte_enable=False,
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**4,
#                              11,
#                              desc="HBM BID",
#                              byte_enable=False,
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**7,
#                              585,
#                              desc="HBM RD ID",
#                              byte_enable=False,
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**6,
#                              6,
#                              desc="HBM RD ID",
#                              byte_enable=False,
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)
#         self.cluster.add_mem(2**7,
#                              641,
#                              desc="HBM ReOrd",
#                              byte_enable=False,
#                              speed_optimized=True,
#                              density_optimized=False,
#                              dual_port=True)

#         # ADD: now we have multiple clusters with different cfgs
#         self.clusters = list()
#         for i in range(cfg["s1_quadrant"]["nr_clusters"]):
#             self.clusters.append(SnitchCluster(cfg["clusters"][i], pma_cfg))
#         for i in range(cfg["s1_quadrant"]["nr_clusters"]):
#             self.clusters[i].cfg["tie_ports"] = False
#             self.clusters[i].cfg["boot_addr"] = self.cfg["peripherals"]["rom"]["address"]

#             self.clusters[i].cfg['cluster_base_expose'] = True

#             if "ro_cache_cfg" in self.cfg["s1_quadrant"]:
#                 ro_cache = self.cfg["s1_quadrant"]["ro_cache_cfg"]
#                 ro_tag_width = self.clusters[i].cfg['addr_width'] - clog2(
#                     ro_cache['width'] // 8) - clog2(ro_cache['count']) + 3
#                 self.clusters[i].add_mem(ro_cache["count"],
#                                     ro_cache["width"],
#                                     desc="ro cache data",
#                                     byte_enable=False,
#                                     speed_optimized=True,
#                                     density_optimized=True)
#                 self.clusters[i].add_mem(ro_cache["count"],
#                                     ro_tag_width,
#                                     desc="ro cache tag",
#                                     byte_enable=False,
#                                     speed_optimized=True,
#                                     density_optimized=True)

#             self.clusters[i].add_mem(cfg["spm_narrow"]["length"] // 8,
#                                 64,
#                                 desc="SPM Narrow",
#                                 speed_optimized=False,
#                                 density_optimized=True)

#             self.clusters[i].add_mem(cfg["spm_wide"]["length"] // 64,
#                                 512,
#                                 desc="SPM Wide",
#                                 speed_optimized=False,
#                                 density_optimized=True)

#             # CVA6
#             self.clusters[i].add_mem(256,
#                                 128,
#                                 desc="cva6 data cache array",
#                                 byte_enable=True,
#                                 speed_optimized=True,
#                                 density_optimized=False)
#             self.clusters[i].add_mem(256,
#                                 128,
#                                 desc="cva6 instruction cache array",
#                                 byte_enable=True,
#                                 speed_optimized=True,
#                                 density_optimized=False)
#             self.clusters[i].add_mem(256,
#                                 44,
#                                 desc="cva6 data cache tag",
#                                 byte_enable=True,
#                                 speed_optimized=True,
#                                 density_optimized=False)
#             self.clusters[i].add_mem(256,
#                                 45,
#                                 desc="cva6 instruction cache tag",
#                                 byte_enable=True,
#                                 speed_optimized=True,
#                                 density_optimized=False)
#             self.clusters[i].add_mem(256,
#                                 64,
#                                 desc="cva6 data cache valid and dirty",
#                                 byte_enable=True,
#                                 speed_optimized=True,
#                                 density_optimized=False)
#             # HBM
#             self.clusters[i].add_mem(2**6,
#                                 16,
#                                 byte_enable=False,
#                                 desc="HBM Re-order",
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**6,
#                                 14,
#                                 byte_enable=False,
#                                 desc="HBM Fifo",
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**4,
#                                 32,
#                                 byte_enable=False,
#                                 desc="HBM WR Fifo",
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**4,
#                                 102,
#                                 byte_enable=False,
#                                 desc="HBM RD Fifo",
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**6,
#                                 48,
#                                 byte_enable=False,
#                                 desc="HBM Test",
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**4,
#                                 576,
#                                 byte_enable=False,
#                                 desc="HBM Test/W Data",
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**4,
#                                 64,
#                                 byte_enable=False,
#                                 desc="HBM Test",
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**4,
#                                 204,
#                                 byte_enable=False,
#                                 desc="HBM Analyzer",
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)

#             self.clusters[i].add_mem(2**3,
#                                 56,
#                                 desc="HBM RD CMD",
#                                 byte_enable=False,
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**4,
#                                 74,
#                                 desc="HBM WR CMD",
#                                 byte_enable=False,
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**4,
#                                 11,
#                                 desc="HBM BID",
#                                 byte_enable=False,
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**7,
#                                 585,
#                                 desc="HBM RD ID",
#                                 byte_enable=False,
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**6,
#                                 6,
#                                 desc="HBM RD ID",
#                                 byte_enable=False,
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#             self.clusters[i].add_mem(2**7,
#                                 641,
#                                 desc="HBM ReOrd",
#                                 byte_enable=False,
#                                 speed_optimized=True,
#                                 density_optimized=False,
#                                 dual_port=True)
#     def render_wrapper(self):
#         return self.cluster.render_wrapper()
#     def render_wrappers(self,idx):
#         return self.clusters[idx].render_wrapper()