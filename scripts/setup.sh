#!/bin/bash

setup_vendorscript() {
  mkdir -p /opt/centminmod
  cp -a first-login.sh /opt/centminmod
  chmod +x /opt/centminmod/first-login.sh
  echo '/opt/centminmod/first-login.sh' >> /root/.bashrc
}

setup_vendorscript