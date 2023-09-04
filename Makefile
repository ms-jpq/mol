MAKEFLAGS += --check-symlink-times
MAKEFLAGS += --jobs
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
MAKEFLAGS += --shuffle
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.DELETE_ON_ERROR:
.FORCE:
.ONESHELL:
.SHELLFLAGS := -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar -c

.DEFAULT_GOAL := help

.PHONY: clean clobber lint

clean:
	shopt -u failglob
	rm -rf -- '$(LIB)/*/cloud-init*'

clobber: clean
	shopt -u failglob
	rm -rf -- '$(VAR)'

VAR := ./var
CACHE := $(VAR)/cache
LIB := $(VAR)/lib
CURL := curl --fail --location --output

HOSTTYPE := $(shell printf -- '%s' "$$HOSTTYPE")
NAME ?= _

lint:
	shellcheck -- **/*.sh

help: ./README.md
	cat -- '$<' >&2

$(VAR) $(CACHE) $(LIB):
	mkdir -v -p -- '$@'

include makelib/*.mk
