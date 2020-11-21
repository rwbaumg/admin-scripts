#!/bin/bash
# burns an iso image to a CD/DVD disc
# rwb[at]0x19e.net

# specify the CD/DVD drive
DRIVE=/dev/cdrom
IMAGE=""

hash isoinfo 2>/dev/null || { echo >&2 "You need to install genisoimage. Aborting."; exit 1; }
hash wodim 2>/dev/null || { echo >&2 "You need to install wodim. Aborting."; exit 1; }
hash setcd 2>/dev/null || { echo >&2 "You need to install setcd. Aborting."; exit 1; }
hash growisofs 2>/dev/null || { echo >&2 "You need to install growisofs. Aborting."; exit 1; }

if [ -n "${1}" ]; then
  if [ "${1}" == "-h" ] || [ "${1}" == "--help" ]; then
    echo "Usage: $0 <iso> [drive]"
    exit 1
  fi
  IMAGE="${1}"
elif [ -z "${1}" ]; then
  echo "Usage: $0 <iso> [drive]"
  exit 1
fi
if [ -n "${2}" ]; then
  DRIVE="${2}"
fi

if [ ! -b "${DRIVE}" ]; then
  echo >&2 "ERROR: Optical drive '${DRIVE}' does not exist. Check hardware and drivers for errors."
  exit 1
fi
if [ ! -e "${IMAGE}" ]; then
  echo >&2 "ERROR: File '${IMAGE}' does not exist."
  exit 1
fi

# check if superuser
if [ $EUID -eq 0 ]; then
   echo >&2 "ERROR: This script should not be run as root."
   exit 1
fi

if ! SIZE=$(stat --format="%s" "$IMAGE"); then
  echo >&2 "ERROR: Failed to determine block size of image ${IMAGE}"
  exit 1
fi

# get image info
if ! IMAGE_INFO=$(isoinfo -d -i "${IMAGE}"); then
  echo >&2 "ERROR: Failed to gather image information."
  exit 1
fi

IMAGE_NAME=$(echo "${IMAGE_INFO}" | grep -Po "(?<=Volume\sid:\s)[^\n]+$")
if [ -z "${IMAGE_NAME}" ]; then
  IMAGE_NAME=$(date +%s)
  echo >&2 "WARNING: Failed to determine image name; using '${IMAGE_NAME}'."
fi

echo "Checking for disc ..."
while true; do
  cdinfo=$(setcd -i "$DRIVE")
  case "$cdinfo" in
    *'Disc found'*)
      break;
      ;;
    *'not ready'*)
      echo '(waiting for drive to be ready)' >&2;
      sleep 3;
      ;;
    *'is open'*)
      echo '(drive is open)' >&2;
      sleep 5;
      ;;
    *)
      printf 'Confused by setcd -i, bailing out:\n%s\n' "$cdinfo" &2
      exit 1
    esac
done

# get the size in megabytes
SIZE_IN_MB=$((SIZE/1024/1024))

# note: to get drive info
# wodim -prcap dev=/dev/cdrom

echo "Writing $IMAGE_NAME ($SIZE_IN_MB MB) to drive ${DRIVE}"
echo "Burning ISO $IMAGE ..."

# burn image to disc
# if ! wodim -eject -tao  speed=8 dev="${DRIVE}" -v -data "${IMAGE}"; then
if ! growisofs -dvd-compat -Z "${DRIVE}"="${IMAGE}"; then
  echo >&2 "ERROR: Failed to burn image $IMAGE_NAME using drive ${DRIVE}."
  exit 1
fi

# eject the disk
echo "Ejecting ${DRIVE} ..."
if ! eject "$DRIVE"; then
  echo >&2 "WARNING: Failed to eject ${DRIVE}"
fi

echo "Image $IMAGE_NAME burned to disc."
exit 0
