.PHONY: virtio-win

VIRTIO_WIN_IMG := https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
VIRTIO_WIN := $(VAR)/$(notdir $(VIRTIO_WIN_IMG))

virtio-win: $(VIRTIO_WIN)
$(VIRTIO_WIN): | $(VAR)
	$(CURL) '$@' -- '$(VIRTIO_WIN_IMG)'
