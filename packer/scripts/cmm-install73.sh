#!/bin/bash

# setup persistent config settings to override centminmod defaults
mkdir -p /etc/centminmod
touch /etc/centminmod/custom_config.inc
echo "LETSENCRYPT_DETECT='y'" >> /etc/centminmod/custom_config.inc
if [[ "$INSTALL_PHPFPMSYSTEMD" = [yY] ]]; then
  echo "SWITCH_PHPFPM_SYSTEMD='y'" >> /etc/centminmod/custom_config.inc
fi
echo "NGINX_VIDEO='y'" >> /etc/centminmod/custom_config.inc
if [[ "$INSTALL_PHPPGO" = [yY] ]]; then
  echo "PHP_PGO='y'" >> /etc/centminmod/custom_config.inc
fi
echo "PHPFINFO='y'" >> /etc/centminmod/custom_config.inc
if [[ "$INSTALL_BROTLI" = [yY] ]]; then
  echo "NGXDYNAMIC_BROTLI='y'" >> /etc/centminmod/custom_config.inc
  echo "NGINX_LIBBROTLI='y'" >> /etc/centminmod/custom_config.inc
  echo "NGINX_BROTLIDEP_UPDATE='y'" >> /etc/centminmod/custom_config.inc
  echo "PHP_BROTLI='y'" >> /etc/centminmod/custom_config.inc
fi
echo "PHP_LZFOUR='y'" >> /etc/centminmod/custom_config.inc
echo "PHP_LZF='y'" >> /etc/centminmod/custom_config.inc
if [[ "$INSTALL_INSTALL_LOGROTATEZSTD" = [yY] ]]; then
  echo "PHP_ZSTD='y'" >> /etc/centminmod/custom_config.inc
  echo "ZSTD_LOGROTATE_NGINX='y'" >> /etc/centminmod/custom_config.inc
  echo "ZSTD_LOGROTATE_PHPFPM='y'" >> /etc/centminmod/custom_config.inc
fi
echo "MARIADB_INSTALLTENTHREE='y'" >> /etc/centminmod/custom_config.inc
cat /etc/centminmod/custom_config.inc
echo

# update server and setup TMPDIR
echo
echo "hostname: $(hostname)"
echo
lscpu
echo
yum -y update
mkdir -p /home/packertmp
mkdir -p /root/tools/packer/scripts
chmod 1777 /home/packertmp
export TMPDIR=/home/packertmp

# install centmin mod 123.09beta01 with PHP 7.3 latest defaults
curl -O https://centminmod.com/betainstaller73.sh && chmod 0700 betainstaller73.sh && bash betainstaller73.sh

# install docker
echo "INSTALL_DOCKER=$INSTALL_DOCKER"

if [[ "$INSTALL_DOCKER" = [yY] ]]; then
  echo
  echo "---------------------------------------------"
  echo "docker install"
  echo "---------------------------------------------"
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum -y install yum-utils device-mapper-persistent-data lvm2
  yum -y install docker-ce
  mkdir -p /etc/systemd/system/docker.service.d
  touch /etc/systemd/system/docker.service.d/docker.conf
  mkdir -p /etc/docker
  wget -O /etc/docker/daemon.json https://gist.githubusercontent.com/centminmod/e79bca8d3ef56d4d7272663f755e830d/raw/daemon.json
  systemctl daemon-reload
  systemctl start docker
  systemctl enable docker
  echo
  systemctl status docker
  echo
  journalctl -u docker --no-pager
  echo
  docker info
fi

# install redis
echo "INSTALL_REDIS=$INSTALL_REDIS"

if [[ "$INSTALL_REDIS" = [yY] ]]; then
  echo
  echo "---------------------------------------------"
  echo "redis install"
  echo "---------------------------------------------"
  mkdir -p /root/tools
  git clone https://github.com/centminmod/centminmod-redis
  cd centminmod-redis
  ./redis-install.sh install
  redis-cli info
fi

# install auditd
echo "INSTALL_AUDITD=$INSTALL_AUDITD"

if [[ "$INSTALL_AUDITD" = [yY] ]]; then
  echo
  echo "---------------------------------------------"
  echo "auditd install"
  echo "---------------------------------------------"
  echo "AUDITD_ENABLE='y'" >> /etc/centminmod/custom_config.inc
  /usr/local/src/centminmod/tools/auditd.sh setup
fi

# might as well do some quick benchmarks to test the temp droplets performance
# http/2 https benchmarks
echo
echo "---------------------------------------------"
echo "centmin mod nginx http/2 https benchmarks"
echo "---------------------------------------------"
mkdir -p /root/tools
cd /root/tools
wget -O https_bench.sh https://github.com/centminmod/centminmodbench/raw/master/https_bench.sh
chmod +x https_bench.sh
time /root/tools/https_bench.sh

# sysbench
echo
echo "---------------------------------------------"
echo "sysbench benchmarks"
echo "---------------------------------------------"
mkdir -p /root/tools/sysbench
cd /root/tools/sysbench
wget -O /root/tools/sysbench/sysbench.sh https://github.com/centminmod/centminmod-sysbench/raw/master/sysbench.sh
chmod +x sysbench.sh
./sysbench.sh install

echo
echo "---------------------------------------------"
echo "./sysbench.sh cpu"
echo "---------------------------------------------"
./sysbench.sh cpu
echo
echo "---------------------------------------------"
echo "./sysbench.sh mem"
echo "---------------------------------------------"
./sysbench.sh mem
echo
echo "---------------------------------------------"
echo "./sysbench.sh file"
echo "---------------------------------------------"
./sysbench.sh file
echo
echo "---------------------------------------------"
echo "./sysbench.sh file-fsync"
echo "---------------------------------------------"
./sysbench.sh file-fsync
echo
echo "---------------------------------------------"
echo "./sysbench.sh mysqloltpnew"
echo "---------------------------------------------"
./sysbench.sh mysqloltpnew
echo

# install elrepo kernel-ml
echo "INSTALL_ELREPO=$INSTALL_ELREPO"

if [[ "$INSTALL_BBR" = [yY] ]]; then
  INSTALL_ELREPO='y'
fi

if [[ "$INSTALL_ELREPO" = [yY] ]]; then
  uname -r
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
  rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
  yum -y remove kernel-tools kernel-tools-libs
  yum -y install kernel-ml kernel-ml-devel kernel-ml-tools --enablerepo=elrepo-kernel
  yum -y versionlock kernel-[0-9]*
  awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
  grub2-set-default 0
  grub2-mkconfig -o /boot/grub2/grub.cfg
  echo
  echo "sysctl net.ipv4.tcp_available_congestion_control"
  sysctl net.ipv4.tcp_available_congestion_control
  echo
  echo "sysctl -n net.ipv4.tcp_congestion_control"
  sysctl -n net.ipv4.tcp_congestion_control
fi
if [[ "$INSTALL_BBR" = [yY] ]]; then
  echo 'net.core.default_qdisc=fq' | tee -a /etc/sysctl.conf
  echo 'net.ipv4.tcp_congestion_control=bbr' | tee -a /etc/sysctl.conf
  echo 'net.ipv4.tcp_notsent_lowat=16384' | tee -a /etc/sysctl.conf
  sysctl -p
  echo "sysctl net.ipv4.tcp_available_congestion_control"
  sysctl net.ipv4.tcp_available_congestion_control
  echo
  echo "sysctl -n net.ipv4.tcp_congestion_control"
  sysctl -n net.ipv4.tcp_congestion_control
  echo
  echo "sysctl -n net.core.default_qdisc"
  sysctl -n net.core.default_qdisc
  echo
  echo "sysctl -n net.ipv4.tcp_notsent_lowat"
  sysctl -n net.ipv4.tcp_notsent_lowat
  echo
  echo "lsmod | grep bbr"
  lsmod | grep bbr
fi

# setup first-login.sh
if [ -f /opt/centminmod/first-login.sh ]; then
  echo
  echo "setup /opt/centminmod/first-login.sh"
  # echo '/opt/centminmod/first-login.sh' >> /root/.bashrc
# cat >> /root/.bashrc <<EOF
# if [ -f /opt/centminmod/first-login-run ]; then /opt/centminmod/first-login.sh; fi
# EOF
  touch /opt/centminmod/first-login-run
  echo
  date
fi

# cleanup after centminmod install
yum -y clean all
yum-config-manager --disable rpmforge >/dev/null 2>&1
ccache -C
rm -rf /tmp/* /var/tmp/*
unset HISTFILE
rm -rf /var/log/*.gz /var/log/*.[0-9] /var/log/*-????????
rm -rf /var/lib/cloud/instances/*
cat /dev/null > /var/log/lastlog; 
cat /dev/null > /var/log/wtmp;
rm -rf /root/centminlogs/*
rm -f /etc/centminmod/email-primary.ini
rm -f /etc/centminmod/email-secondary.ini
rm -rf /home/sysbench
rm -f /var/lib/mysql/ib_logfile0.gz
rm -f /var/lib/mysql/ib_logfile1.gz
find /svr-setup -maxdepth 1 -type d ! -wholename "/svr-setup" -exec rm -rf {} \;
rm -f /svr-setup/1
rm -f /svr-setup/axel-2.14.1.tar.gz
rm -f /svr-setup/axel-2.4-1.el5.rf.i386.rpm
rm -f /svr-setup/axel-2.4-1.el5.rf.x86_64.rpm
rm -f /svr-setup/axel-2.4-1.el6.rf.i686.rpm
rm -f /svr-setup/axel-2.4-1.el6.rf.x86_64.rpm
rm -f /svr-setup/axel-2.5.tar.gz
rm -f /svr-setup/axel-2.6.tar.gz
rm -f /svr-setup/ccache-3.4.1.tar.gz
rm -f /svr-setup/city-fan.org-release-1-13.rhel6.noarch.rpm
rm -f /svr-setup/city-fan.org-release-1-13.rhel7.noarch.rpm
rm -f /svr-setup/csf.tgz-local
rm -f /svr-setup/epel-release*
rm -f /svr-setup/help-dummy.o
rm -f /svr-setup/mongodb-1.4.0.tgz
rm -f /svr-setup/ngx-fancyindex-0.3.1.tar.gz
rm -f /svr-setup/ngx_cache_purge-2.4.2.tar.gz
rm -f /svr-setup/package.xml
rm -f /svr-setup/redis2-nginx-module_v0.14.tar.gz
rm -f /svr-setup/remi-release-5.rpm
rm -f /svr-setup/remi-release-6.rpm
rm -f /svr-setup/rpmforge-release-0.5.3-1.el5*
rm -f /svr-setup/rpmforge-release-0.5.3-1.el6*
rm -f /svr-setup/set-misc-nginx-module_v0.31*
rm -f /svr-setup/varnish-release-3.0-1.el6.noarch.rpm
rm -f /svr-setup/wget-1.19.4.tar.gz
rm -rf /usr/local/nginxbackup/confbackup/*
rm -rf /usr/local/nginxbackup/nginxdirbackup/*
find /var/log -mtime -1 -type f -exec truncate -s 0 {} \;
rm -f /etc/ssh/*key*
history -c

# verify image readiness for digitalocean marketplace submission
mkdir -p /root/tools
cd /root/tools
rm -rf marketplace-partners
git clone https://github.com/digitalocean/marketplace-partners
cd marketplace-partners/marketplace_validation
./img_check.sh
rm -rf /root/tools/marketplace-partners

# clean history again
history -c