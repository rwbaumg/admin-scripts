#!/bin/bash
# Gets a URL to the top-rated desktop on Reddit
# and performs optional processing, such as setting
# the current background.

WALLPAPER_RSS_URL="https://www.reddit.com/r/wallpapers.rss"

# Configure the image processing command and arguments
IMG_CMD="feh"
# CMD_ARG="--bg-seamless"

# Allow overriding image command using environment variables
if [ -n "${IMAGE_COMMAND}" ]; then
  IMG_CMD="${IMAGE_COMMAND}"
fi
if [ -n "${IMAGE_COMMAND_ARGS}" ]; then
  CMD_ARG="${IMAGE_COMMAND_ARGS}"
fi

if echo "${IMG_CMD}" | grep -Po '\s'; then
  echo >&2 "ERROR: Invalid image command: '${IMG_CMD}'"
  exit 1
fi
if [ -z "${IMG_CMD}" ] && [ -n "${CMD_ARGS}" ]; then
  echo >&2 "ERROR: Image command arguments configured without base command."
  exit 1
fi

# Check for required commands
hash curl 2>/dev/null || { echo >&2 "You need to install curl. Aborting."; exit 1; }

# Check for configured image command
hash "${IMG_CMD}" 2>/dev/null || { echo >&2 "You need to install ${IMG_CMD}. Aborting."; exit 1; }

TOP_URL=$(curl ${WALLPAPER_RSS_URL} \
            | grep -Eo 'https:[^&]+(jpg|jpeg|png)' \
            | grep -v  thumb \
            | head -1)

if [ -z "${TOP_URL}" ]; then
  echo >&2 "ERROR: Failed to determine URL for top-rated Reddit image."
  echo >&2 "ERROR: Reddit URL: ${WALLPAPER_RSS_URL}"
  exit 1
fi

echo "Current top-rated wallpaper: ${TOP_URL}"

if [ -n "${IMG_CMD}${CMD_ARGS}" ]; then
  echo "Image processing command: ${IMG_CMD} ${CMD_ARGS}"
  echo "${TOP_URL}" | xargs "${IMG_CMD}" "${CMD_ARG}"
  exit $?
fi

exit 0
