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

# DISK=/home/zhou/workspace/riscv/freedom-u-sdk/work/rootfs.bin
BBL = bootloader/bbl
# if -bios none option omit, qemu will use opensbi bios boot loader as default.
# and specify(uncomment) following kernel image
# BBL=../linux/arch/riscv/boot/Image
QEMU = /home/zhou/workspace/dbt/qemu/build/qemu-system-riscv64

DISK = disk/riscv_disk
GUEST_IP = 10.0.2.20
# user talnet
# $ telnet localhost 2323
busybox-run:
	$(QEMU) \
		-nographic \
		-machine virt \
		-m 128 \
		-kernel $(BBL) \
		-bios none \
		-append "root=/dev/vda ro" \
		-drive file=$(DISK),format=raw,id=hd0      \
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
		-kernel $(BBL) \
		-bios none \
		-append "root=/dev/vda ro console=ttyS0" \
		-drive file=$(IMAGE_FILE),format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0 \
		-netdev type=tap,script=scripts/ifup.sh,downscript=scripts/ifdown.sh,id=net0 \
		-device virtio-net-device,netdev=net0
# DO NOT press CTRL-a + x to quit QEMU force shutdown the system.
# Otherwise the disk network will crashed. Though, I don't know why
# Note: the disk image is stateful and needs to be shutdown cleanly.
# https://github.com/michaeljclark/busybear-linux.git

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
