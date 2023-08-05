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
	rm -rf -- '$(VAR)/'*.html '$(VAR)/cloud-init' '$(VAR)/vm/'*.{log,hist}

clobber: clean
	shopt -u failglob
	rm -rf -- '$(VAR)'

VAR := ./var
CURL := curl --fail --location --output
CLOUD_INIT := $(VAR)/cloud-init.iso

NAME ?= _

lint:
	shellcheck -- **/*.sh

help: ./README.md
	cat -- '$<'

$(VAR):
	mkdir -v -p -- '$@'

$(VAR)/vm:
	mkdir -v -p -- '$@'

$(VAR)/cloud-init: | $(VAR)
	mkdir -v -p -- '$@'

$(VAR)/cloud-init/meta-data: ./cloud-init/meta-data | $(VAR)/cloud-init
	cat -- '$<' | ./libexec/envsubst.pl >'$@'

$(VAR)/cloud-init/user-data: ./cloud-init/user-data | $(VAR)/cloud-init
	shopt -u failglob
	export -- PASSWD AUTHORIZED_KEYS
	PASSWD="$$(openssl passwd -1 -salt "$$(uuidgen)" root)"
	AUTHORIZED_KEYS="$$(cat -- ~/.ssh/*.pub)"
	cat -- '$<' | ./libexec/envsubst.pl >'$@'

c-i: $(CLOUD_INIT)
$(CLOUD_INIT): $(VAR)/cloud-init $(VAR)/cloud-init/meta-data $(VAR)/cloud-init/user-data
	rm -v -fr -- '$@'
	hdiutil makehybrid -iso -joliet -default-volume-name cidata -o '$@' '$<'


define TEMPLATE

.PHONY: root.$1 run.$1 clobber.$1

$1_VM := $(VAR)/vm/$(NAME).$1
$1_RUN := $$($1_VM)/run.raw

$$($1_CLOUD_IMG): | $(VAR)
	$(CURL) '$$@' -- '$$($1_CLOUD)'

root.$1: $$($1_RAW)

$$($1_VM):
	mkdir -v -p -- '$$@'

$$($1_RUN): | $$($1_RAW) $$($1_VM)
	cp -f -- '$$($1_RAW)' '$$@'
	qemu-img resize -f raw -- '$$@' +88G

run.$1: $$($1_RUN) $(CLOUD_INIT)

clobber.$1:
	rm -v -rf -- '$$($1_VM)'

endef

include makelib/*.mk
