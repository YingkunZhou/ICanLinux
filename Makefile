ISA ?= rv64imafdc
ABI ?= lp64d

kernel:
	./scripts/kernel.sh

bbl:
	./scripts/bbl.sh

busybox:
	./scripts/busybox.sh

dropbear:
	./scripts/ssh.sh

riscv-disk:
	./scripts/disk.sh

busybear.bin:
	sudo env PATH=$(PATH) UID=$(shell id -u) GID=$(shell id -g) \
	./scripts/image.sh

initramfs:
	./scripts/initramfs.sh

rootfs:
	./scripts/rootfs.sh

# DISK=/home/zhou/workspace/riscv/freedom-u-sdk/work/rootfs.bin
BBL = bootloader/bbl
# if -bios none option omit, qemu will use opensbi bios boot loader as default.
# and specify(uncomment) following kernel image
# BBL=../linux/arch/riscv/boot/Image
QEMU = /home/zhou/workspace/dbt/qemu/build/qemu-system-riscv64

DISK_FILE = disk/riscv_disk
GUEST_IP = 10.0.2.20
# user talnet
# $ telnet localhost 2323
busybox-run:
	$(QEMU) \
		-nographic \
		-machine virt \
		-m 128 \
		-bios none \
		-kernel $(BBL) \
		-append "root=/dev/vda ro" \
		-drive file=$(DISK_FILE),format=raw,id=hd0      \
		-device virtio-blk-device,drive=hd0       \
		-netdev user,id=net0,hostfwd=tcp::2323-$(GUEST_IP):23,hostfwd=tcp::8080-$(GUEST_IP):80 \
		-device virtio-net-device,netdev=net0

IMAGE_FILE = disk/busybear.bin

# kernel ssh
# ssh root@192.168.122.2
busybear-run:
	sudo $(QEMU) \
		-nographic \
		-machine virt \
		-bios none \
		-kernel $(BBL) \
		-append "root=/dev/vda ro console=ttyS0" \
		-drive file=$(IMAGE_FILE),format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0 \
		-netdev type=tap,script=scripts/ifup.sh,downscript=scripts/ifdown.sh,id=net0 \
		-device virtio-net-device,netdev=net0
# DO NOT press CTRL-a + x to quit QEMU force shutdown the system.
# Otherwise the disk network will crashed. Though, I don't know why
# Note: the disk image is stateful and needs to be shutdown cleanly.
# https://github.com/michaeljclark/busybear-linux.git

INITRAMFS = disk/initramfs.cpio.gz
initramfs-run:
	$(QEMU) \
		-nographic \
		-machine virt \
		-bios none \
		-kernel $(BBL) \
		-initrd $(INITRAMFS) \
		-netdev user,id=net0 \
		-device virtio-net-device,netdev=net0

ROOTFS = disk/rootfs.ext4
rootfs-run:
	$(QEMU) \
		-nographic \
		-machine virt \
		-bios none \
		-kernel $(BBL) \
		-initrd $(INITRAMFS) \
		-drive file=$(ROOTFS),format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0 \
		-netdev user,id=net0 \
		-device virtio-net-device,netdev=net0


FED = Minimal
VER = 20200108.n.0

fedora-run:
	$(QEMU) \
		-nographic \
		-machine virt \
		-smp 4 \
		-m 3G \
		-kernel disk/Fedora-$(FED)-Rawhide-$(VER)-fw_payload-uboot-qemu-virt-smode.elf \
		-bios none \
		-object rng-random,filename=/dev/urandom,id=rng0 \
		-device virtio-rng-device,rng=rng0 \
		-device virtio-blk-device,drive=hd0 \
		-drive file=disk/Fedora-$(FED)-Rawhide-$(VER)-sda.raw,format=raw,id=hd0 \
		-device virtio-net-device,netdev=usernet \
		-netdev user,id=usernet,hostfwd=tcp::3333-:22

GITID := $(shell git describe --dirty --always)
fit := image-$(GITID).fit
vfat_image := hifive-unleashed-vfat.part
flash_image := hifive-unleashed-$(GITID).gpt
uboot_wrkdir := uboot
uboot := $(uboot_wrkdir)/u-boot.bin
confdir := conf
initramfs := disk/initramfs.cpio.gz
bbl := bootloader/bbl
bbl_bin := bbl.bin
vmlinux := kernel/vmlinux
vmlinux_bin := vmlinux.bin

$(vmlinux_bin): $(vmlinux)
	riscv64-unknown-linux-gnu-objcopy -O binary $< $@

$(bbl_bin): $(bbl)
	riscv64-unknown-linux-gnu-objcopy -S -O binary --change-addresses -0x80000000 $< $@

$(uboot): $(uboot_srcdir) $(target_gcc)
	rm -rf $(uboot_wrkdir)
	mkdir -p $(uboot_wrkdir)
	mkdir -p $(dir $@)
	$(MAKE) -C ../freedom-u-sdk/HiFive_U-Boot O=$(uboot_wrkdir) HiFive-U540_regression_defconfig
	$(MAKE) -C ../freedom-u-sdk/HiFive_U-Boot O=$(uboot_wrkdir) CROSS_COMPILE=riscv64-unknown-linux-gnu-

$(fit): $(bbl_bin) $(vmlinux_bin) $(uboot) $(initramfs) $(confdir)/uboot-fit-image.its
	$(uboot_wrkdir)/tools/mkimage -f $(confdir)/uboot-fit-image.its -A riscv -O linux -T flat_dt $@

# Relevant partition type codes
BBL		= 2E54B353-1271-4842-806F-E436D6AF6985
VFAT            = EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
LINUX		= 0FC63DAF-8483-4772-8E79-3D69D8477DE4
#FSBL		= 5B193300-FC78-40CD-8002-E86C45580B47
UBOOT		= 5B193300-FC78-40CD-8002-E86C45580B47
UBOOTENV	= a09354ac-cd63-11e8-9aff-70b3d592f0fa
UBOOTDTB	= 070dd1a8-cd64-11e8-aa3d-70b3d592f0fa
UBOOTFIT	= 04ffcafa-cd65-11e8-b974-70b3d592f0fa

VFAT_START=2048
VFAT_END=65502
VFAT_SIZE=63454
UBOOT_START=1100
UBOOT_END=2020
UBOOT_SIZE=950
UENV_START=1024
UENV_END=1099
RESERVED_SIZE=2000

vfat_image: $(vfat_image)

$(vfat_image): $(fit) $(confdir)/uEnv.txt
	@if [ `du --apparent-size --block-size=512 $(uboot) | cut -f 1` -ge $(UBOOT_SIZE) ]; then \
		echo "Uboot is too large for partition!!\nReduce uboot or increase partition size"; \
		rm $(flash_image); exit 1; fi
	dd if=/dev/zero of=$(vfat_image) bs=1024 count=$(VFAT_SIZE)
	/sbin/mkfs.vfat $(vfat_image)
	MTOOLS_SKIP_CHECK=1 mcopy -i $(vfat_image) $(fit) ::hifiveu.fit
	MTOOLS_SKIP_CHECK=1 mcopy -i $(vfat_image) $(confdir)/uEnv.txt ::uEnv.txt

flash_image : $(flash_image)

$(flash_image): $(uboot) $(fit) $(vfat_image)
	dd if=/dev/zero of=$(flash_image) bs=1M count=64
	/sbin/sgdisk --clear  \
		--new=1:$(VFAT_START):$(VFAT_END)  --change-name=1:"Vfat Boot"	--typecode=1:$(VFAT)   \
		--new=3:$(UBOOT_START):$(UBOOT_END)   --change-name=3:uboot	--typecode=3:$(UBOOT) \
		--new=4:$(UENV_START):$(UENV_END)   --change-name=4:uboot-env	--typecode=4:$(UBOOTENV) \
		$(flash_image)
	dd conv=notrunc if=$(vfat_image) of=$(flash_image) bs=1024 seek=$(VFAT_START)
	dd conv=notrunc if=$(uboot) of=$(flash_image) bs=1024 seek=$(UBOOT_START) count=$(UBOOT_SIZE)

.PHONY: format-boot-loader
format-boot-loader: $(bbl_bin) $(uboot) $(fit) $(vfat_image)
	@test -b $(DISK) || (echo "$(DISK): is not a block device"; exit 1)
	$(eval DEVICE_NAME := $(shell basename $(DISK)))
	$(eval SD_SIZE := $(shell cat /sys/block/$(DEVICE_NAME)/size))
	$(eval ROOT_SIZE := $(shell expr $(SD_SIZE) \- $(RESERVED_SIZE)))
	/sbin/sgdisk --clear  \
		--new=1:$(VFAT_START):$(VFAT_END)  --change-name=1:"Vfat Boot"	--typecode=1:$(VFAT)   \
		--new=2:264192:$(ROOT_SIZE) --change-name=2:root	--typecode=2:$(LINUX) \
		--new=3:$(UBOOT_START):$(UBOOT_END)   --change-name=3:uboot	--typecode=3:$(UBOOT) \
		--new=4:$(UENV_START):$(UENV_END)  --change-name=4:uboot-env	--typecode=4:$(UBOOTENV) \
		$(DISK)
	-/sbin/partprobe
	@sleep 1
ifeq ($(DISK)p1,$(wildcard $(DISK)p1))
	@$(eval PART1 := $(DISK)p1)
	@$(eval PART2 := $(DISK)p2)
	@$(eval PART3 := $(DISK)p3)
	@$(eval PART4 := $(DISK)p4)
else ifeq ($(DISK)s1,$(wildcard $(DISK)s1))
	@$(eval PART1 := $(DISK)s1)
	@$(eval PART2 := $(DISK)s2)
	@$(eval PART3 := $(DISK)s3)
	@$(eval PART4 := $(DISK)s4)
else ifeq ($(DISK)1,$(wildcard $(DISK)1))
	@$(eval PART1 := $(DISK)1)
	@$(eval PART2 := $(DISK)2)
	@$(eval PART3 := $(DISK)3)
	@$(eval PART4 := $(DISK)4)
else
	@echo Error: Could not find bootloader partition for $(DISK)
	@exit 1
endif
	dd if=$(uboot) of=$(PART3) bs=4096
	dd if=$(vfat_image) of=$(PART1) bs=4096

DEMO_IMAGE	:= sifive-debian-demo-mar7.tar.xz
DEMO_URL	:= https://github.com/tmagik/freedom-u-sdk/releases/download/hifiveu-2.0-alpha.1/

$(DEMO_IMAGE):
	wget $(DEMO_URL)$(DEMO_IMAGE)

format-buildroot-image: format-boot-loader
	/sbin/mke2fs -t ext4 $(PART2)
	-mkdir tmp-mnt
	sudo mount $(PART2) tmp-mnt && cd tmp-mnt && \
		gunzip -c $(initramfs) | sudo cpio -i
	sudo umount tmp-mnt

format-demo-image: $(DEMO_IMAGE) format-boot-loader
	@echo "Done setting up basic initramfs boot. We will now try to install"
	@echo "a Debian snapshot to the Linux partition, which requires sudo"
	@echo "you can safely cancel here"
	/sbin/mke2fs -L ROOTFS -t ext4 $(PART2)
	-mkdir tmp-mnt
	-sudo mount $(PART2) tmp-mnt && cd tmp-mnt && \
		sudo tar -Jxf ../$(DEMO_IMAGE) -C .
	sudo umount tmp-mnt

all: $(fit) $(flash_image)
	@echo
	@echo "GPT (for SPI flash or SDcard) and U-boot Image files have"
	@echo "been generated for an ISA of $(ISA) and an ABI of $(ABI)"
	@echo
	@echo $(fit)
	@echo $(flash_image)
	@echo
	@echo "To completely erase, reformat, and program a disk sdX, run:"
	@echo "  make DISK=/dev/sdX format-boot-loader"
	@echo "  ... you will need gdisk and e2fsprogs installed"
	@echo "  Please note this will not currently format the SDcard ext4 partition"
	@echo "  This can be done manually if needed"
	@echo

-include $(initramfs).d
