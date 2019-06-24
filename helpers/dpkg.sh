#!/usr/bin/env bash
# Debian packaging helpers

# Check if a package is installed
function check_installed() {
  pkg_name="$1"
  if [ -z "${pkg_name}" ]; then
    echo >&2 "ERROR: Package name not provided to check script."
    exit 1
  fi

  if hash apt-cache 2>/dev/null; then
    if apt-cache policy "${pkg_name}" | grep -v '(none)' | grep -q "Installed"; then
      return 0
    fi
  fi

  return 1
}

# Attempt to install a package
function install_pkg() {
  pkg_name="$1"
  if [ -z "${pkg_name}" ]; then
    echo >&2 "ERROR: Package name not provided to check script."
    return 1
  fi

  if check_installed "${pkg_name}"; then
    # package is already installed
    # echo "Package '${pkg_name}' is installed."
    return 0
  fi

  if hash apt-get 2>/dev/null; then
    # echo "Updating apt cache..."
    if ! apt-get update; then
      echo >&2 "ERROR: Failed to update apt cache."
      return 1
    fi
  fi

  # echo "Installing missing package '${pkg_name}' via apt-get ..."
  if ! apt-get install -V -y "${pkg_name}"; then
    echo >&2 "ERROR: Failed to install package '${pkg_name}'."
    return 1
  fi

  return 0
}

# Check if a source repository is enabled
function is_source_repo_enabled() {
  source="$1"
  if [ -z "$source" ]; then
    echo >&2 "ERROR: Missing source argument to function."
    return 1
  fi

  if hash apt-cache 2>/dev/null; then
    if ! hash lsb_release 2>/dev/null; then
      echo >&2 "ERROR: Unable to determine OS release (missing lsb_release command)."
      return 1
    fi

    os_info="$(lsb_release --short --id --release --codename)"
    { read -r os_id; read -r os_release; read -r os_codename; } <<< "$os_info"

    if apt-cache policy | grep -q -E "^(\s+)?release\sv=$os_release,o=${os_id},a=$os_codename,n=$os_codename,l=${os_id},c=${source}"; then
      echo "Package source '${source}' is already enabled."
      return 0
    fi

    if add-apt-repository --yes "${source}"; then
      echo "Enabled package source '${source}'."
      return 0
    else
      echo >&2 "Failed to enable package source '${source}'."
      return 1
    fi
  fi

  echo >&2 "The current operating system lacks a supported package manager."
  return 1
}

# Install a signing key given a web URL
function install_key_from_url() {
  hash apt-key 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }
  hash gpg 2>/dev/null || { echo >&2 "You need to install gnupg. Aborting."; exit 1; }

  key_url="$1"
  if [ -z "${key_url}" ]; then
    echo >&2 "No key URL was specified."
    exit 1
  fi

  # check if the key is already installed
  KEY_RW=$(wget -qO - "${key_url}")
  if [ -z "${KEY_RW}" ]; then
    echo >&2 "Failed to retrieve signing key from ${key_url}"
    exit 1
  fi
  if ! echo "${KEY_RW}" | gpg --list-packets > /dev/null 2>&1; then
    echo >&2 "Invalid key returned from URL ${key_url}"
    exit 1
  fi

  GPG_RW=$(echo "${KEY_RW}" | gpg --with-fingerprint --keyid-format SHORT 2>/dev/null | grep -P '^pub' | head -n1)
  KEY_ID=$(echo "${GPG_RW}" | cut -d' ' -f5- | awk '{$1=$1};1')

  KEY_TP=$(echo "${GPG_RW}" | awk '{ print $2 }' | awk '{$1=$1};1')
  KEY_SZ=$(echo "${KEY_TP}" | cut -d/ -f1)
  KEY_FP=$(echo "${KEY_TP}" | cut -d/ -f2)

  KEY_LIST=$(apt-key list --keyid-format SHORT 2>/dev/null)
  if echo "${KEY_LIST}" | grep "${KEY_FP}" > /dev/null 2>&1; then
    echo "Found signing key  : ${KEY_ID}"
    if [ "$VERBOSITY" -gt 0 ]; then
    echo "Key fingerprint    : ${KEY_FP}"
    echo "Key size and type  : ${KEY_SZ}"
    fi
    return
  fi

  # add the release key
  echo "Retrieve signing key from ${key_url} ..."

  if [ "$VERBOSITY" -gt 0 ]; then
  echo "Key identifier     : ${KEY_ID}"
  echo "Key fingerprint    : ${KEY_FP}"
  echo "Key size and type  : ${KEY_SZ}"
  fi

  if ! echo "${KEY_RW}" | sudo apt-key add -; then
    exit 1
  fi

  return 0
}
