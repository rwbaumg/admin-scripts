#!/usr/bin/env bash
# Date/time helpers

function formatSize() {
  local size=$1

  if [ -z "$size" ]; then
    size=0
  fi

  if hash bc 2>/dev/null; then
    if [ "$size" -ge 1048576 ]; then
      # size=$(echo $((size/1048576)))gb
      size=$(echo "scale=2;$size/1048576"| bc)gB
    elif [ "$size" -ge 1024 ]; then
      # size=$(echo $((size/1024)))mb
      size=$(echo "scale=2;$size/1024" | bc)mB
    else
      size=$size"kB"
    fi
  else
    size=$size"kB"
  fi

  echo "$size"
}
