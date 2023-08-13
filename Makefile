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

.PHONY: clean clobber lint c-i

clean:
	shopt -u failglob
	rm -rf -- '$(CACHE)/'*.html '$(VAR)/vm/cloud-init' '$(VAR)/vm/'*.{iso,log,hist}

clobber: clean
	shopt -u failglob
	rm -rf -- '$(VAR)'

VAR := ./var
CACHE := $(VAR)/cache
LIB := $(VAR)/lib
CURL := curl --fail --location --output

NAME ?= _

lint:
	shellcheck -- **/*.sh

help: ./README.md
	cat -- '$<' >&2

$(VAR) $(CACHE) $(LIB):
	mkdir -v -p -- '$@'

CLOUD_INIT := $(shell printf -- '%s ' ./cloud-init/**/*)


define TEMPLATE
.PHONY: root.$1 run.$1 clobber.$1

$1_VM := $(LIB)/$(NAME).$1
$1_RUN := $$($1_VM)/run.raw
$1_CI := $$($1_VM)/cloud-init

$$($1_CLOUD_IMG): | $(CACHE)
	$(CURL) '$$@' -- '$$($1_CLOUD)'

root.$1: $$($1_RAW)

$$($1_VM): | $(LIB)
	mkdir -v -p -- '$$@'

$$($1_RUN): | $$($1_RAW) $$($1_VM)
	cp -f -- '$$($1_RAW)' '$$@'
	qemu-img resize -f raw -- '$$@' +88G

$$($1_CI): $(CLOUD_INIT) | $$($1_VM)
	mkdir -v -p -- '$$@'
	./libexec/cloud-init.sh '$(NAME)' '$$@'
	touch -- '$$@'

$$($1_CI).iso: $$($1_CI)
	hdiutil makehybrid -iso -joliet -default-volume-name cidata -o '$$@' '$$<'

run.$1: $$($1_RUN) $$($1_CI).iso

clobber.$1:
	rm -v -rf -- '$$($1_VM)'
endef

include makelib/*.mk
