#!/bin/bash

set -e

. conf/scripts.config

if [ -z $(which riscv64-unknown-elf-gcc) ]; then
    echo "error: riscv64-unknown-elf-gcc not found" && exit 1
fi

rm ${BBL} -rf
mkdir ${BBL}

dtc -O dtb -I dts -o ${BBL}/system.dtb dts/system.dts

cd ${BBL}
${RISCV_PK}/configure --enable-logo --host=riscv64-unknown-elf --with-payload=../kernel/vmlinux #--with-arch=rv64imac
# if you really need rv64imac, patch
# cp ../sample/bbl_logo_file .   # optional
make -j$(nproc)

# RISCV_COPY_FLAGS=--set-section-flags .bss=alloc,contents --set-section-flags .sbss=alloc,contents -O binary
# $(RISCV_COPY) $(RISCV_COPY_FLAGS) $< $@
# $(RISCV_DUMP) -d $< > $<.txt
