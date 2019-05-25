#!/bin/bash
# Bareos post-upgrade script
# This script handles re-configuring the daemon after (possible) configuration changes
# made during the upgrade process.

ETC_DIR="/etc/bareos"

hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }

# Ensure sudo privileges for the current user if not running as root.
if [[ $EUID -ne 0 ]]; then
  echo "NOTICE: Running as user $USER; sudo privileges required."
  if ! sudo echo "" > /dev/null 2>&1; then
    echo >&2 "ERROR: Must have sudo privileges to modify configuration files."
    exit 1
  fi
fi

# Disables the specified configuration file by adding the '.disabled' extension.
function disable_config_file()
{
  local path="$1"
  if [ -z "${path}" ]; then
    echo >&2 "ERROR: Path cannot be null."
    exit 1
  fi
  if [ ! -e "${path}" ]; then
    return 0
  fi

  full_path=$(realpath "${path}")
  if ! sudo mv -vf "${full_path}"{,.disabled}; then
    return 1
  fi

  return 0
}

# Adds a configuration path to the list of files to be disabled.
declare -a config_paths=();
function disable_conf()
{
  if [ -z "$1" ]; then
    echo >&2 "Configuration path cannot be null."
    exit 1
  fi
  if echo "${config_paths[@]}" | grep -q -w "$1"; then
    echo >&2 "Configuration path '$1' processed twice."
    exit 1
  fi
  config_path="${ETC_DIR}/$1"
  config_paths=("${config_paths[@]}" "${config_path}")
}

disable_conf "bareos-dir.d/catalog/MyCatalog.conf"
disable_conf "bareos-dir.d/client/bareos-fd.conf"
disable_conf "bareos-dir.d/console/bareos-mon.conf"
disable_conf "bareos-dir.d/director/bareos-dir.conf"
disable_conf "bareos-dir.d/fileset/Windows All Drives.conf"
disable_conf "bareos-dir.d/job/backup-bareos-fd.conf"
disable_conf "bareos-fd.d/director/bareos-dir.conf"
disable_conf "bareos-fd.d/director/bareos-mon.conf"
disable_conf "bareos-sd.d/director/bareos-dir.conf"
disable_conf "bareos-sd.d/director/bareos-mon.conf"
disable_conf "bareos-sd.d/storage/bareos-sd.conf"

err_count=0
for ((idx=0;idx<=$((${#config_paths[@]}-1));idx++)); do
  config_path="${config_paths[$idx]}"
  if [ -e "${config_path}" ]; then
    config_rel_path=$(realpath --relative-to="$(realpath "${PWD}")" "${config_path}")
    if ! disable_config_file "${config_path}"; then
      echo >&2 "ERROR: Failed to disable configuration: ${config_rel_path}"
      ((err_count++))
    else
      echo "Disabled configuration: ${config_rel_path}"
    fi
  fi
done
if [[ $err_count -gt 0 ]]; then
  echo >&2 "WARNING: One or more configurations could not be disabled."
else
  echo "Default configuration files disabled successfully."
fi

# git handling for etckeeper (check if /etc/.git exists)
if hash git 2>/dev/null; then
  if git -C "/etc" rev-parse > /dev/null 2>&1; then
    if [[ "$(git --git-dir=/etc/.git --work-tree=/etc status --porcelain -- /etc/bareos|grep -E '^(M| M|D| D)')" != "" ]]; then
      pushd /etc/bareos > /dev/null 2>&1
      git add --all
      git commit -m "bareos: auto-commit configuration reset."
      popd > /dev/null 2>&1
      echo "Committed Bareos configuration changes to to local /etc Git repository."
    fi
  fi
fi

exit 0
