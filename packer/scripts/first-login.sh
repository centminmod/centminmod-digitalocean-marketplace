#!/bin/bash
############################################################
# https://github.com/digitalocean/marketplace-partners/blob/master/marketplace_docs/build-an-image.md
############################################################
VER=0.1
TOTALMEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
TOTALMEM_T=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
TOTALMEM_SWAP=$(awk '/SwapFree/ {print $2}' /proc/meminfo)
HOME_DFSIZE=$(df --output=avail /home | tail -1)
CONFIGSCANDIR='/etc/centminmod/php.d'

if [ ! -d /opt/centminmod ]; then
  mkdir -p /opt/centminmod
fi

bookmark() {
echo "
===============================================================================
* Getting Started Guide - https://centminmod.com/getstarted.html
* Centmin Mod FAQ - https://centminmod.com/faq.html
* Centmin Mod Config Files - https://centminmod.com/configfiles.html
* Change Log - https://centminmod.com/changelog.html
* Community Forums https://community.centminmod.com  [ << Register ]
* Cloudflare with Centmin Mod Nginx https://centminmod.com/nginx_configure_cloudflare.html
===============================================================================
"

echo
}

msg() {
bookmark
echo "Running a number of tasks required to initially setup your server"
sleep 2
updatedb
echo
}

yum_updates() {
  echo
  echo "--------------------------------------------------------------------"
  echo "Ensure yum packages are up to date"
  echo
  yum -y update --enablerepo=remi
  echo
  echo "--------------------------------------------------------------------"
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
}

set_hostname() {
  echo
  echo "--------------------------------------------------------------------"
  echo "Setup main hostname as per Getting Started Guide Step 1"
  echo "https://centminmod.com/getstarted.html"
  echo
  echo "Main hostname is not same as desired site domain name but"
  echo "used for where server statistics files get hosted as outlined"
  echo "here https://community.centminmod.com/threads/1513/"
  echo
  echo "It's usually something like host.domain.com"
  echo "--------------------------------------------------------------------"
  echo
  read -ep "Enter desired main hostname for this VPS: " yourhostname
  echo
  hostnamectl set-hostname $yourhostname
  IPADDR=$(hostname -I | cut -f1 -d' ')
  echo $IPADDR $yourhostname >> /etc/hosts
  if [ -f /usr/local/nginx/conf/conf.d/virtual.conf ]; then
    sed -i "s|server_name .*|server_name ${yourhostname};|" /usr/local/nginx/conf/conf.d/virtual.conf
    echo "updated main hostname nginx vhost at"
    echo "/usr/local/nginx/conf/conf.d/virtual.conf"
  fi
}

cmm_update() {
  echo
  echo "--------------------------------------------------------------------"
  echo "Ensure centmin mod up to date"
  echo "--------------------------------------------------------------------"
  cd /usr/local/src
  mv centminmod centminmod-automoved
  branchname=123.09beta01
  git clone -b ${branchname} --depth=1 https://github.com/centminmod/centminmod.git centminmod
  if [[ "$?" -eq '0' ]]; then
    rm -rf centminmod-automoved
    echo
    echo "Completed. Fresh /usr/local/src/centminmod code base in place"
    # echo "To run centmin.sh again, you need to change into directory: /usr/local/src/centminmod"
    # echo "cd /usr/local/src/centminmod"
  else
    mv centminmod-automoved centminmod
    echo
    echo "Error: wasn't able to successfully update /usr/local/src/centminmod code base"
    echo "       restoring previous copy of /usr/local/src/centminmod code base"
  fi
  echo
}

reset_pureftpd_params() {
  # echo
  echo "--------------------------------------------------------------------"
  echo "regenerate pure-ftpd ssl cert /etc/ssl/private/pure-ftpd-dhparams.pem"
  echo "please wait... can take a few minutes depending on speed of server"
  echo "--------------------------------------------------------------------"
  if [ -f /etc/ssl/private/pure-ftpd-dhparams.pem ]; then
    rm -f /etc/ssl/private/pure-ftpd-dhparams.pem
  fi
  openssl dhparam -out /etc/ssl/private/pure-ftpd-dhparams.pem 2048 >/dev/null 2>&1

  echo
  echo "--------------------------------------------------------------------"
  echo "regenerating pure-ftpd self-signed ssl certificate"
  echo "--------------------------------------------------------------------"
  CNIP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
  if [ -f /etc/pki/pure-ftpd/pure-ftpd.pem ]; then
    rm -f /etc/pki/pure-ftpd/pure-ftpd.pem
  fi
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
  } 2>&1 | tee /opt/centminmod/php-info-password.txt
}

reset_opcache() {
  echo
  echo "--------------------------------------------------------------------"
  echo "Generate Zend Opcache Admin password"
  echo "--------------------------------------------------------------------"
  N=$(od -vAn -N8 -tx < /dev/urandom | sed -e 's/\s//g')
  locate opcache.php | while read f; do
    fname=$(basename ${f})
    if [[ "${fname}" = 'opcache.php' ]]; then
      cp -a "${f}" /usr/local/nginx/html/${N}_opcache.php
    else
      rm -f "${f}"
    fi
  done
  echo
  echo "reset initial /usr/local/nginx/html/opcache.php"
  echo
  OPSALT=$(openssl rand 10 -base64 | tr -dc 'a-zA-Z0-9')
  OPUSER=$(echo "opadmin${OPSALT}")
  OPPASS=$(openssl rand 22 -base64 | tr -dc 'a-zA-Z0-9')
  
  sed -i "s|OPCACHEUSERNAME|$OPUSER|" /usr/local/nginx/html/${N}_opcache.php
  sed -i "s|OPCACHEPASSWORD|$OPPASS|" /usr/local/nginx/html/${N}_opcache.php

  echo "" > /root/centminlogs/zendopcache_passfile.txt
  echo "-------------------------------------------------------" >> /root/centminlogs/zendopcache_passfile.txt
  echo "File Location: /usr/local/nginx/html/${N}_opcache.php" >> /root/centminlogs/zendopcache_passfile.txt
  echo "Password protected ${hname}/${N}_opcache.php" >> /root/centminlogs/zendopcache_passfile.txt
  echo "-------------------------------------------------------" >> /root/centminlogs/zendopcache_passfile.txt
  echo "Username: $OPUSER" >> /root/centminlogs/zendopcache_passfile.txt
  echo "Password: $OPPASS" >> /root/centminlogs/zendopcache_passfile.txt
  echo "-------------------------------------------------------" >> /root/centminlogs/zendopcache_passfile.txt

  /usr/local/nginx/conf/htpasswd.sh create /usr/local/nginx/conf/htpasswd_opcache $OPUSER $OPPASS

cat > "/usr/local/nginx/conf/include_opcache.conf" <<EOF
            location ~ ^/(${N}_opcache.php) {
    include /usr/local/nginx/conf/php.conf;
  auth_basic "Password Protected";
  auth_basic_user_file /usr/local/nginx/conf/htpasswd_opcache;
            }
EOF

  {
    cat /root/centminlogs/zendopcache_passfile.txt
  } 2>&1 | tee /opt/centminmod/zend-opcache-admin-login.txt
}

reset_mysqlroot() {
  echo
  echo "--------------------------------------------------------------------"
  echo "Generate mysql root password"
  echo "--------------------------------------------------------------------"
  if [ -f /root/.my.cnf ]; then
    echo
    OLDMYSQLROOTPASS=$(awk -F '=' '/password/ {print $2}' /root/.my.cnf)
    NEWMYSQLROOTPASS=$(openssl rand 21 -base64 | tr -dc 'a-zA-Z0-9')
    echo "setup mysql root password"
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

log_cleanup() {
  if [ -f /var/log/audit/audit.log ]; then
    # remove packer snapshot image builder entries
    find /var/log/audit/audit.log -mtime -1 -type f -exec truncate -s 0 {} \;
  fi
  if [ -f /var/log/messages ]; then
    # remove packer snapshot image builder entries
    sed -i '1,28d' /var/log/messages
    sed -i '/Set hostname to <packer/d' /var/log/messages
  fi
  if [ -f /var/log/lfd.log ]; then
    # remove packer snapshot image builder entries
    sed -i '1,6d' /var/log/lfd.log
  fi
  if [ -f /var/log/secure ]; then
    # remove packer snapshot image builder entries
    sed -i '1d' /var/log/secure
  fi
  if [ -f /etc/csf/csf.allow ]; then
    # remove packer snapshot image builder entries
    sed -i '/csf SSH installation/d' /etc/csf/csf.allow
  fi
  if [ -f /etc/csf/csf.ignore ]; then
    # remove packer snapshot image builder entries
    sed -i '/127.0.0.1/{n;N;d}' /etc/csf/csf.ignore
  fi
  rm -f /tmp/script_*
  rm -f /home/script_*
}

service_checks() {
  if [[ -f /usr/lib/systemd/system/redis.service && "$(systemctl status redis >/dev/null 2>&1; echo $?)" -ne '0' ]]; then
    service redis start >/dev/null 2>&1
    chkconfig redis on >/dev/null 2>&1
  fi
}

reset_bashrc() {
  echo
  echo "--------------------------------------------------------------------"
  echo "cleanup /root/.bashrc"
  echo "--------------------------------------------------------------------"
  sed -i '/first-login.sh/d' /root/.bashrc
  # sed -i '/first-login.sh/d' /usr/local/bin/dmotd
  if [ -f /opt/centminmod/first-login-run ]; then
    rm -f /opt/centminmod/first-login-run
  fi
  if [ -f /opt/centminmod/first-login.sh ]; then
    rm -f /opt/centminmod/first-login.sh
  fi
  if [ -f /opt/centminmod/first-login.sh-prebuilt ]; then
    rm -f /opt/centminmod/first-login.sh-prebuilt
  fi
  if [ -f /var/lib/cloud/scripts/per-instance/01-setup-first-login.sh ]; then
    rm -f /var/lib/cloud/scripts/per-instance/01-setup-first-login.sh
  fi
  chown -R nginx:nginx /usr/local/nginx/html
}

tmpsetup() {
  echo "CentOS 7 Setup /tmp"
  echo "CentOS 7 + non-OpenVZ virtualisation detected"
  systemctl is-enabled tmp.mount
  # only mount /tmp on tmpfs if CentOS system
  # total memory size is greater than ~15.25GB
  # will give /tmp a size equal to 1/2 total memory
  if [[ "$TOTALMEM" -ge '16000001' ]]; then
     cp -ar /tmp /tmp_backup
     #rm -rf /tmp
     #mkdir -p /tmp
     mount -t tmpfs -o rw,noexec,nosuid tmpfs /tmp
     chmod 1777 /tmp
     cp -ar /tmp_backup/* /tmp
     echo "tmpfs /tmp tmpfs rw,noexec,nosuid 0 0" >> /etc/fstab
     cp -ar /var/tmp /var/tmp_backup
     ln -s /tmp /var/tmp
     cp -ar /var/tmp_backup/* /tmp
     rm -rf /tmp_backup
     rm -rf /var/tmp_backup
  elif [[ "$TOTALMEM" -ge '8100001' || "$TOTALMEM" -lt '16000000' ]]; then
     # set on disk non-tmpfs /tmp to 6GB size
     # if total memory is between 2GB and <8GB
     cp -ar /tmp /tmp_backup
     # rm -rf /tmp
     if [[ "$HOME_DFSIZE" -le '15750000' ]]; then
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=1048576
     elif [[ "$HOME_DFSIZE" -gt '15750001' && "$HOME_DFSIZE" -le '20999000' ]]; then
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=2097152
     else
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=6291456
     fi
     echo Y | mkfs.ext4 /home/usertmp_donotdelete
     # mkdir -p /tmp
     mount -t ext4 -o loop,rw,noexec,nosuid /home/usertmp_donotdelete /tmp
     chmod 1777 /tmp
     cp -ar /tmp_backup/* /tmp
     echo "/home/usertmp_donotdelete /tmp ext4 loop,rw,noexec,nosuid 0 0" >> /etc/fstab
     cp -ar /var/tmp /var/tmp_backup
     ln -s /tmp /var/tmp
     cp -ar /var/tmp_backup/* /tmp
     rm -rf /tmp_backup
     rm -rf /var/tmp_backup
  elif [[ "$TOTALMEM" -ge '2050061' || "$TOTALMEM" -lt '8100000' ]]; then
     # set on disk non-tmpfs /tmp to 4GB size
     # if total memory is between 2GB and <8GB
     cp -ar /tmp /tmp_backup
     # rm -rf /tmp
     if [[ "$HOME_DFSIZE" -le '15750000' ]]; then
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=1048576
     elif [[ "$HOME_DFSIZE" -gt '15750001' && "$HOME_DFSIZE" -le '20999000' ]]; then
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=2097152
     else
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=4194304
     fi
     echo Y | mkfs.ext4 /home/usertmp_donotdelete
     # mkdir -p /tmp
     mount -t ext4 -o loop,rw,noexec,nosuid /home/usertmp_donotdelete /tmp
     chmod 1777 /tmp
     cp -ar /tmp_backup/* /tmp
     echo "/home/usertmp_donotdelete /tmp ext4 loop,rw,noexec,nosuid 0 0" >> /etc/fstab
     cp -ar /var/tmp /var/tmp_backup
     ln -s /tmp /var/tmp
     cp -ar /var/tmp_backup/* /tmp
     rm -rf /tmp_backup
     rm -rf /var/tmp_backup
  elif [[ "$TOTALMEM" -ge '1153434' || "$TOTALMEM" -lt '2050060' ]]; then
     # set on disk non-tmpfs /tmp to 2GB size
     # if total memory is between 1.1-2GB
     cp -ar /tmp /tmp_backup
     # rm -rf /tmp
     if [[ "$HOME_DFSIZE" -le '15750000' ]]; then
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=1048576
     elif [[ "$HOME_DFSIZE" -gt '15750001' && "$HOME_DFSIZE" -le '20999000' ]]; then
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=2097152
     else
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=3000000
     fi
     echo Y | mkfs.ext4 /home/usertmp_donotdelete
     # mkdir -p /tmp
     mount -t ext4 -o loop,rw,noexec,nosuid /home/usertmp_donotdelete /tmp
     chmod 1777 /tmp
     cp -ar /tmp_backup/* /tmp
     echo "/home/usertmp_donotdelete /tmp ext4 loop,rw,noexec,nosuid 0 0" >> /etc/fstab
     cp -ar /var/tmp /var/tmp_backup
     ln -s /tmp /var/tmp
     cp -ar /var/tmp_backup/* /tmp
     rm -rf /tmp_backup
     rm -rf /var/tmp_backup
  elif [[ "$TOTALMEM" -le '1153433' ]]; then
     # set on disk non-tmpfs /tmp to 1GB size
     # if total memory is <1.1GB
     cp -ar /tmp /tmp_backup
     # rm -rf /tmp
     if [[ "$HOME_DFSIZE" -le '15750000' ]]; then
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=1048576
     elif [[ "$HOME_DFSIZE" -gt '15750001' && "$HOME_DFSIZE" -le '20999000' ]]; then
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=2097152
     else
      dd if=/dev/zero of=/home/usertmp_donotdelete bs=1024 count=3000000
     fi
     echo Y | mkfs.ext4 /home/usertmp_donotdelete
     # mkdir -p /tmp
     mount -t ext4 -o loop,rw,noexec,nosuid /home/usertmp_donotdelete /tmp
     chmod 1777 /tmp
     cp -ar /tmp_backup/* /tmp
     echo "/home/usertmp_donotdelete /tmp ext4 loop,rw,noexec,nosuid 0 0" >> /etc/fstab
     cp -ar /var/tmp /var/tmp_backup
     ln -s /tmp /var/tmp       
     cp -ar /var/tmp_backup/* /tmp
     rm -rf /tmp_backup
     rm -rf /var/tmp_backup
  fi
}

tmpfix() {
  # digitalocean single / root partition doesn't require separate larger
  # /tmp directory like bare metal where folks may partition /tmp too
  # small for real world usage and run into problems.
  # digitalocean VPS won't run into such issues due to /tmp mounted on 
  # single / root partition
  # echo
  # echo "--------------------------------------------------------------------"
  # echo "/tmp adjustment"
  # echo "--------------------------------------------------------------------"
  sed -i '/usertmp_donotdelete/d' /etc/fstab
  rm -f /home/usertmp_donotdelete
  mount -a
}

autotune_nginx() {
if [ -f /usr/local/nginx/conf/nginx.conf ]; then
  echo "auto tune nginx"

NOCPUS=$(grep "processor" /proc/cpuinfo |wc -l)
NGINXCONFCPU='/usr/local/nginx/conf/nginx.conf'
if [[ "$(grep 'worker_processes' $NGINXCONFCPU | grep -o 2)" -eq '2' ]]; then
  WORKERCHECKA=$(grep 'worker_processes  2;' $NGINXCONFCPU)
  WORKERCHECKB=$(grep 'worker_processes 2;' $NGINXCONFCPU)
else
  WORKERCHECKA=$(grep 'worker_processes  1;' $NGINXCONFCPU)
  WORKERCHECKB=$(grep 'worker_processes 1;' $NGINXCONFCPU)
fi

if [[ "$NOCPUS" -le "2" ]]; then
        NOCPUS=$NOCPUS

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [[ "$NOCPUS" -le 4 && "$NOCPUS" -gt 2 ]]; then    
        NOCPUS=$(echo "$NOCPUS"/2 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [[ "$NOCPUS" -le "6" && "$NOCPUS" -gt "4" ]]; then
        NOCPUS=$(echo "$NOCPUS"/2 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [ "$NOCPUS" = "7" ]; then
        NOCPUS=$(echo "$NOCPUS"/2.333 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [ "$NOCPUS" = "8" ]; then
        NOCPUS=$(echo "$NOCPUS"/2 | bc)

        echo
  if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
    sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
  elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
    sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
  fi
fi
if [[ "$NOCPUS" -le "10" && "$NOCPUS" -gt "8" ]]; then
        NOCPUS=$(echo "$NOCPUS"/2 | bc)

        echo
  if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
    sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
  elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
    sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
  fi
fi
if [ "$NOCPUS" = "11" ]; then
        NOCPUS=$(echo "$NOCPUS"/2 | bc)

        echo
  if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
    sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
  elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
    sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
  fi
fi
if [ "$NOCPUS" = "12" ]; then
        NOCPUS=$(echo "$NOCPUS"/2 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [[ "$NOCPUS" -le "15" && "$NOCPUS" -ge "13" ]]; then
        NOCPUS=$(echo "$NOCPUS"/2.1 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [[ "$NOCPUS" -le "16" && "$NOCPUS" -gt "12" ]]; then
        NOCPUS=$(echo "$NOCPUS"/2 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [[ "$NOCPUS" -le "23" && "$NOCPUS" -ge "17" ]]; then
        NOCPUS=$(echo "$NOCPUS"/2.1 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [[ "$NOCPUS" -le "31" && "$NOCPUS" -ge "24" ]]; then
        NOCPUS=$(echo "$NOCPUS"/2.4 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [[ "$NOCPUS" -le "47" && "$NOCPUS" -ge "32" ]]; then
        NOCPUS=$(echo "$NOCPUS"/2.6 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [[ "$NOCPUS" -le "64" && "$NOCPUS" -ge "48" ]]; then
        NOCPUS=$(echo "$NOCPUS"/2.666 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [[ "$NOCPUS" -le "127" && "$NOCPUS" -ge "65" ]]; then
        NOCPUS=$(echo "$NOCPUS"/4.7083 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi
if [[ "$NOCPUS" -le "191" && "$NOCPUS" -ge "128" ]]; then
        NOCPUS=$(echo "$NOCPUS"/6.4 +10 | bc)

        echo
  if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
    sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
  elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
    sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
  fi
fi
if [[ "$NOCPUS" -le "256" && "$NOCPUS" -ge "192" ]]; then
        NOCPUS=$(echo "$NOCPUS"/6.4 +10 | bc)

        echo
  if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
    sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
  elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
    sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
  fi
fi
if [[ "$NOCPUS" -ge "257" ]]; then
        NOCPUS=$(echo "$NOCPUS"/6.5 +10 | bc)

        echo
    if [[ ! -z "$WORKERCHECKA" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*;/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    elif [[ ! -z "$WORKERCHECKB" ]]; then
        #echo "set cpu worker_processes to $NOCPUS"
        sed -i "s/worker_processes .*/worker_processes $NOCPUS;/g" $NGINXCONFCPU
    fi
fi

fi
}

autotune_php() {
    echo "auto tune php"
    TOTALMEM_T=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    TOTALMEM_SWAP=$(awk '/SwapFree/ {print $2}' /proc/meminfo)
    PHPINICUSTOM='a_customphp.ini'
    CUSTOMPHPINIFILE="${CONFIGSCANDIR}/${PHPINICUSTOM}"

    if [[ "$CENTOS_SIX" = '6' ]]; then
      if [[ ! -f /proc/user_beancounters && -f /usr/bin/numactl ]]; then
        # account for multiple cpu socket numa based memory
        # https://community.centminmod.com/posts/48189/
        GETCPUNODE_COUNT=$(numactl --hardware | awk '/available: / {print $2}')
        if [[ "$GETCPUNODE_COUNT" -ge '2' ]]; then
          FREEMEM_NUMANODE=$(($(numactl --hardware | awk '/free:/ {print $4}' | sort -r | head -n1)*1024))
          FREEMEMCACHED=$(egrep '^Buffers|^Cached' /proc/meminfo | awk '{summ+=$2} END {print summ}' | head -n1)
          FREEMEM=$(($FREEMEM_NUMANODE+$FREEMEMCACHED))
        else
          FREEMEM=$(egrep '^MemFree|^Buffers|^Cached' /proc/meminfo | awk '{summ+=$2} END {print summ}' | head -n1)
        fi
      elif [[ -f /proc/user_beancounters ]]; then
        FREEMEMOPENVZ=$(grep '^MemFree' /proc/meminfo | awk '{summ+=$2} END {print summ}' | head -n1)
        FREEMEMCACHED=$(egrep '^Buffers|^Cached' /proc/meminfo | awk '{summ+=$2} END {print summ}' | head -n1)
        FREEMEM=$(($FREEMEMOPENVZ+$FREEMEMCACHED))
      else
        FREEMEM=$(egrep '^MemFree|^Buffers|^Cached' /proc/meminfo | awk '{summ+=$2} END {print summ}' | head -n1)
      fi
    elif [[ "$CENTOS_SEVEN" = '7' ]]; then
      if [[ ! -f /proc/user_beancounters && -f /usr/bin/numactl ]]; then
        # account for multiple cpu socket numa based memory
        # https://community.centminmod.com/posts/48189/
        GETCPUNODE_COUNT=$(numactl --hardware | awk '/available: / {print $2}')
        if [[ "$GETCPUNODE_COUNT" -ge '2' ]]; then
          FREEMEM_NUMANODE=$(($(numactl --hardware | awk '/free:/ {print $4}' | sort -r | head -n1)*1024))
          FREEMEMCACHED=$(egrep '^Buffers|^Cached' /proc/meminfo | awk '{summ+=$2} END {print summ}' | head -n1)
          FREEMEM=$(($FREEMEM_NUMANODE+$FREEMEMCACHED))
        else
          FREEMEM=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
        fi
      elif [[ -f /proc/user_beancounters ]]; then
        FREEMEMOPENVZ=$(grep '^MemFree' /proc/meminfo | awk '{summ+=$2} END {print summ}' | head -n1)
        FREEMEMCACHED=$(egrep '^Buffers|^Cached' /proc/meminfo | awk '{summ+=$2} END {print summ}' | head -n1)
        FREEMEM=$(($FREEMEMOPENVZ+$FREEMEMCACHED))
      else
        FREEMEM=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
      fi
    fi
    TOTALMEM_PHP=$FREEMEM

    if [[ ! -f "${CUSTOMPHPINIFILE}" ]]; then
        touch ${CUSTOMPHPINIFILE}
    else
        \cp -a ${CUSTOMPHPINIFILE} ${CUSTOMPHPINIFILE}-bak_$DT
        rm -rf $CUSTOMPHPINIFILE
        rm -rf ${CONFIGSCANDIR}/custom_php.ini
        echo "" > ${CUSTOMPHPINIFILE}
    fi

    if [[ "$(date +"%Z")" = 'EST' ]]; then
        echo "date.timezone = Australia/Brisbane" >> ${CUSTOMPHPINIFILE}
    else
        echo "date.timezone = UTC" >> ${CUSTOMPHPINIFILE}
    fi

    # dynamic PHP memory_limit calculation
    if [[ "$TOTALMEM_PHP" -le '262144' ]]; then
        ZOLIMIT='32'
        PHP_MEMORYLIMIT='48M'
        PHP_UPLOADLIMIT='48M'
        PHP_REALPATHLIMIT='512k'
        PHP_REALPATHTTL='14400'
    elif [[ "$TOTALMEM_PHP" -gt '262144' && "$TOTALMEM_PHP" -le '393216' ]]; then
        ZOLIMIT='80'
        PHP_MEMORYLIMIT='96M'
        PHP_UPLOADLIMIT='96M'
        PHP_REALPATHLIMIT='640k'
        PHP_REALPATHTTL='21600'
    elif [[ "$TOTALMEM_PHP" -gt '393216' && "$TOTALMEM_PHP" -le '524288' ]]; then
        ZOLIMIT='112'
        PHP_MEMORYLIMIT='128M'
        PHP_UPLOADLIMIT='128M'
        PHP_REALPATHLIMIT='768k'
        PHP_REALPATHTTL='28800'
    elif [[ "$TOTALMEM_PHP" -gt '524288' && "$TOTALMEM_PHP" -le '1049576' ]]; then
        ZOLIMIT='144'
        PHP_MEMORYLIMIT='160M'
        PHP_UPLOADLIMIT='160M'
        PHP_REALPATHLIMIT='768k'
        PHP_REALPATHTTL='28800'
    elif [[ "$TOTALMEM_PHP" -gt '1049576' && "$TOTALMEM_PHP" -le '2097152' ]]; then
        ZOLIMIT='160'
        PHP_MEMORYLIMIT='320M'
        PHP_UPLOADLIMIT='320M'
        PHP_REALPATHLIMIT='1536k'
        PHP_REALPATHTTL='28800'
    elif [[ "$TOTALMEM_PHP" -gt '2097152' && "$TOTALMEM_PHP" -le '3145728' ]]; then
        ZOLIMIT='192'
        PHP_MEMORYLIMIT='384M'
        PHP_UPLOADLIMIT='384M'
        PHP_REALPATHLIMIT='2048k'
        PHP_REALPATHTTL='43200'
    elif [[ "$TOTALMEM_PHP" -gt '3145728' && "$TOTALMEM_PHP" -le '4194304' ]]; then
        ZOLIMIT='224'
        PHP_MEMORYLIMIT='512M'
        PHP_UPLOADLIMIT='512M'
        PHP_REALPATHLIMIT='3072k'
        PHP_REALPATHTTL='43200'
    elif [[ "$TOTALMEM_PHP" -gt '4194304' && "$TOTALMEM_PHP" -le '8180000' ]]; then
        ZOLIMIT='288'
        PHP_MEMORYLIMIT='640M'
        PHP_UPLOADLIMIT='640M'
        PHP_REALPATHLIMIT='4096k'
        PHP_REALPATHTTL='43200'
    elif [[ "$TOTALMEM_PHP" -gt '8180000' && "$TOTALMEM_PHP" -le '16360000' ]]; then
        ZOLIMIT='320'
        PHP_MEMORYLIMIT='800M'
        PHP_UPLOADLIMIT='800M'
        PHP_REALPATHLIMIT='4096k'
        PHP_REALPATHTTL='43200'
    elif [[ "$TOTALMEM_PHP" -gt '16360000' && "$TOTALMEM_PHP" -le '32400000' ]]; then
        ZOLIMIT='480'
        PHP_MEMORYLIMIT='1024M'
        PHP_UPLOADLIMIT='1024M'
        PHP_REALPATHLIMIT='4096k'
        PHP_REALPATHTTL='43200'
    elif [[ "$TOTALMEM_PHP" -gt '32400000' && "$TOTALMEM_PHP" -le '64800000' ]]; then
        ZOLIMIT='600'
        PHP_MEMORYLIMIT='1280M'
        PHP_UPLOADLIMIT='1280M'
        PHP_REALPATHLIMIT='4096k'
        PHP_REALPATHTTL='43200'
    elif [[ "$TOTALMEM_PHP" -gt '64800000' ]]; then
        ZOLIMIT='800'
        PHP_MEMORYLIMIT='2048M'
        PHP_UPLOADLIMIT='2048M'
        PHP_REALPATHLIMIT='8192k'
        PHP_REALPATHTTL='86400'
    fi

    echo "max_execution_time = 60" >> ${CUSTOMPHPINIFILE}
    echo "short_open_tag = On" >> ${CUSTOMPHPINIFILE}
    echo "realpath_cache_size = $PHP_REALPATHLIMIT" >> ${CUSTOMPHPINIFILE}
    echo "realpath_cache_ttl = $PHP_REALPATHTTL" >> ${CUSTOMPHPINIFILE}
    echo "upload_max_filesize = $PHP_UPLOADLIMIT" >> ${CUSTOMPHPINIFILE}
    echo "memory_limit = $PHP_MEMORYLIMIT" >> ${CUSTOMPHPINIFILE}
    echo "post_max_size = $PHP_UPLOADLIMIT" >> ${CUSTOMPHPINIFILE}
    echo "expose_php = Off" >> ${CUSTOMPHPINIFILE}
    echo "mail.add_x_header = Off" >> ${CUSTOMPHPINIFILE}
    echo "max_input_nesting_level = 128" >> ${CUSTOMPHPINIFILE}
    echo "max_input_vars = 10000" >> ${CUSTOMPHPINIFILE}
    echo "mysqlnd.net_cmd_buffer_size = 16384" >> ${CUSTOMPHPINIFILE}
    echo "mysqlnd.collect_memory_statistics = Off" >> ${CUSTOMPHPINIFILE}
    echo "mysqlnd.mempool_default_size = 16000" >> ${CUSTOMPHPINIFILE}
    echo "always_populate_raw_post_data=-1" >> ${CUSTOMPHPINIFILE}

    if [ -f "${CONFIGSCANDIR}/zendopcache.ini" ]; then
      sed -i "s|opcache.memory_consumption=.*|opcache.memory_consumption=$ZOLIMIT|" "${CONFIGSCANDIR}/zendopcache.ini"
    fi
    echo "contents of ${CUSTOMPHPINIFILE}"
    cat "${CUSTOMPHPINIFILE}"
}

autotune_mysql() {
  # https://community.centminmod.com/posts/25691/
  if [ -f /usr/local/src/centminmod/tools/setio.sh ]; then
    echo
    echo "auto tune mysql"
      /usr/local/src/centminmod/tools/setio.sh set
      mysqlrestart >/devnull 2>&1
  fi  
}

autotune_cpu() {
  # tune-adm
  # tuned-adm list
  tuned-adm profile latency-performance  >/devnull 2>&1
}

autotune() {
  echo
  echo "--------------------------------------------------------------------"
  echo "auto tune Centmin Mod LEMP stack settings"
  echo "based on detected server environment"
  echo "--------------------------------------------------------------------"
  autotune_nginx
  autotune_php
  autotune_mysql
  autotune_cpu
  echo
}

enable_phpstatus() {
  echo
  echo "--------------------------------------------------------------------"
  echo "enable php-fpm status for localhost only ?"
  echo "as per https://centminmod.com/phpfpm.html#phpstatus"
  echo "--------------------------------------------------------------------"
  read -ep "Do you want to enable php-fpm status page ? [y/n]: " enablephpstatus
  echo
  if [[ "$enablephpstatus" = [yY] ]]; then
    sed -i 's|^#include /usr/local/nginx/conf/phpstatus.conf;|include /usr/local/nginx/conf/phpstatus.conf;|' /usr/local/nginx/conf/conf.d/virtual.conf
    nprestart >/dev/null 2>&1
    echo "php-fpm status enabled"
    echo
    echo "curl -s localhost/phpstatus"
    curl -s localhost/phpstatus
    echo
    # sleep 3
    echo "shortcut command = fpmstats"
  fi
}

do_spaces_setup() {
  echo
  echo "--------------------------------------------------------------------"
  echo "setup DigitalOcean Spaces + s3cmd"
  echo "https://www.digitalocean.com/docs/spaces/resources/s3cmd/"
  echo "--------------------------------------------------------------------"
  echo
  read -ep "Do you want to setup DigitalOcean Spaces & s3cdm ? [y/n]: " setup_spaces
  echo
  if [[ "$setup_spaces" = [yY] ]]; then
    echo "installing s3cmd via yum"
    echo "please wait..."
    yum -y -q install s3cmd >/dev/null 2>&1
    spaces_err=$?
    if [[ "$spaces_err" -ne '0' ]]; then
      echo "error: s3cmd failed to install"
    elif [[ "$spaces_err" -eq '0' ]]; then
      echo
      echo "success: s3cmd installed"
      echo
      echo "setup s3cmd --configure options for DO Spaces"
      echo "s3cmd configuration will be saved to /root/.s3cfg"
      echo
      echo "will need on hand the following details"
      echo 
      echo "1. DO Spaces Access Key"
      echo "2. DO Spaces Secret Key"
      echo "3. DO Spaces Endpoint i.e. sfo2.digitaloceanspaces.com"
      echo "4. Desired s3cmd Encryption password you want to set"
      echo
      read -ep "Enter your DO Spaces Access Key : " do_spaces_accesskey
      echo
      read -ep "Enter your DO Spaces Secret Key : " do_spaces_secretkey
      echo
      read -ep "Enter your DO Spaces Endpoint : " do_spaces_endpoint
      echo
      read -ep "Enter desired Encryption password : " do_spaces_passphrase
      echo

cat > /root/.s3cfg <<EOFF
[default]
access_key = $do_spaces_accesskey
access_token = 
add_encoding_exts = 
add_headers = 
bucket_location = US
ca_certs_file = 
cache_file = 
check_ssl_certificate = True
check_ssl_hostname = True
cloudfront_host = cloudfront.amazonaws.com
content_disposition = 
content_type = 
default_mime_type = binary/octet-stream
delay_updates = False
delete_after = False
delete_after_fetch = False
delete_removed = False
dry_run = False
enable_multipart = True
encrypt = False
expiry_date = 
expiry_days = 
expiry_prefix = 
follow_symlinks = False
force = False
get_continue = False
gpg_command = /bin/gpg
gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_passphrase = $do_spaces_passphrase
guess_mime_type = True
host_base = ${do_spaces_endpoint}
host_bucket = %(bucket)s.${do_spaces_endpoint}
human_readable_sizes = False
invalidate_default_index_on_cf = False
invalidate_default_index_root_on_cf = True
invalidate_on_cf = False
kms_key = 
limit = -1
limitrate = 0
list_md5 = False
log_target_prefix = 
long_listing = False
max_delete = -1
mime_type = 
multipart_chunk_size_mb = 15
multipart_max_chunks = 10000
preserve_attrs = True
progress_meter = True
proxy_host = 
proxy_port = 0
put_continue = False
recursive = False
recv_chunk = 65536
reduced_redundancy = False
requester_pays = False
restore_days = 1
restore_priority = Standard
secret_key = $do_spaces_secretkey
send_chunk = 65536
server_side_encryption = False
signature_v2 = False
signurl_use_https = False
simpledb_host = sdb.amazonaws.com
skip_existing = False
socket_timeout = 300
stats = False
stop_on_error = False
storage_class = 
throttle_max = 100
upload_id = 
urlencoding_mode = normal
use_http_expect = False
use_https = True
use_mime_magic = True
verbosity = WARNING
website_endpoint = http://%(bucket)s.s3-website-%(location)s.amazonaws.com/
website_error = 
website_index = index.html
EOFF
        echo "test s3cmd credentials"
        echo "list DO Spaces"
        echo
        echo "s3cmd ls"
        s3cmd ls
        cmd_err=$?
        if [[ "$cmd_err" -eq '0' ]]; then
          space_name=$(s3cmd ls | head -n1 |awk '{print $3}')
          echo
          echo "Do you want to upload regenerated passwords to DO Spaces ?"
          read -ep "Upload passwords to ${space_name}/opt-centminmod-$(hostname)/ ? [y/n]: " upload_passwords
          echo
          if [[ "$upload_passwords" = [yY] ]]; then
            cd /opt/centminmod
            echo "s3cmd put *.txt ${space_name}/opt-centminmod-$(hostname)/"
            s3cmd put *.txt ${space_name}/opt-centminmod-$(hostname)/
            uploadcmd_err=$?
            if [[ "$uploadcmd_err" -eq '0' ]]; then
              echo
              echo "s3cmd ls ${space_name}/opt-centminmod-$(hostname)/ -r"
              s3cmd ls ${space_name}/opt-centminmod-$(hostname)/ -r
              echo
              echo "to delete uploaded files you can run command:"
              echo "s3cmd del ${space_name}/opt-centminmod-$(hostname) -r"
            else
              echo
              echo "error: upload failed"
            fi
          else
            echo "skip uploading regenerated passwords to DO Spaces"
          fi
        else
          echo
          echo "error: s3cmd ls failed..."
        fi
        echo
    fi
else
    echo "skipping DigitalOcean Spaces & s3cmd setup"
  fi
  echo
}

cleanup() {
  reset_memcache_admin
  reset_opcache
  reset_phpinfo
  reset_mysqlroot
  log_cleanup
  tmpfix
  reset_bashrc
}

trap cleanup SIGHUP SIGINT SIGTERM
#########################################################

msg
get_email
set_hostname
whitelistip
cmm_update
yum_updates
autotune
reset_pureftpd_params
reset_memcache_admin
reset_opcache
reset_phpinfo
reset_mysqlroot
log_cleanup
service_checks
tmpfix
enable_phpstatus
reset_bashrc
do_spaces_setup
bookmark
exit