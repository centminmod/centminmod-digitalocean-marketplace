#!/bin/bash

# 2nd snapshot detection
if [[ "$snapshot_second" = [yY] ]]; then
    echo "snapshot_second=$snapshot_second"
    echo
fi

# update server and setup TMPDIR
echo
echo "hostname: $(hostname)"
echo
lscpu
echo
mkdir -p /root/tools
yum -y update

yum -y install virt-what python-devel gawk unzip pyOpenSSL python-dateutil libuuid-devel bc wget lynx screen deltarpm ca-certificates yum-utils bash mlocate subversion rsyslog dos2unix boost-program-options net-tools imake bind-utils libatomic_ops-devel time coreutils autoconf cronie crontabs cronie-anacron gcc gcc-c++ automake libtool make libXext-devel unzip patch sysstat openssh flex bison file libtool-ltdl-devel  krb5-devel libXpm-devel nano gmp-devel aspell-devel numactl lsof pkgconfig gdbm-devel tk-devel bluez-libs-devel iptables* rrdtool diffutils which perl-Test-Simple perl-ExtUtils-Embed perl-ExtUtils-MakeMaker perl-Time-HiRes perl-libwww-perl perl-Crypt-SSLeay perl-Net-SSLeay cyrus-imapd cyrus-sasl-md5 cyrus-sasl-plain strace cmake git net-snmp-libs net-snmp-utils iotop libvpx libvpx-devel t1lib t1lib-devel expect expect-devel readline readline-devel libedit libedit-devel libxslt libxslt-devel openssl openssl-devel curl curl-devel openldap openldap-devel zlib zlib-devel gd gd-devel pcre pcre-devel gettext gettext-devel libidn libidn-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel e2fsprogs e2fsprogs-devel libc-client libc-client-devel cyrus-sasl cyrus-sasl-devel pam pam-devel libaio libaio-devel libevent libevent-devel recode recode-devel libtidy libtidy-devel net-snmp net-snmp-devel enchant enchant-devel lua lua-devel mailx perl-LWP-Protocol-https OpenEXR-devel OpenEXR-libs atk cups-libs fftw-libs-double fribidi gdk-pixbuf2 ghostscript-devel ghostscript-fonts gl-manpages graphviz gtk2 hicolor-icon-theme ilmbase ilmbase-devel jasper-devel jasper-libs jbigkit-devel jbigkit-libs lcms2 lcms2-devel libICE-devel libSM-devel libXaw libXcomposite libXcursor libXdamage-devel libXfixes-devel libXfont libXi libXinerama libXmu libXrandr libXt-devel libXxf86vm-devel libdrm-devel libfontenc librsvg2 libtiff libtiff-devel libwebp libwebp-devel libwmf-lite mesa-libGL-devel mesa-libGLU mesa-libGLU-devel poppler-data urw-fonts xorg-x11-font-utils

# install elrepo kernel-ml
echo "INSTALL_ELREPO=$INSTALL_ELREPO"

if [[ "$INSTALL_BBR" = [yY] ]]; then
  INSTALL_ELREPO='y'
fi

if [[ "$INSTALL_ELREPO" = [yY] ]]; then
  uname -r
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
  rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
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

# # setup first-login.sh
# if [ -f /opt/centminmod/first-login.sh ]; then
#   echo
#   echo "setup /opt/centminmod/first-login.sh"
#   # echo '/opt/centminmod/first-login.sh' >> /root/.bashrc
# # cat >> /root/.bashrc <<EOF
# # if [ -f /opt/centminmod/first-login-run ]; then /opt/centminmod/first-login.sh; fi
# # EOF
#   # touch /opt/centminmod/first-login-run
#   echo
#   date
# fi

# meltdown & spectre checks
if [ -d /root/tools ]; then
  echo
  echo "---------------------------------------------"
  echo "Spectre & Meltdown Checks"
  echo "---------------------------------------------"
  wget -O /root/tools/spectre-meltdown-checker.sh https://github.com/speed47/spectre-meltdown-checker/raw/master/spectre-meltdown-checker.sh
  chmod +x /root/tools/spectre-meltdown-checker.sh
  /root/tools/spectre-meltdown-checker.sh --explain
fi

echo
echo "---------------------------------------------"
echo "check /etc/fstab"
cat /etc/fstab

echo
echo "---------------------------------------------"
echo "droplet metadata"
droplet_id=$(curl -s http://169.254.169.254/metadata/v1/id)
droplet_hostname=$(curl -s http://169.254.169.254/metadata/v1/hostname)
droplet_region=$(curl -s http://169.254.169.254/metadata/v1/region)
droplet_ip=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
droplet_anchor_ip=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/anchor_ipv4/address)
droplet_floating_ip=$(curl -s http://169.254.169.254/metadata/v1/floating_ip/ipv4/ip_address)
echo "droplet_id=$droplet_id"
echo "droplet_hostname=$droplet_hostname"
echo "droplet_region=$droplet_region"
echo "droplet_ip=$droplet_ip"
echo "droplet_anchor_ip=$droplet_anchor_ip"
echo "droplet_floating_ip=$droplet_floating_ip"

echo
date

# cleanup after centminmod install
yum -y clean all
# yum-config-manager --disable rpmforge >/dev/null 2>&1
# ccache -C
rm -rf /tmp/* /var/tmp/*
unset HISTFILE
rm -rf /var/log/*.gz /var/log/*.[0-9] /var/log/*-????????
rm -rf /var/lib/cloud/instances/*
cat /dev/null > /var/log/lastlog; 
cat /dev/null > /var/log/wtmp;
# rm -rf /root/centminlogs/*
# rm -f /etc/centminmod/email-primary.ini
# rm -f /etc/centminmod/email-secondary.ini
# rm -rf /home/sysbench
# rm -f /var/lib/mysql/ib_logfile0.gz
# rm -f /var/lib/mysql/ib_logfile1.gz
# find /svr-setup -maxdepth 1 -type d ! -wholename "/svr-setup" -exec rm -rf {} \;
# rm -f /svr-setup/1
# rm -f /svr-setup/axel-2.14.1.tar.gz
# rm -f /svr-setup/axel-2.4-1.el5.rf.i386.rpm
# rm -f /svr-setup/axel-2.4-1.el5.rf.x86_64.rpm
# rm -f /svr-setup/axel-2.4-1.el6.rf.i686.rpm
# rm -f /svr-setup/axel-2.4-1.el6.rf.x86_64.rpm
# rm -f /svr-setup/axel-2.5.tar.gz
# rm -f /svr-setup/axel-2.6.tar.gz
# rm -f /svr-setup/ccache-3.4.1.tar.gz
# rm -f /svr-setup/city-fan.org-release-1-13.rhel6.noarch.rpm
# rm -f /svr-setup/city-fan.org-release-1-13.rhel7.noarch.rpm
# rm -f /svr-setup/csf.tgz-local
# rm -f /svr-setup/epel-release*
# rm -f /svr-setup/help-dummy.o
# rm -f /svr-setup/mongodb-1.4.0.tgz
# rm -f /svr-setup/ngx-fancyindex-0.3.1.tar.gz
# rm -f /svr-setup/ngx_cache_purge-2.4.2.tar.gz
# rm -f /svr-setup/package.xml
# rm -f /svr-setup/redis2-nginx-module_v0.14.tar.gz
# rm -f /svr-setup/remi-release-5.rpm
# rm -f /svr-setup/remi-release-6.rpm
# rm -f /svr-setup/rpmforge-release-0.5.3-1.el5*
# rm -f /svr-setup/rpmforge-release-0.5.3-1.el6*
# rm -f /svr-setup/set-misc-nginx-module_v0.31*
# rm -f /svr-setup/varnish-release-3.0-1.el6.noarch.rpm
# rm -f /svr-setup/wget-1.19.4.tar.gz
# rm -rf /usr/local/nginxbackup/confbackup/*
# rm -rf /usr/local/nginxbackup/nginxdirbackup/*
find /var/log -mtime -1 -type f -exec truncate -s 0 {} \;
rm -rf /home/packertmp
rm -rf /root/tools
rm -f /etc/ssh/*key*
# history -c
echo
date

# verify image readiness for digitalocean marketplace submission
# mkdir -p /root/tools
# cd /root/tools
# rm -rf marketplace-partners
# git clone https://github.com/digitalocean/marketplace-partners
# cd marketplace-partners/marketplace_validation
# ./img_check.sh
# rm -rf /root/tools/marketplace-partners
# echo
# date

# clean history again
history -c