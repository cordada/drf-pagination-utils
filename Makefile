SHELL = /usr/bin/env bash -e -o pipefail

# Sources Root
SOURCES_ROOT = $(CURDIR)/src

# Python
PYTHON = python3
PYTHON_PIP = $(PYTHON) -m pip
PYTHON_PIP_VERSION_SPECIFIER = ==23.1.2
PYTHON_SETUPTOOLS_VERSION_SPECIFIER = ==70.3.0
PYTHON_WHEEL_VERSION_SPECIFIER = ~=0.38.4
PYTHON_VIRTUALENV_DIR = .pyenv
PYTHON_PIP_TOOLS_VERSION_SPECIFIER = ==6.14.0
PYTHON_PIP_TOOLS_SRC_FILES = requirements.in requirements-dev.in

# Django Admin
DJANGO_ADMIN = $(PYTHON) $(SOURCES_ROOT)/manage.py

# Black
BLACK = black --config .black.cfg.toml

# Mypy
MYPY_CACHE_DIR = $(CURDIR)/.mypy_cache

# Coverage.py
COVERAGE = coverage
COVERAGE_TEST_RCFILE = $(CURDIR)/.coveragerc.test.ini
COVERAGE_TEST_DATA_FILE = $(CURDIR)/.test.coverage

# Test Reports
TEST_REPORT_DIR = $(CURDIR)/test_reports

include make/_common/help.mk
include make/django.mk
include make/python.mk
include make/vcs.mk

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "$@: Read README.md"
	@echo
	@$(MAKE) -s help-tasks

.PHONY: clean
clean: clean-build
clean: ## Delete temporary files, logs, cached files, build artifacts, etc.
	find . -iname __pycache__ -type d -prune -exec rm -r {} \;
	find . -iname '*.py[cod]' -delete

	$(RM) -r "$(MYPY_CACHE_DIR)"
	$(RM) -r "$(COVERAGE_TEST_DATA_FILE)"
	$(RM) -r "$(TEST_REPORT_DIR)"

.PHONY: clean-all
clean-all: clean
clean-all: ## Delete (almost) everything that can be reconstructed later
	$(RM) -r *.egg-info/

.PHONY: clean-build
clean-build: ## Remove build artifacts
	$(RM) -r .eggs/
	$(RM) -r build/
	$(RM) -r dist/

	find . -name '*.egg-info' -exec $(RM) -r {} +
	find . -name '*.egg' -exec $(RM) {} +

.PHONY: install
install: install-deps
install: ## Install
	$(PYTHON_PIP) install --editable .
	$(PYTHON_PIP) check

.PHONY: install-dev
install-dev: install-deps-dev
install-dev: ## Install for development
	$(PYTHON_PIP) install --editable .
	$(PYTHON_PIP) check

.PHONY: install-deps
install-deps: python-pip-install
install-deps: ## Install dependencies
	$(PYTHON_PIP) install -r requirements.txt
	$(PYTHON_PIP) check

.PHONY: install-deps-dev
install-deps-dev: install-deps
install-deps-dev: python-pip-tools-install
install-deps-dev: ## Install dependencies for development
	$(PYTHON_PIP) install -r requirements-dev.txt
	$(PYTHON_PIP) check

.PHONY: build
build: ## Build Python package
	$(PYTHON) setup.py build

.PHONY: dist
dist: build
dist: ## Create Python package distribution
	$(PYTHON) setup.py sdist
	$(PYTHON) setup.py bdist_wheel

.PHONY: upload-release
upload-release: ## Upload dist packages
	$(PYTHON) -m twine upload 'dist/*'

.PHONY: deploy
deploy: upload-release
deploy: ## Deploy or publish

.PHONY: lint
lint: FLAKE8_FILES = *.py "$(SOURCES_ROOT)"
lint: ISORT_FILES = *.py "$(SOURCES_ROOT)"
lint: BLACK_SRC = *.py "$(SOURCES_ROOT)"
lint: ## Run linters
	flake8 $(FLAKE8_FILES)
	mypy
	isort --check-only $(ISORT_FILES)
	$(PYTHON) setup.py check --metadata
	$(BLACK) --check $(BLACK_SRC)

.PHONY: lint-report
lint-report: FLAKE8_FILES = *.py "$(SOURCES_ROOT)"
lint-report: FLAKE8_JUNIT_REPORT_DIR = $(TEST_REPORT_DIR)/junit/flake8
lint-report: MYPY_JUNIT_REPORT_DIR = $(TEST_REPORT_DIR)/junit/mypy
lint-report: ## Run linters and generate reports
	mkdir -p "$(FLAKE8_JUNIT_REPORT_DIR)"
	-flake8 --format junit-xml --output-file "$(FLAKE8_JUNIT_REPORT_DIR)/report.junit.xml" $(FLAKE8_FILES)

	mkdir -p "$(MYPY_JUNIT_REPORT_DIR)"
	-mypy --no-pretty --junit-xml "$(MYPY_JUNIT_REPORT_DIR)/report.junit.xml"

.PHONY: lint-fix
lint-fix: BLACK_SRC = *.py "$(SOURCES_ROOT)"
lint-fix: ISORT_FILES = *.py "$(SOURCES_ROOT)"
lint-fix: ## Fix lint errors
	$(BLACK) $(BLACK_SRC)
	isort $(ISORT_FILES)

.PHONY: test
test: DJANGO_ADMIN_TEST_TEST_LABELS ?= "$(SOURCES_ROOT)"
test: django-test
test: ## Run tests

.PHONY: test-report
test-report: export DJANGO_ADMIN_TEST_TEST_LABELS ?= "$(SOURCES_ROOT)"
test-report: django-test-report
test-report: ## Run tests and generate reports

.PHONY: test-coverage
test-coverage: DJANGO_ADMIN_TEST_TEST_LABELS ?= "$(SOURCES_ROOT)"
test-coverage: PYTHON =
test-coverage: export COVERAGE_RCFILE = $(COVERAGE_TEST_RCFILE)
test-coverage: export COVERAGE_FILE = $(COVERAGE_TEST_DATA_FILE)
test-coverage: django-test-coverage
test-coverage: ## Run tests and measure code coverage

.PHONY: test-coverage-report
test-coverage-report: export COVERAGE_RCFILE = $(COVERAGE_TEST_RCFILE)
test-coverage-report: export COVERAGE_FILE = $(COVERAGE_TEST_DATA_FILE)
test-coverage-report: ## Run tests, measure code coverage, and generate reports
	$(COVERAGE) report
	$(COVERAGE) xml
	$(COVERAGE) html
