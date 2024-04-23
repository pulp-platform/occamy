
APP     = snax-wide-gemm-data-reshuffler

INCDIRS = data

INCDIRS += ../../../snax/streamer-gemm/include
INCDIRS += ../../../snax/gemm/include
INCDIRS += ../../../snax/data-reshuffler/include

# Include this binary in the final build
RISCV_LDFLAGS += ../../../snax/streamer-gemm/build/snax-streamer-gemm-lib.o
RISCV_LDFLAGS += ../../../snax/gemm/build/snax-gemm-lib.o
RISCV_LDFLAGS += ../../../snax/data-reshuffler/build/snax-data-reshuffler-lib.o

SRCS    = src/snax-wide-gemm-data-reshuffler.c


include ./data/Makefile
include ../../common.mk
$(DEP): $(DATA_H)
