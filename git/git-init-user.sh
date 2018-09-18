#!/bin/bash
# First-time Git environment setup

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
ROOT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

if [ $VERBOSITY -gt 1 ]; then
  echo "Resolved script directory: $ROOT_DIR"
fi

if [ -e "$HOME/.gitconfig" ]; then
  echo >&2 "WARNING: '$HOME/.gitconfig' already exists and will not be modified."
else
  echo "Installing .gitconfig ..."
  cp -v "${ROOT_DIR}/gitconfig.template ${HOME}/.gitconfig"

  USER_FULLNAME=$(getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1)
  USER_DOMAIN=$(hostname -d)
  USER_EMAIL="${USER}@${USER_DOMAIN}"

  git config --global user.name "${USER_FULLNAME}"
  git config --global user.email "${USER_EMAIL}"
fi
if [ -e "$HOME/.gitattributes" ]; then
  echo >&2 "WARNING: '$HOME/.gitattributes' already exists and will not be modified."
else
  echo "Installing .gitattributes ..."
  cp -v "${ROOT_DIR}/gitattributes.template ${HOME}/.gitattributes"
fi

# Check for missing diff support
declare -a missing=();
function add_missing()
{
  if [ -z "$1" ]; then
    echo >&2 "ERROR: Package name cannot be null."
    exit 1
  fi
  package_name="$1"
  missing=("${missing[@]}" "${package_name}")
  echo >&2 "WARNING: Package '${package_name}' is required for full extended diff support."
}

if ! hash pdfinfo 2>/dev/null; then
  add_missing "poppler-utils"
fi
if ! hash pandoc 2>/dev/null; then
  add_missing "pandoc"
fi
if ! hash hexdump 2>/dev/null; then
  add_missing "bsdmainutils"
fi
if ! hash odt2txt 2>/dev/null; then
  add_missing "odt2txt"
fi
if ! hash tar 2>/dev/null; then
  add_missing "tar"
fi
if ! hash xzcat 2>/dev/null; then
  add_missing "xz-utils"
fi
if ! hash bzcat 2>/dev/null; then
  add_missing "bzip2"
fi
if ! hash zcat 2>/dev/null; then
  add_missing "gzip"
fi
if ! hash unzip 2>/dev/null; then
  add_missing "unzip"
fi

# Print out mappings
packages=""
for ((idx=0;idx<=$((${#missing[@]}-1));idx++)); do
  pkg="${missing[$idx]}"
  if [ $idx -gt 0 ]; then
    packages="${packages} $pkg"
  else
    packages="${pkg}"
  fi
done
echo "Found ${#missing[@]} missing package(s)."

# See if apt-get is available
if hash apt-get 2>/dev/null; then
  echo "Attempting to install via apt-get ..."
  sudo apt-get install $packages
  if ! [ $? -eq 0 ]; then
    echo >&2 "ERROR: Failed to install missing packages."
    exit 1
  fi
else
  echo "For example, to install missing packages using apt-get run:"
  echo "sudo apt-get install ${packages}"
fi

exit 0
