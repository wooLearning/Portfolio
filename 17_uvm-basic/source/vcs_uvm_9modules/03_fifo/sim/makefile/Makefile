VCS      ?= vcs
VLOGAN   ?= vlogan
SIMV     ?= ./simv
VERDI    ?= verdi
UVM_HOME ?= /tools/synopsys/vcs/W-2024.09-SP1/etc/uvm-1.2
UVM_OPTS ?= -ntb_opts uvm-1.2
COV_METRICS ?= line+cond+fsm+tgl+branch+assert
COV_DIR ?= simv.vdb

RTL_DIR  := ../rtl
TB_DIR   := .

VLOGAN_FLAGS := -full64 -sverilog -timescale=1ns/1ps
VCS_FLAGS    := -full64 -sverilog $(UVM_OPTS) -debug_access+all -kdb -lca -timescale=1ns/1ps
COV_FLAGS    := -cm $(COV_METRICS) -cm_dir $(COV_DIR)
INCDIRS      := +incdir+$(UVM_HOME) +incdir+$(TB_DIR)

RTL_SRCS := $(RTL_DIR)/sync_fifo.sv
TB_SRCS  := $(TB_DIR)/fifo_if.sv \
            $(TB_DIR)/tb_fifo_pkg.sv \
            $(TB_DIR)/tb_fifo.sv

.PHONY: all compile lint run coverage urg wave verdi verdi_cov verdi_all clean

all: compile

compile:
	$(VCS) $(VCS_FLAGS) $(COV_FLAGS) $(INCDIRS) $(TB_SRCS) $(RTL_SRCS) -top tb_fifo -o simv

lint:
	$(VLOGAN) $(VLOGAN_FLAGS) $(INCDIRS) $(UVM_HOME)/uvm_pkg.sv $(TB_SRCS) $(RTL_SRCS)

run: compile
	$(SIMV) $(COV_FLAGS)

coverage: run urg

urg:
	urg -dir $(COV_DIR) -report urgReport

wave: run
	$(VERDI) -full64 -dbdir simv.daidir -ssf novas.fsdb -top tb_fifo &

verdi: wave

verdi_cov: coverage
	$(VERDI) -full64 -cov -covdir $(COV_DIR) &

verdi_all: coverage
	$(VERDI) -full64 -dbdir simv.daidir -ssf novas.fsdb -top tb_fifo -cov -covdir $(COV_DIR) &

clean:
	rm -rf simv simv.daidir csrc ucli.key vc_hdrs.h AN.DB DVEfiles verdiLog vdCovLog novas.* novas.conf *.fsdb *.log .*.sch.verilog.xml $(COV_DIR) urgReport
