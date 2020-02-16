#!/bin/bash
# Install GnuPG

BASE_PATH=$(dirname "$0")
echo "Installing OpenSSH & GnuPG and initial configurations...."

read -r -d '' LOGROTATE_CFG << EOF
/var/log/sshdusers.log
{
        weekly
        missingok
        rotate 4
        compress
        delaycompress
        notifempty
        create 644 syslog syslog
}
EOF

read -r -d '' USER_SSH_CFG << EOF
# configure gpg agent forwarding
# RemoteForward <remote> <local>

# example ssh configuration for myhost.example.com
# uncomment and use use 'ssh myhost' to connect
#Host myhost
#  HostName myhost.example.com
#  SendEnv LANG LC_*
#  HashKnownHosts yes
#  GSSAPIAuthentication yes
#  GSSAPIDelegateCredentials no
#  ForwardAgent yes
#  RemoteForward /home/$USER/.gnupg/S.gpg-agent /run/user/$UID/gnupg/S.gpg-agent.extra
EOF

hash apt-get 2>/dev/null || { echo >&2 "You need to install apt-get. Aborting."; exit 1; }
hash update-alternatives 2>/dev/null || { echo >&2 "You need to install dpkg. Aborting."; exit 1; }
hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }

if ! sudo apt-get update; then
  exit 1
fi

# Install OpenSSH
if ! sudo apt-get install -y openssh-server openssh-client openssh-sftp-server; then
  exit 1
fi

# Install GnuPG v1 & v2
if ! sudo apt-get install -y gnupg gnupg-agent gnupg-pkcs11-scd gnupg2; then
  exit 1
fi

# Install 'extra' packages not available on all distros
if ! sudo apt-get install -y gnupg-utils; then
  echo >&2 "WARNING: Failed to install gnupg-utils (probably not available for this distro)."
fi

# Install OpenSC
if ! sudo apt-get install -y opensc opensc-pkcs11; then
  echo >&2 "WARNING: Failed to install OpenSC."
fi

# Install supported pinentry interfaces
PINENTRY_INST=0

if dpkg -l 2>/dev/null | grep -Pq '^ii(\s+)libncursesw5'; then
  if ! sudo apt-get install -y pinentry-curses; then
    echo >&2 "WARNING: Failed to install pinentry-curses program."
  else
    PINENTRY_INST=1
  fi
fi

if dpkg -l 2>/dev/null | grep -Pq '^ii(\s+)libgtk2.0-0'; then
  if ! sudo apt-get install -y pinentry-gtk2; then
    echo >&2 "WARNING: Failed to install pinentry-gtk2 program."
  else
    PINENTRY_INST=1
  fi
fi

if dpkg -l 2>/dev/null | grep -Pq '^^ii(\s+)libqt5gui5'; then
  if ! sudo apt-get install -y pinentry-qt; then
    echo >&2 "WARNING: Failed to install pinentry-qt program."
  else
    PINENTRY_INST=1
  fi
fi

if [ $PINENTRY_INST -eq 0 ]; then
  echo >&2 "WARNING: Failed to install any pinentry applications."
fi

function check_sshd_config() {
  if ! bad_opts=$(sudo /usr/sbin/sshd -t 2>&1 | grep -Po '(?<=line\s)[0-9]+(?:\:\sBad configuration option\:\s)?[A-Za-z0-9]+' | awk -F: '{ printf "%s:%s\n",$1,$3 }' | sed -e 's/\s//g'); then
    echo >&2 "ERROR: Failed to validate OpenSSH configuration - please run 'sudo /usr/sbin/sshd -t' and correct the issue."
    exit 1
  fi

  if [ -z "${bad_opts}" ]; then
    return 0
  fi

  echo >&2 "WARNING: OpenSSH configuration file has unsupported options; disabling...."
  IFS=$'\n'; for line in $bad_opts; do
    opt_line=$(echo "$line" | awk -F: '{ print $1 }')
    opt_name=$(echo "$line" | awk -F: '{ print $2 }')
    if [ -z "${opt_line}" ] || [ -z "${opt_name}" ]; then
      echo >&2 "ERROR: Automated corrections for OpenSSH configuration failed."
      return 1
    fi

    echo >&2 "WARNING: Found unsupported option '${opt_name}' on line ${opt_line}; commenting out..."
    if ! sudo sed -i "${opt_line} s/^/#/" /etc/ssh/sshd_config; then
      echo >&2 "ERROR: Failed to comment out line ${opt_line} in '/etc/ssh/sshd_config'."
      return 1
    fi
  done

  return 0
}

# Configure alternative gpg options, defaulting to the newest installed binary
sudo update-alternatives --verbose --install /usr/local/bin/gpg gnupg /usr/local/bin/gpg2 100
sudo update-alternatives --verbose --install /usr/local/bin/gpg gnupg /usr/bin/gpg2 50
sudo update-alternatives --verbose --install /usr/local/bin/gpg gnupg /usr/bin/gpg 10

echo "Installing base configuration /etc/ssh/sshd_config ..."
if ! sudo cp -v "${BASE_PATH}/configs/ssh/sshd.config" /etc/ssh/sshd_config; then
  echo >&2 "WARNING: Failed to install sshd configuration."
elif check_sshd_config; then
  echo "OpenSSH configuration passed check; restarting service..."
  if ! sudo service ssh restart; then
    echo >&2 "WARNING: Failed to restart openssh service."
  fi
else
  echo >&2 "ERROR: The installed OpenSSH configuration appears to be broken!"
  echo >&2 "ERROR: Please run 'sudo /usr/sbin/sshd -t' to identify the issue."
fi

if [ -e "/etc/rsyslog.d/" ]; then
  echo "Configuring OpenSSH user logging..."

  if [ ! -e "/etc/rsyslog.d/sshdusers.conf" ]; then
    if ! sudo cp -v "${BASE_PATH}/configs/ssh/sshdusers.rsyslog" /etc/rsyslog.d/sshdusers.conf; then
      echo >&2 "WARNING: Failed to install sshdusers rsyslog configuration."
    fi
  else
    if ! sudo service rsyslog restart; then
      echo >&2 "WARNING: Failed to restart rsyslog."
    fi
    echo "sshdusers rsyslog configuration is already installed."
  fi

  if [ ! -e "/etc/logrotate.d/sshdusers" ]; then
    if ! sudo bash -c "echo '${LOGROTATE_CFG}' > /etc/logrotate.d/sshdusers"; then
      echo >&2 "WARNING: Failed to install logrotate configuration for sshdusers logging."
    fi
  else
    echo "sshdusers logrotate configuration is already installed."
  fi
fi

echo "Finished OpenSSH / GnuPG installation checks."

## (Optional) Configure user settings

echo "Configuring user settings for OpenSSH + GnuPG ..."

if [ ! -e "$HOME/.gnupg/gpg.conf" ]; then
  cp -v "${BASE_PATH}/configs/gnupg/gpg.conf.example" "$HOME/.gnupg/gpg.conf"
fi
if [ ! -e "$HOME/.gnupg/gpg-agent.conf" ]; then
  cp -v "${BASE_PATH}/configs/gnupg/gpg-agent.conf.example" "$HOME/.gnupg/gpg-agent.conf"
fi
if [ ! -e "$HOME/.gnupg/dirmngr.conf" ]; then
  cp -v "${BASE_PATH}/configs/gnupg/dirmngr.conf.example" "$HOME/.gnupg/dirmngr.conf"
fi
if [ ! -e "$HOME/.gnupg/scdaemon.conf" ]; then
  cp -v "${BASE_PATH}/configs/gnupg/scdaemon.conf.example" "$HOME/.gnupg/scdaemon.conf"
fi

if [ ! -e "$HOME/.ssh" ]; then
  mkdir -v "$HOME/.ssh"
  chmod -v 700 "$HOME/.ssh"
fi

if [ ! -e "$HOME/.ssh/config" ]; then
  echo "Installing example .ssh/config ..."
  echo "${USER_SSH_CFG}" > "$HOME/.ssh/config"
fi

exit 0
