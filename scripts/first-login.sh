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

get_email() {
  echo
  echo "--------------------------------------------------------------------"
  echo "Setup Server Administration Email"
  echo "Emails will be used for future notification alert features"
  echo "--------------------------------------------------------------------"
  echo "Hit Enter To Skip..."
  echo "Will be prompted everytime run centmin.sh if both emails not entered"
  echo "--------------------------------------------------------------------"
  read -ep "enter primary email: " mainemail
  read -ep "enter secondary email: " secondemail
  echo "--------------------------------------------------------------------"

  if [ -z "$mainemail" ]; then
    mainemail=""
    rm -rf /etc/centminmod/email-primary.ini
    echo "primary email setup skipped..."
  else
    echo
    echo "Primary: $mainemail"
    echo "$mainemail" > /etc/centminmod/email-primary.ini
    echo "setup at /etc/centminmod/email-primary.ini"
    echo
    echo -n "  "
    cat /etc/centminmod/email-primary.ini
    echo
    if [ -f "$(which git)" ]; then
      git config --global user.email "$mainemail"
      git config --global user.name "cmm-user"
      # git config user.email
      # git config user.name
    fi
  fi
  if [ -z "$secondemail" ]; then
    secondemail=$mainemail
    rm -rf /etc/centminmod/email-secondary.ini
    echo "secondary email setup skipped..."
  else
    echo "Secondary: $secondemail"
    echo "$secondemail" > /etc/centminmod/email-secondary.ini
    echo "setup at /etc/centminmod/email-secondary.ini"
    echo
    echo -n "  "
    cat /etc/centminmod/email-secondary.ini
    echo
  fi
  echo
}

whitelistip() {
  # whitelist ssh log in user's IP in csf firewall
  # https://centminmod.com/csf_firewall.html
  echo
  echo "--------------------------------------------------------------------"
  echo "Whitelist IP in CSF Firewall"
  echo "--------------------------------------------------------------------"
  ssh_user_ip=$(echo $SSH_CLIENT | awk '{print $1}')
  csf -a ${ssh_user_ip} # do-firstlogin-ip-whitelisting
  echo "${ssh_user_ip}" >> /etc/csf/csf.ignore
  csf -ra >/dev/null 2>&1
  echo
}

set_hostname() {
  echo
  echo "--------------------------------------------------------------------"
  echo "Setup main hostname as per Getting Started Guide Step 1"
  echo "https://centminmod.com/getstarted.html"
  echo "--------------------------------------------------------------------"
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
  echo "--------------------------------------------------------------------"
  echo "Ensure centmin mod up to date"
  echo "--------------------------------------------------------------------"
  cmupdate
  echo
}

reset_mysqlroot() {
  echo
  echo "--------------------------------------------------------------------"
  echo "Generate mysql root password"
  echo "--------------------------------------------------------------------"
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
    echo "--------------------------------------------------------------------"
    echo "New MySQL root user password: $NEWMYSQLROOTPASS"
    echo "--------------------------------------------------------------------"
    echo
    sed -i "s|password=.*|password=$NEWMYSQLROOTPASS|" /root/.my.cnf
    echo "--------------------------------------------------------------------"
    echo "/root/.my.cnf updated"
    echo "--------------------------------------------------------------------"
    echo
    cat /root/.my.cnf
    echo
  fi
}

reset_bashrc() {
  cp -f /etc/skel/.bashrc /root/.bashrc
}

msg
get_email
set_hostname
whitelistip
cmm_update
reset_mysqlroot
reset_bashrc