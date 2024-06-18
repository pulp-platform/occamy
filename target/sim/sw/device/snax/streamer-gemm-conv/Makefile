MK_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
include $(MK_DIR)/../common.mk

############
## Outputs #
############

OBJS        = $(BUILDDIR)/snax-streamer-gemm-conv-lib.o
ALL_OUTPUTS = $(OBJS)
INCDIRS += $(abspath include)

##########
## Rules #
##########

.PHONY: all
all: $(ALL_OUTPUTS)

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)
