#!/bin/bash
# define a keyword using wikipedia by DNS
# rwb[at]0x19e[dot]net

hash curl 2>/dev/null || { echo >&2 "You need to install curl. Aborting."; exit 1; }
hash jq 2>/dev/null || { echo >&2 "You need to install jq. Aborting."; exit 1; }
hash sed 2>/dev/null || { echo >&2 "You need to install sed. Aborting."; exit 1; }

if [[ -z "$1" ]]; then
  echo >&2 "Usage: $0 <keyword>"
  exit 1
fi

# alternative way to query (not as reliable)
#dig +short txt ${1}.wp.dg.cx

LANG="en"

# convert spaces to underscores
var=$(echo "$*" | sed 's/ /_/g')

# retrieve wiki data
wiki_data=$(curl -s "https://$LANG.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro&explaintext&titles=$var&redirects" | jq '.query.pages | to_entries[0] | .value.extract')

# eliminate quotes characters
data=$(echo "$wiki_data" | sed 's/\\\"/"/g')

if [[ $data = "null" ]]; then
  echo >&2 "ERROR: No data to fetch."
  exit 1
fi

# print result
url=https://en.wikipedia.org/wiki/$var
echo -e "${data:1:${#data}-2}\n"
echo "See more on $url"

exit 0
