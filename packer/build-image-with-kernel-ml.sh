#!/bin/bash
###############################################
# https://github.com/centminmod/centminmod-digitalocean-marketplace/tree/master/packer
###############################################
dt=$(date +"%d%m%y-%H%M%S")

build() {
  if [ ! -f /usr/bin/jq ]; then
    yum -y -q install jq
  fi
  if [ -d /root/tools/centminmod-digitalocean-marketplace/packer ]; then
    mkdir -p /root/tools
    mkdir -p /home/packertmp
    mkdir -p /root/tools/packer/scripts
    chmod 1777 /home/packertmp
    export TMPDIR=/home/packertmp
    cd /root/tools/centminmod-digitalocean-marketplace/packer

    # validate
    echo
    echo "packer validate packer-centos7-basic.json"
    packer validate packer-centos7-basic.json

    # inspect
    echo
    echo "packer inspect packer-centos7-basic.json"
    packer inspect packer-centos7-basic.json

    # build
    echo
    snapshot_new_name="centos7-packer-php72-kernel-ml-redis-systemd-${dt}"
    export PACKER_LOG_PATH="packerlog-php72-kernel-ml-$(date +"%d%m%y-%H%M%S").log"
    echo "time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_elrepo=y' -var 'install_bbr=y' -var 'install_redis=y' -var 'enable_phpfpm_systemd=y' packer-centos7-basic.json"
    time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_elrepo=y' -var 'install_bbr=y' -var 'install_redis=y' -var 'enable_phpfpm_systemd=y' packer-centos7-basic.json

    echo
    date
    
    # get snapshot_id
    echo
    echo "get snapshot id"
    snapshot_name=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $10}' | sed -e "s|'||g" -e 's|)||g')
    snapshot_id=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $12}' | sed -e "s|'||g" -e 's|)||g')
    snapshot_region=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $15}' | sed -e "s|'||g" -e 's|)||g')
    echo "snapshot name: $snapshot_name ($snapshot_id) in $snapshot_region created"
    
    # snapshot info query API by snapshot id
    # https://developers.digitalocean.com/documentation/v2/#retrieve-an-existing-snapshot-by-id
    echo
    curl -sX GET -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/snapshots/${snapshot_id}" | jq -r .
    echo

    # rename snapshot image description name
    curl -sX PUT -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "{\"name\":\"$snapshot_new_name\"}" "https://api.digitalocean.com/v2/images/${snapshot_id}" | jq -r .
    echo
  else
    echo "/root/tools/centminmod-digitalocean-marketplace/packer does not exist"
    exit 1
  fi
}


build