fedora_CLOUD := $(shell ./libexec/which-recent.fedora.sh $(VAR)/fedoras.html)
fedora_CLOUD_IMG := $(VAR)/$(notdir $(fedora_CLOUD))
fedora_RAW := $(basename $(fedora_CLOUD_IMG))

$(fedora_RAW): $(fedora_CLOUD_IMG)
	gunzip --decompress --keep -- '$<'
	touch -- '$@'

$(eval $(call TEMPLATE,fedora))
