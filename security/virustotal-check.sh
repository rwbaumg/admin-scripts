#!/bin/bash
#
# [ 0x19e Networks ]
#
# VirusTotal MD5 Database Check
#
# Takes as MD5 hash or a file as the only argument
# If a file path is provided then md5sum is used to
# calculate the hash.
#
# Note that since this script doesn't upload anything
# there won't be any results for files not seen before.
# This is good in a lot of situations but keep in mind
# you'll need a different script to perform submission.
#

echo "Virus Total MD5 DB Check"

# the virustotal API key to use
# below is the API key for 0x19e Networks - feel free to use it but please
# don't give it out to others. if they are meant to have it they can get it
# themselves.
API_KEY="374e4810c5a6584c9a2fcf456b39223e09c198233996e0181a35a713abab4e2f"

if [[ -z "$1" ]]; then
  echo "Usage: $0 [file or hash...]" >&2
  exit 1
fi

hash curl 2>/dev/null || { echo >&2 "You need to install curl. Aborting."; exit 1; }
hash awk 2>/dev/null || { echo >&2 "You need to install gawk. Aborting."; exit 1; }

# process file
if [[ -f "$1" ]]; then
  MD5_SUM=$(md5sum "$1" | awk '{print $1}')
  echo "Processing $1 ($MD5_SUM) ..."
  REPORT=$(curl -s -X POST 'https://www.virustotal.com/vtapi/v2/file/report' --form apikey="$API_KEY" --form resource="$MD5_SUM")
  SUMMARY=$(echo "$REPORT" | awk -F'positives\":' '{print $2}' | awk -F' ' '{print $1" "$4$5$6}'|sed 's/["}]//g')
  echo "VirusTotal Hits: $SUMMARY"
  exit 0
fi

# process single hash
HTEST=$(echo "$1" | grep -e "[0-9a-f]\{32\}")
if [ ! -f "$1" ] && [ "$HTEST" != "$1" ]; then
  echo "$1 is not a valid md5 hash"
else
  echo "Processing $1 ..."
  REPORT=$(curl -s -X POST 'https://www.virustotal.com/vtapi/v2/file/report' --form apikey="$API_KEY" --form resource="$1")
  echo "$REPORT" | awk -F'positives\":' '{print "VirusTotal Hits:" $2}' | awk -F' ' '{print $1$2" "$3$6$7}'|sed 's/["}]//g'
fi

exit 0
