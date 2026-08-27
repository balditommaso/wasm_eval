#!/bin/bash

KERNEL_MAJOR="7.2"
KERNEL_VERSION="7.2"
RT_VERSION="7.2-rt5"

# DOWNLOAD
KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"
RT_PATCH="patch-${RT_VERSION}.patch.xz"

BASE_URL="https://cdn.kernel.org/pub/linux/kernel"
KERNEL_URL="${BASE_URL}/v${KERNEL_MAJOR%%.*}.x/${KERNEL_TAR}"
RT_URL="${BASE_URL}/projects/rt/${KERNEL_MAJOR}/${RT_PATCH}"

TARGET_DIR="kernels"

echo "Ensuring directory '${TARGET_DIR}' exists..."
mkdir -p "${TARGET_DIR}"
cd "${TARGET_DIR}" || { echo "Failed to enter ${TARGET_DIR}"; exit 1; }

echo "Checking for Linux Kernel source (v${KERNEL_VERSION})..."
if [ ! -f "${KERNEL_TAR}" ]; then
    echo "Downloading kernel source..."
    wget -q --show-progress "${KERNEL_URL}"
else
    echo "Kernel source already present: ${KERNEL_TAR}"
fi

echo "Checking for PREEMPT_RT patch (v${RT_VERSION})..."
if [ ! -f "${RT_PATCH}" ]; then
    echo "Downloading RT patch..."
    wget -q --show-progress "${RT_URL}"
else
    echo "RT patch already present: ${RT_PATCH}"
fi

# EXTRACT and patch linux kernel source
TARGET_SRC_DIR="linux-${KERNEL_VERSION}-rt"

# Check if we already extracted and patched it
if [ -d "${TARGET_SRC_DIR}" ]; then
    echo "Patched kernel directory already exists: ${TARGET_SRC_DIR}"
    cd "${TARGET_SRC_DIR}" || { echo "Failed to enter ${TARGET_SRC_DIR}"; exit 1; }
else
    echo "Extracting Linux Kernel source..."
    # Remove any leftover unpatched directory from previous failed runs
    rm -rf "linux-${KERNEL_VERSION}"
    
    tar -xf "${KERNEL_TAR}" || { echo "Failed to extract ${KERNEL_TAR}"; exit 1; }
    
    # Rename the extracted folder to our target directory name
    mv "linux-${KERNEL_VERSION}" "${TARGET_SRC_DIR}" || { echo "Failed to rename extracted directory"; exit 1; }
    
    cd "${TARGET_SRC_DIR}" || { echo "Failed to enter ${TARGET_SRC_DIR}"; exit 1; }
    
    echo "Applying RT patch..."
    # Standard patch application. No -R flag.
    xzcat "../${RT_PATCH}" | patch -p1 || { echo "Failed to apply RT patch"; exit 1; }

    echo "Generating KVM-optimized configuration..."
    # Configuration must happen AFTER patching so the RT options are available
    make x86_64_defconfig
    make kvm_guest.config

    ./scripts/config --enable CONFIG_EXPERT
    ./scripts/config --enable CONFIG_PREEMPT_RT
    ./scripts/config --disable CONFIG_DEBUG_INFO_BTF
    ./scripts/config --enable CONFIG_NO_HZ_FULL
    ./scripts/config --enable CONFIG_RCU_NOCB_CPU
    ./scripts/config --disable CONFIG_CPU_FREQ
    ./scripts/config --disable CONFIG_CPU_IDLE
    ./scripts/config --enable CONFIG_PARAVIRT_SPINLOCKS

    make olddefconfig
fi

grep -E "CONFIG_PREEMPT_RT|CONFIG_EXPERT|CONFIG_DEBUG_INFO_BTF" .config

make -j10
# Remember to enable Expert Mode to see the RT options!
# General setup -> Configure standard kernel features (expert users) -> Fully Preemptible Kernel (Real-Time)
# make menuconfig || { echo "Failed to run 'make menuconfig'"; exit 1; }