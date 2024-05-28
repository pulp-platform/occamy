
include ../toolchain.mk
SNITCH_ROOT = $(shell bender path snitch_cluster)
SNRT_DIR    = $(SNITCH_ROOT)/sw/snRuntime
MKFILE_DIR  := $(shell pwd)
DEVICE_DIR      = $(abspath ../)
SW_DIR      = $(abspath ../../)
OCCAMY_SNRT_DIR        = $(DEVICE_DIR)/runtime
BUILDDIR    = $(abspath build/)

#############
# Snax Libs #
#############
SNAX_LIBS = gemm
SNAX_LIBS += mac
SNAX_LIBS += streamer-gemm
SNAX_LIBS += streamer-simd
SNAX_LIBS += data-reshuffler



INCDIRS = $(addprefix $(MKFILE_DIR)/,$(addsuffix /include,$(SNAX_LIBS)))
INCDIRS += $(SNRT_DIR)/src
INCDIRS += $(SNRT_DIR)/api
INCDIRS += $(SNRT_DIR)/vendor/riscv-opcodes
INCDIRS += $(OCCAMY_SNRT_DIR)/src
INCDIRS += $(SW_DIR)/shared/platform
INCDIRS += $(SW_DIR)/shared/platform/generated
INCDIRS += $(SW_DIR)/shared/runtime

RISCV_LDFLAGS += -L$(SNRT_DIR)
RISCV_LDFLAGS += -lsnRuntime

###########
# Outputs #
###########
OBJS = $(addprefix $(BUILDDIR)/snax-,$(addsuffix -lib.o,$(SNAX_LIBS)))
SNAX_LIB = $(BUILDDIR)/libsnaxRuntime.a
SNAX_DUMP = $(BUILDDIR)/libsnaxRuntime.dump
ALL_OUTPUTS = $(OBJS) $(SNAX_LIB) $(SNAX_DUMP)
.PHONY: all
all: $(ALL_OUTPUTS)

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)


$(BUILDDIR):
	mkdir -p $@

$(BUILDDIR)/snax-gemm-lib.o: $(MKFILE_DIR)/gemm/src/snax-gemm-lib.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) $(RISCV_LDFLAGS) -c  $< -o $@

$(BUILDDIR)/snax-mac-lib.o: $(MKFILE_DIR)/mac/src/snax-mac-lib.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) $(RISCV_LDFLAGS) -c  $< -o $@

$(BUILDDIR)/snax-data-reshuffler-lib.o: $(MKFILE_DIR)/data-reshuffler/src/snax-data-reshuffler-lib.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) $(RISCV_LDFLAGS) -c  $< -o $@

$(BUILDDIR)/snax-streamer-gemm-lib.o: $(MKFILE_DIR)/streamer-gemm/src/snax-streamer-gemm-lib.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) $(RISCV_LDFLAGS) -c  $< -o $@

$(BUILDDIR)/snax-streamer-simd-lib.o: $(MKFILE_DIR)/streamer-simd/src/snax-streamer-simd-lib.c | $(BUILDDIR)
	$(RISCV_CC) $(RISCV_CFLAGS) $(RISCV_LDFLAGS) -c  $< -o $@

$(SNAX_LIB): $(OBJS) | $(BUILDDIR)
	$(RISCV_AR) $(RISCV_ARFLAGS) $@ $^

$(SNAX_DUMP): $(SNAX_LIB) | $(BUILDDIR)
	$(RISCV_OBJDUMP) -D $< > $@
.PHONY: debug
debug:
	@echo "MKFILE_DIR is" $(MKFILE_DIR)
	@echo "BUILD_DIR is" $(BUILDDIR)
	@echo "SNRT_DIR is" $(SNRT_DIR)
	@echo "OBJS is" $(OBJS)
	@echo "INCDIRS is" $(INCDIRS)