#!/bin/bash

TINYFS="tinyfs.gz"

if [ ! -f "${TINYFS}" ]; then
    echo "Downloading tinyfs.gz..."
    wget https://retis.santannapisa.it/luca/KernelProgramming/Old-20/tinyfs.gz || { echo "Failed to download ${TINYFS}"; exit 1; }
else
    echo "tinyfs.gz already present: ${TINYFS}"
fi

mkdir -p ./tmp

cp cyclictest ./tmp
cd tmp || { echo "Failed to enter tmp directory"; exit 1; }
find . | cpio -H newc -o | gzip > ../mod.gz
cd ..

cat mod.gz tinyfs.gz > test.gz

rm -rf tmp
rm mod.gz tinyfs.gz

