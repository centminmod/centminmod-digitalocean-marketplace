#!/bin/bash

CENTOSVER=$(awk '{ print $3 }' /etc/redhat-release)

if [ "$CENTOSVER" == 'release' ]; then
    CENTOSVER=$(awk '{ print $4 }' /etc/redhat-release | cut -d . -f1,2)
    if [[ "$(cat /etc/redhat-release | awk '{ print $4 }' | cut -d . -f1)" = '7' ]]; then
        CENTOS_SEVEN='7'
    fi
fi

if [[ "$(cat /etc/redhat-release | awk '{ print $3 }' | cut -d . -f1)" = '6' ]]; then
    CENTOS_SIX='6'
fi

# Check for Redhat Enterprise Linux 7.x
if [ "$CENTOSVER" == 'Enterprise' ]; then
    CENTOSVER=$(awk '{ print $7 }' /etc/redhat-release)
    if [[ "$(awk '{ print $1,$2 }' /etc/redhat-release)" = 'Red Hat' && "$(awk '{ print $7 }' /etc/redhat-release | cut -d . -f1)" = '7' ]]; then
        CENTOS_SEVEN='7'
        REDHAT_SEVEN='y'
    fi
fi

if [[ -f /etc/system-release && "$(awk '{print $1,$2,$3}' /etc/system-release)" = 'Amazon Linux AMI' ]]; then
    CENTOS_SIX='6'
fi

# 2nd snapshot detection
if [[ "$snapshot_second" = [yY] ]]; then
    echo "snapshot_second=$snapshot_second"
    echo
fi

pip_updates() {
  # for glances and psutil as glances is installed via outdated EPEL
  # yum repo but there's a new version available
  if [[ ! -f /usr/bin/python-config ]]; then
    yum -q -y install python-devel
  fi
  if [[ "$CENTOS_SEVEN" -eq '7' && ! -f /usr/bin/pip ]] || [[ "$CENTOS_SIX" -eq '6' &&  ! -f /usr/bin/pip2.7 ]]; then
    if [[ "$CENTOS_SEVEN" -eq '7' ]]; then
      yum -q -y install python2-pip >/dev/null 2>&1
      yum -q -y versionlock python2-pip >/dev/null 2>&1
      export CC='gcc'
      PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip install -qqq --upgrade pip
    else
      yum -q -y install python-pip >/dev/null 2>&1
      yum -q -y versionlock python-pip >/dev/null 2>&1
      export CC='gcc'
      PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip install -qqq --upgrade pip
      if [[ "$CENTOS_SIX" -eq '6' && -f "/usr/local/src/centminmod/addons/python27_install.sh" && ! -f /usr/bin/pip2.7 ]]; then
        "/usr/local/src/centminmod/addons/python27_install.sh" install
        PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip2.7 install -qqq --upgrade pip
        PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip2.7 install -qqq --upgrade psutil
        PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip2.7 install -qqq --upgrade glances
        echo
        echo "CentOS 6 python 2.7 compatibility updates completed"
        echo
      fi
    fi
  elif [[ "$CENTOS_SIX" -eq '6' && -f /usr/bin/pip2.7 ]]; then
    CHECK_PIPVER=$(PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip show pip 2>&1 | awk '/^Version: / {print $2}' | sed -e 's|\.|0|g')
    if [[ "$CHECK_PIPVER" -lt '1801' ]]; then
      PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip2.7 install -qqq --upgrade pip
    fi
  elif [[ "$CENTOS_SEVEN" -eq '7' && -f /usr/bin/pip ]]; then
    CHECK_PIPVER=$(PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip show pip 2>&1 | awk '/^Version: / {print $2}' | sed -e 's|\.||g')
    if [[ "$CHECK_PIPVER" -lt '901' ]]; then
      PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip install -qqq --upgrade pip
    fi
  fi
  if [[ "$CENTOS_SEVEN" -eq '7' && -f /usr/bin/pip && -f /usr/bin/python-config ]]; then
    CHECK_PIPALL_UPDATES=$(PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip list -o --format columns)
    CHECK_PIPUPDATE=$(echo "$CHECK_PIPALL_UPDATES" | grep -o pip)
    CHECK_PSUTILUPDATE=$(echo "$CHECK_PIPALL_UPDATES" | grep -o psutil)
    CHECK_GLANCESUPDATE=$(echo "$CHECK_PIPALL_UPDATES" | grep -io glances)
    if [[ "$CHECK_PIPUPDATE" = 'pip' ]]; then
      export CC='gcc'
      PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip install -qqq --upgrade pip
      yum -q -y versionlock python2-pip >/dev/null 2>&1
    fi
    if [[ "$CHECK_PSUTILUPDATE" = 'psutil' ]]; then
      export CC='gcc'
      if [[ "$(rpm -qa python2-psutil | grep -o python2-psutil)" = 'python2-psutil' ]]; then
        yum -q -y remove python2-psutil >/dev/null 2>&1
      fi
      PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip install -qqq --upgrade psutil
    fi
    if [[ "$CHECK_GLANCESUPDATE" = 'Glances' ]]; then
      export CC='gcc'
      PYTHONWARNINGS=ignore:::pip._internal.cli.base_command pip install -qqq --upgrade glances
    fi
  fi
}

# setup persistent config settings to override centminmod defaults
mkdir -p /etc/centminmod
touch /etc/centminmod/custom_config.inc
echo "LETSENCRYPT_DETECT='y'" >> /etc/centminmod/custom_config.inc
if [[ "$INSTALL_DUALCERTS" = [yY] ]]; then
  echo "DUALCERTS='y'" >> /etc/centminmod/custom_config.inc
fi
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
if [[ "$INSTALL_ARGON" = [yY] ]]; then
  echo "PHP_ARGON='y'" >> /etc/centminmod/custom_config.inc
fi
if [[ "$INSTALL_MONGODB" = [yY] ]]; then
  echo "PHPMONGODB='y'" >> /etc/centminmod/custom_config.inc
fi
if [[ "$INSTALL_MARIADBTENFOUR" = [yY] ]]; then
  echo "MARIADB_INSTALLTENFOUR='y'" >> /etc/centminmod/custom_config.inc
elif [[ "$INSTALL_MARIADBTENTHREE" = [yY] ]]; then
  echo "MARIADB_INSTALLTENTHREE='y'" >> /etc/centminmod/custom_config.inc
elif [[ "$INSTALL_MARIADBTENTWO" = [yY] ]]; then
  echo "MARIADB_INSTALLTENTWO='y'" >> /etc/centminmod/custom_config.inc
fi
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

# install centmin mod 123.09beta01 with PHP 7.1 latest defaults
curl -O https://centminmod.com/betainstaller71.sh && chmod 0700 betainstaller71.sh && bash betainstaller71.sh

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
  # wget -O /etc/docker/daemon.json https://gist.githubusercontent.com/centminmod/e79bca8d3ef56d4d7272663f755e830d/raw/daemon.json
cat > /etc/docker/daemon.json <<EOF
{
    "dns": ["8.8.8.8", "8.8.4.4"]
}
EOF
  cat /etc/docker/daemon.json
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

# install mongodb
echo "INSTALL_MONGODB=$INSTALL_MONGODB"

if [[ "$INSTALL_MONGODB" = [yY] ]]; then
  echo
  echo "---------------------------------------------"
  echo "mongodb install"
  echo "---------------------------------------------"
cat > /etc/yum.repos.d/mongodb-org-4.0.repo <<EOF
[mongodb-org-4.0]
name=MongoDB Repository
#baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.0/x86_64/
baseurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOF
  yum -y install mongodb-org
  mongo_err=$?
  if [[ "$mongo_err" -ne '0' ]]; then
    rm -f /etc/yum.repos.d/mongodb-org-4.0.repo
  else
    service mongod start
    echo
    service mongod status
    echo
    chkconfig mongod on
    echo
    mongo --version
  fi
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

# install go
echo "INSTALL_GO=$INSTALL_GO"

if [[ "$INSTALL_GO" = [yY] ]]; then
  echo
  echo "---------------------------------------------"
  echo "golang install"
  echo "---------------------------------------------"
  /usr/local/src/centminmod/addons/golang.sh install
fi

# install nodejs
echo "INSTALL_NODEJS=$INSTALL_NODEJS"

if [[ "$INSTALL_NODEJS" = [yY] ]]; then
  echo
  echo "---------------------------------------------"
  echo "nodejs install"
  echo "---------------------------------------------"
  /usr/local/src/centminmod/addons/nodejs.sh install
fi

# install newer git 1.8.3 upgrade to 2.16
echo "INSTALL_NEWERGIT=$INSTALL_NEWERGIT"

if [[ "$INSTALL_NEWERGIT" = [yY] ]]; then
  echo
  echo "---------------------------------------------"
  echo "git 2.16+ install"
  echo "---------------------------------------------"
  /usr/local/src/centminmod/addons/git2_install.sh
fi

# install custom curl
echo "INSTALL_CURL=$INSTALL_CURL"

if [[ "$INSTALL_CURL" = [yY] ]]; then
  echo
  echo "---------------------------------------------"
  echo "custom curl install"
  echo "---------------------------------------------"
  /usr/local/src/centminmod/addons/customcurl.sh
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

# openssl
echo
echo "---------------------------------------------"
echo "openssl benchmarks"
echo "---------------------------------------------"
multi=" -multi $(nproc)"
echo
opensslbin='openssl'
ciphers='rsa2048 rsa4096 ecdsap256 sha256 sha1 md5 rc4 aes-256-cbc aes-128-cbc';
echo
echo "$opensslbin speed${multi} $ciphers"
$opensslbin speed${multi} $ciphers 2>&1 | egrep -iv '\+|Fork' 2>&1 | sed -e "s|evp|evp $c|";
echo
ciphers='aes-128-cbc aes-256-cbc aes-128-gcm aes-256-gcm'; for c in $ciphers; do 
    echo
    echo "$opensslbin speed${multi} -evp $c";
    $opensslbin speed${multi} -evp $c 2>&1 | egrep -iv '\+|Fork' 2>&1 | sed -e "s|evp|evp $c|";
  done
echo
opensslbin='/opt/openssl/bin/openssl'
ciphers='rsa2048 rsa4096 ecdsap256 sha256 sha1 md5 rc4 aes-256-cbc aes-128-cbc';
echo
echo "$opensslbin speed${multi} $ciphers"
$opensslbin speed${multi} $ciphers 2>&1 | egrep -iv '\+|Fork' 2>&1 | sed -e "s|evp|evp $c|";
echo
ciphers='aes-128-cbc aes-256-cbc aes-128-gcm aes-256-gcm chacha20'; for c in $ciphers; do 
    echo
    echo "$opensslbin speed${multi} -evp $c";
    $opensslbin speed${multi} -evp $c 2>&1 | egrep -iv '\+|Fork' 2>&1 | sed -e "s|evp|evp $c|";
  done
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
  yum-config-manager --enable elrepo-kernel
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

# check first-login.sh
if [ -f /opt/centminmod/first-login.sh ]; then
  echo
  echo "check /opt/centminmod/first-login.sh"
  ls -lAh /opt/centminmod/first-login.sh
  echo
  date
else
  echo "error: /opt/centminmod/first-login.sh does not exist"
  echo
  date
fi

# check /var/lib/cloud/scripts/per-instance/01-setup-first-login.sh
if [ -f /var/lib/cloud/scripts/per-instance/01-setup-first-login.sh ]; then
  echo
  echo "check /var/lib/cloud/scripts/per-instance/01-setup-first-login.sh"
  ls -lAh /var/lib/cloud/scripts/per-instance/01-setup-first-login.sh
  echo
  date
else
  echo "error: /var/lib/cloud/scripts/per-instance/01-setup-first-login.sh does not exist"
  echo
  date
fi

pip_updates

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

# checklist
echo
echo "---------------------------------------------"
echo "checking installed software"
echo "---------------------------------------------"
echo "nginx -V"
nginx -V
echo
echo "---------------------------------------------"
echo "php -v"
php -v
echo
echo "---------------------------------------------"
echo "csf -V"
csf -V
echo
echo "---------------------------------------------"
echo "mysqladmin ver"
mysqladmin ver
echo
echo "---------------------------------------------"
echo "nprestart"
nprestart
echo
echo "---------------------------------------------"
echo "mysqlrestart"
mysqlrestart
echo
echo "---------------------------------------------"
echo "memcachedrestart"
memcachedrestart
echo
echo "---------------------------------------------"
echo "service redis restart"
service redis restart
echo
echo "---------------------------------------------"
echo "service postfix restart"
service postfix restart
echo
echo
echo "---------------------------------------------"
echo "service pure-ftpd restart"
service pure-ftpd restart
echo
echo "---------------------------------------------"
echo "service memcached status"
service memcached status
echo
echo "---------------------------------------------"
echo "service nginx status"
service nginx status
echo
echo "---------------------------------------------"
echo "service redis status"
service redis status
echo
echo "---------------------------------------------"
echo "service postfix status"
service postfix status
echo
echo "---------------------------------------------"
echo "service pure-ftpd status"
service pure-ftpd status
echo
echo "check pure-ftpd config /etc/pure-ftpd/pure-ftpd.conf"
echo "cat /etc/pure-ftpd/pure-ftpd.conf | egrep 'UnixAuthentication|VerboseLog|PureDB |CreateHomeDir|TLS|PassivePortRange|TLSCipherSuite|MaxClientsNumber|MaxClientsPerIP|NoAnonymous|Umask' | grep -v '#'"
cat /etc/pure-ftpd/pure-ftpd.conf | egrep 'UnixAuthentication|VerboseLog|PureDB |CreateHomeDir|TLS|PassivePortRange|TLSCipherSuite|MaxClientsNumber|MaxClientsPerIP|NoAnonymous|Umask' | grep -v '#'
echo
echo "---------------------------------------------"
echo "service csf status"
service csf status
echo
echo "---------------------------------------------"
echo "service lfd status"
service lfd status
echo
echo "---------------------------------------------"
echo "fpmstatus"
fpmstatus
echo
echo "---------------------------------------------"
echo "fpmstats"
fpmstats
echo
if [[ "$INSTALL_ARGON" = [yY] ]]; then
  echo "---------------------------------------------"
  echo "PHP Argon2 Checks"
  echo
  php --ri sodium
  echo
  php -r 'print_r(get_defined_constants());' | grep -i argon
  echo
fi
if [[ "$INSTALL_MONGODB" = [yY] ]]; then
  echo
  echo "---------------------------------------------"
  echo "mongodb"
  mongo --version
  echo
  echo "php --ri mongodb"
  php --ri mongodb
  echo
  service mongod status
  echo
fi
if [[ "$INSTALL_AUDITD" = [yY] ]]; then
  service auditd restart
  service auditd status
  echo "check auditd rules"
  auditctl -l
  echo
fi
if [[ "$INSTALL_GO" = [yY] ]]; then
  echo "go version"
  go version
  echo
fi
if [[ "$INSTALL_NODEJS" = [yY] ]]; then
  echo "node -v"
  node -v
  echo "npm --version"
  npm --version
  echo
fi
if [[ "$INSTALL_CUSTOMCURL" = [yY] ]]; then
  echo "curl -V"
  curl -V
  echo
fi
echo
echo "---------------------------------------------"
echo "cminfo top"
cminfo top

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
yum -y update --disableplugin=priorities --enablerepo=remi
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
rm -rf /home/packertmp
rm -f /etc/ssh/*key*
history -c
echo
date

# verify image readiness for digitalocean marketplace submission
sleep 20
mkdir -p /root/tools
cd /root/tools
rm -rf marketplace-partners
git clone https://github.com/digitalocean/marketplace-partners
cd marketplace-partners/marketplace_validation

# systemctl stop csf lfd
# sleep 20
truncate -s 0 /var/log/lfd.log
echo "cat /var/log/lfd.log"
cat /var/log/lfd.log
echo
./img_check.sh
echo
# systemctl start csf lfd
# sleep 20
truncate -s 0 /var/log/lfd.log

rm -rf /root/tools/marketplace-partners
rm -rf /root/tools/*
echo
date

# clear mail log for root user
truncate -s 0 /var/mail/root
find /var/log -mtime -1 -type f -exec truncate -s 0 {} \;
# clean history again
history -c