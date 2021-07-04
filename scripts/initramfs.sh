#!/bin/bash

set -e

. conf/scripts.config

if [ -z $(which ${CROSS_COMPILE}-gcc) ]; then
    echo "error: ${CROSS_COMPILE}-gcc not found" && exit 1
fi

rm ${INITRAMFS} -rf
mkdir -p ${INITRAMFS}
cp conf/buildroot_initramfs_config ${INITRAMFS}/.config
make -C ${BUILDROOT} RISCV=${RISCV} O=${PWD}/${INITRAMFS} olddefconfig
make -C ${BUILDROOT} RISCV=${RISCV} O=${PWD}/${INITRAMFS}
rm ${SYSROOT} -rf
mkdir -p ${SYSROOT}
tar -xpf ${INITRAMFS}/images/rootfs.tar -C ${SYSROOT} --exclude ./dev --exclude ./usr/share/locale
make -C ${KERNEL} ARCH=${ISA} CROSS_COMPILE=${CROSS_COMPILE}- INSTALL_MOD_PATH=$PWD/${SYSROOT} modules_install
cd ${KERNEL}
${LINUX}/usr/gen_initramfs.sh -o ../${RAM_FILE} -u $(id -u) -g $(id -g) ../conf/initramfs.txt ../${SYSROOT}
