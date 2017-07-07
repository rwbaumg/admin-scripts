#!/bin/bash
#
# [ 0x19e Networks ]
#
# VirusTotal File Submission
#
# This script submits a file to VirusTotal and reports on the results.

# check if curl command exists
hash curl 2>/dev/null || { echo >&2 "You need to install curl. Aborting."; exit 1; }

# check if python is installed (used for formatting)
hash python 2>/dev/null || { echo >&2 "You need to install python. Aborting."; exit 1; }

if [[ -z "$1" ]]; then
  echo "Usage: $0 <filename>" >&2
  exit 1
fi

if [[ ! -e "$1" ]]; then
  echo >&2 "ERROR: File does not exist: $1"
  exit 1
fi

# the virustotal API key to use
# below is the API key for 0x19e Networks - feel free to use it but please
# don't give it out to others. if they are meant to have it they can get it
# themselves.
API_KEY="374e4810c5a6584c9a2fcf456b39223e09c198233996e0181a35a713abab4e2f"

file_path=$1
#file_path=$(realpath $1)

echo "$(tput setaf 3)Uploading $1 to VirusTotal...$(tput sgr0)"
vt_result=$(curl -X POST 'https://www.virustotal.com/vtapi/v2/file/scan' --form apikey=$API_KEY --form file=@"$file_path")

# uncomment to debug response
# echo $vt_result

# 6 is sha256, 9 is md5
vt_hash=$(echo -e $vt_result | awk -F: ' {print $6}' |  awk -F, '{print $1}' | sed -e 's/^[[:space:]]*//' | tr -d \")

echo "$(tput setaf 3)SHA256:$vt_hash$(tput sgr0)"
echo "$(tput setaf 3)Waiting for report...$(tput sgr0)"

# wait for the report to finish
# TODO: set abort timeout?
while true; do
  response=`curl -X POST 'https://www.virustotal.com/vtapi/v2/file/report' --form apikey=$API_KEY --form resource=$vt_hash 2>/dev/null`

  if [ $(echo -n "$response"|grep -o '"response_code": 1'| wc -l) -eq 1 ]; then
    # scan finished; display report
    echo "$(tput setaf 2)Displaying report...$(tput sgr0)"

    # use pygmentize if available to display the report
    if hash pygmentize 2>/dev/null; then
      echo "$response" | python -mjson.tool | pygmentize -l javascript -f console | less -r
    else
      # use python to pretify - no pretty colors
      echo "$response" | python -mjson.tool | less -r
    fi

    break;
  fi

  # sleep before checking again
  echo -e -n "$(tput setaf 3).$(tput sgr0)\r"
  sleep 5
done
