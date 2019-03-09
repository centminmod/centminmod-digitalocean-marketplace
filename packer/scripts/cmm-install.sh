#!/bin/bash

# setup persistent config settings to override centminmod defaults
mkdir -p /etc/centminmod
touch /etc/centminmod/custom_config.inc
echo "LETSENCRYPT_DETECT='y'" >> /etc/centminmod/custom_config.inc
echo "NGINX_VIDEO='y'" >> /etc/centminmod/custom_config.inc
echo "NGXDYNAMIC_BROTLI='y'" >> /etc/centminmod/custom_config.inc
echo "NGINX_LIBBROTLI='y'" >> /etc/centminmod/custom_config.inc
echo "NGINX_BROTLIDEP_UPDATE='y'" >> /etc/centminmod/custom_config.inc
echo "PHPFINFO='y'" >> /etc/centminmod/custom_config.inc
echo "PHP_BROTLI='y'" >> /etc/centminmod/custom_config.inc
echo "PHP_LZFOUR='y'" >> /etc/centminmod/custom_config.inc
echo "PHP_LZF='y'" >> /etc/centminmod/custom_config.inc
echo "PHP_ZSTD='y'" >> /etc/centminmod/custom_config.inc
echo "ZSTD_LOGROTATE_NGINX='y'" >> /etc/centminmod/custom_config.inc
echo "ZSTD_LOGROTATE_PHPFPM='y'" >> /etc/centminmod/custom_config.inc
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

# install centmin mod 123.09beta01 with PHP 7.2 latest defaults
curl -O https://centminmod.com/betainstaller72.sh && chmod 0700 betainstaller72.sh && bash betainstaller72.sh

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