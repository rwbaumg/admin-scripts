#!/bin/bash
# 0x19e Networks
#
# Erase the first three tapes and label using barcodes as 'Scratch' volumes
#
# WARNING: Any existing data on tapes 1-3 will be lost!
#
# Robert W. Baumgartner <rwb@0x19e.net>

ENCRYPT=""
if [ "$1" == "encrypt" ]; then
  echo "Labeling for LTO encryption..."
  ENCRYPT="$1"
elif [ ! -z "$1" ]; then
  echo >&2 "ERROR: Invalid argument (only 'encrypt' is supported)."
  exit 1
fi

# slot 1
sudo /usr/lib/bareos/scripts/mtx-changer /dev/sg1 load 1 /dev/st0 0
sudo mt -f /dev/st0 status
sudo mt -f /dev/st0 rewind
sudo mt -f /dev/st0 weof
sudo mt -f /dev/st0 rewind
echo "label barcodes pool=Scratch drive=0 slot=1 ${ENCRYPT} yes" | sudo bconsole
sudo mt -f /dev/st0 status
sudo /usr/lib/bareos/scripts/mtx-changer /dev/sg1 unload 1 /dev/st0 0

# slot 2
sudo /usr/lib/bareos/scripts/mtx-changer /dev/sg1 load 2 /dev/st0 0
sudo mt -f /dev/st0 status
sudo mt -f /dev/st0 rewind
sudo mt -f /dev/st0 weof
sudo mt -f /dev/st0 rewind
echo "label barcodes pool=Scratch drive=0 slot=2 ${ENCRYPT} yes" | sudo bconsole
sudo mt -f /dev/st0 status
sudo /usr/lib/bareos/scripts/mtx-changer /dev/sg1 unload 2 /dev/st0 0

# slot 3
sudo /usr/lib/bareos/scripts/mtx-changer /dev/sg1 load 3 /dev/st0 0
sudo mt -f /dev/st0 status
sudo mt -f /dev/st0 rewind
sudo mt -f /dev/st0 weof
sudo mt -f /dev/st0 rewind
echo "label barcodes pool=Scratch drive=0 slot=3 ${ENCRYPT} yes" | sudo bconsole
sudo mt -f /dev/st0 status
sudo /usr/lib/bareos/scripts/mtx-changer /dev/sg1 unload 3 /dev/st0 0

# unmount drive
echo 'unmount storage=Tape drive=0' | sudo bconsole
