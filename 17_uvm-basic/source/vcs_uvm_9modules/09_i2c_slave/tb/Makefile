.RECIPEPREFIX := >

VCS ?= vcs
VERDI ?= verdi
URG ?= urg
TOP ?= tb_i2c_slave
RTL := ../rtl/i2c_slave.sv
SEQ ?= smoke
SEQ_ARG := I2C_SLAVE_SEQ
FILELIST := files.f
BUILD_LOG := build.log
RUN_LOG := run.log
RUN_ARGS ?= +$(SEQ_ARG)=$(SEQ)
COV_METRICS ?= line+cond+fsm+tgl+branch+assert
COV_DIR ?= simv.vdb
VCS_FLAGS := -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps -debug_access+all -kdb -lca +define+FSDB
COV_FLAGS := -cm $(COV_METRICS) -cm_dir $(COV_DIR)

.PHONY: help check compile build run coverage urg wave verdi verdi_cov verdi_all clean

help:
>@echo "make build         : compile with VCS"
>@echo "make run SEQ=smoke : build and run"
>@echo "make coverage SEQ=all : run and generate URG report"
>@echo "make verdi_all SEQ=all : coverage plus Verdi waveform/coverage GUI"
>@echo "make clean         : remove simulation outputs"

check:
>@test -f "$(RTL)" || (echo "Missing $(RTL)" && exit 1)
>@test -f "$(FILELIST)" || (echo "Missing $(FILELIST)" && exit 1)

compile build: check
>$(VCS) $(VCS_FLAGS) $(COV_FLAGS) -f $(FILELIST) -top $(TOP) -l $(BUILD_LOG)

run: build
>./simv $(COV_FLAGS) $(RUN_ARGS) -l $(RUN_LOG)

coverage: run urg

urg:
>$(URG) -dir $(COV_DIR) -report urgReport

wave: run
>$(VERDI) -full64 -dbdir simv.daidir -ssf novas.fsdb -top $(TOP) &

verdi: wave

verdi_cov: coverage
>$(VERDI) -full64 -cov -covdir $(COV_DIR) &

verdi_all: coverage
>$(VERDI) -full64 -dbdir simv.daidir -ssf novas.fsdb -top $(TOP) -cov -covdir $(COV_DIR) &

clean:
>rm -rf csrc simv simv.daidir ucli.key DVEfiles novas* *.log *.vpd *.fsdb $(COV_DIR) urgReport vdCovLog verdiLog AN.DB vc_hdrs.h
