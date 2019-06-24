#!/bin/bash
# Prints details about an installed package.
# For systems using APT and DPKG (ie. Debian/Ubuntu)

PKG_NAME=""
if [ -n "$1" ]; then
  PKG_NAME="$1"
fi

function get_installed_packages()
{
  for pkg in $(dpkg --get-selections | grep install | awk -F' ' '{ print $1 }'); do
    echo "$pkg"
  done
}

function print_pkg_info()
{
  pkg_name="$1"
  if [ -z "${pkg_name}" ]; then
    echo >&2 "Usage: $0 <package_name>"
    exit 1
  fi

  dpkg_name=$(echo "${pkg_name}" | sed -e 's/\+/\\+/g' -e 's/\-/\\-/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g')
  dpkg_meta=$(dpkg -l | grep -Po "^(?:ii(\s+))${dpkg_name}(\:[^\s]*)?(?:\s+).*(?:\s+).*(?:\s+)")
  dpkg_name=$(echo "${dpkg_meta}" | awk -F' ' '{ print $2 }')
  dpkg_version=$(echo "${dpkg_meta}" | awk -F' ' '{ print $3 }')
  dpkg_arch=$(echo "${dpkg_meta}" | awk -F' ' '{ print $4 }')

  dpkg_info=$(dpkg -s "${pkg_name}")
  dpkg_s_version=$(echo "${dpkg_info}" | grep "Version:" | awk -F' ' '{ print $2 }')
  dpkg_s_arch=$(echo "${dpkg_info}" | grep "Architecture:" | awk -F' ' '{ print $2 }')

  if [ "${dpkg_version}" != "${dpkg_s_version}" ]; then
    echo >&2 "ERROR: DPKG version '${dpkg_version}' does not match extracted value of '${dpkg_s_version}'."
    exit 1
  fi

  if [ "${dpkg_arch}" != "${dpkg_s_arch}" ]; then
    echo >&2 "ERROR: Architecture '${dpkg_s_arch}' does not match expected value of '${dpkg_arch}'."
    exit 1
  fi

  if [ "${pkg_name}" != "${dpkg_name}" ] && [ "${pkg_name}:${dpkg_arch}" != "${dpkg_name}" ]; then
    echo >&2 "ERROR: Package name '${dpkg_name}' does not match."
    exit 1
  fi

  apt_cache_info=$(apt-cache showpkg "${pkg_name}" | grep "/var/lib/dpkg/status" | grep -v "File:")
  apt_cache_version=$(echo "${apt_cache_info}" | awk -F' ' '{ print $1 }')
  apt_cache_file=$(echo "${apt_cache_info}" | awk -F' ' '{ print $2 }' |  grep -Po '(?<=\().*(?=\))')

  if [ "${dpkg_version}" != "${apt_cache_version}" ]; then
    echo >&2 "ERROR: Version mismatch: dpkg='${dpkg_version}', apt-cache='${apt_cache_version}'"
    exit 1
  fi

  deb_url_cmd="apt-get download --print-uris ${pkg_name}=${dpkg_version}"
  deb_url=$(${deb_url_cmd} 2>/dev/null | cut -d' ' -f1 | grep -Po "(?<=').*(?=')")

  apt_cache_srcinfo=$(apt-cache policy "${pkg_name}" | grep "${dpkg_version}" -A1 | tail -n1)
  apt_cache_src_url=$(echo "${apt_cache_srcinfo}" | awk -F' ' '{ print $2 }')
  apt_cache_src_repo=$(echo "${apt_cache_srcinfo}" | awk -F' ' '{ print $3 }')
  apt_cache_src_arch=$(echo "${apt_cache_srcinfo}" | awk -F' ' '{ print $4 }')

  es_src_url=$(echo "${apt_cache_src_url}" | sed -e 's/http\:\/\///g' -e 's/\//_/g')
  es_src_repo="${apt_cache_src_repo/\//_}"

  if ! echo "${apt_cache_file}" | grep -q "${es_src_repo}"; then
    echo >&2 "ERROR: Cache file name is missing APT repository identifier."
    exit 1
  fi

  echo "Pkg. Name    : ${dpkg_name}"
  echo "Pkg. Version : ${dpkg_version}"
  if [ -n "${apt_cache_src_arch}" ]; then
  echo "Architecture : ${apt_cache_src_arch}"
  fi
  echo "Source URL   : ${apt_cache_src_url}"
  if [ -n "${apt_cache_src_repo}" ]; then
  echo "Source Repo. : ${apt_cache_src_repo}"
  fi
  if [ -n "${deb_url}" ]; then
  echo "Deb. URL     : ${deb_url}"
  fi
  #echo "Source Repo. : ${apt_cache_src_url} ${apt_cache_src_repo}"
  #echo "APT Cache    : ${apt_cache_file}"

  if ! echo "${apt_cache_file}" | grep -q "${es_src_url}"; then
    echo >&2 "WARNING: Cache file name is missing APT source URL."
    #echo >&2 "INFO: Package version: '${dpkg_version}'"
    #echo >&2 "INFO: Cache file: '${apt_cache_file}'"
    #echo >&2 "INFO: Source URL string: '${es_src_url}'"
    #echo >&2 "INFO: Source repo. string: '${es_src_repo}'"
    return 1
  fi
  if [ -z "${apt_cache_src_arch}" ]; then
    echo >&2 "WARNING: APT cache does not specify an architecture."
    return 1
  elif [ "${dpkg_arch}" != "all" ] && [ "${apt_cache_src_arch}" != "${dpkg_s_arch}" ]; then
    echo >&2 "WARNING: Cached architecture '${apt_cache_src_arch}' does not match expected value of '${dpkg_arch}'."
    return 1
  fi
  return 0
}

### Print package information

if [ -n "${PKG_NAME}" ]; then
  print_pkg_info "$PKG_NAME"
else
  for pkg in $(get_installed_packages); do
    print_pkg_info "${pkg}"; echo
  done
fi

exit 0
