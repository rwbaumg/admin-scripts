#!/bin/bash

if [[ -z "$1" ]]; then
  echo "Usage: $0 <string>"
  exit 1
fi

echo -n $1 | sha1sum | awk '{print $1}'
