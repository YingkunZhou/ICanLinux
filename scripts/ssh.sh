#!/bin/bash

set -e

. conf/scripts.config

if [ -z $(which ${CROSS_COMPILE}-gcc) ]; then
    echo "error: ${CROSS_COMPILE}-gcc not found" && exit 1
fi

cd ${DROPBEAR}
./configure --host=${CROSS_COMPILE} --disable-zlib
make -j$(nproc)
