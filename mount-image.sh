#!/bin/bash
# Mounts an image to the specified mountpoint

hash mountpoint 2>/dev/null || { echo >&2 "'mountpoint' command not found; you need to install initscripts package. Aborting."; exit 1; }
hash mount 2>/dev/null || { echo >&2 "You need to install 'mount'. Aborting."; exit 1; }

if [ $# -lt 1 ]; then
  echo "Usage: $0 <image> [mountpoint]"
  echo "Note: Mountpoint defaults to /mnt if not specified."
  exit 1
fi

IMAGE="$1"
MOUNT_POINT="/mnt"

MOUNT_RW="false"
MOUNT_OPTS="loop"

# check if image exists
if [ ! -e "$IMAGE" ]; then
  echo >&2 "'$IMAGE' does not exist; aborting."
  exit 1
fi

# verify image is a regular file
if [ ! -f "$IMAGE" ]; then
  echo >&2 "'$IMAGE' is not a regular file; aborting."
  exit 1
fi

# test image to ensure it can be mounted
# todo: support additional image types
MOUNT_TYPE="iso9660"
IMAGE_TYPE=$(file -i "$IMAGE" | awk -F" " '{ printf "%s\n", $2 }' | sed 's/application\///g' | sed 's/;//g')
if [ "$IMAGE_TYPE" != "x-iso9660-image" ]; then
  echo >&2 "'$IMAGE' is not a valid ISO9660 image file; aborting."
  exit 1
fi

if [ -n "$2" ]; then
  # user-specified mountpoint
  MOUNT_POINT="$2"
fi

# check if mountpoint exists
if [ ! -d "$MOUNT_POINT" ]; then
  echo >&2 "'$MOUNT_POINT' does not exist; aborting."
  exit 1
fi

# check if mountpoint is in use
if $(mountpoint -q "$MOUNT_POINT" > /dev/null); then
  echo >&2 "'$MOUNT_POINT' is already in use; aborting."
  exit 1
fi

# check if mountpoint is empty
if [ -z "$MOUNT_POINT" ]; then
  echo >&2 "'$MOUNT_POINT' is not empty; aborting."
  exit 1
fi

# decide whether or not image should be mounted r/o
if [ "$MOUNT_RW" == "true" ]; then
  MOUNT_OPTS=$MOUNT_OPTS",rw"
else
  MOUNT_OPTS=$MOUNT_OPTS",ro"
fi

# mount the image
echo "Mounting $IMAGE to $MOUNT_POINT ..."
mount -t $MOUNT_TYPE -o $MOUNT_OPTS "$IMAGE" "$MOUNT_POINT"

exit $?
