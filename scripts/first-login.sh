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
  echo
  echo "----------------------------------------------------------"
  echo "Whitelist IP in CSF Firewall"
  echo "----------------------------------------------------------"
  ssh_user_ip=$(echo $SSH_CLIENT | awk '{print $1}')
  csf -a ${ssh_user_ip} # do-firstlogin-ip-whitelisting
  echo "${ssh_user_ip}" >> /etc/csf/csf.ignore
  csf -ra >/dev/null 2>&1
  echo
}

set_hostname() {
  echo
  echo "----------------------------------------------------------"
  echo "Setup main hostname as per Getting Started Guide Step 1"
  echo "https://centminmod.com/getstarted.html"
  echo "----------------------------------------------------------"
  echo
  read -p "Enter desired hostname for this VPS: " yourhostname
  echo
  hostnamectl set-hostname $yourhostname
  IPADDR=$(hostname -I | cut -f1 -d' ')
  echo $IPADDR $yourhostname >> /etc/hosts
  if [ -f /usr/local/nginx/conf/conf.d/virtual.conf ]; then
    sed -i "s|server_name .*|server_name ${yourhostname};|" /usr/local/nginx/conf/conf.d/virtual.conf
  fi
}

cmm_update() {
  echo
  echo "----------------------------------------------------------"
  echo "Ensure centmin mod up to date"
  echo "----------------------------------------------------------"
  cmupdate
  echo
}

reset_mysqlroot() {
  echo
  echo "----------------------------------------------------------"
  echo "Generate mysql root password"
  echo "----------------------------------------------------------"
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
    echo "----------------------------------------------------------"
    echo "New MySQL root user password: $NEWMYSQLROOTPASS"
    echo "----------------------------------------------------------"
    echo
    sed -i "s|password=.*|password=$NEWMYSQLROOTPASS|" /root/.my.cnf
    echo "----------------------------------------------------------"
    echo "/root/.my.cnf updated"
    echo "----------------------------------------------------------"
    echo
    cat /root/.my.cnf
    echo
  fi
}

reset_bashrc() {
  cp -f /etc/skel/.bashrc /root/.bashrc
}

msg
whitelistip
cmm_update
set_hostname
reset_mysqlroot
reset_bashrc