#!/bin/bash

set -e

. conf/scripts.config

if [ -z $(which ${CROSS_COMPILE}-gcc) ]; then
    echo "error: ${CROSS_COMPILE}-gcc not found" && exit 1
fi

rm ${ROOTFS} -rf
mkdir -p ${ROOTFS}
cp conf/buildroot_rootfs_config ${ROOTFS}/.config
make -C ${BUILDROOT} RISCV=${RISCV} O=${PWD}/${ROOTFS} olddefconfig
make -C ${BUILDROOT} RISCV=${RISCV} O=${PWD}/${ROOTFS}
cp ${ROOTFS}/images/rootfs.ext4 ${ROOT_FILE}
