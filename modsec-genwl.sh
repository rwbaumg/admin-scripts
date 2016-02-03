#!/bin/bash
#
# -=[ 0x19e Networks ]=-
#
# mod_security2 whitelist generator
#
# Author: rwb[at]0x19e[dot]net
# Date: 2016/02/03

INPUT_LOG="/var/log/apache2/*error*log"
OUTPUT_FILE=""
BASE_ID=9999000
RULE_COUNT=0
RULE_ARRAY=()
RULE_DOC=""
SEARCH_CLIENTS=()
SEARCH_HOSTS=()
VERBOSITY=0
MODULE_CHECK="false"
DATE_RANGE=""
DATE_FORMAT="+%a %b %d (\d\d\:\d\d\:\d\d\.[\d]+) %Y"

MAKE_TMPL="false"
TMPL_SN="%SERVER_NAME%"
TMPL_ID="%RULE_ID%"

MODSEC_HEADER="<IfModule mod_security2.c>"
MODSEC_FOOTER="</IfModule>"

IP_REGEX="((([1-9]?\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}([1-9]?\d|1\d\d|2[0-5][0-5]|2[0-4]\d))"

read -r -d '' RULE_TEMPLATE_FULL << EOF
SecRule SERVER_NAME "HOSTNAME" phase:MATCH_PHASE,chain,nolog,id:WHITELIST_ID
  SecRule REQUEST_FILENAME "@streq REQUEST_URI" chain
  SecRule ARGS_NAMES "ARG_NAME" ctl:ruleRemoveById=RULE_ID
EOF

read -r -d '' RULE_TEMPLATE_NOARGS << EOF
SecRule SERVER_NAME "HOSTNAME" phase:MATCH_PHASE,chain,nolog,id:WHITELIST_ID
  SecRule REQUEST_FILENAME "@streq REQUEST_URI" ctl:ruleRemoveById=RULE_ID
EOF

read -r -d '' RULE_TEMPLATE_NOARGS_NOPHASE << EOF
SecRule SERVER_NAME "HOSTNAME" pass,chain,nolog,id:WHITELIST_ID
  SecRule REQUEST_FILENAME "@streq REQUEST_URI" ctl:ruleRemoveById=RULE_ID
EOF

function valid_ip()
{
  local ip=$1
  local stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
    && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    stat=$?
  fi
  return $stat
}

function valid_hostname()
{
  local host=$1

  if [[ $host =~ ^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$ ]]; then
    return 0
  fi
  return 1
}

exit_script()
{
  # Default exit code is 1
  local exit_code=1
  local re var

  re='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'
  if echo "$1" | egrep -q "$re"; then
    exit_code=$1
    shift
  fi

  re='[[:alnum:]]'
  if echo "$@" | egrep -iq "$re"; then
    if [ $exit_code -eq 0 ]; then
      echo "INFO: $@"
    else
      echo "ERROR: $@" 1>&2
    fi
  fi

  # Print 'aborting' string if exit code is not 0
  [ $exit_code -ne 0 ] && echo "Aborting script..."

  exit $exit_code
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename $0)|" <<"    EOF"
    USAGE

    This script will generate a mod_security2 whitelist from an input log.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     input                   The input log containing mod_security2 warnings.

    OPTIONS

     -b, --base-id <value>   The starting rule ID. Default: 9999000
     -o, --output <value>    Save output to the specified file.

     -c, --client <value>    Only consider violations from the specified client
                             IP address. This option can be specified multiple
                             times.

     -s, --hostname <value>  Only consider violations for the specified server
                             hostname. This option can be specified multiple
                             times.

     -d, --date <value>      Select the date range for processing (for example,
                             'today' or 'yesterday').

     -t, --make-template     Output rules in modsec-wl template format.

     --module-check          Use mod_security2 header and footer.

     -v, --verbose           Make the script more verbose.
     -h, --help              Prints this usage.

    EOF

    exit_script $@
}

test_arg()
{
  # Used to validate user input
  local arg="$1"
  local argv="$2"

  if [ -z "$argv" ]; then
    if echo "$arg" | egrep -q '^-'; then
      usage "Null argument supplied for option $arg"
    fi
  fi

  if echo "$argv" | egrep -q '^-'; then
    usage "Argument for option $arg cannot start with '-'"
  fi
}

test_input_path()
{
  # test directory argument
  local arg="$1"

  test_arg $arg

  if ! ls -la $arg* > /dev/null 2>&1; then
    usage "Specified input file does not exist."
  fi
}

test_output_path()
{
  # test directory argument
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -e "$arg" ] || [ -e "$argv" ]; then
    usage "Specified output file already exists."
  fi
}

test_numeric()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  re='^[0-9]+$'
  if ! [[ $argv =~ $re ]]; then
    usage "Argument for $arg must be numeric."
  fi
}

test_ip_arg()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if ! valid_ip "$argv"; then
    usage "Argument specified for $arg is not a valid IP address."
  fi
}

test_host_arg()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if ! valid_hostname "$argv"; then
    usage "Argument specified for $arg is not a valid hostname."
  fi
}

PATH_SUPPLIED="false"

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -b|--base-id)
      test_numeric "$1" "$2"
      shift
      BASE_ID="$1"
      shift
    ;;
    -o|--output)
      test_output_path "$1" "$2"
      shift
      OUTPUT_FILE="$1"
      shift
    ;;
    -c|--client)
      test_ip_arg "$1" "$2"
      shift
      SEARCH_CLIENTS+="$1"'\n'
      shift
    ;;
    -s|--hostname)
      test_host_arg "$1" "$2"
      shift
      SEARCH_HOSTS+="$1"'\n'
      shift
    ;;
    -d|--date)
      test_arg "$1" "$2"
      shift
      DATE_RANGE="$1"
      shift
    ;;
    --module-check)
      MODULE_CHECK="true"
      shift
    ;;
    -t|--make-template)
      MAKE_TMPL="true"
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      shift
    ;;
    -vv)
      ((VERBOSITY++))
      ((VERBOSITY++))
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      if [ "$PATH_SUPPLIED" == "true" ]; then
        usage "Input file can only be specified once."
      fi
      test_input_path "$1"
      INPUT_LOG="$1"
      PATH_SUPPLIED="true"
      shift
    ;;
  esac
done

create_rule()
{
  if [ -z "$1" ]; then
    exit_script 1 "Log entry cannot be null."
  fi

  local log_entry="$1"
  local whitelist_id=$(($BASE_ID+$RULE_COUNT))
  local client_ip=$(echo $log_entry | grep -Po "(?<=\[client\s)$IP_REGEX(?=\])")
  local request_uri=$(echo $log_entry | grep -Po '(?<=\[uri\s\")([A-Za-z0-9\.\/\-_]+)(?=\"\])')
  local match_phase=$(echo $log_entry | grep -Po '(?<=\(phase\s)\d(?=\))')
  local hostname=$(echo $log_entry | grep -Po '(?<=\[hostname\s\")([A-Za-z\.-_]+)(?=\"\])')
  local rule_id=$(echo $log_entry | grep -Po '(?<=\[id\s\")\d+(?=\"\])')
  local arg_name=$(echo $log_entry | grep -Po '(?<=at\sARGS\:)[A-Za-z]+(?=\.\s)')

  if [ ${#SEARCH_CLIENTS[@]} -ge 1 ]; then
    # client filtering enabled, check ip address
   if ! echo -e "${SEARCH_CLIENTS[@]}" | fgrep --line-regexp "$client_ip" > /dev/null 2>&1; then
      # client not in array, ignore violation
      if [ $VERBOSITY -gt 1 ]; then
        echo >&2 "INFO: Skipping violation for ignored client (ip: $client_ip)"
      fi
      return 1
    fi
  fi

  if [ ${#SEARCH_HOSTS[@]} -ge 1 ]; then
    # client filtering enabled, check ip address
   if ! echo -e "${SEARCH_HOSTS[@]}" | fgrep --line-regexp "$hostname" > /dev/null 2>&1; then
      # client not in array, ignore violation
      if [ $VERBOSITY -gt 1 ]; then
        echo >&2 "INFO: Skipping violation for ignored host (ip: $hostname)"
      fi
      return 1
    fi
  fi

  if [ -z "$request_uri" ] || [ -z "$hostname" ]; then
    if [ $VERBOSITY -gt 1 ]; then
      echo >&2 "ERROR: Failed to process log entry: $log_entry"
    fi
   return 1
  fi

  if [ -z "$rule_id" ]; then
    if [ $VERBOSITY -gt 1 ]; then
      echo >&2 "ERROR: Failed to find rule ID in log entry: $log_entry"
    fi
   return 1
  fi

  if [ "$MAKE_TMPL" == "true" ]; then
    whitelist_id="$TMPL_ID"
    hostname="$TMPL_SN"
  fi

  if [ "$match_phase" == "4" ]; then
    # ignore phase 4 since its not possible to whitelist
    match_phase=""
  fi

  # get the required template for this rule
  local template="$RULE_TEMPLATE_FULL"
  if [ -z "$arg_name" ]; then
    template="$RULE_TEMPLATE_NOARGS"
  fi
  if [ -z "$match_phase" ] && [ -z "$arg_name" ]; then
    template="$RULE_TEMPLATE_NOARGS_NOPHASE"
  fi

  # generate the rule
  local rule=$( echo "$template" | sed -e "s|REQUEST_URI|$request_uri|" \
                                       -e "s|MATCH_PHASE|$match_phase|" \
                                       -e "s|HOSTNAME|$hostname|" \
                                       -e "s|RULE_ID|$rule_id|" \
                                       -e "s|ARG_NAME|$arg_name|")
  # create a hash for checking duplicates
  local rule_hash=$(echo "$rule" | tr '\n' ';' | sed -e 's/ //g' | sha1sum | awk '{print $1}')

  if [ $VERBOSITY -gt 2 ]; then
    echo "Rule hash: $rule_hash"
    echo -e "Rule items:\n${RULE_ARRAY[@]}"
  fi

  if ! echo -e "${RULE_ARRAY[@]}" | fgrep --line-regexp "$rule_hash" > /dev/null 2>&1; then
    # store the generated rule hash
    RULE_ARRAY+=$rule_hash'\n'

    # assign id to the generated rule
    rule=$( echo "$rule" | sed -e "s|WHITELIST_ID|$whitelist_id|")

    RULE_DOC+=${rule}'\n\n'
    ((RULE_COUNT++))
  else
    if [ $VERBOSITY -gt 1 ]; then
      echo >&2 "INFO: Found duplicate entry for rule violation (rule id: $rule_id)"
    fi
  fi
}

if [ -z "$INPUT_LOG" ]; then
 usage "No input log(s) were specified."
fi

if [ $VERBOSITY -gt 0 ]; then
  echo >&2 "INFO: Grepping log(s) for rule violations..."
fi
if [ $VERBOSITY -gt 1 ]; then
  echo >&2 "INFO: Log path: $INPUT_LOG"
fi

# gather log entries
if [ -n "$DATE_RANGE" ]; then
  if [ $VERBOSITY -gt 0 ]; then
    echo >&2 "INFO: Using date range '$DATE_RANGE' ..."
  fi

  DATE_REGEX=$(date -d "$DATE_RANGE" "$DATE_FORMAT")
  if (($? > 0)); then
    exit_script $?
  fi

  LOG_ENTRIES=$(grep -i modsec $INPUT_LOG \
    | grep -v "Warning" \
    | grep -v "(http://www.modsecurity.org/) configured." \
    | grep -v "compiled version=" \
    | grep -P "$DATE_REGEX" \
    | sed "s/$/\\n/")
else
  LOG_ENTRIES=$(grep -i modsec $INPUT_LOG \
    | grep -v "Warning" \
    | grep -v "(http://www.modsecurity.org/) configured." \
    | grep -v "compiled version=" \
    | sed "s/$/\\n/")
fi

# todo: support "Warning" flag as option in above

if (($? > 0)); then
  exit_script $?
fi

# get a count of the results
violation_count=0
IFS=$'\n'; for entry in $LOG_ENTRIES; do
  ((violation_count++))
done

if [ $violation_count -eq 0 ]; then
  exit_script 1 "No rule violations found."
fi

if [ $VERBOSITY -gt 0 ]; then
  echo >&2 "INFO: Found a total of $violation_count rule violation(s)."
  echo >&2 "INFO: Generating rules..."
fi

if [ "$MODULE_CHECK" == "true" ]; then
  RULE_DOC+=${MODSEC_HEADER}'\n\n'
fi
IFS=$'\n'; for entry in $LOG_ENTRIES; do
  create_rule "$entry"
done
if [ "$MODULE_CHECK" == "true" ]; then
  RULE_DOC+=${MODSEC_FOOTER}'\n'
fi

if [ $VERBOSITY -gt 0 ]; then
  echo >&2 "INFO: Generated $RULE_COUNT rule(s)."
  if [ -z "$OUTPUT_FILE" ] && [ -n "$RULE_DOC" ]; then
    # print an extra newline
    echo >&2
  fi
fi

# output rule buffer
if [ -n "$RULE_DOC" ]; then
  if [ -z "$OUTPUT_FILE" ]; then
    echo -e "$RULE_DOC"
  else
    if [ $VERBOSITY -gt 0 ]; then
      echo >&2 "INFO: Saving generated rules to $OUTPUT_FILE"
    fi
    echo -e "$RULE_DOC" > "$OUTPUT_FILE"
  fi
fi

if [ $VERBOSITY -gt 0 ]; then
  echo >&2 "INFO: Finished."
fi

exit 0
