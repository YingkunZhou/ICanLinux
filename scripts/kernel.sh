#!/bin/bash

set -e

. conf/scripts.config

if [ -z $(which ${CROSS_COMPILE}-gcc) ]; then
    echo "error: ${CROSS_COMPILE}-gcc not found" && exit 1
fi

mkdir -p kernel
cp sample/kernel.config ${KERNEL}/.config
# make ARCH=riscv CROSS_COMPILE=${CROSS_COMPILE}- oldconfig
# O=${must be absolute path}
make -C ${LINUX} O=${PWD}/${KERNEL} ARCH=${ISA} CROSS_COMPILE=${CROSS_COMPILE}- olddefconfig
make -C ${LINUX} O=${PWD}/${KERNEL} ARCH=${ISA} CROSS_COMPILE=${CROSS_COMPILE}- all -j$(nproc)
