PYTHON ?= python3
PYTHON_PIP ?= $(PYTHON) -m pip
PYTHON_VIRTUALENV_DIR ?= pyenv
PYTHON_PIP_VERSION_SPECIFIER ?= >=21.1.2
PYTHON_SETUPTOOLS_VERSION_SPECIFIER ?= >=57.0.0
PYTHON_WHEEL_VERSION_SPECIFIER ?= >=0.36.2
PYTHON_PIP_TOOLS_VERSION_SPECIFIER ?= >=6.1.0
PYTHON_PIP_TOOLS_SRC_FILES ?= requirements.in
PYTHON_PIP_TOOLS_COMPILE_ARGS ?= --allow-unsafe --strip-extras --quiet

.PHONY: python-pip-install
python-pip-install: ## Install Pip
	$(PYTHON_PIP) install 'pip$(PYTHON_PIP_VERSION_SPECIFIER)'

.PHONY: python-setuptools-install
python-setuptools-install: ## Install Setuptools
	$(PYTHON_PIP) install 'setuptools$(PYTHON_SETUPTOOLS_VERSION_SPECIFIER)'

.PHONY: python-wheel-install
python-wheel-install: ## Install Wheel
	$(PYTHON_PIP) install 'wheel$(PYTHON_WHEEL_VERSION_SPECIFIER)'

.PHONY: python-deps-compile
python-deps-compile: $(patsubst %,python-deps-compile-%,$(PYTHON_PIP_TOOLS_SRC_FILES))
python-deps-compile: ## Compile Python dependency manifests

python-deps-compile-%:
	pip-compile $(PYTHON_PIP_TOOLS_COMPILE_ARGS) "$(*)"

.PHONY: python-deps-sync-check
python-deps-sync-check: $(patsubst %,python-deps-sync-check-%,$(PYTHON_PIP_TOOLS_SRC_FILES))
python-deps-sync-check: ## Check that compiled Python dependency manifests are up-to-date with their sources

python-deps-sync-check-%: python-deps-compile-%
	@# Replace file extension of source Python dependency manifest (.in)
	@# with file extension of compiled Python dependency manifest (.txt).
	git diff --exit-code -- "$(*:.in=.txt)"

.PHONY: python-virtualenv
python-virtualenv: ## Create virtual Python environment
	$(PYTHON) -m venv "$(PYTHON_VIRTUALENV_DIR)"

.PHONY: python-pip-tools-install
python-pip-tools-install: ## Install Pip Tools
	$(PYTHON_PIP) install 'pip-tools$(PYTHON_PIP_TOOLS_VERSION_SPECIFIER)'
