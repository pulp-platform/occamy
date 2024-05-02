// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <stdarg.h>

#include "sw_mailbox.h"
#include "snrt.h"

volatile uint32_t dma_wait_cycles = 0;

//================================================================================
// MACROS AND SETTINGS
//================================================================================

// set to >0 for debugging
#define DEBUG_LEVEL_OFFLOAD_MANAGER 1

const uint32_t active_pe = 8;

/* MAILBOX SIGNALING */
#define MBOX_DEVICE_READY (0x01U)
#define MBOX_DEVICE_START (0x02U)
#define MBOX_DEVICE_BUSY (0x03U)
#define MBOX_DEVICE_DONE (0x04U)
#define MBOX_DEVICE_STOP (0x0FU)
#define MBOX_DEVICE_LOGLVL (0x10U)
#define MBOX_HOST_READY (0x1000U)
#define MBOX_HOST_DONE (0x3000U)

#define TO_RUNTIME (0x10000000U) // bypass PULP driver
#define RAB_UPDATE (0x20000000U) // handled by PULP driver
#define RAB_SWITCH (0x30000000U) // handled by PULP driver

//================================================================================
// TYPES
//================================================================================

// Shrinked gomp_team_t descriptor
typedef struct offload_rab_miss_handler_desc_s {
  void (*omp_task_f)(void *arg, uint32_t argc);
  void *omp_args;
  void *omp_argc;
  int barrier_id;
} offload_rab_miss_handler_desc_t;

typedef uint32_t virt_addr_t;
typedef uint32_t virt_pfn_t;

// This struct represents a miss in the RAB Miss Hardware FIFO.
typedef struct rab_miss_t {
  virt_addr_t virt_addr;
  int core_id;
  int cluster_id;
  int intra_cluster_id;
  uint8_t is_prefetch;
} rab_miss_t;

//================================================================================
// Data
//================================================================================
static volatile uint32_t g_printf_mutex = 0;

static volatile uint32_t *soc_scratch = (uint32_t *)(0x02000014);
struct l3_layout l3l;

const uint32_t snrt_stack_size __attribute__((weak, section(".rodata"))) = 12;

// The boot data generated along with the system RTL.
// See `hw/system/snitch_cluster/test/tb_lib.hh` for details.
struct snrt_cluster_bootdata {
  uint32_t boot_addr;
  uint32_t core_count;
  uint32_t hartid_base;
  uint32_t tcdm_start;
  uint32_t tcdm_size;
  uint32_t tcdm_offset;
  uint64_t global_mem_start;
  uint64_t global_mem_end;
  uint32_t cluster_count;
  uint32_t s1_quadrant_count;
  uint32_t clint_base;
};

/**
 * @brief Called by each hart before the pre-main barrier in snrt crt0
 *
 */
void _snrt_hier_wakeup(void) {
  const uint32_t core_id = snrt_cluster_core_idx();

  // master core wakes other cluster cores through cluster local clint
  if (core_id == 0) {
    // clear the interrupt from cva6
    snrt_int_sw_clear(snrt_hartid());
    // wake remaining cluster cores
    const unsigned cluster_core_num = snrt_cluster_core_num();
    snrt_int_cluster_set(~0x1 & ((1 << cluster_core_num) - 1));
  } else {
    // clear my interrupt
    snrt_int_cluster_clr(1 << core_id);
  }
}

//================================================================================
// TODO: Symbols to declare somewhere else on a merge
//================================================================================
/**
 * @brief A re-entrant wrapper to printf
 *
 */
void snrt_printf(const char *format, ...) {
  va_list args;

  snrt_mutex_acquire(&g_printf_mutex);

  va_start(args, format);
  vprintf(format, args);
  va_end(args);

  snrt_mutex_release(&g_printf_mutex);
}

//================================================================================
// HERO Functions
//================================================================================

static void offload_rab_misses_handler(void *arg, uint32_t argc) {
  (void)arg;
  (void)argc;
  snrt_err("unimplemented!\r\n");
  // static void offload_rab_misses_handler(uint32_t *status) {
  // uint32_t *status = (uint32_t)arg;
  // if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
  //   snrt_trace("offload_rab_misses_handler: synch @%p (0x%x)\n", status,
  //              *(volatile unsigned int *)status);
  // do {
  //   handle_rab_misses();
  // } while (*((volatile uint32_t *)status) != 0xdeadbeefU);
  // if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
  //   snrt_trace("offload_rab_misses_handler: synch @%p (0x%x)\n", status,
  //              *(volatile unsigned int *)status);
}

static int gomp_offload_manager() {
  const uint32_t core_id = snrt_cluster_core_idx();

  // Init the manager (handshake btw host and accelerator is here)
  // gomp_init_offload_manager();

  // FIXME For the momenent we are not using the cmd sended as trigger.
  // It should be used to perform the deactivation of the accelerator,
  // as well as other operations, like local data allocation or movement.
  // FIXME Note that the offload at the moment use several time the mailbox.
  // We should compact the offload descriptor and just sent a pointer to
  // that descriptor.
  uint32_t cmd = (uint32_t)NULL;
  uint32_t data;

  // Offloaded function pointer and arguments
  void (*offloadFn)(uint64_t) = NULL;
  uint64_t offloadArgs = 0x0;
  unsigned nbOffloadRabMissHandlers = 0x0;
  uint32_t offload_rab_miss_sync = 0x0U;
  // offload_rab_miss_handler_desc_t rab_miss_handler = {.omp_task_f = offload_rab_misses_handler,
  //                                                     .omp_args = (void *)&offload_rab_miss_sync,
  //                                                     .omp_argc = 1,
  //                                                     .barrier_id = -1};

  int cycles = 0;
  uint32_t issue_fpu, dma_busy;
  rab_miss_t rab_miss;
  // reset_vmm();

  while (1) {
    //if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
    //  snrt_trace("Waiting for command...\n");

    // (1) Wait for the offload trigger cmd == MBOX_DEVICE_START
    mailbox_read((unsigned int *)&cmd, 1);
    cycles = read_csr(mcycle);
    if (MBOX_DEVICE_STOP == cmd) {
      //if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
      //  snrt_trace("Got MBOX_DEVICE_STOP from host, stopping execution now.\n");
      break;
    } else if (MBOX_DEVICE_LOGLVL == cmd) {
      //if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
      //  snrt_trace("Got command 0x%x, setting log level.\n", cmd);
      mailbox_read((unsigned int *)&data, 1);
      //snrt_debug_set_loglevel(data);
      continue;
    } else if (MBOX_DEVICE_START != cmd) {
      //if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
      //  snrt_trace("Got unexpected command 0x%x, stopping execution now.\n", cmd);
      break;
    }

    // (2) The host sends through the mailbox the pointer to the function that should be
    // executed on the accelerator.
    mailbox_read((unsigned int *)&offloadFn, 1);

    //if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
    //  snrt_trace("tgt_fn @ 0x%x\n", (unsigned int)offloadFn);

    // (3) The host sends through the mailbox the pointer to the arguments that should
    // be used.
    mailbox_read((unsigned int *)&offloadArgs, 1);

    //if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
    //  snrt_trace("tgt_vars @ 0x%x\n", (unsigned int)offloadArgs);

    // (3b) The host sends through the mailbox the number of rab misses handlers threads
    mailbox_read((unsigned int *)&nbOffloadRabMissHandlers, 1);

    //if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
    //  snrt_trace("nbOffloadRabMissHandlers %d/%d\n", nbOffloadRabMissHandlers, active_pe);

    // (3c) Spawning nbOffloadRabMissHandlers
    unsigned mhCoreMask = 0;
    nbOffloadRabMissHandlers =
        nbOffloadRabMissHandlers < active_pe - 1 ? nbOffloadRabMissHandlers : active_pe - 1;
    if (nbOffloadRabMissHandlers) {
      offload_rab_miss_sync = 0x0U;
      for (int pid = active_pe - 1, i = nbOffloadRabMissHandlers; i > 0; i--, pid--) {
        //if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
        //  snrt_trace("enabling RAB miss handler on %d\n", pid);
        mhCoreMask |= (1 << pid);
      }
    }
    omp_getData()->maxThreads = active_pe - nbOffloadRabMissHandlers;
    omp_getData()->numThreads = active_pe - nbOffloadRabMissHandlers;
    // eu_dispatch_team_config(mhCoreMask);
    // eu_dispatch_push((unsigned int)&offload_rab_misses_handler);
    // eu_dispatch_push((unsigned int)&offload_rab_miss_sync);
    // eu_dispatch_team_config(omp_getData()->coreMask);

    // (4) Ensure access to offloadArgs. It might be in SVM.
    if (offloadArgs != 0x0) {
      // FIXME
      // pulp_tryread((unsigned int *)offloadArgs);
    }
    //if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
    //  snrt_trace("begin offloading\n");
    // reset_timer();
    // start_timer();

    //for (unsigned i = 0; i < 16; i += 2) {
    //  snrt_trace(" %2d: 0x%08x = ... ; %2d: 0x%08x = ...\n", i, ((uint32_t *)offloadArgs)[i],
    //             /* *((uint32_t *)(((uint32_t *)offloadArgs)[i])) ,*/  i + 1,
    //             ((uint32_t *)offloadArgs)[i + 1] /*, *((uint32_t *)(((uint32_t *)offloadArgs)[i + 1]))*/ );
    //}

    // (5) Execute the offloaded function.
    // snrt_reset_perf_counter(SNRT_PERF_CNT0);
    // snrt_reset_perf_counter(SNRT_PERF_CNT1);
    // snrt_start_perf_counter(SNRT_PERF_CNT0, SNRT_PERF_CNT_ISSUE_FPU, core_id);
    // snrt_start_perf_counter(SNRT_PERF_CNT1, SNRT_PERF_CNT_DMA_BUSY, core_id);
    cycles = read_csr(mcycle);
    dma_wait_cycles = 0;

    offloadFn(offloadArgs);
    // snrt_stop_perf_counter(SNRT_PERF_CNT0);
    // snrt_stop_perf_counter(SNRT_PERF_CNT1);
    // issue_fpu = snrt_get_perf_counter(SNRT_PERF_CNT0);
    // dma_busy = snrt_get_perf_counter(SNRT_PERF_CNT1);

    //if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
    //  snrt_trace("end offloading\n");
    
    // (6) Report EOC and profiling
    //snrt_info("cycles: %d\r\n", cycles);

    mailbox_write(MBOX_DEVICE_DONE);
    cycles = read_csr(mcycle) - cycles;
    mailbox_write(cycles);
    mailbox_write(dma_wait_cycles);

    //if (DEBUG_LEVEL_OFFLOAD_MANAGER > 0)
    //  snrt_trace("Kernel execution time [Snitch cycles] = %d\n", cycles);

    if (nbOffloadRabMissHandlers) {
      offload_rab_miss_sync = 0xdeadbeefU;
      // gomp_atomic_add_thread_pool_idle_cores(nbOffloadRabMissHandlers);
    }
  }

  return 0;
}

int main(int argc, char *argv[]) {
  (void)argc;
  (void)argv;
  unsigned core_idx = snrt_cluster_core_idx();
  unsigned core_num = snrt_cluster_core_num();

  /**
   * One core initializes the global data structures
   */
  if (snrt_is_dm_core()) {
    // read memory layout from scratch2
    memcpy(&l3l, (void *)soc_scratch[2], sizeof(struct l3_layout));
    g_a2h_rb = (struct ring_buf *)l3l.a2h_rb;
    g_a2h_mbox = (struct ring_buf *)l3l.a2h_mbox;
    g_h2a_mbox = (struct ring_buf *)l3l.h2a_mbox;
  }

  snrt_cluster_hw_barrier();

  __snrt_omp_bootstrap(core_idx);

  gomp_offload_manager();

  //snrt_trace("bye\n");
  // exit
  __snrt_omp_destroy(core_idx);
  snrt_hero_exit(0);
  return 0;
}
