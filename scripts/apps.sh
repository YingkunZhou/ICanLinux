#!/bin/bash

set -e

. conf/scripts.config

if [ -z $(which ${CROSS_COMPILE}-gcc) ]; then
    echo "error: ${CROSS_COMPILE}-gcc not found" && exit 1
fi

make -C riscv-rootfs

# TODO: well, linux kernel v4.19 works but the latest v5.13 (master branch) failed, still looking for the reason!!!
mkdir -p ${KERNEL}
cp conf/emu_defconfig ${KERNEL}/.config
# make ARCH=riscv CROSS_COMPILE=${CROSS_COMPILE}- oldconfig
# O=${must be absolute path}
make -C ${LINUX} O=${PWD}/${KERNEL} RISCV_ROOTFS_HOME=${PWD}/${RISCV_ROOTFS} ARCH=${ISA} CROSS_COMPILE=${CROSS_COMPILE}- olddefconfig
make -C ${LINUX} O=${PWD}/${KERNEL} RISCV_ROOTFS_HOME=${PWD}/${RISCV_ROOTFS} ARCH=${ISA} CROSS_COMPILE=${CROSS_COMPILE}- all -j$(nproc)
# remake -C ${LINUX} O=${PWD}/${KERNEL} ARCH=${ISA} CROSS_COMPILE=${CROSS_COMPILE}- all --profile

# and then, bbl.sh
./scripts/bbl_apps.sh
