#!/bin/bash
# Search for broken PDF files

hash pdfinfo 2>/dev/null || { echo >&2 "You need to install poppler-utils. Aborting."; exit 1; }

SEARCH_DIR="$(readlink -m "$0")"

if [ ! -z "$1" ]; then
  if [ ! -e "$1" ]; then
    echo >&2 "Search path does not exist: $1"
    exit 1
  fi

  SEARCH_DIR="$1"
fi

echo "Searching folder '${SEARCH_DIR}' ..."

find "${SEARCH_DIR}" -type f -name '*.pdf' | while read -r f; do
  if [ ! -s "$f" ]; then
    echo "Empty (zero-byte) PDF  : '$f'"
  elif ! pdfinfo "$f" > /dev/null 2>&1; then
    echo "Corrupted PDF document : '$f'"
  fi
done

echo "Finished."
exit 0
