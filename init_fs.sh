#!/bin/bash
set -euo pipefail

WORKDIR="./tmp"
OUTPUT="test.gz"
TINYFS="tinyfs.gz"
WASM_RUNTIME="WasmEdge-0.17.1-ubuntu20.04_x86_64.tar.gz"

if ! command -v docker &> /dev/null; then
    echo "Error: Docker is required to fetch the correct Ubuntu 20.04 libraries."
    exit 1
fi

if [ ! -f "${TINYFS}" ]; then
    wget -qO "${TINYFS}" "https://retis.santannapisa.it/luca/KernelProgramming/Old-20/tinyfs.gz"
fi

if [ ! -f "${WASM_RUNTIME}" ]; then
    wget -qO "${WASM_RUNTIME}" "https://github.com/WasmEdge/WasmEdge/releases/download/0.17.1/${WASM_RUNTIME}"
fi

# Clean and extract
rm -rf "${WORKDIR}" wasmedge_extracted mod.gz "${OUTPUT}" u20_libs
mkdir -p wasmedge_extracted
tar -xzf "${WASM_RUNTIME}" -C wasmedge_extracted

# Dynamically find the binary and its root directory
WASM_BIN_PATH=$(find wasmedge_extracted -type f -name "wasmedge" -executable | head -n 1)
WASM_BIN_DIR=$(dirname "$WASM_BIN_PATH")
WASM_ROOT_DIR=$(dirname "$WASM_BIN_DIR")

# Prepare overlay and copy the intact WasmEdge structure
mkdir -p "${WORKDIR}/root"
cp -r "$WASM_ROOT_DIR" "${WORKDIR}/wasmedge"
WASM_LIB_DIR=$(find "${WORKDIR}/wasmedge" -maxdepth 1 -type d \( -name "lib" -o -name "lib64" \) | head -n 1)

# ------------------------------------------------------------
# Extract pure glibc 2.31 libraries via Docker
# ------------------------------------------------------------
echo "Fetching exact glibc 2.31 compatible libraries via Docker (Ubuntu 20.04)..."
mkdir -p u20_libs

# Run a temporary container in the background
CONTAINER_ID=$(docker run -d ubuntu:20.04 sleep 60)

# Ensure packages are installed in the container
docker exec "$CONTAINER_ID" apt-get update -qq
docker exec "$CONTAINER_ID" apt-get install -y -qq zlib1g libtinfo6 libstdc++6

# Extract the libraries (-L ensures we copy the real .so files, not symlinks)
docker cp -L "$CONTAINER_ID":/lib/x86_64-linux-gnu/libz.so.1 u20_libs/
docker cp -L "$CONTAINER_ID":/lib/x86_64-linux-gnu/libtinfo.so.6 u20_libs/
docker cp -L "$CONTAINER_ID":/usr/lib/x86_64-linux-gnu/libstdc++.so.6 u20_libs/
docker cp -L "$CONTAINER_ID":/lib/x86_64-linux-gnu/libgcc_s.so.1 u20_libs/

# Destroy the temporary container
docker rm -f "$CONTAINER_ID" > /dev/null

echo "Injecting Ubuntu 20.04 libraries into WasmEdge..."
cp u20_libs/* "$WASM_LIB_DIR/"

# Add your benchmarks
cp cyclictest hello.wasm "${WORKDIR}/root/"
chmod +x "${WORKDIR}/root/cyclictest"

# Build initramfs
pushd "${WORKDIR}" > /dev/null
find . -print0 | cpio --null -H newc -o --quiet | gzip > ../mod.gz
popd > /dev/null

cat "${TINYFS}" mod.gz > "${OUTPUT}"
rm -rf "${WORKDIR}" wasmedge_extracted mod.gz u20_libs

echo "Initramfs ready: ${OUTPUT}"