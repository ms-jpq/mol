ubuntu_CLOUD := $(shell ./libexec/which-lts.ubuntu.sh)
ubuntu_CLOUD_IMG := $(VAR)/$(notdir $(ubuntu_CLOUD))
ubuntu_RAW := $(basename $(ubuntu_CLOUD_IMG)).raw

$(ubuntu_RAW): $(ubuntu_CLOUD_IMG)
	qemu-img convert -f qcow2 -O raw -p -- '$<' '$@'

$(eval $(call TEMPLATE,ubuntu))
