.PHONY: novnc

NPROC = $(shell sysctl -n hw.physicalcpu)

novnc: $(VAR)/noVNC
$(VAR)/noVNC: | $(VAR)
	URI='https://github.com/novnc/noVNC'
	if [[ -d '$@' ]]; then
		cd -- '$@'
		git pull --recurse-submodules --no-tags '--jobs=$(NPROC)'
	else
		git clone --recurse-submodules --shallow-submodules --depth=1 '--jobs=$(NPROC)' -- "$$URI" '$@'
	fi
