#!/bin/bash

set -e

. conf/scripts.config

#
# locate compiler
#
GCC_DIR=$(dirname $(which ${CROSS_COMPILE}-gcc))/..
if [ ! -d ${GCC_DIR} ]; then
    echo "Cannot locate ${CROSS_COMPILE}-gcc"
    exit 1
fi

mkdir -p mnt
# copy skeleton provided by samples
# etc  root
cp -a ${SAMPLE}/skeleton/* mnt/
# install linux commands provided by busybox
# bin  etc  linuxrc  root  sbin  usr
cp -a ${BUSYBOX}/_install/* mnt/
# install modules from Linux kernel
# bin  etc  lib/modules  linuxrc  root  sbin  usr
make -C ${KERNEL} ARCH=${ISA} CROSS_COMPILE=${CROSS_COMPILE}- INSTALL_MOD_PATH=$PWD/mnt modules_install
# install libraries from toolchain
# bin  etc  lib  linuxrc  root  sbin  usr
cp -a ${GCC_DIR}/sysroot/lib  mnt/
# remove unneeded libraries and files
# bin  etc  lib  root  sbin  usr
cd mnt/lib
rm -f *.a *.la *.spec *fortran* ../linuxrc
# create empty directories
# bin  dev  etc  home  lib  mnt  proc  root  sbin  sys  tmp  usr  var
cd ..
mkdir dev home mnt proc sys tmp var

cd etc/network
mkdir if-down.d  if-post-down.d  if-pre-up.d  if-up.d

cd ../../..

dd if=/dev/zero of=${DISK_FILE} bs=1M count=${DISK_SIZE}
# riscv-rootfs?
mkfs.ext2 -L riscv-rootfs ${DISK_FILE}
sudo mkdir -p /mnt/rootfs
sudo mount ${DISK_FILE} /mnt/rootfs
sudo cp -a mnt/* /mnt/rootfs
rm -rf mnt
sudo chown -R -h root:root /mnt/rootfs
df /mnt/rootfs
sudo umount /mnt/rootfs
file ${DISK_FILE}
#
# remove if configure failed
#
if [[ $? -ne 0 ]]; then
    echo "*** failed to create ${IMAGE_FILE}"
    rm -f ${IMAGE_FILE}
else
    echo "+++ successfully created ${IMAGE_FILE}"
    ls -l ${IMAGE_FILE}
fi

#
# finish
#
sudo rmdir /mnt/rootfs
