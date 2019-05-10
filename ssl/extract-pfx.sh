#!/bin/bash
# Extract certificate and private key from a PKCS#12 / .pfx file.

hash openssl 2>/dev/null || { echo >&2 "You need to install openssl. Aborting."; exit 1; }

VERBOSITY=0
CRT_OUTPUT=""
KEY_OUTPUT=""

trap cleanup EXIT INT TERM
cleanup()
{
  extra_opts=""
  if [ $VERBOSITY -gt 0 ]; then
    extra_opts="-v"
  fi
  if [ -e "${CRT_OUTPUT}" ] && [ ! -s "${CRT_OUTPUT}" ]; then
    rm ${extra_opts} "${CRT_OUTPUT}"
  fi
  if [ -e "${KEY_OUTPUT}" ] && [ ! -s "${KEY_OUTPUT}" ]; then
    rm ${extra_opts} "${KEY_OUTPUT}"
  fi
}

exit_script()
{
  # Default exit code is 1
  local exit_code=1
  local re var

  re='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'
  if echo "$1" | grep -q "$re"; then
    exit_code=$1
    shift
  fi

  re='[[:alnum:]]'
  if echo "$@" | grep -iq "$re"; then
    if [ $exit_code -eq 0 ]; then
      echo >&2 "INFO: $@"
    else
      echo "ERROR: $@" 1>&2
    fi
  fi

  # Print 'aborting' string if exit code is not 0
  [ $exit_code -ne 0 ] && echo >&2 "Aborting script..."

  exit $exit_code
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename $0)|" << EOF
    USAGE

    Extract certificate and private key from a PKCS#12 (.pfx) file.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

      pfxFilePath              Full path to the PKCS#12 file to extract.

    OPTIONS
     -o, --output <path>       The location to extract files to.
     -l, --list                List all PKCS#12 files in the current folder.

     -v, --verbose             Make the script more verbose.
     -h, --help                Prints this usage.

EOF

    exit_script $@
}

test_arg()
{
  # Used to validate user input
  local arg="$1"
  local argv="$2"

  if [ -z "$argv" ]; then
    if echo "$arg" | grep -q '^-'; then
      usage "Null argument supplied for option $arg"
    fi
  fi

  if echo "$argv" | grep -q '^-'; then
    usage "Argument for option $arg cannot start with '-'"
  fi
}

test_file_arg()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  if [ ! -e "$argv" ]; then
    usage "File not found: '$argv'"
  fi
}

test_path_arg()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  if [ ! -d "$argv" ]; then
    usage "Path not found: '$argv'"
  fi
}

list_bundles()
{
  if [ $VERBOSITY -gt 0 ]; then
    echo "Listing PKCS#12 bundles contained in $(realpath .) ..."
  fi

  i=0
  IFS=$'\n'; for line in $(find ./ -type f -name "*.pfx"); do
    PFX_FILE="$line"
    PFX_REL_PATH=$(realpath --relative-to=$(realpath .) ${PFX_FILE})

    ((i++))

    if [ $VERBOSITY -gt 0 ]; then
      echo "PKCS#12 Bundle: ./${PFX_REL_PATH}"
    else
      echo "./${PFX_REL_PATH}"
    fi
  done

  if [ $VERBOSITY -gt 0 ]; then
    echo "Found $i PKCS#12 bundle(s) in $(realpath .)"
  fi
}

CONF_NAME=""
LIST_MODE="false"
FORCE_MODE="false"
EXTRA_ARGS=""
PFX_FILE=""
OUTPUT_PATH="$(realpath .)"
PKEY_OPTS="-nodes"

# process arguments
argc=0
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -o|--output)
      test_path_arg "$1" "$2"
      shift
      OUTPUT_PATH="$(realpath $1)"
      shift
    ;;
    -l|--list)
      LIST_MODE="true"
      shift
    ;;
    -f|--force)
      FORCE_MODE="true"
      shift
    ;;
    --keep-encryption)
      PKEY_OPTS=""
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      if [ ! -z "${PFX_FILE}" ]; then
        usage "Cannot specify multiple PKCS#12 bundles."
      fi
      test_file_arg "$1"
      PFX_FILE="$(realpath $1)"
      shift
    ;;
  esac
done

if [ "${LIST_MODE}" == "true" ]; then
  # list valid pfx bundles
  list_bundles
  exit_script 0
fi

if [ -z "${PFX_FILE}" ]; then
  usage "No PKCS#12 file specified to extract."
fi

PFX_REL_PATH=$(realpath --relative-to=$(realpath .) ${PFX_FILE})
PFX_FILE_NAME=$(basename "${PFX_FILE}")
PFX_BASE_NAME="${PFX_FILE_NAME%.*}"

if [ -z "${PFX_BASE_NAME}" ]; then
  usage "Cannot determine base name for file '${PFX_BASE_NAME}'."
fi

CRT_OUTPUT="${OUTPUT_PATH}/${PFX_BASE_NAME}.crt"
KEY_OUTPUT="${OUTPUT_PATH}/${PFX_BASE_NAME}.key"

REMOVE_ENCRYPTION="true"
if [ -z "${PKEY_OPTS}" ]; then
  REMOVE_ENCRYPTION="false"
fi

if [ $VERBOSITY -gt 0 ]; then
  echo "PKCS#12 File Path  : ${PFX_FILE}"
  echo "Output Folder Path : ${OUTPUT_PATH}"
  echo "Certificate output : ${CRT_OUTPUT}"
  echo "Private-key output : ${KEY_OUTPUT}"
  echo "Remove encryption  : ${REMOVE_ENCRYPTION}"
fi

EXTRA_OPTS=""
if [ $VERBOSITY -gt 0 ]; then
  EXTRA_OPTS="-v"
fi
if [ -e "${CRT_OUTPUT}" ] && [ ! -s "${CRT_OUTPUT}" ]; then
  rm ${EXTRA_OPTS} "${CRT_OUTPUT}"
fi
if [ -e "${KEY_OUTPUT}" ] && [ ! -s "${KEY_OUTPUT}" ]; then
  rm ${EXTRA_OPTS} "${KEY_OUTPUT}"
fi

if [ -e "${CRT_OUTPUT}" ] && [ "${FORCE_MODE}" != "true" ]; then
  usage "Certificate '${CRT_OUTPUT}' already exists. Use -f/--force to overwrite."
fi
if [ -e "${KEY_OUTPUT}" ] && [ "${FORCE_MODE}" != "true" ]; then
  usage "Private-key '${KEY_OUTPUT}' already exists. Use -f/--force to overwrite."
fi

echo "Extracting certificate and private-key from PKCS#12 file './${PFX_REL_PATH}' ..."

# OpenSSL commands:
# openssl pkcs12 -in myfile.pfx -nokeys -out certificate.crt
# openssl pkcs12 -in myfile.pfx -nocerts ${PKEY_OPTS} -out private-key.key

# Extract certificate
if [ $VERBOSITY -gt 0 ]; then
  echo "Extracting certificate ..."
fi
if ! $(openssl pkcs12 -in "${PFX_FILE}" -nokeys -out "${CRT_OUTPUT}"); then
  exit_script 2
fi

# Extract private-key
if [ $VERBOSITY -gt 0 ]; then
  echo "Extracting private-key ..."
fi
if ! $(openssl pkcs12 -in "${PFX_FILE}" -nocerts ${PKEY_OPTS} -out "${KEY_OUTPUT}"); then
  exit_script 2
fi

exit_script 0
