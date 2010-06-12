.PHONY: help
help:
	@echo
	@echo Type \"make install\" to install the configuration files
	@echo in your home directory.
	@echo

.PHONY: install
install:
	./install

.PHONY: dist
dist:
	zip -r ../config .

