#!/bin/bash

set -e

. conf/scripts.config

if [ -z $(which ${CROSS_COMPILE}-gcc) ]; then
    echo "error: ${CROSS_COMPILE}-gcc not found" && exit 1
fi

# cp sample/busybox.config ${BUSYBOX}/busybox/.config  # optional for 1_30_1
# cp ${BUSYBOX}/michaeljclark/busybear-linux/conf/busybox.config ${BUSYBOX}/.config  # quite same
cd ${BUSYBOX}
CROSS_COMPILE=${CROSS_COMPILE}- make distclean
# make oldconfig
CROSS_COMPILE=${CROSS_COMPILE}- make defconfig
# Enable static linking under settings to make it easier to prepare the rootFS later.
# https://embeddedinn.xyz/articles/tutorial/Linux-Python-on-RISCV-using-QEMU-from-scratch/
# CROSS_COMPILE=${CROSS_COMPILE}- make menuconfig
# yes "" | make oldconfig
CROSS_COMPILE=${CROSS_COMPILE}- make all -j$(nproc)
CROSS_COMPILE=${CROSS_COMPILE}- make install
