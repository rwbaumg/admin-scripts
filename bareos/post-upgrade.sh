#!/bin/bash
# Bareos post-upgrade script
# This script handles re-configuring the daemon after (possible) configuration changes
# made during the upgrade process.

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
function disable_conf()
{
  local path="$1"
  if [ -z "${path}" ]; then
    echo >&2 "ERROR: Path cannot be null."
    exit 1
  fi
  if [ ! -e "${path}" ]; then
    echo >&2 "ERROR: Specified path does not exist: ${path}"
    exit 1
  fi

  local full_path=$(realpath "${path}")
  if ! sudo mv -vf ${full_path}{,.disabled}; then
    return 1
  fi

  return 0
}

# Adds a configuration path to the list of files to be disabled.
declare -a conf_paths=();
function disable_conf()
{
  if [ -z "$1" ]; then
    exit_script 1 "Configuration path cannot be null."
  fi
  if echo "${conf_paths[@]}" | grep -q -w "$1"; then
    exit_script 1 "Configuration path '$1' processed twice."
  fi
  conf_path="$1"
  conf_paths=("${conf_paths[@]}" "${conf_path}")
}

disable_conf "bareos/bareos-dir.d/catalog/MyCatalog.conf"
disable_conf "bareos/bareos-dir.d/client/bareos-fd.conf"
disable_conf "bareos/bareos-dir.d/console/bareos-mon.conf"
disable_conf "bareos/bareos-dir.d/director/bareos-dir.conf"
disable_conf "bareos/bareos-dir.d/fileset/Windows All Drives.conf"
disable_conf "bareos/bareos-dir.d/job/backup-bareos-fd.conf"
disable_conf "bareos/bareos-fd.d/director/bareos-dir.conf"
disable_conf "bareos/bareos-fd.d/director/bareos-mon.conf"
disable_conf "bareos/bareos-sd.d/director/bareos-dir.conf"
disable_conf "bareos/bareos-sd.d/director/bareos-mon.conf"
disable_conf "bareos/bareos-sd.d/storage/bareos-sd.conf"

err_count=0
for ((idx=0;idx<=$((${#config_paths[@]}-1));idx++)); do
  config_path="${config_paths[$idx]}"
  config_rel_path=$(realpath --relative-to=$(realpath "${PWD}") "${config_path}")
  if ! disable_conf "${config_path}"; then
    echo >&2 "ERROR: Failed to disable configuration: ${config_rel_path}"
    ((err_count++))
  else
    echo "Disabled configuration: ${config_rel_path}"
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
    if [[ "$(git --git-dir=/etc/.git --work-tree=/etc status --porcelain -- /etc/bareos|egrep '^(M| M|D| D)')" != "" ]]; then
      pushd /etc/bareos > /dev/null 2>&1
      git add --all
      git commit -m "bareos: auto-commit configuration reset."
      popd > /dev/null 2>&1
      echo "Committed Bareos configuration changes to to local /etc Git repository."
    fi
  fi
fi

exit 0
