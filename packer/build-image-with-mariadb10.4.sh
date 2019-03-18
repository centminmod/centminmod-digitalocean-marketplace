#!/bin/bash
###############################################
# https://github.com/centminmod/centminmod-digitalocean-marketplace/tree/master/packer
###############################################
dt=$(date +"%d%m%y-%H%M%S")
do_imageid=${1:-"centos-7-x64"}
snapshot_second_count='1'

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
    snapshot_new_name="centos7-packer-php72-mariadb104-redis-systemd-${dt}"
    snapshot_new_name_second="centos7-packer-php72-mariadb104-redis-systemd-2-${dt}"
    export PACKER_LOG_PATH="packerlog-php72-mariadb104-redis-systemd-$(date +"%d%m%y-%H%M%S").log"
    echo "time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var "do_image=$do_imageid" -var 'install_mariadbtenfour=y' -var "enable_argon=y" -var 'install_redis=y' -var 'enable_phpfpm_systemd=y' packer-centos7-basic.json"
    time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var "do_image=$do_imageid" -var 'install_mariadbtenfour=y' -var "enable_argon=y" -var 'install_redis=y' -var 'enable_phpfpm_systemd=y' packer-centos7-basic.json

    echo
    date
    
    # get snapshot_id
    echo
    echo "get snapshot id"
    snapshot_name=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $10}' | sed -e "s|'||g" -e 's|)||g')
    snapshot_id=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $12}' | sed -e "s|'||g" -e 's|)||g')
    snapshot_region=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $15}' | sed -e "s|'||g" -e 's|)||g')

    if [ "${snapshot_id}" ]; then
        echo "snapshot name: $snapshot_name ($snapshot_id) in $snapshot_region created"
        # snapshot info query API by snapshot id
        # https://developers.digitalocean.com/documentation/v2/#retrieve-an-existing-snapshot-by-id
        echo
        curl -sX GET -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/snapshots/${snapshot_id}" | jq -r .
        echo

        # rename snapshot image description name
        echo "rename snapshot"
        curl -sX PUT -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "{\"name\":\"${snapshot_id}-${snapshot_new_name}\"}" "https://api.digitalocean.com/v2/images/${snapshot_id}" | jq -r .
        echo
    fi

    if [[ "${droplet_id}" && "$snapshot_second" = [yY] ]]; then
        # create second snapshot
        echo "create 2nd snapshot"
        droplet_id=$(awk -F '=' '/droplet_id=/ {print $2}' $PACKER_LOG_PATH)
        curl -sX POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "{\"type\":\"snapshot\",\"name\":\"${snapshot_id}-${snapshot_new_name_second}\"}" "https://api.digitalocean.com/v2/droplets/${droplet_id}/actions" | jq -r .
        echo
    fi
    if [ -f /usr/local/bin/doctl ]; then
        echo
        doctl compute image list-user | grep 'packer' | egrep 'Distribution|snapshot'
        echo
    fi
  else
    echo "/root/tools/centminmod-digitalocean-marketplace/packer does not exist"
    exit 1
  fi
}


build