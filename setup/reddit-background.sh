#!/bin/bash
# Gets a URL to the top-rated desktop on Reddit
# and performs optional processing, such as setting
# the current background.
#
# To get only the URL, without displaying the image and store it in a variable use:
#   REDDIT_URL=$(NO_DISPLAY=1 ./reddit-background.sh 2>/dev/null)
#   echo $REDDIT_URL

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
if [ -z "${NO_DISPLAY}" ]; then
  NO_DISPLAY="false"
fi

if echo "${IMG_CMD}" | grep -Po '\s'; then
  echo >&2 "ERROR: Invalid image command: '${IMG_CMD}'"
  exit 1
fi
if [ -z "${IMG_CMD}" ] && [ -n "${CMD_ARG}" ]; then
  echo >&2 "ERROR: Image command arguments configured without base command."
  exit 1
fi

# Check for required commands
hash curl 2>/dev/null || { echo >&2 "You need to install curl. Aborting."; exit 1; }

# Check for configured image command
# hash "${IMG_CMD}" 2>/dev/null || { echo >&2 "You need to install ${IMG_CMD}. Aborting."; exit 1; }

if ! CURL_OUT=$(curl -s "${WALLPAPER_RSS_URL}" 2>/dev/null); then
  echo >&2 "ERROR: Request to '${WALLPAPER_RSS_URL}' failed."
  exit 1
fi
if echo "${CURL_OUT}" | grep -q "whoa there, pardner"; then
  echo >&2 "ERROR: Rate-limited."
  exit 1
fi

if ! TOP_URL=$(echo "${CURL_OUT}" | grep -Eo 'https:[^&]+(jpg|jpeg|png)' \
                 | grep -v  thumb \
                 | head -1); then
  echo >&2 "ERROR: Failed to extract top URL from response."
  exit 1
fi

if [ -z "${TOP_URL}" ]; then
  echo >&2 "ERROR: Failed to determine URL for top-rated Reddit image."
  echo >&2 "ERROR: Reddit URL: ${WALLPAPER_RSS_URL}"
  exit 1
fi

echo -n >&2 "Current top-rated wallpaper: "
echo "${TOP_URL}"

if hash "${IMG_CMD}" 2>/dev/null && [[ ! "${NO_DISPLAY}" =~ ^(true|t|1) ]]; then
  if [ -n "${IMG_CMD}${CMD_ARG}" ]; then
    if ! echo "${TOP_URL}" | xargs "${IMG_CMD}" "${CMD_ARG}" 2>/dev/null; then
      echo >&2 "ERROR: Failed to display background image using '${IMG_CMD}' command."
      exit 1
    fi
  fi
fi

exit 0
