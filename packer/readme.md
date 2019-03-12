* [packer.io install](#packerio-install)
* [packer explained](#packer-explained)
* [build centminmod digitalocean snapshot image](#build-centminmod-digitalocean-snapshot-image)
  * [Override Variables](#override-variables)
* [Example validation & inspection](#example-validation--inspection)
* [Example start of packer build run](#example-start-of-packer-build-run)
* [Using build-image.sh script](#using-build-imagesh-script)
* [DigitalOcean Marketplace img_check.sh compatibility](#digitalocean-marketplace-img_checksh-compatibility)
* [Updated packer builds with benchmarks](#updated-packer-builds-with-benchmarks)
* [Example Build With Docker + Redis + ELRepo Linux 5.x Kernel](#example-build-with-docker--redis--elrepo-linux-5x-kernel)
  * [first boot MOTD](#first-boot-motd)
  * [first boot prompts](#first-boot-prompts)

# packer.io install

```
yum -y install jq
mkdir -p /root/tools
cd /root/tools
packer_version=1.3.5
wget https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_amd64.zip
unzip packer_${packer_version}_linux_amd64.zip -df /usr/local/bin
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

Build CentOS 7 64bit Centmin Mod DigitalOcean snapshot image using packer.io using `packer-centos7-basic.json` or `packer-centos7-basic-php73.json` or `packer-centos7-basic-php71.json` configuration using DigitalOcean `sfo2` region and lowest disk space sized DigitalOcean droplet plan, [cpu optimized droplet](https://centminmod.com/digitalocean/) (c-2 default) or [standard droplet 1GB plan](https://centminmod.com/digitalocean/) (s-1vcpu-1gb) - both come in at 25GB disk size. However cpu optimized droplet (c-2), can install Centmin and build DigitalOcean snapshot image 3x times faster than standard droplet 1GB plan.

You need to manually export your generated [DigitalOcean API Token](https://cloud.digitalocean.com/account/api/tokens) below `TOKEN='YOUR_DO_API_KEY'`

## For PHP 7.2 default Centmin Mod builds

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
export PACKER_LOG_PATH="packerlog-php72-$(date +"%d%m%y-%H%M%S").log"
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

## For PHP 7.3 default Centmin Mod builds

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
export PACKER_LOG_PATH="packerlog-php73-$(date +"%d%m%y-%H%M%S").log"
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

## For PHP 7.1 default Centmin Mod builds

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
export PACKER_LOG_PATH="packerlog-php71-$(date +"%d%m%y-%H%M%S").log"
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

## Override Variables

You can also override `packer-centos7-basic.json` or `packer-centos7-basic-php73.json` or `packer-centos7-basic-php71.json` set variables at runtime on command line.

Variables available

* do_token - default takes the value of exported `TOKEN` variable
* do_image_name - default = `centos7-packer-snapshot-{{timestamp}}`
* do_image - default = `centos-7-x64`
* do_region - default = `sfo2` (others available `nyc3` or `ams3` or `sgp1` which also have corresponding DigitalOcean Spaces region available)
* do_size - default = `c-2` or set to `s-1vcpu-1gb`
* do_tags - default = `cmm`
* install_elrepo - default = `n`
* install_bbr - default = `n`
* install_docker - default = `n`
* install_redis - default = `n`
* install_auditd - default = `n`
* enable_brotli - default = `n`
* enable_phppgo - default = `n`
* enable_logrotate_zstd - default = `n`
* enable_phpfpm_systemd - default = `n`

## For PHP 7.2 default Centmin Mod builds

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_size=s-1vcpu-1gb' packer-centos7-basic.json
```

or install docker & redis

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' packer-centos7-basic.json
```

or install docker & redis + elrepo Linux 5.x Kernel

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_elrepo=y' -var 'install_bbr=y' packer-centos7-basic.json
```

or install docker & redis & auditd

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' packer-centos7-basic.json
```

or install docker & redis & auditd & enable nginx brotli module + php brotli extension

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' -var 'enable_brotli=y' packer-centos7-basic.json
```

or install docker & redis & auditd & enable nginx brotli module + php brotli extension & enable zstd compression for php-fpm & nginx log rotation

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' -var 'enable_brotli=y' -var 'enable_logrotate_zstd=y' packer-centos7-basic.json
```

or install docker & redis & auditd & enable nginx brotli module + php brotli extension & enable PHP 7 PGO (for greater than 2 cpu core droplets)

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' -var 'enable_brotli=y' -var 'enable_phppgo=y' packer-centos7-basic.json
```

or

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_token=YOUR_DO_API_KEY' -var 'do_size=s-1vcpu-1gb' -var 'do_tags=YOURTAGS' packer-centos7-basic.json
```

or 

## For PHP 7.3 default Centmin Mod builds

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_size=s-1vcpu-1gb' packer-centos7-basic-php73.json
```

or install docker & redis

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' packer-centos7-basic-php73.json
```

or install docker & redis + elrepo Linux 5.x Kernel

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_elrepo=y' -var 'install_bbr=y' packer-centos7-basic-php73.json
```

or install docker & redis & auditd

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' packer-centos7-basic-php73.json
```

or install docker & redis & auditd & enable nginx brotli module + php brotli extension

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' -var 'enable_brotli=y' packer-centos7-basic-php73.json
```

or install docker & redis & auditd & enable nginx brotli module + php brotli extension & enable zstd compression for php-fpm & nginx log rotation

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' -var 'enable_brotli=y' -var 'enable_logrotate_zstd=y' packer-centos7-basic-php73.json
```

or install docker & redis & auditd & enable nginx brotli module + php brotli extension & enable PHP 7 PGO (for greater than 2 cpu core droplets)

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' -var 'enable_brotli=y' -var 'enable_phppgo=y' packer-centos7-basic-php73.json
```

or

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_token=YOUR_DO_API_KEY' -var 'do_size=s-1vcpu-1gb' -var 'do_tags=YOURTAGS' packer-centos7-basic-php73.json
```

or 

## For PHP 7.1 default Centmin Mod builds

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_size=s-1vcpu-1gb' packer-centos7-basic-php71.json
```

or install docker & redis

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' packer-centos7-basic-php71.json
```

or install docker & redis + elrepo Linux 5.x Kernel

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_elrepo=y' -var 'install_bbr=y' packer-centos7-basic-php71.json
```

or install docker & redis & auditd

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' packer-centos7-basic-php71.json
```

or install docker & redis & auditd & enable nginx brotli module + php brotli extension

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' -var 'enable_brotli=y' packer-centos7-basic-php71.json
```

or install docker & redis & auditd & enable nginx brotli module + php brotli extension & enable zstd compression for php-fpm & nginx log rotation

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' -var 'enable_brotli=y' -var 'enable_logrotate_zstd=y' packer-centos7-basic-php71.json
```

or install docker & redis & auditd & enable nginx brotli module + php brotli extension & enable PHP 7 PGO (for greater than 2 cpu core droplets)

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_auditd=y' -var 'enable_brotli=y' -var 'enable_phppgo=y' packer-centos7-basic-php71.json
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

  do_image              = centos-7-x64
  do_image_name         = centos7-packer-snapshot-php72-{{timestamp}}
  do_region             = sfo2
  do_size               = c-2
  do_tags               = cmm
  do_token              = {{env `TOKEN`}}
  enable_brotli         = n
  enable_logrotate_zstd = n
  enable_phpfpm_systemd = n
  enable_phppgo         = n
  install_auditd        = n
  install_bbr           = n
  install_docker        = n
  install_elrepo        = n
  install_redis         = n

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
==> digitalocean: Creating snapshot: centos7-packer-snapshot-php72-15520722XX
==> digitalocean: Waiting for snapshot to complete...
==> digitalocean: Destroying droplet...
==> digitalocean: Deleting temporary ssh key...
Build 'digitalocean' finished.

==> Builds finished. The artifacts of successful builds are:
--> digitalocean: A snapshot was created: 'centos7-packer-snapshot-php72-15520722XX' (ID: 4447XXXX3) in regions 'sfo2'
```

# Using build-image.sh script

Above manual steps can be automated using `build-image.sh` script or one of the variants below with different default options enabled

* `packer/build-image.sh` - with additional redis option and [PHP-FPM systemd statistics support](https://community.centminmod.com/threads/centos-7-proper-php-fpm-systemd-service-file.16511/#post-70380)
* `packer/build-image-all.sh` - enable all options for ngx_brotli, docker, redis, auditd, linux mainline kernel + Google BBR, PHP profile guided optimizations (PGO), zstd compressed nginx & php-fpm logrotation
* `packer/build-image-with-brotli.sh` - with `build-image.sh` defaults + with ngx_brotli
* `packer/build-image-with-docker.sh` - with `build-image.sh` defaults + with docker
* `packer/build-image-with-kernel-ml.sh` - with `build-image.sh` defaults + with linux mainline kernel
* `packer/build-image-with-phppgo.sh` - with `build-image.sh` defaults + with PHP profile guided optimizations (PGO) [~5-30% faster PHP 7.x performance](https://community.centminmod.com/threads/php-7-3-vs-7-2-vs-7-1-vs-7-0-php-fpm-benchmarks.16090/)
* `packer/build-image-with-zstd.sh` - with `build-image.sh` defaults + with zstd compressed nginx & php-fpm logrotation (smaller compressed rotated logs)

```
export TOKEN='YOUR_DO_API_KEY'

./build-image.sh 

packer validate packer-centos7-basic.json
Template validated successfully.

packer inspect packer-centos7-basic.json
Optional variables and their defaults:

  do_image              = centos-7-x64
  do_image_name         = centos7-packer-snapshot-php72-{{timestamp}}
  do_region             = sfo2
  do_size               = c-2
  do_tags               = cmm
  do_token              = {{env `TOKEN`}}
  enable_brotli         = n
  enable_logrotate_zstd = n
  enable_phppgo         = n
  install_auditd        = n
  install_bbr           = n
  install_docker        = n
  install_elrepo        = n
  install_redis         = n

Builders:

  digitalocean

Provisioners:

  shell

Note: If your build names contain user variables or template
functions such as 'timestamp', these are processed at build time,
and therefore only show in their raw form here.

time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_redis=y' packer-centos7-basic.json
digitalocean output will be in this color.

==> digitalocean: Creating temporary ssh key for droplet...
==> digitalocean: Creating droplet...
==> digitalocean: Waiting for droplet to become active...
==> digitalocean: Using ssh communicator to connect: 167.xxx.xxx.xxx
==> digitalocean: Waiting for SSH to become available...
==> digitalocean: Connected to SSH!
==> digitalocean: Provisioning with shell script: scripts/cmm-install.sh
    digitalocean: LETSENCRYPT_DETECT='y'
    digitalocean: NGINX_VIDEO='y'
    digitalocean: PHPFINFO='y'
    digitalocean: PHP_LZFOUR='y'
    digitalocean: PHP_LZF='y'
    digitalocean: MARIADB_INSTALLTENTHREE='y'
    digitalocean:
    digitalocean:
    digitalocean: hostname: packer-5c84f7e3-3c53-4e05-fc85-f089ed9b27e5
    digitalocean:
    digitalocean: Architecture:          x86_64
    digitalocean: CPU op-mode(s):        32-bit, 64-bit
    digitalocean: Byte Order:            Little Endian
    digitalocean: CPU(s):                2
    digitalocean: On-line CPU(s) list:   0,1
    digitalocean: Thread(s) per core:    1
    digitalocean: Core(s) per socket:    1
    digitalocean: Socket(s):             2
    digitalocean: NUMA node(s):          1
    digitalocean: Vendor ID:             GenuineIntel
    digitalocean: CPU family:            6
    digitalocean: Model:                 79
    digitalocean: Model name:            Intel(R) Xeon(R) CPU E5-2697A v4 @ 2.60GHz
    digitalocean: Stepping:              1
    digitalocean: CPU MHz:               2599.996
    digitalocean: BogoMIPS:              5199.99
    digitalocean: Virtualization:        VT-x
    digitalocean: Hypervisor vendor:     KVM
    digitalocean: Virtualization type:   full
    digitalocean: L1d cache:             32K
    digitalocean: L1i cache:             32K
    digitalocean: L2 cache:              256K
    digitalocean: L3 cache:              40960K
    digitalocean: NUMA node0 CPU(s):     0,1
    digitalocean: Flags:                 fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon rep_good nopl eagerfpu pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm rdseed adx smap xsaveopt
    digitalocean:
```

# DigitalOcean Marketplace img_check.sh compatibility

Unfortunately, DigitalOcean Marketplace's img_check.sh script isn't 100% compatible with CentOS systems due to false assumptions the script makes about CentOS 6/7 systems. See details at https://github.com/digitalocean/marketplace-partners/pull/35 and my DO idea submission at https://ideas.digitalocean.com/ideas/DO-I-2983.

* CSF Firewall compatibility if not using firewalld https://github.com/digitalocean/marketplace-partners/issues/32
* User password set check compatibility for CentOS/Redhat https://github.com/digitalocean/marketplace-partners/issues/33

# Updated packer builds with benchmarks

Being a benchmark & performance addict, might as well benchmark each packer created temporary droplet before it gets automatically destroyed by packer after snapshot image builds. So added Centmin Mod Nginx HTTP/2 HTTPS ECDSA vs RSA ssl cert benchmarks via h2load HTTP/2 HTTPS load tester and sysbench benchmarks.

```
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean: h2load --version
    digitalocean: h2load nghttp2/1.31.1
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-RSA-AES128-GCM-SHA256 -H 'Accept-Encoding: gzip' -c100 -n1000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-RSA-AES128-GCM-SHA256
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 223.19ms, 4480.57 req/s, 9.96MB/s
    digitalocean: requests: 1000 total, 1000 started, 1000 done, 1000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 1000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 2.22MB (2331900) total, 202.15KB (207000) headers (space savings 26.86%), 2.00MB (2102000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     1.06ms     44.78ms     11.73ms      6.01ms    84.80%
    digitalocean: time for connect:     4.78ms    128.31ms     80.40ms     35.30ms    68.00%
    digitalocean: time to 1st byte:    94.18ms    138.74ms    119.59ms     11.50ms    67.00%
    digitalocean: req/s           :      45.03       50.40       47.17        0.93    73.00%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-RSA-AES256-GCM-SHA384 -H 'Accept-Encoding: gzip' -c100 -n1000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-RSA-AES256-GCM-SHA384
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 224.19ms, 4460.54 req/s, 9.92MB/s
    digitalocean: requests: 1000 total, 1000 started, 1000 done, 1000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 1000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 2.22MB (2331900) total, 202.15KB (207000) headers (space savings 26.86%), 2.00MB (2102000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     1.92ms     46.55ms     11.68ms      6.40ms    87.30%
    digitalocean: time for connect:     4.58ms    131.28ms     80.78ms     37.98ms    62.00%
    digitalocean: time to 1st byte:    99.43ms    141.66ms    121.19ms     12.30ms    60.00%
    digitalocean: req/s           :      45.87       49.52       47.03        0.84    64.00%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-ECDSA-AES128-GCM-SHA256 -H 'Accept-Encoding: gzip' -c100 -n1000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-ECDSA-AES128-GCM-SHA256
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 191.33ms, 5226.65 req/s, 11.62MB/s
    digitalocean: requests: 1000 total, 1000 started, 1000 done, 1000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 1000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 2.22MB (2331900) total, 202.15KB (207000) headers (space savings 26.86%), 2.00MB (2102000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:      330us     34.23ms     10.53ms      6.21ms    79.20%
    digitalocean: time for connect:     3.69ms    107.49ms     60.86ms     29.36ms    66.00%
    digitalocean: time to 1st byte:    74.24ms    118.18ms     96.51ms     12.73ms    68.00%
    digitalocean: req/s           :      52.93       57.96       55.80        1.18    69.00%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-ECDSA-AES256-GCM-SHA384 -H 'Accept-Encoding: gzip' -c100 -n1000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-ECDSA-AES256-GCM-SHA384
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 207.53ms, 4818.58 req/s, 10.72MB/s
    digitalocean: requests: 1000 total, 1000 started, 1000 done, 1000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 1000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 2.22MB (2331900) total, 202.15KB (207000) headers (space savings 26.86%), 2.00MB (2102000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     2.20ms     42.58ms     11.67ms      6.04ms    82.20%
    digitalocean: time for connect:     3.61ms    110.73ms     63.86ms     31.58ms    61.00%
    digitalocean: time to 1st byte:    78.04ms    122.05ms    101.39ms     12.88ms    60.00%
    digitalocean: req/s           :      49.60       54.84       51.58        1.12    67.00%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-RSA-AES128-GCM-SHA256 -H 'Accept-Encoding: gzip' -c300 -n6000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-RSA-AES128-GCM-SHA256
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 961.05ms, 6243.17 req/s, 13.87MB/s
    digitalocean: requests: 6000 total, 6000 started, 6000 done, 6000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 6000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 13.33MB (13976700) total, 1.18MB (1242000) headers (space savings 26.86%), 12.03MB (12612000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     2.06ms    129.10ms     32.79ms     13.32ms    93.00%
    digitalocean: time for connect:    22.22ms    381.65ms    225.32ms    103.95ms    61.00%
    digitalocean: time to 1st byte:   269.84ms    413.17ms    345.61ms     42.09ms    57.67%
    digitalocean: req/s           :      21.05       22.31       21.58        0.31    62.67%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-RSA-AES256-GCM-SHA384 -H 'Accept-Encoding: gzip' -c300 -n6000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-RSA-AES256-GCM-SHA384
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 969.31ms, 6189.96 req/s, 13.75MB/s
    digitalocean: requests: 6000 total, 6000 started, 6000 done, 6000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 6000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 13.33MB (13976700) total, 1.18MB (1242000) headers (space savings 26.86%), 12.03MB (12612000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     1.83ms    130.93ms     32.39ms     15.03ms    88.82%
    digitalocean: time for connect:    25.36ms    394.90ms    229.99ms    108.61ms    58.67%
    digitalocean: time to 1st byte:   280.64ms    426.43ms    353.13ms     46.85ms    59.67%
    digitalocean: req/s           :      20.85       22.81       21.62        0.51    78.67%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-ECDSA-AES128-GCM-SHA256 -H 'Accept-Encoding: gzip' -c300 -n6000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-ECDSA-AES128-GCM-SHA256
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 810.64ms, 7401.60 req/s, 16.44MB/s
    digitalocean: requests: 6000 total, 6000 started, 6000 done, 6000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 6000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 13.33MB (13976700) total, 1.18MB (1242000) headers (space savings 26.86%), 12.03MB (12612000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:      955us     76.01ms     31.17ms      6.57ms    90.10%
    digitalocean: time for connect:    18.36ms    220.63ms    148.02ms     32.33ms    81.00%
    digitalocean: time to 1st byte:   116.87ms    253.74ms    179.73ms     29.87ms    78.67%
    digitalocean: req/s           :      25.09       27.57       25.91        0.56    75.00%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-ECDSA-AES256-GCM-SHA384 -H 'Accept-Encoding: gzip' -c300 -n6000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-ECDSA-AES256-GCM-SHA384
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 898.14ms, 6680.48 req/s, 14.84MB/s
    digitalocean: requests: 6000 total, 6000 started, 6000 done, 6000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 6000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 13.33MB (13976700) total, 1.18MB (1242000) headers (space savings 26.86%), 12.03MB (12612000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     5.49ms    110.49ms     32.16ms     12.53ms    90.73%
    digitalocean: time for connect:    21.19ms    325.34ms    177.54ms     93.96ms    56.00%
    digitalocean: time to 1st byte:   212.38ms    358.71ms    282.20ms     49.21ms    54.67%
    digitalocean: req/s           :      22.67       24.08       23.29        0.40    60.67%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-RSA-AES128-GCM-SHA256 -H 'Accept-Encoding: br' -c100 -n1000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-RSA-AES128-GCM-SHA256
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 188.65ms, 5300.88 req/s, 34.50MB/s
    digitalocean: requests: 1000 total, 1000 started, 1000 done, 1000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 1000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 6.51MB (6824900) total, 205.08KB (210000) headers (space savings 29.29%), 6.29MB (6592000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     2.22ms     47.60ms      9.18ms      7.42ms    88.80%
    digitalocean: time for connect:     4.49ms    120.05ms     74.26ms     33.08ms    61.00%
    digitalocean: time to 1st byte:    91.72ms    127.71ms    110.88ms     10.25ms    59.00%
    digitalocean: req/s           :      53.39       59.80       56.27        1.13    74.00%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-RSA-AES256-GCM-SHA384 -H 'Accept-Encoding: br' -c100 -n1000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-RSA-AES256-GCM-SHA384
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 188.38ms, 5308.39 req/s, 34.55MB/s
    digitalocean: requests: 1000 total, 1000 started, 1000 done, 1000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 1000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 6.51MB (6824900) total, 205.08KB (210000) headers (space savings 29.29%), 6.29MB (6592000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     1.59ms     47.46ms      9.13ms      6.81ms    88.60%
    digitalocean: time for connect:     4.68ms    118.83ms     74.85ms     32.26ms    68.00%
    digitalocean: time to 1st byte:    94.17ms    126.76ms    112.21ms      9.83ms    66.00%
    digitalocean: req/s           :      53.27       58.65       55.79        0.97    68.00%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-ECDSA-AES128-GCM-SHA256 -H 'Accept-Encoding: br' -c100 -n1000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-ECDSA-AES128-GCM-SHA256
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 171.04ms, 5846.45 req/s, 38.05MB/s
    digitalocean: requests: 1000 total, 1000 started, 1000 done, 1000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 1000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 6.51MB (6824900) total, 205.08KB (210000) headers (space savings 29.29%), 6.29MB (6592000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     1.28ms     44.88ms      8.87ms      6.31ms    89.10%
    digitalocean: time for connect:     3.57ms     98.91ms     59.43ms     26.85ms    60.00%
    digitalocean: time to 1st byte:    76.64ms    106.14ms     94.42ms      7.10ms    66.00%
    digitalocean: req/s           :      60.00       67.09       62.28        1.32    73.00%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-ECDSA-AES256-GCM-SHA384 -H 'Accept-Encoding: br' -c100 -n1000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-ECDSA-AES256-GCM-SHA384
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 167.80ms, 5959.65 req/s, 38.79MB/s
    digitalocean: requests: 1000 total, 1000 started, 1000 done, 1000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 1000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 6.51MB (6824900) total, 205.08KB (210000) headers (space savings 29.29%), 6.29MB (6592000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     2.37ms     40.55ms      8.64ms      5.65ms    88.10%
    digitalocean: time for connect:     9.14ms     94.88ms     60.33ms     26.45ms    60.00%
    digitalocean: time to 1st byte:    69.05ms    101.90ms     90.55ms      9.03ms    55.00%
    digitalocean: req/s           :      61.62       69.63       64.11        1.41    66.00%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-RSA-AES128-GCM-SHA256 -H 'Accept-Encoding: br' -c300 -n6000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-RSA-AES128-GCM-SHA256
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 770.49ms, 7787.28 req/s, 50.67MB/s
    digitalocean: requests: 6000 total, 6000 started, 6000 done, 6000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 6000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 39.04MB (40934700) total, 1.20MB (1260000) headers (space savings 29.29%), 37.72MB (39552000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     2.92ms    123.66ms     22.90ms     15.38ms    85.30%
    digitalocean: time for connect:    22.29ms    376.73ms    223.69ms    105.12ms    58.00%
    digitalocean: time to 1st byte:   287.67ms    398.43ms    343.93ms     35.69ms    63.00%
    digitalocean: req/s           :      26.21       29.47       27.25        0.70    76.00%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-RSA-AES256-GCM-SHA384 -H 'Accept-Encoding: br' -c300 -n6000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-RSA-AES256-GCM-SHA384
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 810.96ms, 7398.66 req/s, 48.14MB/s
    digitalocean: requests: 6000 total, 6000 started, 6000 done, 6000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 6000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 39.04MB (40934700) total, 1.20MB (1260000) headers (space savings 29.29%), 37.72MB (39552000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     5.73ms    127.03ms     25.28ms     14.00ms    93.93%
    digitalocean: time for connect:    30.02ms    368.54ms    222.05ms    102.94ms    57.67%
    digitalocean: time to 1st byte:   277.18ms    389.97ms    336.64ms     36.86ms    64.00%
    digitalocean: req/s           :      25.21       26.80       25.83        0.42    65.00%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-ECDSA-AES128-GCM-SHA256 -H 'Accept-Encoding: br' -c300 -n6000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-ECDSA-AES128-GCM-SHA256
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 691.06ms, 8682.29 req/s, 56.49MB/s
    digitalocean: requests: 6000 total, 6000 started, 6000 done, 6000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 6000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 39.04MB (40934700) total, 1.20MB (1260000) headers (space savings 29.29%), 37.72MB (39552000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:      854us     98.68ms     22.52ms     12.32ms    86.02%
    digitalocean: time for connect:    27.16ms    287.61ms    168.94ms     81.44ms    54.33%
    digitalocean: time to 1st byte:   197.20ms    309.86ms    257.65ms     36.20ms    57.33%
    digitalocean: req/s           :      29.44       33.22       30.71        0.88    65.67%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load -t1 --ciphers=ECDHE-ECDSA-AES256-GCM-SHA384 -H 'Accept-Encoding: br' -c300 -n6000 https://http2.domain.com/
    digitalocean: TLS Protocol: TLSv1.2
    digitalocean: Cipher: ECDHE-ECDSA-AES256-GCM-SHA384
    digitalocean: Server Temp Key: ECDH P-256 256 bits
    digitalocean: Application protocol: h2
    digitalocean:
    digitalocean: finished in 721.57ms, 8315.24 req/s, 54.10MB/s
    digitalocean: requests: 6000 total, 6000 started, 6000 done, 6000 succeeded, 0 failed, 0 errored, 0 timeout
    digitalocean: status codes: 6000 2xx, 0 3xx, 0 4xx, 0 5xx
    digitalocean: traffic: 39.04MB (40934700) total, 1.20MB (1260000) headers (space savings 29.29%), 37.72MB (39552000) data
    digitalocean:                      min         max         mean         sd        +/- sd
    digitalocean: time for request:     2.29ms    102.88ms     24.37ms     12.90ms    91.07%
    digitalocean: time for connect:    22.09ms    307.06ms    167.93ms     82.52ms    59.67%
    digitalocean: time to 1st byte:   208.20ms    329.45ms    268.13ms     39.23ms    63.33%
    digitalocean: req/s           :      28.13       29.85       28.88        0.40    67.33%
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean:
    digitalocean: h2load tests completed using temp /etc/hosts entry:
    digitalocean: server-ip-mask http2.domain.com #h2load
    digitalocean:
    digitalocean: centmin mod local code last commit:
    digitalocean:
    digitalocean: 3092268 George Liu Sat, 9 Mar 2019 18:34:42 +1000
    digitalocean: update march_hostcheck function in 123.09beta01
    digitalocean:
    digitalocean: users requests req/s encoding cipher protocol started succeeded
    digitalocean: 100 1000 4480.57 gzip ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2 1000 1000
    digitalocean: 100 1000 4460.54 gzip ECDHE-RSA-AES256-GCM-SHA384 TLSv1.2 1000 1000
    digitalocean: 100 1000 5226.65 gzip ECDHE-ECDSA-AES128-GCM-SHA256 TLSv1.2 1000 1000
    digitalocean: 100 1000 4818.58 gzip ECDHE-ECDSA-AES256-GCM-SHA384 TLSv1.2 1000 1000
    digitalocean: 300 6000 6243.17 gzip ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2 6000 6000
    digitalocean: 300 6000 6189.96 gzip ECDHE-RSA-AES256-GCM-SHA384 TLSv1.2 6000 6000
    digitalocean: 300 6000 7401.60 gzip ECDHE-ECDSA-AES128-GCM-SHA256 TLSv1.2 6000 6000
    digitalocean: 300 6000 6680.48 gzip ECDHE-ECDSA-AES256-GCM-SHA384 TLSv1.2 6000 6000
    digitalocean: 100 1000 5300.88 br'  ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2 1000 1000
    digitalocean: 100 1000 5308.39 br'  ECDHE-RSA-AES256-GCM-SHA384 TLSv1.2 1000 1000
    digitalocean: 100 1000 5846.45 br'  ECDHE-ECDSA-AES128-GCM-SHA256 TLSv1.2 1000 1000
    digitalocean: 100 1000 5959.65 br'  ECDHE-ECDSA-AES256-GCM-SHA384 TLSv1.2 1000 1000
    digitalocean: 300 6000 7787.28 br'  ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2 6000 6000
    digitalocean: 300 6000 7398.66 br'  ECDHE-RSA-AES256-GCM-SHA384 TLSv1.2 6000 6000
    digitalocean: 300 6000 8682.29 br'  ECDHE-ECDSA-AES128-GCM-SHA256 TLSv1.2 6000 6000
    digitalocean: 300 6000 8315.24 br'  ECDHE-ECDSA-AES256-GCM-SHA384 TLSv1.2 6000 6000
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean: h2load result summary
    digitalocean: min:      avg:      max:      stddev:   requests-succeeded:
    digitalocean: 4460.540  6256.274  8682.290  1337.717  100.00
    digitalocean: -------------------------------------------------------------------------------------------
    digitalocean: h2load result summary end
    digitalocean:
    digitalocean: clean up https://http2.domain.com
```

```
    digitalocean: ---------------------------------------------
    digitalocean: ./sysbench.sh cpu
    digitalocean: ---------------------------------------------
    digitalocean: -------------------------------------------
    digitalocean: System Information
    digitalocean: -------------------------------------------
    digitalocean:
    digitalocean: 3.10.0-862.2.3.el7.x86_64
    digitalocean:
    digitalocean: CentOS Linux release 7.6.1810 (Core)
    digitalocean:
    digitalocean: Centmin Mod
    digitalocean: Architecture:          x86_64
    digitalocean: CPU op-mode(s):        32-bit, 64-bit
    digitalocean: Byte Order:            Little Endian
    digitalocean: CPU(s):                2
    digitalocean: On-line CPU(s) list:   0,1
    digitalocean: Thread(s) per core:    1
    digitalocean: Core(s) per socket:    1
    digitalocean: Socket(s):             2
    digitalocean: NUMA node(s):          1
    digitalocean: Vendor ID:             GenuineIntel
    digitalocean: CPU family:            6
    digitalocean: Model:                 85
    digitalocean: Model name:            Intel(R) Xeon(R) Platinum 8168 CPU @ 2.70GHz
    digitalocean: Stepping:              4
    digitalocean: CPU MHz:               2693.674
    digitalocean: BogoMIPS:              5387.34
    digitalocean: Virtualization:        VT-x
    digitalocean: Hypervisor vendor:     KVM
    digitalocean: Virtualization type:   full
    digitalocean: L1d cache:             32K
    digitalocean: L1i cache:             32K
    digitalocean: L2 cache:              1024K
    digitalocean: L3 cache:              33792K
    digitalocean: NUMA node0 CPU(s):     0,1
    digitalocean: Flags:                 fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon rep_good nopl eagerfpu pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm mpx avx512f avx512dq rdseed adx smap clflushopt clwb avx512cd avx512bw avx512vl xsaveopt xsavec xgetbv1 pku ospke
    digitalocean:
    digitalocean: CPU Flags
    digitalocean:  fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon rep_good nopl eagerfpu pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm mpx avx512f avx512dq rdseed adx smap clflushopt clwb avx512cd avx512bw avx512vl xsaveopt xsavec xgetbv1 pku ospke
    digitalocean:
    digitalocean: CPU NODE SOCKET CORE L1d:L1i:L2:L3 ONLINE
    digitalocean: 0   0    0      0    0:0:0:0       yes
    digitalocean: 1   0    1      1    0:0:0:0       yes
    digitalocean:
    digitalocean:               total        used        free      shared  buff/cache   available
    digitalocean: Mem:           3790         296        3003          18         490        3218
    digitalocean: Low:           3790         786        3003
    digitalocean: High:             0           0           0
    digitalocean: Swap:          1023           0        1023
    digitalocean:
    digitalocean: Filesystem      Size  Used Avail Use% Mounted on
    digitalocean: /dev/vda1        25G  5.3G   20G  21% /
    digitalocean: devtmpfs        1.9G     0  1.9G   0% /dev
    digitalocean: tmpfs           1.9G     0  1.9G   0% /dev/shm
    digitalocean: tmpfs           1.9G   17M  1.9G   1% /run
    digitalocean: tmpfs           1.9G     0  1.9G   0% /sys/fs/cgroup
    digitalocean: tmpfs           380M     0  380M   0% /run/user/0
    digitalocean: /dev/loop0      5.8G   25M  5.5G   1% /tmp
    digitalocean:
    digitalocean:
    digitalocean: sysbench cpu --cpu-max-prime=20000 --threads=1 run
    digitalocean: sysbench 1.0.16 (using bundled LuaJIT 2.1.0-beta2)
    digitalocean: threads: 1
    digitalocean: prime: 20000
    digitalocean: events/s: 447.43
    digitalocean: time: 10.0002s
    digitalocean: min: 2.21
    digitalocean: avg: 2.23
    digitalocean: max: 3.49
    digitalocean: 95th: 2.26
    digitalocean:
    digitalocean: | cpu sysbench | threads: | events/s: | time: | min: | avg: | max: | 95th: |
    digitalocean: | --- | --- | --- | --- | --- | --- | --- | --- |
    digitalocean: | 1.0.16 | 1 | 447.43 | 10.0002s | 2.21 | 2.23 | 3.49 | 2.26 |
    digitalocean:
    digitalocean: sysbench,threads,events/s,time,min,avg,max,95th
    digitalocean: 1.0.16,1,447.43,10.0002s,2.21,2.23,3.49,2.26
    digitalocean:
    digitalocean: sysbench cpu --cpu-max-prime=20000 --threads=2 run
    digitalocean: sysbench 1.0.16 (using bundled LuaJIT 2.1.0-beta2)
    digitalocean: threads: 2
    digitalocean: prime: 20000
    digitalocean: events/s: 893.19
    digitalocean: time: 10.0021s
    digitalocean: min: 2.22
    digitalocean: avg: 2.24
    digitalocean: max: 3.04
    digitalocean: 95th: 2.26
    digitalocean:
    digitalocean: | cpu sysbench | threads: | events/s: | time: | min: | avg: | max: | 95th: |
    digitalocean: | --- | --- | --- | --- | --- | --- | --- | --- |
    digitalocean: | 1.0.16 | 2 | 893.19 | 10.0021s | 2.22 | 2.24 | 3.04 | 2.26 |
    digitalocean:
    digitalocean: sysbench,threads,events/s,time,min,avg,max,95th
    digitalocean: 1.0.16,2,893.19,10.0021s,2.22,2.24,3.04,2.26
    digitalocean:
```

# Example Build With Docker + Redis + ELRepo Linux 5.x Kernel

For prebuilt image with [override variable](#override-variables) options enabled to install docker & redis + elrepo Linux 5.x Kernel

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' -var 'install_elrepo=y' -var 'install_bbr=y' packer-centos7-basic.json
```

Then using that image to create a new CentOS 7 droplet with Centmin Mod LEMP stack pre installed


## first boot MOTD

On First boot right now shows MOTD banner but eventually it will show first time initialisation prompts for users to setup their droplets i.e. hostname and regenerating passwords on first login.

```
===============================================================================
 - Hostname......: centos7-packer-kernel-ml on CentOS Linux 7.6.1810
 - Users.........: Currently 1 user(s) logged on (includes: root)
===============================================================================
 - CPU usage.....: 0.00, 0.02, 0.01 (1, 5, 15 min)
 - Processes.....: 104 running
 - System uptime.: 0 days 0 hours 10 minutes 13 seconds
===============================================================================
              total        used        free      shared  buff/cache   available
Mem:            985         285         331          15         368         470
Swap:          1023           0        1023
===============================================================================
Filesystem     Type      Size  Used Avail Use% Mounted on
devtmpfs       devtmpfs  466M     0  466M   0% /dev
tmpfs          tmpfs     493M     0  493M   0% /dev/shm
tmpfs          tmpfs     493M   13M  480M   3% /run
tmpfs          tmpfs     493M     0  493M   0% /sys/fs/cgroup
/dev/vda1      xfs        25G  5.7G   20G  23% /
tmpfs          tmpfs      99M     0   99M   0% /run/user/0

===============================================================================
# ! This server maybe running CSF Firewall !
#   DO NOT run the below command or you  will lock yourself out of the server:
#
#   iptables -F


===============================================================================
* Getting Started Guide - https://centminmod.com/getstarted.html
* Centmin Mod FAQ - https://centminmod.com/faq.html
* Centmin Mod Config Files - https://centminmod.com/configfiles.html
* Change Log - https://centminmod.com/changelog.html
* Community Forums https://community.centminmod.com  [ << Register ]
===============================================================================
```

## first boot prompts

Preview of what first login prompts would look like eventually

```
===============================================================================
* Getting Started Guide - https://centminmod.com/getstarted.html
* Centmin Mod FAQ - https://centminmod.com/faq.html
* Centmin Mod Config Files - https://centminmod.com/configfiles.html
* Change Log - https://centminmod.com/changelog.html
* Community Forums https://community.centminmod.com  [ << Register ]
===============================================================================


Below are a number of tasks required to initially setup your server


--------------------------------------------------------------------
Setup Server Administration Email
Emails will be used for future notification alert features
--------------------------------------------------------------------
Hit Enter To Skip...
Will be prompted everytime run centmin.sh if both emails not entered
--------------------------------------------------------------------
enter primary email: myemail@domain.com
enter secondary email: myotheremail@domain2.com
--------------------------------------------------------------------

Primary: 1
setup at /etc/centminmod/email-primary.ini

  myemail@domain.com

Secondary: 2
setup at /etc/centminmod/email-secondary.ini

  myotheremail@domain2.com

--------------------------------------------------------------------
Setup main hostname as per Getting Started Guide Step 1
https://centminmod.com/getstarted.html

Main hostname is not same as desired site domain name but
used for where server statistics files get hosted as outlined
here https://community.centminmod.com/threads/1513/

It's usually something like host.domain.com
--------------------------------------------------------------------

Enter desired hostname for this VPS: host.do-test.com


--------------------------------------------------------------------
Whitelist IP in CSF Firewall
--------------------------------------------------------------------
Adding 45.xxx.xxx.xxx to csf.allow and iptables ACCEPT...
csf: IPSET adding [45.xxx.xxx.xxx] to set [chain_ALLOW]


--------------------------------------------------------------------
Ensure centmin mod up to date
--------------------------------------------------------------------
Saved working directory and index state WIP on 123.09beta01: 303fa79 smarter MARCH_TARGETNATIVE='n' routine in 123.09beta01
HEAD is now at 303fa79 smarter MARCH_TARGETNATIVE='n' routine in 123.09beta01
Updating 303fa79..c173666
Fast-forward
 centmin.sh                |   7 ++++++-
 example/custom_config.inc |   1 +
 inc/shortcuts_install.inc |  22 +++++++++++++---------
 inc/sshd.inc              |   3 +++
 tools/php-systemd.sh      | 190 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 5 files changed, 213 insertions(+), 10 deletions(-)
 create mode 100644 tools/php-systemd.sh

--------------------------------------------------------------------
regenerate /etc/ssl/private/pure-ftpd-dhparams.pem
--------------------------------------------------------------------
--------------------------------------------------------------------
regenerating pure-ftpd self-signed ssl certificate
--------------------------------------------------------------------
Generating a 1024 bit RSA private key
................++++++
..............++++++
writing new private key to '/etc/pki/pure-ftpd/pure-ftpd.pem'
-----
--------------------------------------------------------------------
Memcached Server Admin Login File: /usr/local/nginx/html/memcache_e6b9b3b7c4fe33d9.php
Memcached Server Admin Login: /memcache_e6b9b3b7c4fe33d9.php
new memcached username: memadmin2nOJDiSQRZ8
new memcached password: qx71dmaSIKthkshpBNL7NUVOlA
--------------------------------------------------------------------

--------------------------------------------------------------------
PHP Info Login File: /usr/local/nginx/html/37fb8314_phpi.php
PHP Info Login: /37fb8314_phpi.php
PHP Info Login username: phpiadminjGxbutW8tzUteE8
PHP Info Login password: R3rLh54nQ3loFkl3UVr6lbdpQ
--------------------------------------------------------------------

--------------------------------------------------------------------
Generate mysql root password
--------------------------------------------------------------------
Previous MySQL root password:

[client]
user=root
password=Jba538IU41gyfVKdAhb8nxTEXFt

mysqladmin -u root -pJba538IU41gyfVKdAhb8nxTEXFt password NmtATq5mcrFGiROovi6AjXilIVe5

--------------------------------------------------------------------
New MySQL root user password: NmtATq5mcrFGiROovi6AjXilIVe5
--------------------------------------------------------------------

--------------------------------------------------------------------
/root/.my.cnf updated
--------------------------------------------------------------------

[client]
user=root
password=NmtATq5mcrFGiROovi6AjXilIVe5
```

ELRepo Linux 5.x mainline kernel

```
uname -r
5.0.0-2.el7.elrepo.x86_64
```

Automatically enabled Google BBR when you choose ELRepo option install

```
sysctl net.ipv4.tcp_available_congestion_control
net.ipv4.tcp_available_congestion_control = reno cubic bbr

sysctl -n net.core.default_qdisc
fq

sysctl -n net.ipv4.tcp_congestion_control
bbr

lsmod | grep bbr
tcp_bbr                20480  15
```

current Nginx build

```
nginx -V
nginx version: nginx/1.15.9 (100319-151809-centos7-kvm)
built by gcc 8.2.1 20180905 (Red Hat 8.2.1-3) (GCC) 
built with OpenSSL 1.1.1b  26 Feb 2019
TLS SNI support enabled
```
> configure arguments: --with-ld-opt='-Wl,-E -L/usr/local/zlib-cf/lib -L/usr/local/lib -ljemalloc -Wl,-z,relro -Wl,-rpath,/usr/local/zlib-cf/lib:/usr/local/lib' --with-cc-opt='-I/usr/local/zlib-cf/include -I/usr/local/include -m64 -march=x86-64 -mavx -mavx2 -mpclmul -msse4 -msse4.1 -msse4.2 -DTCP_FASTOPEN=23 -g -O3 -fstack-protector-strong -flto -fuse-ld=gold --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wimplicit-fallthrough=0 -fcode-hoisting -Wimplicit-fallthrough=0 -fcode-hoisting -Wno-cast-function-type -Wp,-D_FORTIFY_SOURCE=2' --sbin-path=/usr/local/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf --build=100319-151809-centos7-kvm --with-compat --with-http_stub_status_module --with-http_secure_link_module --with-http_flv_module --with-http_mp4_module --add-module=../nginx-rtmp-module --with-libatomic --with-http_gzip_static_module --with-http_sub_module --with-http_addition_module --with-http_image_filter_module=dynamic --with-http_geoip_module --with-stream_geoip_module --with-stream_realip_module --with-stream_ssl_preread_module --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-http_realip_module --add-dynamic-module=../ngx-fancyindex-0.4.2 --add-module=../ngx_cache_purge-2.5 --add-dynamic-module=../ngx_devel_kit-0.3.0 --add-dynamic-module=../set-misc-nginx-module-0.32 --add-dynamic-module=../echo-nginx-module-0.61 --add-module=../redis2-nginx-module-0.15 --add-module=../ngx_http_redis-0.3.7 --add-module=../memc-nginx-module-0.18 --add-module=../srcache-nginx-module-0.31 --add-dynamic-module=../headers-more-nginx-module-0.33 --with-pcre-jit --with-zlib=../zlib-cloudflare-1.3.0 --with-http_ssl_module --with-http_v2_module --with-openssl=../openssl-1.1.1b

PHP-FPM

```
php -v
PHP 7.2.16 (cli) (built: Mar 10 2019 15:26:19) ( NTS )
Copyright (c) 1997-2018 The PHP Group
Zend Engine v3.2.0, Copyright (c) 1998-2018 Zend Technologies
    with Zend OPcache v7.2.16, Copyright (c) 1999-2018, by Zend Technologies
```

PHP-FPM via systemd supported statistics

```
fpmstats
Processes active: 0, idle: 0, Requests: 0, slow: 0, Traffic: 0req/sec
```

```
php -m
[PHP Modules]
bcmath
bz2
calendar
Core
ctype
curl
date
dom
enchant
exif
fileinfo
filter
ftp
gd
geoip
gettext
gmp
hash
iconv
igbinary
imagick
imap
intl
json
ldap
libxml
lz4
lzf
mailparse
mbstring
mcrypt
memcache
memcached
mysqli
mysqlnd
openssl
pcntl
pcre
PDO
pdo_mysql
pdo_sqlite
Phar
posix
pspell
readline
redis
Reflection
session
shmop
SimpleXML
snmp
soap
sockets
SPL
sqlite3
standard
sysvmsg
sysvsem
sysvshm
tidy
tokenizer
xml
xmlreader
xmlrpc
xmlwriter
xsl
Zend OPcache
zip
zlib

[Zend Modules]
Zend OPcache
```

MariaDB 10.x MySQL Server

```
mysqladmin ver
mysqladmin  Ver 9.1 Distrib 10.3.13-MariaDB, for Linux on x86_64
Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Server version          10.3.13-MariaDB
Protocol version        10
Connection              Localhost via UNIX socket
UNIX socket             /var/lib/mysql/mysql.sock
Uptime:                 32 min 52 sec

Threads: 4  Questions: 1  Slow queries: 0  Opens: 17  Flush tables: 1  Open tables: 11  Queries per second avg: 0.000
```

Redis Server

```
redis-cli info     
# Server
redis_version:5.0.3
redis_git_sha1:00000000
redis_git_dirty:0
redis_build_id:5194991bde1f5722
redis_mode:standalone
os:Linux 5.0.0-2.el7.elrepo.x86_64 x86_64
arch_bits:64
multiplexing_api:epoll
atomicvar_api:atomic-builtin
gcc_version:4.8.5
process_id:4550
run_id:22f17d1aeaf34c0f85e10ceaa39eed45074faf48
tcp_port:6379
uptime_in_seconds:2
uptime_in_days:0
hz:10
configured_hz:10
lru_clock:8771074
executable:/usr/bin/redis-server
config_file:/etc/redis.conf

# Clients
connected_clients:1
client_recent_max_input_buffer:4
client_recent_max_output_buffer:0
blocked_clients:0

# Memory
used_memory:853896
used_memory_human:833.88K
used_memory_rss:5173248
used_memory_rss_human:4.93M
used_memory_peak:853896
used_memory_peak_human:833.88K
used_memory_peak_perc:105.17%
used_memory_overhead:840694
used_memory_startup:791000
used_memory_dataset:13202
used_memory_dataset_perc:20.99%
allocator_allocated:1128856
allocator_active:1376256
allocator_resident:3620864
total_system_memory:1033334784
total_system_memory_human:985.46M
used_memory_lua:37888
used_memory_lua_human:37.00K
used_memory_scripts:0
used_memory_scripts_human:0B
number_of_cached_scripts:0
maxmemory:0
maxmemory_human:0B
maxmemory_policy:noeviction
allocator_frag_ratio:1.22
allocator_frag_bytes:247400
allocator_rss_ratio:2.63
allocator_rss_bytes:2244608
rss_overhead_ratio:1.43
rss_overhead_bytes:1552384
mem_fragmentation_ratio:6.37
mem_fragmentation_bytes:4361360
mem_not_counted_for_evict:0
mem_replication_backlog:0
mem_clients_slaves:0
mem_clients_normal:49694
mem_aof_buffer:0
mem_allocator:jemalloc-5.1.0
active_defrag_running:0
lazyfree_pending_objects:0

# Persistence
loading:0
rdb_changes_since_last_save:0
rdb_bgsave_in_progress:0
rdb_last_save_time:1552274944
rdb_last_bgsave_status:ok
rdb_last_bgsave_time_sec:-1
rdb_current_bgsave_time_sec:-1
rdb_last_cow_size:0
aof_enabled:0
aof_rewrite_in_progress:0
aof_rewrite_scheduled:0
aof_last_rewrite_time_sec:-1
aof_current_rewrite_time_sec:-1
aof_last_bgrewrite_status:ok
aof_last_write_status:ok
aof_last_cow_size:0

# Stats
total_connections_received:1
total_commands_processed:0
instantaneous_ops_per_sec:0
total_net_input_bytes:14
total_net_output_bytes:0
instantaneous_input_kbps:0.00
instantaneous_output_kbps:0.00
rejected_connections:0
sync_full:0
sync_partial_ok:0
sync_partial_err:0
expired_keys:0
expired_stale_perc:0.00
expired_time_cap_reached_count:0
evicted_keys:0
keyspace_hits:0
keyspace_misses:0
pubsub_channels:0
pubsub_patterns:0
latest_fork_usec:0
migrate_cached_sockets:0
slave_expires_tracked_keys:0
active_defrag_hits:0
active_defrag_misses:0
active_defrag_key_hits:0
active_defrag_key_misses:0

# Replication
role:master
connected_slaves:0
master_replid:63b29331f459e86e6f117fb0b395ea4496898896
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:0
second_repl_offset:-1
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0

# CPU
used_cpu_sys:0.008154
used_cpu_user:0.001068
used_cpu_sys_children:0.000000
used_cpu_user_children:0.000000

# Cluster
cluster_enabled:0

# Keyspace
```

Memcached Server

```
memcached -V
memcached 1.5.12
```

```
echo stats | nc 127.0.0.1 11211 
STAT pid 4046
STAT uptime 2042
STAT time 1552274989
STAT version 1.5.12
STAT libevent 2.1.8-stable
STAT pointer_size 64
STAT rusage_user 0.175650
STAT rusage_system 0.068732
STAT max_connections 2048
STAT curr_connections 1
STAT total_connections 2
STAT rejected_connections 0
STAT connection_structures 2
STAT reserved_fds 20
STAT cmd_get 0
STAT cmd_set 0
STAT cmd_flush 0
STAT cmd_touch 0
STAT get_hits 0
STAT get_misses 0
STAT get_expired 0
STAT get_flushed 0
STAT delete_misses 0
STAT delete_hits 0
STAT incr_misses 0
STAT incr_hits 0
STAT decr_misses 0
STAT decr_hits 0
STAT cas_misses 0
STAT cas_hits 0
STAT cas_badval 0
STAT touch_hits 0
STAT touch_misses 0
STAT auth_cmds 0
STAT auth_errors 0
STAT bytes_read 6
STAT bytes_written 0
STAT limit_maxbytes 8388608
STAT accepting_conns 1
STAT listen_disabled_num 0
STAT time_in_listen_disabled_us 0
STAT threads 4
STAT conn_yields 0
STAT hash_power_level 16
STAT hash_bytes 524288
STAT hash_is_expanding 0
STAT slab_reassign_rescues 0
STAT slab_reassign_chunk_rescues 0
STAT slab_reassign_evictions_nomem 0
STAT slab_reassign_inline_reclaim 0
STAT slab_reassign_busy_items 0
STAT slab_reassign_busy_deletes 0
STAT slab_reassign_running 0
STAT slabs_moved 0
STAT lru_crawler_running 0
STAT lru_crawler_starts 2040
STAT lru_maintainer_juggles 2091
STAT malloc_fails 0
STAT log_worker_dropped 0
STAT log_worker_written 0
STAT log_watcher_skipped 0
STAT log_watcher_sent 0
STAT bytes 0
STAT curr_items 0
STAT total_items 0
STAT slab_global_page_pool 0
STAT expired_unfetched 0
STAT evicted_unfetched 0
STAT evicted_active 0
STAT evictions 0
STAT reclaimed 0
STAT crawler_reclaimed 0
STAT crawler_items_checked 0
STAT lrutail_reflocked 0
STAT moves_to_cold 0
STAT moves_to_warm 0
STAT moves_within_lru 0
STAT direct_reclaims 0
STAT lru_bumps_dropped 0
END
```

Docker

```
docker info
Containers: 0
 Running: 0
 Paused: 0
 Stopped: 0
Images: 0
Server Version: 18.09.3
Storage Driver: overlay2
 Backing Filesystem: xfs
 Supports d_type: true
 Native Overlay Diff: true
Logging Driver: json-file
Cgroup Driver: cgroupfs
Plugins:
 Volume: local
 Network: bridge host macvlan null overlay
 Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
Swarm: inactive
Runtimes: runc
Default Runtime: runc
Init Binary: docker-init
containerd version: e6b3f5632f50dbc4e9cb6288d911bf4f5e95b18e
runc version: 6635b4f0c6af3810594d2770f662f34ddc15b40d
init version: fec3683
Security Options:
 seccomp
  Profile: default
Kernel Version: 5.0.0-2.el7.elrepo.x86_64
Operating System: CentOS Linux 7 (Core)
OSType: linux
Architecture: x86_64
CPUs: 1
Total Memory: 985.5MiB
Name: centos7-packer-kernel-ml
ID: HBJP:BM7K:MSAL:W2DS:SKXQ:KKTR:S4QT:R2S4:V7LQ:ADB2:YWW3:OLZI
Docker Root Dir: /var/lib/docker
Debug Mode (client): false
Debug Mode (server): false
Registry: https://index.docker.io/v1/
Labels:
Experimental: false
Insecure Registries:
 127.0.0.0/8
Live Restore Enabled: false
Product License: Community Engine

WARNING: bridge-nf-call-iptables is disabled
WARNING: bridge-nf-call-ip6tables is disabled
```