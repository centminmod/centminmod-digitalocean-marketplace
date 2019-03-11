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

echo
echo "Below are a number of tasks required to initially setup your server"
sleep 2
updatedb
echo
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

reset_pureftpd_params() {
  echo
  echo "regenerate /etc/ssl/private/pure-ftpd-dhparams.pem"
  openssl dhparam -out /etc/ssl/private/pure-ftpd-dhparams.pem 2048 >/dev/null 2>&1

  echo
  echo "regenerating pure-ftpd self-signed ssl certificate"
  CNIP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
  openssl req -x509 -days 7300 -sha256 -nodes -subj "/C=US/ST=California/L=Los Angeles/O=Default Company Ltd/CN==$CNIP" -newkey rsa:1024 -keyout /etc/pki/pure-ftpd/pure-ftpd.pem -out /etc/pki/pure-ftpd/pure-ftpd.pem
  chmod 600 /etc/pki/pure-ftpd/*.pem
}

reset_memcache_admin() {
# Randomize memcache_${N}.php filename
N=$(od -vAn -N8 -tx < /dev/urandom | sed -e 's/\s//g')
rm -f /usr/local/nginx/html/memcache_*
\cp -a /usr/local/src/centminmod/config/memcached/memcache.php /usr/local/nginx/html/memcache_${N}.php
chown -R nginx:nginx /usr/local/nginx/html
chmod 644 /usr/local/nginx/html/memcache_${N}.php

sed -i "s/'ADMIN_USERNAME','memcache'/'ADMIN_USERNAME','memcacheuser'/g" /usr/local/nginx/html/memcache_${N}.php
sed -i "s/'ADMIN_PASSWORD','password'/'ADMIN_PASSWORD','memcachepass'/g" /usr/local/nginx/html/memcache_${N}.php
sed -i "s/mymemcache-server1:11211/localhost:11211/g" /usr/local/nginx/html/memcache_${N}.php
sed -i "s/\$MEMCACHE_SERVERS\[] = 'mymemcache-server2:11211'; \/\/ add more as an array/\/\/ mymemcache-server2:/g" /usr/local/nginx/html/memcache_${N}.php

CSALT=$(openssl rand 8 -base64 | tr -dc 'a-zA-Z0-9')
memcacheduser=$(echo "memadmin${CSALT}")
memcachedpassword=$(openssl rand 19 -base64 | tr -dc 'a-zA-Z0-9')

sed -i "s/'ADMIN_USERNAME','memcacheuser'/'ADMIN_USERNAME','${memcacheduser}'/g" /usr/local/nginx/html/memcache_${N}.php 2>&1>/dev/null
sed -i "s/'ADMIN_PASSWORD','memcachepass'/'ADMIN_PASSWORD','${memcachedpassword}'/g" /usr/local/nginx/html/memcache_${N}.php 2>&1>/dev/null
{
echo "--------------------------------------------------------------------"
echo "Memcached Server Admin Login File: /usr/local/nginx/html/memcache_${N}.php"
echo "Memcached Server Admin Login: ${hname}/memcache_${N}.php"
echo "new memcached username: ${memcacheduser}"
echo "new memcached password: ${memcachedpassword}"
echo "--------------------------------------------------------------------"
} 2>&1 | tee /opt/centminmod/memcache-admin-login.txt
}

reset_phpinfo() {
  locate phpi.php | while read f; do
    fname=$(basename ${f})
    if [[ "${fname}" = 'phpi.php' ]]; then
      cp -a "${f}" /usr/local/nginx/html/phpi.php
    else
      rm -f "${f}"
    fi
  done
  # Randomize phpi.php filename
  NPHP=$(od -vAn -N4 -tx < /dev/urandom)
  NPHP=$(echo ${NPHP} | sed -e 's/\s//')
  PHPISALT=$(openssl rand 11 -base64 | tr -dc 'a-zA-Z0-9')
  PHPIUSER=$(echo "phpiadmin${PHPISALT}")
  PHPIPASS=$(openssl rand 19 -base64 | tr -dc 'a-zA-Z0-9')
  echo ""
  mv /usr/local/nginx/html/phpi.php "/usr/local/nginx/html/${NPHP}_phpi.php"
  sed -i "s|PHPUSERNAME|$PHPIUSER|" "/usr/local/nginx/html/${NPHP}_phpi.php"
  sed -i "s|PHPPASSWORD|$PHPIPASS|" "/usr/local/nginx/html/${NPHP}_phpi.php"
  chown nginx:nginx "/usr/local/nginx/html/${NPHP}_phpi.php"
  {
  echo "--------------------------------------------------------------------"
  echo "PHP Info Login File: /usr/local/nginx/html/${NPHP}_phpi.php"
  echo "PHP Info Login: ${hname}/${NPHP}_phpi.php"
  echo "PHP Info Login username: ${PHPIUSER}"
  echo "PHP Info Login password: ${PHPIPASS}"
  echo "--------------------------------------------------------------------"
  echo
  } 2>&1 | tee /opt/centminmod/php-info-password.txt
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
    cat /root/.my.cnf | tee /opt/centminmod/mysql-root-password.txt
    echo
  fi
}

auditd_cleanup() {
  if [ -f /var/log/audit/audit.log ]; then
    find /var/log/audit/audit.log -mtime -1 -type f -exec truncate -s 0 {} \;
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
reset_pureftpd_params
reset_memcache_admin
reset_phpinfo
reset_mysqlroot
auditd_cleanup
reset_bashrc