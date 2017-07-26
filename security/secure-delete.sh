#!/bin/bash
# securely deletes a file

if [ ! $# -gt 0 ]; then
  echo >&2 "Usage: $0 <file> ..."
  exit 1
fi

RND_SOURCE="/dev/urandom"
SHRED_TIMES=48
# SHRED_TIMES=10

echo "Starting secure delete ..."
echo "Entropy source   : $RND_SOURCE"
echo "Overwrite count  : $SHRED_TIMES"

FILE_COUNT=0

function shred_file()
{
  local file="$1"
  local verbose_flag="-v"

  if [ -z "$file" ]; then
    echo >&2 "ERROR: No file was supplied to shred."
    exit 1
  fi

  echo "Shredding file : $file ..."

  shred $verbose_flag \
        --random-source "$RND_SOURCE" \
        --iterations "$SHRED_TIMES" \
        --zero \
        --remove \
        "$file"

  echo "Shredded file  : $file"
  ((FILE_COUNT++))
}

function shred_folder()
{
  if [ -z "$1" ]; then
    echo >&2 "ERROR: Null argument for folder"
    exit 1
  fi
  if [ ! -d "$1" ]; then
    echo >&2 "ERROR: Argument is not a directory"
  fi

  echo "Searching directory '$1' ..."

  # find . -type f -print0 | xargs -0 shred_file
  for f in `find "$1" -type f`; do
    shred_file "$f"
  done
}

echo "Processing file(s) ..."

for arg in "$@"; do
  if [ ! -e "$arg" ]; then
    echo >&2 "ERROR: File/folder not found: $arg"
    exit 1
  fi

  if [ -d "$arg" ]; then
    # note: erasing files from subdirectories is dangerous, and this
    # script should supply more options before allowing recursive
    # erasure. print out a message and skip the folder
    echo >&2 "Ignored folder : $arg"

    # uncomment below to enable subdirectory handling
    # shred_folder "$arg"
  elif [ -f "$arg" ]; then
    shred_file "$arg"
  fi
done

echo "Finished erasing $FILE_COUNT file(s)."

exit 0
