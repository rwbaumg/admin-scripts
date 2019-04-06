#!/bin/bash
# Configure Bareos Logwatch using example provided in source
# See bareos/core/scripts/logwatch/README for details.

## Resolve root directory path
SOURCE="${BASH_SOURCE[0]}"
if [ -h "$SOURCE" ]; then
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  export ROOT_DIR="$( cd -P $DIR && pwd )"
else
  export ROOT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
fi

BAREOS_SRC="${ROOT_DIR}"
#BAREOS_SRC="/usr/local/src/bareos/core"
#BAREOS_SRC_LW="${BAREOS_SRC}/scripts/logwatch/"
LOGWATCH_CFG="/etc/logwatch"
LOGWATCH_DIR="/usr/share/logwatch/"

#if [[ $EUID -ne 0 ]]; then
#  echo >&2 "This script must be run as root."
#  exit 1
#fi
if [ ! -e "${BAREOS_SRC}" ]; then
  echo >&2 "ERROR: Bareos source directory '${BAREOS_SRC}' does not exist."
  exit 1
fi
if [ ! -e "${LOGWATCH_CFG}" ]; then
  echo >&2 "ERROR: Logwatch directory '${LOGWATCH_CFG}' does not exist."
  exit 1
fi
if [ ! -e "${LOGWATCH_DIR}" ]; then
  echo >&2 "ERROR: Logwatch directory '${LOGWATCH_DIR}' does not exist."
  exit 1
fi

# Manual installation
pushd ${BAREOS_SRC}

sudo cp -v -p logwatch/bareos ${LOGWATCH_DIR}/scripts/services/bareos
sudo cp -v -p logwatch/applybareosdate ${LOGWATCH_DIR}/scripts/shared/applybareosdate
sudo cp -v -p logwatch/logfile.bareos.conf ${LOGWATCH_DIR}/default.conf/logfiles/bareos.conf
sudo cp -v -p logwatch/services.bareos.conf ${LOGWATCH_DIR}/default.conf/services/bareos.conf

sudo chmod -v 755 ${LOGWATCH_DIR}/scripts/services/bareos
sudo chmod -v 755 ${LOGWATCH_DIR}/scripts/shared/applybareosdate
sudo chmod -v 644 ${LOGWATCH_DIR}/default.conf/logfiles/bareos.conf
sudo chmod -v 644 ${LOGWATCH_DIR}/default.conf/services/bareos.conf

sudo ln -s ${LOGWATCH_DIR}/default.conf/services/bareos.conf ${LOGWATCH_CFG}/conf/services/bareos.conf
sudo ln -s ${LOGWATCH_DIR}/default.conf/logfiles/bareos.conf ${LOGWATCH_CFG}/conf/logfiles/bareos.conf

popd

# Automatic installation
#pushd ${BAREOS_SRC_LW}
#make install
#popd

exit $?
