#!/bin/bash
############################################################
# https://github.com/digitalocean/marketplace-partners/blob/master/marketplace_docs/build-an-image.md
############################################################

yum -y update
yum clean all
rm -rf /tmp/* /var/tmp/*
unset HISTFILE
find /var/log -mtime -1 -type f -exec truncate -s 0 {} \;
rm -rf /var/log/*.gz /var/log/*.[0-9] /var/log/*-????????
rm -rf /var/lib/cloud/instances/*
rm -f /root/.ssh/authorized_keys /etc/ssh/*key*
dd if=/dev/zero of=/zerofile; sync; rm /zerofile; sync
cat /dev/null > /var/log/lastlog; 
cat /dev/null > /var/log/wtmp;
rm -rf /root/centminlogs/*
rm -f /etc/centminmod/email-primary.ini
rm -f /etc/centminmod/email-secondary.ini
rm -f /var/lib/mysql/ib_logfile0.gz
rm -f /var/lib/mysql/ib_logfile1.gz
find /svr-setup -maxdepth 1 -type d ! -wholename "/svr-setup" -exec rm -rf {} \;
cat /dev/null > /root/.bash_history
history -c
shutdown -h now & exit 0