.RECIPEPREFIX := >

VCS ?= vcs
TOP ?= tb_loopback_uvm
TESTNAME ?= loopback_run_test
FILELIST := files.f
SEED ?= 1
SEEDS ?= 1 2 3 4 5

VCS_OPTS := -full64 -sverilog -ntb_opts uvm-1.2
VCS_OPTS += -timescale=1ns/1ps -debug_access+all -kdb -lca
VCS_OPTS += +incdir+../uvm_tb

.PHONY: help build run regress_random clean

help:
>@echo "make build                           : compile Loopback UVM TB"
>@echo "make run                             : run Loopback integrated scenario"
>@echo "make run SEED=31                     : run Loopback integrated scenario with seed override"
>@echo "Example commands:"
>@echo "  make run"
>@echo "  make run"
>@echo "  make run SEED=31"
>@echo "Integrated flow: full + random + negative + reset_recovery"

build:
>$(VCS) $(VCS_OPTS) -f $(FILELIST) -top $(TOP) -l build.log

run: build
>./simv +UVM_TESTNAME=$(TESTNAME) +ntb_random_seed=$(SEED) -l run.log

regress_random: build
>@set -e; for seed in $(SEEDS); do echo "[loopback regression] TESTNAME=$(TESTNAME) SEED=$$seed"; ./simv +UVM_TESTNAME=$(TESTNAME) +ntb_random_seed=$$seed -l run_$$seed.log; done

clean:
>rm -rf csrc simv simv.daidir ucli.key DVEfiles novas* *.log *.vpd *.fsdb *.vcd
