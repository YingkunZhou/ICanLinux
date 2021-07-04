$(shell mkdir -p rootfsimg/build)

APPS = hello stream redis dwarf/md5 dwarf/sort dwarf/wordcount zlib # strace
APPS_DIR = $(addprefix apps/, $(APPS))

ROOTFS_PATH := $(abspath .)

.PHONY: rootfsimg $(APPS_DIR) clean

rootfsimg: $(APPS_DIR)

$(APPS_DIR): %:
	$(MAKE) -s -C $@ RISCV_ROOTFS_HOME=$(ROOTFS_PATH) install

clean:
	-$(foreach app, $(APPS_DIR), $(MAKE) -s -C $(app) clean ;)
	-rm -f rootfsimg/build/*
