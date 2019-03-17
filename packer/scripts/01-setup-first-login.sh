#!/bin/bash
# /var/lib/cloud/scripts/per-instance/01-setup-first-login.sh

# ensure /opt/centminmod directory is always present in droplet
if [ ! -d /opt/centminmod ]; then
  mkdir -p /opt/centminmod
fi

# override and use first-login.sh from github repo to ensure
# a new droplet launched with prebuilt images uses the latest
# version of the script without needing to rebuild the snapshot
# image every time first-login.sh is updated
if [ -f /opt/centminmod/first-login.sh ]; then
  # backup existing first-login.sh built with the snapshot image
  \cp -af /opt/centminmod/first-login.sh /opt/centminmod/first-login.sh-prebuilt
fi
wget -q -O /opt/centminmod/first-login.sh https://github.com/centminmod/centminmod-digitalocean-marketplace/raw/master/packer/scripts/first-login.sh
geterr=$?
if [[ "$geterr" -eq '0' ]]; then
  chmod +x /opt/centminmod/first-login.sh
else
  # if wget download of latest first-login.sh fails, use
  # previously prebuilt first-login.sh instead. This ensures
  # there's always at least one version of first-login.sh 
  # launched with a new droplet build with the snapshot image
  rm -f /opt/centminmod/first-login.sh
  \cp -af /opt/centminmod/first-login.sh-prebuilt /opt/centminmod/first-login.sh
  chmod +x /opt/centminmod/first-login.sh
fi
echo '/opt/centminmod/first-login.sh' >> /root/.bashrc