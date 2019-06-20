#!/usr/bin/env bash
#
# Script to find the correct device to play audio from
#   See speaker-test(1) for more

hash grep 2>/dev/null || { echo >&2 "You need to install grep. Aborting."; exit 1; }
hash speaker-test 2>/dev/null || { echo >&2 "You need to install alsa-utils. Aborting."; exit 1; }

set -euo pipefail

pcmDevs="$(
  aplay --list-pcms |
    grep --invert-match --extended-regexp '^[[:space:]]' |
    grep --invert-match --extended-regexp '^(default|null|pulse)' |
    while IFS=, read -r record _; do echo "$record"; done |
    while IFS=: read -r label cardKeyValue; do
      card="${cardKeyValue/CARD=/}"
      if [ "$card" = Loopback ];then continue;fi
      printf -- '%s:%s\n' "$label" "$card"
    done |
    sort --stable |
    uniq
)"; declare -ra pcmDevs

currentlyTesting=0
reportInterruptedDevice() (
  if [[ -z "$currentlyTesting" ]];then return; fi
  printf 'INTERRUPTED testing device "%s"\n' "$currentlyTesting"
)
trap reportInterruptedDevice SIGINT

for pcmDevice in "${pcmDevs[@]}";do
  currentlyTesting="$pcmDevice"

  printf 'TESTING device "%s"\n' "$pcmDevice"
  if ! speaker-test --channels 2 --device "$pcmDevice" -t wav; then
    printf '\nFAILED testing device "%s"\n\n' "$pcmDevice"
  else
    printf '\nFINSHED testing device "%s"\n\n' "$pcmDevice"
  fi
done
currentlyTesting=''

exit 0
