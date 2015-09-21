#!/bin/bash
# creates an image of a CD/DVD disk
# rwb[at]0x19e.net

# specify the CD/DVD drive
DRIVE=/dev/cdrom

# check if superuser
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root" >&2
   exit 1
fi

# check if a disk is inserted
blkid $DRIVE > /dev/null 2>&1;
if [ $? -ne 0 ]; then
  echo >&2 "ERROR: No disk found on $DRIVE"
  exit 1
fi

# get some information about the inserted disk
LABEL=$(blkid $DRIVE|sed -n 's/.*LABEL=\"\([^\"]*\)\".*/\1/p'|sed -e 's/ /_/g')
SIZE=$(blockdev --getsize64 /dev/cdrom)
OUTPUT=$(readlink -f $LABEL.iso)

# get the size in megabytes
SIZE_IN_MB=$[$SIZE/1024/1024]

echo "Ripping $LABEL ($SIZE_IN_MB MB)"
echo "Writing image to $OUTPUT ..."

# create an image
dd if=$DRIVE | pv -brtep -s $SIZE | dd of=$OUTPUT

# eject the disk
eject $DRIVE

echo "Image saved to $OUTPUT"

exit 0
