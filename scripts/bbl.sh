#!/bin/bash

set -e

. conf/scripts.config

if [ -z $(which ${CROSS_COMPILE}-strip) ]; then
    echo "error: ${CROSS_COMPILE}-strip not found" && exit 1
fi

# can launch linux kernel v4.20 v5.1 master
rm ${BBL} -rf
mkdir ${BBL}

cd ${BBL}
${RISCV_PK}/configure --enable-logo --host=${CROSS_COMPILE} --with-payload=../${KERNEL}/vmlinux
# cp ../sample/bbl_logo_file .   # optional
make -j$(nproc)
chmod 755 bbl
${CROSS_COMPILE}-strip bbl
