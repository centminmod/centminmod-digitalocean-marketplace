#!/bin/bash
############################################################
# https://github.com/digitalocean/marketplace-partners/blob/master/marketplace_docs/build-an-image.md
############################################################

msg() {
echo "
===============================================================================
* Getting Started Guide - https://centminmod.com/getstarted.html
* Centmin Mod FAQ - https://centminmod.com/faq.html
* Centmin Mod Config Files - https://centminmod.com/configfiles.html
* Change Log - https://centminmod.com/changelog.html
* Community Forums https://community.centminmod.com  [ << Register ]
===============================================================================
"
}

whitelistip() {
  # whitelist ssh log in user's IP in csf firewall
  # https://centminmod.com/csf_firewall.html
  echo "whitelist IP in CSF Firewall"
  ssh_user_ip=$(echo $SSH_CLIENT | awk '{print $1}')
  csf -a ${ssh_user_ip} # do-firstlogin-ip-whitelisting
  echo "${ssh_user_ip}" >> /etc/csf/csf.ignore
  csf -ra >/dev/null 2>&1
}

set_hostname() {
  read -p "Enter desired hostname for this VPS: " yourhostname
  hostnamectl set-hostname $yourhostname
  IPADDR=$(hostname -I | cut -f1 -d' ')
  echo $IPADDR $yourhostname >> /etc/hosts
}

cmm_update() {
  echo "ensure centmin mod up to date"
  cmupdate
}

reset_mysqlroot() {
  echo "generate mysql root password"
  if [ -f /root/.my.cnf ]; then
    echo "Previous MySQL root password:"
    echo
    cat /root/.my.cnf
    echo
    OLDMYSQLROOTPASS=$(awk -F '=' '/password/ {print $2}' /root/.my.cnf)
    NEWMYSQLROOTPASS=$(openssl rand 21 -base64 | tr -dc 'a-zA-Z0-9')
    echo "mysqladmin -u root -p${OLDMYSQLROOTPASS} password $NEWMYSQLROOTPASS"
    mysqladmin -u root -p${OLDMYSQLROOTPASS} password $NEWMYSQLROOTPASS
    echo
    echo "New MySQL root user password: $NEWMYSQLROOTPASS"
    echo
    sed -i "s|password=.*|password=$NEWMYSQLROOTPASS|" /root/.my.cnf
    echo "/root/.my.cnf updated"
    echo
    cat /root/.my.cnf
    echo
  fi
}

reset_bashrc() {
  cp -f /etc/skel/.bashrc /root/.bashrc
}

msg
whitelist
cmm_update
set_hostname
reset_mysqlroot
reset_bashrc