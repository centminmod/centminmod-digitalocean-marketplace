#!/bin/bash
############################################################
# https://github.com/digitalocean/marketplace-partners/blob/master/marketplace_docs/build-an-image.md
############################################################

yum -y update
yum-config-manager --disable rpmforge >/dev/null 2>&1
yum clean all
ccache -C
rm -rf /tmp/* /var/tmp/*
unset HISTFILE
rm -rf /var/log/*.gz /var/log/*.[0-9] /var/log/*-????????
rm -rf /var/lib/cloud/instances/*
# dd if=/dev/zero of=/zerofile; sync; rm /zerofile; sync
cat /dev/null > /var/log/lastlog; 
cat /dev/null > /var/log/wtmp;
rm -rf /root/centminlogs/*
rm -f /etc/centminmod/email-primary.ini
rm -f /etc/centminmod/email-secondary.ini
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

cd /usr/local/src
branchname=123.09beta01
du -sh centminmod
rm -rf centminmod
git clone -b ${branchname} --depth=1 https://github.com/centminmod/centminmod.git centminmod
du -sh centminmod

du -h --max-depth=1 /
du -h --max-depth=1 /var
du -h --max-depth=1 /usr
du -h --max-depth=1 /usr/local/
du -sh /svr-setup/

echo
df -hT
echo

find /var/log -mtime -1 -type f -exec truncate -s 0 {} \;
cat /dev/null > /root/.bash_history
# rm -f /root/.ssh/authorized_keys
rm -f /etc/ssh/*key*
history -c