#!/bin/bash
# Tests the status of a certificate using all available methods.
# Supports both OCSP and CRL revocation.

hash openssl 2>/dev/null || { echo >&2 "You need to install openssl. Aborting."; exit 1; }
hash perl 2>/dev/null || { echo >&2 "You need to install perl. Aborting."; exit 1; }

SHOW_OUTPUT="false"
SHOW_OCSP="false"
VERBOSE=""

## Uncomment to enable subcommand verbosity
# VERBOSE="-v"

## Uncomment to display raw verification output
# SHOW_OUTPUT="true"
# SHOW_OCSP="true"

if [ -z "$1" ]; then
  echo >&2 "Usage: $0 <certificate>"
  exit 1
fi

CERT="$1"
if [ ! -e "${CERT}" ]; then
  echo >&2 "ERROR: File '${CERT}' does not exist."
  exit 1
fi

issuer_temp=""
cert_temp=""
crl_temp=""
trap cleanup EXIT INT TERM
cleanup() {
  if [ -e "${issuer_temp}" ]; then
    rm ${VERBOSE} "${issuer_temp}"
  fi
  if [ -e "${cert_temp}" ]; then
    rm ${VERBOSE} "${cert_temp}"
  fi
  if [ -e "${crl_temp}" ]; then
    rm ${VERBOSE} "${crl_temp}"
  fi
  exit $?
}

if ! openssl x509 -text -noout -in "${CERT}" > /dev/null 2>&1; then
  echo >&2 "ERROR: The specified file is not a valid certificate."
  exit 1
fi

filename=$(basename "$CERT")
cert_name="${filename%.*}"

cert_temp=$(mktemp "/tmp/${cert_name}.XXXXXXXXXX.crt")

# copy certificate to temp. location
openssl x509 -in "${CERT}" -out "${cert_temp}" -outform pem

ca_hash=$(openssl x509 -noout -inform pem -in "${cert_temp}" -issuer_hash)
if [ -z "$ca_hash" ]; then
  echo >&2 "ERROR: Failed to determine issuer hash."
  exit 1
fi

crt_hash=$(openssl x509 -noout -inform pem -in "${cert_temp}" -hash)
if [ -z "$crt_hash" ]; then
  echo >&2 "ERROR: Failed to determine certificate hash."
  exit 1
fi

crt_fingerprint=$(openssl x509 -inform pem -in "${cert_temp}" -noout -fingerprint | grep -Po '(?<=\sFingerprint\=)([A-Za-z0-9\:]+)(?=\/)?$' | sed 's/\://g')
if [ -z "$crt_fingerprint" ]; then
  echo >&2 "ERROR: Failed to determine certificate fingerprint."
  exit 1
fi

## ensures a certificate is in pem format
function make_pem() {
  local cert_name is_crl
  if [ -z "$1" ]; then
    echo >&2 "ERROR: No certificate path supplied to function."
    exit 1
  fi
  if [ ! -e "$1" ]; then
    echo >&2 "ERROR: File does not exist: $1"
    exit 1
  fi
  if [ ! -z "$2" ]; then
    shopt -sq nocasematch
    if [ "$2" == "crl" ]; then
      is_crl=true
    fi
    shopt -uq nocasematch
  fi

  cert_path="$1"
  cert_filename=$(basename "${cert_path}")
  cert_fileext="${cert_filename##*.}"
  cert_name="${cert_filename%.*}"

  shopt -sq nocasematch
  openssl_cmd="x509"
  if [ "${is_crl}" == "true" ] || [ "${cert_fileext}" == "crl" ]; then
    openssl_cmd="crl"
  fi
  shopt -uq nocasematch

  if ! openssl ${openssl_cmd} -in "${cert_path}" -text -noout > /dev/null 2>&1; then
    # input is in DER format
    temp_file=$(mktemp "/tmp/${cert_name}.XXXXXXXXXX.pem")
    if ! openssl ${openssl_cmd} -inform der \
            -in "${cert_path}" \
            -outform pem \
            -out "${temp_file}"; then
      rm "${temp_file}"
      echo >&2 "ERROR: Failed to convert input to PEM format: ${cert_path}"
      exit 1
    fi
    if ! cp "${temp_file}" "${cert_path}"; then
      rm "${temp_file}"
      echo >&2 "ERROR: Failed to copy converted certificate file: ${cert_path}"
      exit 1
    fi
    rm "${temp_file}"
  fi

  return 0
}

OCSP_URI=$(openssl x509 -in "${cert_temp}" -noout -ocsp_uri)
CRL_URI=$(openssl asn1parse -in "${cert_temp}" | grep -A 1 'X509v3 CRL Distribution Points' | tail -1 | cut -d: -f 4 | cut -b21- | perl -ne 's/(..)/print chr(hex($1))/ge; END {print "\n"}')
ISSUER_URI=$(openssl x509 -in "${cert_temp}" -noout -text | grep "CA Issuers - URI:" | head -n1 | grep -Po '(?<=URI\:)[^$]+$')

ISSUER_CN=$(openssl x509 -in "${cert_temp}" -noout -issuer | grep -Po '(?<=CN\=)[^\/$]+')
if [ -z "${ISSUER_CN}" ]; then
ISSUER_CN=$(openssl x509 -in "${cert_temp}" -noout -issuer | grep -Po '(?<=CN\s\=\s)[^\/,$]+')
fi

if [ -z "${ISSUER_CN}" ]; then
  echo >&2 "ERROR: Could not determine issuer CN for certificate: ${CERT}"
  exit 1
fi
if [ -z "${ISSUER_URI}" ]; then
  echo >&2 "ERROR: Could not find an issuer URI for certificate: ${CERT}"
  exit 1
fi
if [ -z "${CRL_URI}" ]; then
  echo >&2 "ERROR: Could not find a CRL distribution point for certificate: ${CERT}"
  exit 1
fi

#echo "Certificate hash        : ${crt_hash}"
#echo "Issuer hash             : ${ca_hash}"

echo "Certificate path        : ${CERT}"
echo "Certificate fingerprint : ${crt_fingerprint}"
echo "Issuing CA common name  : ${ISSUER_CN}"
echo

echo "Issuing CA URI          : ${ISSUER_URI}"

#if [ ! -z "${CRL_URI}" ]; then
echo "CRL Distribution Point  : ${CRL_URI}"
#fi

if [ ! -z "${OCSP_URI}" ]; then
echo "OCSP URI                : ${OCSP_URI}"
else
echo "OCSP URI                : <none>"
fi

echo

issuer_temp=$(mktemp "/tmp/${cert_name}.XXXXXXXXXX.cer")
if ! wget --quiet -O "${issuer_temp}" "${ISSUER_URI}"; then
  echo >&2 "ERROR: Failed to download issuing CA from ${ISSUER_URI}"
  exit 1
fi
if ! make_pem "${issuer_temp}"; then
  exit 1
fi

# Set the initial result
IS_VALID="true"

OCSP_RESPONSE=""
if [ ! -z "${OCSP_URI}" ]; then
  echo -n "Checking OCSP status... "
  if ! OCSP_RESPONSE=$(openssl ocsp -issuer "${issuer_temp}" -cert "${cert_temp}" -text -url "${OCSP_URI}"); then
    echo >&2 "OCSP validation for ${CERT} failed."
    IS_VALID="false"
  fi
fi

VERIFY_OUT=""
VERIFY_ERRORS=""
if [ ! -z "${CRL_URI}" ]; then
  crl_temp=$(mktemp "/tmp/${cert_name}.XXXXXXXXXX.crl")
  if ! wget --quiet -O "${crl_temp}" "${CRL_URI}"; then
    echo >&2 "WARNING: Failed to download CRL from ${CRL_URI}"
  fi
  if ! make_pem "${crl_temp}"; then
    exit 1
  fi

  if ! VERIFY_OUT=$(openssl verify -x509_strict \
                                   -policy_print \
                                   -issuer_checks \
                                   -purpose sslserver \
                                   -verbose \
                                   -crl_check \
                                   -crl_check_all \
                                   -CAfile "${issuer_temp}" \
                                   -CRLfile "${crl_temp}" \
                                   "${cert_temp}" 2>&1); then
    IS_VALID="false"
    echo >&2 "Certificate and/or CRL verification failed!"
    VERIFY_ERRORS=$(echo "${VERIFY_OUT}" | grep -i error | grep -Po '(?<=depth lookup\:)[^$]+')
  else
    echo "Certificate verification succeeded!"
  fi
fi

if [ "${SHOW_OCSP}" == "true" ] && [ ! -z "${OCSP_RESPONSE}" ]; then
    echo
    echo "OCSP Results"
    echo "---------------------------------------"
    echo "${OCSP_RESPONSE}"
    echo "---------------------------------------"
fi

if [ "${SHOW_OUTPUT}" == "true" ] && [ ! -z "${VERIFY_OUT}" ]; then
    echo
    echo "Verification Output"
    echo "---------------------------------------"
    echo "${VERIFY_OUT}"
    echo "---------------------------------------"
fi

echo

if [ "${IS_VALID}" != "true" ]; then
  if [ ! -z "${VERIFY_ERRORS}" ]; then
    echo >&2 "WARNING: The following errors were returned by the 'openssl verify' command:"
    while read -r err; do
      echo >&2 "-  ${err}"
    done< <(echo "${VERIFY_ERRORS}")
  fi
  exit 1
fi

exit 0
