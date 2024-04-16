
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))
ROOT        := $(MKFILE_DIR)../..

FESVR         ?= ${MKFILE_DIR}work
BIN_DIR       ?= bin
VSIM_BUILDDIR ?= work-vsim

VOPT_FLAGS = +acc
VSIM_FLAGS += -t 1ps
VSIM_FLAGS += -voptargs=+acc
VSIM_FLAGS += -do "log -r /*; run -a"
VSIM_FLAGS += -warning 8386

.PHONY: vsim-set-dir
vsim-set-dir: $(VSIM_BUILDDIR)/compile.vsim.tcl
	vlib $(dir $<)
	sed -i 's#/repo#'$(ROOT)'#g' $<

$(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/occamy_top.vsim: $(VSIM_BUILDDIR)/compile.vsim.tcl | $(BIN_DIR)
	vsim -c -do "source $<; quit" | tee $(dir $<)vlog.log
	@! grep -P "Errors: [1-9]*," $(dir $<)vlog.log
	vopt $(VOPT_FLAGS) -work $(VSIM_BUILDDIR) tb_bin -o tb_bin_opt | tee $(dir $<)vopt.log
	@! grep -P "Errors: [1-9]*," $(dir $<)vopt.log
	@echo "#!/bin/bash" > $@
	@echo 'binary=$$(realpath $$1)' >> $@
	@echo 'echo $$binary > .rtlbinary' >> $@
	@echo 'vsim +permissive $(VSIM_FLAGS) $$3 -work $(MKFILE_DIR)/$(VSIM_BUILDDIR) -c \
				-ldflags "-Wl,-rpath,$(FESVR)/lib -L$(FESVR)/lib -lfesvr -lutil" \
				tb_bin_opt +permissive-off ++$$binary ++$$2' >> $@
	@chmod +x $@
	@echo "#!/bin/bash" > $@.gui
	@echo 'binary=$$(realpath $$1)' >> $@.gui
	@echo 'echo $$binary > .rtlbinary' >> $@.gui
	@echo 'vsim +permissive $(VSIM_FLAGS) -work $(MKFILE_DIR)/$(VSIM_BUILDDIR) \
				-ldflags "-Wl,-rpath,$(FESVR)/lib -L$(FESVR)/lib -lfesvr -lutil" \
				tb_bin_opt +permissive-off ++$$binary ++$$2' >> $@.gui
	@chmod +x $@.gui