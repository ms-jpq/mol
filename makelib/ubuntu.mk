.PHONY: kernel root run clobber.vm

ifeq ($(HOSTTYPE), aarch64)
GOARCH := arm64
else
GOARCH := amd64
endif

$(CACHE)/kernel: $(CACHE)/kernel.elf
	$(OBJCOPY) -O binary $< $@

CLOUD_INIT := $(shell printf -- '%s ' ./cloud-init/**/*)

VERSION_ID := $(shell ./libexec/which-lts.sh)
CLOUD_AT := https://cloud-images.ubuntu.com/releases/$(VERSION_ID)/release
CLOUD := $(CLOUD_AT)/ubuntu-$(VERSION_ID)-server-cloudimg-$(GOARCH).img
KERNEL := $(CLOUD_AT)/unpacked/ubuntu-$(VERSION_ID)-server-cloudimg-$(GOARCH)-vmlinuz-generic
INITRD := $(CLOUD_AT)/unpacked/ubuntu-$(VERSION_ID)-server-cloudimg-$(GOARCH)-initrd-generic

CLOUD_IMG := $(CACHE)/$(notdir $(CLOUD))
KERNEL_IMG := $(CACHE)/$(notdir $(KERNEL))
INITRD_IMG := $(CACHE)/$(notdir $(INITRD))
RAW := $(basename $(CLOUD_IMG)).raw

VM := $(LIB)/$(NAME)
RUN := $(VM)/run.raw
CI := $(VM)/cloud-init

root: $(RAW)
kernel: $(KERNEL_IMG) $(INITRD_IMG)

$(RAW): $(CLOUD_IMG)
	qemu-img convert -f qcow2 -O raw -p -- '$<' '$@'

$(CLOUD_IMG): | $(CACHE)
	$(CURL) '$@' -- '$(CLOUD)'

$(KERNEL_IMG): | $(CACHE)
	$(CURL) '$@' -- '$(KERNEL)'

$(INITRD_IMG): | $(CACHE)
	$(CURL) '$@' -- '$(INITRD)'

$(VM): | $(LIB)
	mkdir -v -p -- '$@'

$(RUN): | $(RAW) $(KERNEL_IMG) $(INITRD_IMG) $(VM)
	cp -f -- '$(RAW)' '$@'
	qemu-img resize -f raw -- '$@' +88G

$(CI): $(CLOUD_INIT) | $(VM)
	mkdir -v -p -- '$@'
	./libexec/cloud-init.sh '$(NAME)' '$@'
	touch -- '$@'

$(CI).iso: $(CI)
	hdiutil makehybrid -iso -joliet -default-volume-name cidata -o '$@' '$<'

run: $(RUN) $(CI).iso

clobber.vm:
	rm -v -rf -- '$(VM)'
