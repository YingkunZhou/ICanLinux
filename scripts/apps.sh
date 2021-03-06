#!/bin/bash

set -e

. conf/scripts.config

if [ -z $(which ${CROSS_COMPILE}-gcc) ]; then
    echo "error: ${CROSS_COMPILE}-gcc not found" && exit 1
fi

make -C ${RISCV_ROOTFS} RISCV=${RISCV}
cp ${BUSYBOX}/busybox ${RISCV_ROOTFS}/rootfsimg/build
cp ${DROPBEAR}/dropbear ${RISCV_ROOTFS}/rootfsimg/build

# TODO: well, linux kernel v4.19 works but the latest v5.13 (master branch) failed, still looking for the reason!!!
# FIXME: now, only failed in the latest version v5.13 (still in Development stage), so don't try it.
# the recommendation of kernel version is v5.4.x or v5.10.x because they are LTS

mkdir -p ${KERNEL}
# make ARCH=riscv CROSS_COMPILE=${CROSS_COMPILE}- oldconfig
# O=${must be absolute path}
cp conf/emu_defconfig ${KERNEL}/.config
make -C ${LINUX} O=${PWD}/${KERNEL} RISCV_ROOTFS_HOME=${PWD}/${RISCV_ROOTFS} ARCH=${ISA} CROSS_COMPILE=${CROSS_COMPILE}- olddefconfig
make -C ${LINUX} O=${PWD}/${KERNEL} RISCV_ROOTFS_HOME=${PWD}/${RISCV_ROOTFS} ARCH=${ISA} CROSS_COMPILE=${CROSS_COMPILE}- vmlinux -j$(nproc)
# remake -C ${LINUX} O=${PWD}/${KERNEL} ARCH=${ISA} CROSS_COMPILE=${CROSS_COMPILE}- all --profile

# and then, bbl.sh
./scripts/apps-bbl.sh
