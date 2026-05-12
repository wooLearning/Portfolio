BLOCK ?= adder
BLOCKS := adder ram fifo

.PHONY: help list check-block compile lint run coverage urg wave verdi verdi_cov verdi_all \
        clean clean-block adder ram fifo compile-all lint-all run-all clean-all

help:
	@echo "Basic RTL/UVM Make targets"
	@echo ""
	@echo "Single block:"
	@echo "  make run BLOCK=adder       # compile and run VCS simulation"
	@echo "  make compile BLOCK=ram     # compile only"
	@echo "  make lint BLOCK=fifo       # vlogan syntax/lint compile"
	@echo "  make wave BLOCK=adder      # run simulation, then open Verdi waveform view"
	@echo "  make coverage BLOCK=adder  # run simulation and generate URG coverage report"
	@echo "  make verdi BLOCK=adder     # alias for wave"
	@echo "  make verdi_cov BLOCK=adder # run coverage, then open Verdi coverage view only"
	@echo "  make verdi_all BLOCK=adder # run coverage, then open waveform + coverage"
	@echo "  make urg BLOCK=adder       # generate URG from an existing simv.vdb"
	@echo "  make clean-block BLOCK=adder # remove one block's simulation outputs"
	@echo ""
	@echo "Shortcuts:"
	@echo "  make adder                 # same as make run BLOCK=adder"
	@echo "  make ram                   # same as make run BLOCK=ram"
	@echo "  make fifo                  # same as make run BLOCK=fifo"
	@echo ""
	@echo "All blocks:"
	@echo "  make run-all"
	@echo "  make lint-all"
	@echo "  make clean                 # remove all simulation outputs"
	@echo ""
	@echo "Available BLOCK values: $(BLOCKS)"

list:
	@printf "%s\n" $(BLOCKS)

check-block:
	@if ! printf "%s\n" $(BLOCKS) | grep -qx "$(BLOCK)"; then \
	  echo "Unknown BLOCK='$(BLOCK)'. Use one of: $(BLOCKS)"; \
	  exit 1; \
	fi

compile lint run coverage urg wave verdi verdi_cov verdi_all: check-block
	$(MAKE) -C $(BLOCK)/tb $@

clean-block: check-block
	$(MAKE) -C $(BLOCK)/tb clean

clean: clean-all

clean-all:
	@for block in $(BLOCKS); do \
	  $(MAKE) clean-block BLOCK=$$block || exit $$?; \
	done

adder ram fifo:
	$(MAKE) run BLOCK=$@

compile-all:
	@for block in $(BLOCKS); do \
	  $(MAKE) compile BLOCK=$$block || exit $$?; \
	done

lint-all:
	@for block in $(BLOCKS); do \
	  $(MAKE) lint BLOCK=$$block || exit $$?; \
	done

run-all:
	@for block in $(BLOCKS); do \
	  $(MAKE) run BLOCK=$$block || exit $$?; \
	done
