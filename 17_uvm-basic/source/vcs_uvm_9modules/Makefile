.PHONY: help list reports check-module module-help compile build run coverage urg wave verdi verdi_cov verdi_all clean

MODULES := 01_adder 02_ram 03_fifo 04_uart_rx 05_uart_tx 06_spi_master 07_spi_slave 08_i2c_master 09_i2c_slave
MODULE ?= 01_adder

help:
	@echo "UVM_TEST workspace"
	@echo "  make list                  - show ordered module folders"
	@echo "  make reports               - show per-module report files"
	@echo "  make module-help MODULE=04_uart_rx"
	@echo "  make run MODULE=04_uart_rx SEQ=smoke"
	@echo "  make coverage MODULE=04_uart_rx SEQ=all"
	@echo "  make verdi_all MODULE=04_uart_rx SEQ=all"
	@echo "  make clean MODULE=04_uart_rx"
	@echo ""
	@echo "Default MODULE is $(MODULE)."

list:
	@echo 01_adder
	@echo 02_ram
	@echo 03_fifo
	@echo 04_uart_rx
	@echo 05_uart_tx
	@echo 06_spi_master
	@echo 07_spi_slave
	@echo 08_i2c_master
	@echo 09_i2c_slave

reports:
	@echo 01_adder/docs/report.md
	@echo 02_ram/docs/report.md
	@echo 03_fifo/docs/report.md
	@echo 04_uart_rx/docs/report.md
	@echo 05_uart_tx/docs/report.md
	@echo 06_spi_master/docs/report.md
	@echo 07_spi_slave/docs/report.md
	@echo 08_i2c_master/docs/report.md
	@echo 09_i2c_slave/docs/report.md

check-module:
	@case " $(MODULES) " in *" $(MODULE) "*) ;; *) echo "Unknown MODULE='$(MODULE)'. Use one of: $(MODULES)"; exit 1;; esac

module-help compile build run coverage urg wave verdi verdi_cov verdi_all clean: check-module
	$(MAKE) -C $(MODULE) $(if $(filter module-help,$@),help,$@)
