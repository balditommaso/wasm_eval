#!/bin/bash
set -e

IMG_FILE="benchmark.img"
MOUNT_DIR="./host_mount_temp"
OUTPUT_DIR="./results"

# Ensure host directories exist
mkdir -p "$MOUNT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "Mounting $IMG_FILE..."
sudo mount -o loop "$IMG_FILE" "$MOUNT_DIR"

echo "Extracting result files to $OUTPUT_DIR..."
if [ "$(ls -A "$MOUNT_DIR")" ]; then
    # Copy all files, preserving attributes where possible
    cp -av "$MOUNT_DIR"/* "$OUTPUT_DIR"/
else
    echo "Warning: No files found to extract inside the image."
fi

echo "Unmounting image..."
sudo umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"

echo "Resetting/cleaning image for the next benchmark run..."
# Completely wipe and re-initialize the raw image so it starts fresh
rm -f "$IMG_FILE"
dd if=/dev/zero of="$IMG_FILE" bs=1M count=50 status=none
mkfs.ext4 -F "$IMG_FILE" > /dev/null

echo "Done! Results saved in $OUTPUT_DIR and $IMG_FILE is reset."