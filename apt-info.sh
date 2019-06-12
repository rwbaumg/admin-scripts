#!/bin/bash
# Prints details about an installed package.
# For systems using APT and DPKG (ie. Debian/Ubuntu)

PKG_NAME=""
#PKG_NAME="apt"
if [ -n "$1" ]; then
  PKG_NAME="$1"
fi

if [ -z "${PKG_NAME}" ]; then
  echo >&2 "Usage: $0 <package_name>"
  exit 1
fi

DPKG_META=$(dpkg -l | grep -Po "^(?:ii(\s+))${PKG_NAME}(\:[^\s]*)?(?:\s+).*(?:\s+).*(?:\s+)")
DPKG_NAME=$(echo "${DPKG_META}" | awk -F' ' '{ print $2 }')
DPKG_VERSION=$(echo "${DPKG_META}" | awk -F' ' '{ print $3 }')
DPKG_ARCH=$(echo "${DPKG_META}" | awk -F' ' '{ print $4 }')

DPKG_INFO=$(dpkg -s "${PKG_NAME}")
DPKG_S_VERSION=$(echo "${DPKG_INFO}" | grep Version | awk -F' ' '{ print $2 }')
DPKG_S_ARCH=$(echo "${DPKG_INFO}" | grep Architecture | awk -F' ' '{ print $2 }')

if [ "${DPKG_ARCH}" != "${DPKG_S_ARCH}" ]; then
  echo >&2 "ERROR: Architecture '${DPKG_S_ARCH}' does not match expected value of '${DPKG_ARCH}'."
  exit 1
fi

if [ "${PKG_NAME}" != "${DPKG_NAME}" ] && [ "${PKG_NAME}:${DPKG_ARCH}" != "${DPKG_NAME}" ]; then
  echo >&2 "ERROR: Package name '${DPKG_NAME}' does not match."
  exit 1
fi

APT_CACHE_INFO=$(apt-cache showpkg "${PKG_NAME}" | grep /var/lib/dpkg/status)
APT_CACHE_VERSION=$(echo "${APT_CACHE_INFO}" | awk -F' ' '{ print $1 }')
APT_CACHE_FILE=$(echo "${APT_CACHE_INFO}" | awk -F' ' '{ print $2 }' |  grep -Po '(?<=\().*(?=\))')

if [ "${DPKG_VERSION}" != "${APT_CACHE_VERSION}" ]; then
  echo >&2 "ERROR: Version mismatch: dpkg='${DPKG_VERSION}', apt-cache='${APT_CACHE_VERSION}'"
  exit 1
fi

DEB_URL_CMD="apt-get download --print-uris ${PKG_NAME}=${DPKG_VERSION}"
DEB_URL=$(${DEB_URL_CMD} | cut -d' ' -f1 | grep -Po "(?<=').*(?=')")

APT_CACHE_SRCINFO=$(apt-cache policy "${PKG_NAME}" | grep "${DPKG_VERSION}" -A1 | tail -n1)
APT_CACHE_SRC_URL=$(echo "${APT_CACHE_SRCINFO}" | awk -F' ' '{ print $2 }')
APT_CACHE_SRC_REPO=$(echo "${APT_CACHE_SRCINFO}" | awk -F' ' '{ print $3 }')
APT_CACHE_SRC_ARCH=$(echo "${APT_CACHE_SRCINFO}" | awk -F' ' '{ print $4 }')

ES_SRC_URL=$(echo "${APT_CACHE_SRC_URL}" | sed -e 's/http\:\/\///g' -e 's/\//_/g')
ES_SRC_REPO=$(echo "${APT_CACHE_SRC_REPO}" | sed -e 's/\//_/g')

if ! echo "${APT_CACHE_FILE}" | grep -q "${ES_SRC_URL}"; then
  echo >&2 "ERROR: Cache file name is missing APT source URL."
  #echo >&2 "INFO: Package version: '${DPKG_VERSION}'"
  #echo >&2 "INFO: Cache file: '${APT_CACHE_FILE}'"
  #echo >&2 "INFO: Source URL string: '${ES_SRC_URL}'"
  #echo >&2 "INFO: Source repo. string: '${ES_SRC_REPO}'"
  exit 1
fi
if ! echo "${APT_CACHE_FILE}" | grep -q "${ES_SRC_REPO}"; then
  echo >&2 "ERROR: Cache file name is missing APT repository identifier."
  exit 1
fi

if [ "${APT_CACHE_SRC_ARCH}" != "${DPKG_S_ARCH}" ]; then
  echo >&2 "ERROR: Cached architecture '${APT_CACHE_SRC_ARCH}' does not match expected value of '${DPKG_ARCH}'."
  exit 1
fi

echo "Pkg. Name    : ${DPKG_NAME}"
echo "Pkg. Version : ${DPKG_VERSION}"
echo "Architecture : ${APT_CACHE_SRC_ARCH}"
echo "Source URL   : ${APT_CACHE_SRC_URL}"
echo "Source Repo. : ${APT_CACHE_SRC_REPO}"
echo "Deb. URL     : ${DEB_URL}"
#echo "Source Repo. : ${APT_CACHE_SRC_URL} ${APT_CACHE_SRC_REPO}"
#echo "APT Cache    : ${APT_CACHE_FILE}"

exit 0
