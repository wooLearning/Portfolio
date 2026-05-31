.PHONY: help compile build lint run coverage urg wave verdi verdi_cov verdi_all clean

help:
	$(MAKE) -C tb help

compile build lint run coverage urg wave verdi verdi_cov verdi_all clean:
	$(MAKE) -C tb $(if $(filter build,$@),compile,$@)
