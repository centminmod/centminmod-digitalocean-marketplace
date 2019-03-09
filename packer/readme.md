
# packer.io install

```
yum -y install jq
mkdir -p /root/tools
cd /root/tools
packer_version=1.3.5
wget https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_amd64.zip
unzip packer_${packer_version}_linux_amd64.zip -d /usr/local/bin
rm -f packer_${packer_version}_linux_amd64.zip
packer
packer version
```
```
packer version
Packer v1.3.5
```
```
packer ---help
Usage: packer [--version] [--help] <command> [<args>]

Available commands are:
    build       build image(s) from template
    fix         fixes templates from old versions of packer
    inspect     see components of a template
    validate    check that a template is valid
    version     Prints the Packer version
```

# packer explained

Packer will use DigitalOcean API to spin up a temporary droplet (c-2 or s-1vcpu-1gb) with CentOS 7 64bit OS and install Centmin Mod 123.09beta01 and then clean up after itself and create a DigitalOcean snapshot image and then automatically detroy and remove that temporary droplet. You can see the associated cost of my test Packer Centmin Mod DigitalOcean temporary droplets below:

![packer droplet costs](/packer/images/packer-droplet-costs-01.png)

# build centminmod digitalocean snapshot image

Build CentOS 7 64bit Centmin Mod DigitalOcean snapshot image using packer.io using `packer-centos7-basic.json` or `packer-centos7-basic-php73.json` or `packer-centos7-basic-php71.json` configuration using DigitalOcean `nyc3` region and lowest disk space sized DigitalOcean droplet plan, [cpu optimized droplet](https://centminmod.com/digitalocean/) (c-2 default) or [standard droplet 1GB plan](https://centminmod.com/digitalocean/) (s-1vcpu-1gb) - both come in at 25GB disk size. However cpu optimized droplet (c-2), can install Centmin and build DigitalOcean snapshot image 3x times faster than standard droplet 1GB plan.

You need to manually export your generated [DigitalOcean API Token](https://cloud.digitalocean.com/account/api/tokens) below `TOKEN='YOUR_DO_API_KEY'`

For PHP 7.2 default Centmin Mod builds

```
mkdir -p /home/packertmp
mkdir -p /root/tools/packer/scripts
chmod 1777 /home/packertmp
export TMPDIR=/home/packertmp

cd /root/tools
git clone https://github.com/centminmod/centminmod-digitalocean-marketplace
cd centminmod-digitalocean-marketplace/packer

export TOKEN='YOUR_DO_API_KEY'

packer validate packer-centos7-basic.json
packer inspect packer-centos7-basic.json
export PACKER_LOG_PATH="packerlog-php72.log"
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build packer-centos7-basic.json

# with debug mode
# time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -debug packer-centos7-basic.json

# parse PACKER_LOG_PATH
snapshot_name=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $10}' | sed -e "s|'||g" -e 's|)||g')
snapshot_id=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $12}' | sed -e "s|'||g" -e 's|)||g')
snapshot_region=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $15}' | sed -e "s|'||g" -e 's|)||g')
echo "snapshot name: $snapshot_name ($snapshot_id) in $snapshot_region created"

# snapshot info query API by snapshot id
# https://developers.digitalocean.com/documentation/v2/#retrieve-an-existing-snapshot-by-id
curl -sX GET -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/snapshots/${snapshot_id}" | jq -r .
```

For PHP 7.3 default Centmin Mod builds

```
mkdir -p /home/packertmp
mkdir -p /root/tools/packer/scripts
chmod 1777 /home/packertmp
export TMPDIR=/home/packertmp

cd /root/tools
git clone https://github.com/centminmod/centminmod-digitalocean-marketplace
cd centminmod-digitalocean-marketplace/packer

export TOKEN='YOUR_DO_API_KEY'

packer validate packer-centos7-basic-php73.json
packer inspect packer-centos7-basic-php73.json
export PACKER_LOG_PATH="packerlog-php73.log"
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build packer-centos7-basic-php73.json

# with debug mode
# time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -debug packer-centos7-basic-php73.json

# parse PACKER_LOG_PATH
snapshot_name=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $10}' | sed -e "s|'||g" -e 's|)||g')
snapshot_id=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $12}' | sed -e "s|'||g" -e 's|)||g')
snapshot_region=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $15}' | sed -e "s|'||g" -e 's|)||g')
echo "snapshot name: $snapshot_name ($snapshot_id) in $snapshot_region created"

# snapshot info query API by snapshot id
# https://developers.digitalocean.com/documentation/v2/#retrieve-an-existing-snapshot-by-id
curl -sX GET -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/snapshots/${snapshot_id}" | jq -r .
```

For PHP 7.1 default Centmin Mod builds

```
mkdir -p /home/packertmp
mkdir -p /root/tools/packer/scripts
chmod 1777 /home/packertmp
export TMPDIR=/home/packertmp

cd /root/tools
git clone https://github.com/centminmod/centminmod-digitalocean-marketplace
cd centminmod-digitalocean-marketplace/packer

export TOKEN='YOUR_DO_API_KEY'

packer validate packer-centos7-basic-php71.json
packer inspect packer-centos7-basic-php71.json
export PACKER_LOG_PATH="packerlog-php71.log"
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build packer-centos7-basic-php71.json

# with debug mode
# time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -debug packer-centos7-basic-php71.json

# parse PACKER_LOG_PATH
snapshot_name=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $10}' | sed -e "s|'||g" -e 's|)||g')
snapshot_id=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $12}' | sed -e "s|'||g" -e 's|)||g')
snapshot_region=$(cat $PACKER_LOG_PATH | grep 'digitalocean: A snapshot was created:' | awk '{print $15}' | sed -e "s|'||g" -e 's|)||g')
echo "snapshot name: $snapshot_name ($snapshot_id) in $snapshot_region created"

# snapshot info query API by snapshot id
# https://developers.digitalocean.com/documentation/v2/#retrieve-an-existing-snapshot-by-id
curl -sX GET -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/snapshots/${snapshot_id}" | jq -r .
```

You can also override `packer-centos7-basic.json` or `packer-centos7-basic-php73.json` or `packer-centos7-basic-php71.json` set variables at runtime on command line.

Variables available

* do_token - default takes the value of exported `TOKEN` variable
* do_image_name - default = `centos7-packer-snapshot-{{timestamp}}`
* do_image - default = `centos-7-x64`
* do_region - default = `nyc3`
* do_size - default = `c-2` or set to `s-1vcpu-1gb`
* do_tags - default = `cmm`

For PHP 7.2 default Centmin Mod builds

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_size=s-1vcpu-1gb' packer-centos7-basic.json
```

or

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_token=YOUR_DO_API_KEY' -var 'do_size=s-1vcpu-1gb' -var 'do_tags=YOURTAGS' packer-centos7-basic.json
```

or 

For PHP 7.3 default Centmin Mod builds

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_size=s-1vcpu-1gb' packer-centos7-basic-php73.json
```

or

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_token=YOUR_DO_API_KEY' -var 'do_size=s-1vcpu-1gb' -var 'do_tags=YOURTAGS' packer-centos7-basic-php73.json
```

or 

For PHP 7.1 default Centmin Mod builds

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_size=s-1vcpu-1gb' packer-centos7-basic-php71.json
```

or

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_token=YOUR_DO_API_KEY' -var 'do_size=s-1vcpu-1gb' -var 'do_tags=YOURTAGS' packer-centos7-basic-php71.json
```

# Example validation & inspection

```
packer validate packer-centos7-basic.json
Template validated successfully.
```

```
packer inspect packer-centos7-basic.json
Optional variables and their defaults:

  do_image      = centos-7-x64
  do_image_name = centos7-packer-snapshot-{{timestamp}}
  do_region     = nyc3
  do_size       = c-2
  do_tags       = cmm
  do_token      = {{env `TOKEN`}}

Builders:

  digitalocean

Provisioners:

  shell

Note: If your build names contain user variables or template
functions such as 'timestamp', these are processed at build time,
and therefore only show in their raw form here.
```

# Example start of packer build run

```
digitalocean output will be in this color.

==> digitalocean: Creating temporary ssh key for droplet...
==> digitalocean: Creating droplet...
==> digitalocean: Waiting for droplet to become active...
==> digitalocean: Using ssh communicator to connect: 45.XXX.XXX.XXXX
==> digitalocean: Waiting for SSH to become available...
==> digitalocean: Connected to SSH!
==> digitalocean: Provisioning with shell script: scripts/cmm-install.sh
    digitalocean: LETSENCRYPT_DETECT='y'
    digitalocean: NGINX_VIDEO='y'
    digitalocean: NGXDYNAMIC_BROTLI='y'
    digitalocean: NGINX_LIBBROTLI='y'
    digitalocean: NGINX_BROTLIDEP_UPDATE='y'
    digitalocean: PHPFINFO='y'
    digitalocean: PHP_BROTLI='y'
    digitalocean: PHP_LZFOUR='y'
    digitalocean: PHP_LZF='y'
    digitalocean: PHP_ZSTD='y'
    digitalocean: ZSTD_LOGROTATE_NGINX='y'
    digitalocean: ZSTD_LOGROTATE_PHPFPM='y'
    digitalocean: MARIADB_INSTALLTENTHREE='y'
    digitalocean:
```

ending output

```
    digitalocean: ---------------------------------------------------------------------------
    digitalocean: Total Curl Installer YUM or DNF Time: 106.3270 seconds
    digitalocean: Total YUM Time: 10.798801321 seconds
    digitalocean: Total YUM or DNF + Source Download Time: 37.8307
    digitalocean: Total Nginx First Time Install Time: 365.1407
    digitalocean: Total PHP First Time Install Time: 264.5881
    digitalocean: Download From Github Time: 0.7836
    digitalocean: Total Time Other eg. source compiles: 320.3526
    digitalocean: Total Centmin Mod Install Time: 987.9121
    digitalocean: ---------------------------------------------------------------------------
    digitalocean: Total Install Time (curl yum + cm install + zip download): 1095.0227 seconds
    digitalocean: ---------------------------------------------------------------------------
    digitalocean: 2 Intel(R) Xeon(R) Platinum 8168 CPU @ 2.70GHz
    digitalocean: 2 2693.674
    digitalocean: ---------------------------------------------------------------------------
    digitalocean:
    digitalocean: Loaded plugins: fastestmirror, priorities, versionlock
    digitalocean: Cleaning repos: base centos-sclo-rh centos-sclo-sclo epel extras mariadb
    digitalocean:               : rpmforge updates
    digitalocean: Cleaning up list of fastest mirrors
    digitalocean: Other repos take up 14 M of disk space (use --verbose for details)
    digitalocean: Cleared cache
==> digitalocean: Gracefully shutting down droplet...
==> digitalocean: Creating snapshot: centos7-packer-snapshot-15520722XX
==> digitalocean: Waiting for snapshot to complete...
==> digitalocean: Destroying droplet...
==> digitalocean: Deleting temporary ssh key...
Build 'digitalocean' finished.

==> Builds finished. The artifacts of successful builds are:
--> digitalocean: A snapshot was created: 'centos7-packer-snapshot-15520722XX' (ID: 4447XXXX3) in regions 'nyc3'
```

# DigitalOcean Marketplace img_check.sh compatibility

Unfortunately, DigitalOcean Marketplace's img_check.sh script isn't 100% compatible with CentOS systems due to false assumptions the script makes about CentOS 6/7 systems. See details at https://github.com/digitalocean/marketplace-partners/pull/35 and my DO idea submission at https://ideas.digitalocean.com/ideas/DO-I-2983.

* CSF Firewall compatibility if not using firewalld https://github.com/digitalocean/marketplace-partners/issues/32
* User password set check compatibility for CentOS/Redhat https://github.com/digitalocean/marketplace-partners/issues/33