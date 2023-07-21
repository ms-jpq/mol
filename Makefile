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
	rm -rf -- '$(VAR)/'*.html '$(VAR)/cloud-init'

clobber: clean
	shopt -u failglob
	rm -rf -- '$(VAR)'

VAR := ./var
CURL := curl --fail --location --output
CLOUD_INIT := $(VAR)/cloud-init.iso

NAME ?= _
ARGV ?=
QEMU_OPTS := --ssh "$$$${SSH:-"127.0.0.1:$$$$(./libexec/ssh-port.sh)"}" --smbios "$$$$(./libexec/authorized_keys.sh)" --drive $(CLOUD_INIT) $$(ARGV)

lint:
	shellcheck -- **/*.sh

help: ./README.md
	cat -- '$<'

$(VAR):
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

.PHONY: root.$1 run.$1 qm.$1 clobber.$1

$1_VM := $(VAR)/$(NAME).$1.vm
$1_RUN := $$($1_VM)/run.raw
$1_LOG := $$($1_VM)/qemu.log
$1_SOCK := $$($1_VM)/qemu.sock

$$($1_CLOUD_IMG): | $(VAR)
	$(CURL) '$$@' -- '$$($1_CLOUD)'

root.$1: $$($1_RAW)

$$($1_VM):
	mkdir -v -p -- '$$@'

$$($1_RUN): | $$($1_RAW) $$($1_VM)
	cp -f -- '$$($1_RAW)' '$$@'
	qemu-img resize -f raw -- '$$@' +88G

run.$1: $$($1_RUN) $(CLOUD_INIT)
	./libexec/run.sh --drive '$$<' --log '$$($1_LOG)' --monitor '$$($1_SOCK)' $(QEMU_OPTS)

qm.$1: $$($1_SOCK)
	socat 'READLINE,history=$$($1_VM)/qm_history' UNIX-CONNECT:'$$<'

clobber.$1:
	rm -v -rf -- '$$($1_VM)'

endef

include makelib/*.mk
