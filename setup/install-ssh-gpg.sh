#!/bin/bash
# Install GnuPG

echo "Installing OpenSSH & GnuPG and initial configurations...."

read -d ''  LOGROTATE_CFG << EOF
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

read -d ''  USER_SSH_CFG << EOF
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
if ! sudo apt-get install -y gnupg gnupg-agent gnupg-pkcs11-scd gnupg-utils gnupg2; then
  exit 1
fi

# Install OpenSC
if ! sudo apt-get install -y opensc opensc-pkcs11; then
  echo >&2 "WARNING: Failed to install OpenSC."
fi

# Install supported pinentry interfaces
PINENTRY_INST=0

if dpkg -l | grep -Pq '^ii(\s+)libncursesw5'; then
  if ! sudo apt-get install -y pinentry-curses; then
    echo >&2 "WARNING: Failed to install pinentry-curses program."
  else
    PINENTRY_INST=1
  fi
fi

if dpkg -l | grep -Pq '^ii(\s+)libgtk2.0-0'; then
  if ! sudo apt-get install -y pinentry-gtk2; then
    echo >&2 "WARNING: Failed to install pinentry-gtk2 program."
  else
    PINENTRY_INST=1
  fi
fi

if dpkg -l | grep -Pq '^ii(\s+)libqt5gui5'; then
  if ! sudo apt-get install -y pinentry-qt; then
    echo >&2 "WARNING: Failed to install pinentry-qt program."
  else
    PINENTRY_INST=1
  fi
fi

if [ $PINENTRY_INST -eq 0 ]; then
  echo >&2 "WARNING: Failed to install any pinentry applications."
fi

if [ ! -e "$HOME/.gnupg/gpg.conf" ]; then
  cp -v configs/gnupg/gpg.conf.example "$HOME/.gnupg/gpg.conf"
fi
if [ ! -e "$HOME/.gnupg/gpg-agent.conf" ]; then
  cp -v configs/gnupg/gpg-agent.conf.example "$HOME/.gnupg/gpg-agent.conf"
fi
if [ ! -e "$HOME/.gnupg/dirmngr.conf" ]; then
  cp -v configs/gnupg/dirmngr.conf.example "$HOME/.gnupg/dirmngr.conf"
fi
if [ ! -e "$HOME/.gnupg/scdaemon.conf" ]; then
  cp -v configs/gnupg/scdaemon.conf.example "$HOME/.gnupg/scdaemon.conf"
fi

# Configure alternative gpg options, defaulting to the newest installed binary
sudo update-alternatives --verbose --install /usr/local/bin/gpg gnupg /usr/local/bin/gpg2 100
sudo update-alternatives --verbose --install /usr/local/bin/gpg gnupg /usr/bin/gpg2 50
sudo update-alternatives --verbose --install /usr/local/bin/gpg gnupg /usr/bin/gpg 10

if [ ! -e "$HOME/.ssh/config" ]; then
  echo "Installing example .ssh/config ..."
  echo "${USER_SSH_CFG}" > $HOME/.ssh/config
fi

echo "Installing base configuration /etc/ssh/sshd_config ..."
if ! sudo cp -v configs/ssh/sshd.config /etc/ssh/sshd_config; then
  echo >&2 "WARNING: Failed to install sshd configuration."
else
  if ! sudo service ssh restart; then
    echo >&2 "WARNING: Failed to restart openssh service."
  fi
fi

if [ -e "/etc/rsyslog.d/" ]; then
  echo "Configuring OpenSSH user logging..."

  if [ ! -e "/etc/rsyslog.d/sshdusers.conf" ]; then
    if ! sudo cp -v configs/ssh/sshdusers.rsyslog /etc/rsyslog.d/sshdusers.conf; then
      echo >&2 "WARNING: Failed to install sshdusers rsyslog configuration."
    fi
  else
    if ! sudo service rsyslog restart; then
      echo >&2 "WARNING: Failed to restart rsyslog."
    fi
    echo "sshdusers rsyslog configuration is already installed."
  fi

  if [ ! -e "/etc/logrotate.d/sshdusers" ]; then
    if ! sudo bash -c 'echo "${LOGROTATE_CFG}" > /etc/logrotate.d/sshdusers'; then
      echo >&2 "WARNING: Failed to install logrotate configuration for sshdusers logging."
    fi
  else
    echo "sshdusers logrotate configuration is already installed."
  fi
fi

echo "Finished OpenSSH / GnuPG installation checks."

exit 0
