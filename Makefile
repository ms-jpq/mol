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
	rm -rf -- '$(CACHE)/'*.html '$(CACHE)/cloud-init' '$(VAR)/vm/'*.{log,hist}

clobber: clean
	shopt -u failglob
	rm -rf -- '$(VAR)'

VAR := ./var
CACHE := $(VAR)/cache
LIB := $(VAR)/lib
CURL := curl --fail --location --output
CLOUD_INIT := $(CACHE)/cloud-init.iso

NAME ?= _

lint:
	shellcheck -- **/*.sh

help: ./README.md
	cat -- '$<'

$(VAR) $(CACHE) $(LIB):
	mkdir -v -p -- '$@'

$(CACHE)/cloud-init: | $(CACHE)
	mkdir -v -p -- '$@'

$(CACHE)/cloud-init/meta-data: ./cloud-init/meta-data | $(CACHE)/cloud-init
	cat -- '$<' | ./libexec/envsubst.pl >'$@'

$(CACHE)/cloud-init/user-data: ./cloud-init/user-data | $(CACHE)/cloud-init
	shopt -u failglob
	export -- PASSWD AUTHORIZED_KEYS
	PASSWD="$$(openssl passwd -1 -salt "$$(uuidgen)" root)"
	AUTHORIZED_KEYS="$$(cat -- ~/.ssh/*.pub)"
	cat -- '$<' | ./libexec/envsubst.pl >'$@'

c-i: $(CLOUD_INIT)
$(CLOUD_INIT): $(CACHE)/cloud-init $(CACHE)/cloud-init/meta-data $(CACHE)/cloud-init/user-data
	rm -v -fr -- '$@'
	hdiutil makehybrid -iso -joliet -default-volume-name cidata -o '$@' '$<'


define TEMPLATE

.PHONY: root.$1 run.$1 clobber.$1

$1_VM := $(LIB)/$(NAME).$1
$1_RUN := $$($1_VM)/run.raw

$$($1_CLOUD_IMG): | $(CACHE)
	$(CURL) '$$@' -- '$$($1_CLOUD)'

root.$1: $$($1_RAW)

$$($1_VM): | $(LIB)
	mkdir -v -p -- '$$@'

$$($1_RUN): | $$($1_RAW) $$($1_VM)
	cp -f -- '$$($1_RAW)' '$$@'
	qemu-img resize -f raw -- '$$@' +88G

run.$1: $$($1_RUN) $(CLOUD_INIT)

clobber.$1:
	rm -v -rf -- '$$($1_VM)'

endef

include makelib/*.mk
