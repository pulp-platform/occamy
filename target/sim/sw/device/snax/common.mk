MK_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
include $(MK_DIR)/../toolchain.mk

###############
# Directories #
###############

# Fixed paths in repository tree
ROOT        = $(abspath $(MK_DIR)/../../../../../)
SNITCH_ROOT = $(shell bender path snitch_cluster)
APPSDIR     = $(abspath $(MK_DIR))
RUNTIME_DIR = $(ROOT)/target/sim/sw/device/runtime
SNRT_DIR    = $(SNITCH_ROOT)/sw/snRuntime
SW_DIR      = $(ROOT)/target/sim/sw/
MATH_DIR    = $(ROOT)/target/sim/sw/device/math

# Paths relative to the app including this Makefile
BUILDDIR    = $(abspath build)
SRC_DIR     = $(abspath src)

###################
# Build variables #
###################

# Dependencies
INCDIRS += $(RUNTIME_DIR)/src
INCDIRS += $(SNRT_DIR)/api
INCDIRS += $(SNRT_DIR)/src
INCDIRS += $(SNRT_DIR)/vendor/riscv-opcodes
INCDIRS += $(SW_DIR)/shared/platform/generated
INCDIRS += $(SW_DIR)/shared/platform
INCDIRS += $(SW_DIR)/shared/runtime

SNRT_LIB_DIR  = $(abspath $(RUNTIME_DIR)/build/)
SNRT_LIB_NAME = snRuntime
SNRT_LIB      = $(realpath $(SNRT_LIB_DIR)/lib$(SNRT_LIB_NAME).a)

# # Link snRuntime library
# RISCV_LDFLAGS += -L$(SNRT_LIB_DIR)
# RISCV_LDFLAGS += -l$(SNRT_LIB_NAME)


$(BUILDDIR):
	mkdir -p $@

$(BUILDDIR)/%.o: $(SRC_DIR)/%.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) $(RISCV_LDFLAGS) -c $< -o $@