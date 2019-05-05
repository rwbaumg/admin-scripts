#!/usr/bin/env bash
# RFC Reader
# rwb[at]0x19e[dot]net

set -e
set -o pipefail
clear
NAME=$(basename $0)

version()
{
  local VER="1.00"
cat <<EOL
${NAME} version ${VER}
Copyright (C) 2015 0x19e Networks
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it.
EOL
}

descrip()
{
  cat <<EOL
This is a simple script that will show you either the
name / subject of an RFC, let you read an RFC, or let you
search for an RFC.
EOL
}

usage()
{
  cat <<EOL
Usage: ${NAME} <name (-n)|read (-r)|search (-s)> <####> <bcp|fyi|ien|std|rfc>
       ${NAME} <latest>
Usage examples:
  ${NAME} name 3334 rfc     # displays RFC #3334 name
    ex: 3334 Policy-Based Accounting. T. Zseby, S. Zander, C. Carle. October
             2002. (Format: TXT=103014 bytes) (Status: EXPERIMENTAL)
  ${NAME} search <term> rfc # Displays index of matches with RFC #'s
    ex: ${NAME} search transport rfc
        0905 ISO Transport Protocol specification ISO DP 8073. ISO. April
             1984. (Format: TXT=249214 bytes) (Obsoletes RFC0892) (Status:
             UNKNOWN)
        0939 Executive summary of the NRC report on transport protocols for
             Department of Defense data networks. National Research Council.
             February 1985. (Format: TXT=42345 bytes) (Status: UNKNOWN)
  ${NAME} read 38 fyi       # read fyi #38
  ${NAME} latest            # shows list of latest rfc's
EOL
}

# temp file and trap statement - trap for clean end
TMP_FILE=$(mktemp --tmpdir rfc.$$.XXXXXXXXXX) ;

trap 'printf "${NAME}: Quitting.\n" 1>&2 ; \
   rm -rf ${TMP_FILE} ; exit 1' 0 1 2 3 9 15

# changing order for function handling
OPTION=$1 ; NUM=$2 ; TYPE=$3

# check if $1 != "search" || -s
case "${OPTION}" in
  'search'|'-s') ;;
  'latest'|'-l') ;;
  'name'|'-n'|'read'|'-r')
    # check if $# -ge 2 && $2 is an integer
    [ $# -ge 2 ] || { version; descrip; usage; exit 1; }
    [ ${NUM} -ne 0 -o ${NUM} -eq 0 2>/dev/null ] ||
      { version; descrip; usage; exit 1; }
    # prepend zeros to make id number <####>
    FN=$(printf "%04d" ${NUM} | xargs)
  ;;
  *) version; descrip; usage; exit 1 ;;
esac

# set $3 to either rfc (default if empty), bcp, fyi, ien, & std
case "${TYPE}" in
  'bcp'|'BCP') ADDRESS="http://www.rfc-editor.org/rfc/bcp/bcp" ;;
  'fyi'|'FYI') ADDRESS="http://www.rfc-editor.org/rfc/fyi/fyi" ;;
  'ien'|'IEN') ADDRESS="http://www.rfc-editor.org/rfc/ien/ien" ;;
  'std'|'STD') ADDRESS="http://www.rfc-editor.org/rfc/std/std" ;;
  *) ADDRESS="http://www.rfc-editor.org/rfc/rfc" ;;
esac

# logging function
# output is format : date option num type term # as set in all the option cases
LOGD()
{
  local LOGFILE=/tmp/$0
  printf "%-14s %-8s %-5s %-4s %-4s\n" $(date "+%Y%m%d_%H%M") \
    "[${1}]" "${2}" "${3}" "${4}" >> ${LOGFILE}
}

# the gooey nougat of the script
case "${OPTION}" in
  'latest'|'-l')
    printf -- "%s\n" "Downloading latest rfc list"
    curl -f -s http://www.rfc-editor.org/rfc/rfc-index-latest.txt | \
      awk '{line++;print}; /\f/ {for (i=line;i<=80;i++) print ""; line=0}' | \
      sed '/\f/d' > "${TMP_FILE}"
      LOGD latest - - ${TERM}
      printf -- "%s\n" "Showing latest rfc's"
      cat "${TMP_FILE}"
  ;;

  'name'|'-n')
    case "${FN}" in
      [0-9]|[0-9][0-9]|[0-9][0-9][0-9]|[0-9][0-9][0-9][0-9])
      curl -s ${ADDRESS}-index.txt | \
        awk '/^'${FN}'/ {do_print=1} do_print==1 {print} NF==0 {do_print=0}'
      LOGD name ${NUM} ${TYPE} -
      ;;
    *) printf -- "Error: unknown parameter '%s'\n" "$2"; usage; exit 1 ;;
    esac
  ;;

  'read'|'-r')
    if [ -z $(wget -q --spider ${ADDRESS}${NUM}.txt || echo $?) ]; then
      printf -- "%s\n" "Downloading ${FN}"
      curl -f -s ${ADDRESS}${NUM}.txt | \
        awk '{line++;print}; /\f/ {for (i=line;i<=58;i++) print "";line=0}' | \
        # sed '/^$/d' > "${TMP_FILE}"
        sed '/\f/d' > "${TMP_FILE}"
      # curl -f -s ${ADDRESS}${NUM}.txt > "${TMP_FILE}"
      LOGD read ${NUM} ${TYPE} ${TERM}
      printf -- "%s (%s)\n" "Showing ${FN}" "${ADDRESS}${NUM}.txt"
      cat "${TMP_FILE}"
    else
      printf -- "%s\n" "File does not exist or is not TXT. Check RFC # : ${FN}"
      usage
    fi
  ;;

  'search'|'-s')
    F=$(echo ${NUM} | head -c 1)
    FU=$(echo ${F} | tr -s '[:lower:]' '[:upper:]')
    FL=$(echo ${F} | tr -s '[:upper:]' '[:lower:]')
    CW=$(echo ${NUM} | cut -c2-)
    curl -s ${ADDRESS}-index.txt | \
      awk 'BEGIN{FS="\n";RS="";ORS="\n\n"}/'[${FU}${FL}]${CW}'/' >"${TMP_FILE}"
    LOGD search ${NUM} - -
    printf -- "%s\n\n" "Showing search for '${F}${CW}'"
    # printf -- "%s\n" "Showing search for '${FL}${CW}'"
    cat "${TMP_FILE}"
  ;;

  *) printf -- "\n"; usage; exit 1 ;;
esac
