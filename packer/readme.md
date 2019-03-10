* [packer.io install](#packerio-install)
* [packer explained](#packer-explained)
* [build centminmod digitalocean snapshot image](#build-centminmod-digitalocean-snapshot-image)
  * [Override Variables](#override-variables)
* [Example validation & inspection](#example-validation--inspection)
* [Example start of packer build run](#example-start-of-packer-build-run)
* [Using build-image.sh script](#using-build-imagesh-script)
* [DigitalOcean Marketplace img_check.sh compatibility](#digitalocean-marketplace-img_checksh-compatibility)
* [Updated packer builds with benchmarks](#updated-packer-builds-with-benchmarks)

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

## For PHP 7.2 default Centmin Mod builds

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'do_size=s-1vcpu-1gb' packer-centos7-basic.json
```

or install docker & redis

```
time TMPDIR=/home/packertmp PACKER_LOG=1 packer build -var 'install_docker=y' -var 'install_redis=y' packer-centos7-basic.json
```

or install docker & redis + elrepo Linux 4.x Kernel

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

or install docker & redis + elrepo Linux 4.x Kernel

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

or install docker & redis + elrepo Linux 4.x Kernel

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

  do_image       = centos-7-x64
  do_image_name  = centos7-packer-snapshot-php72-{{timestamp}}
  do_region      = sfo2
  do_size        = c-2
  do_tags        = cmm
  do_token       = {{env `TOKEN`}}
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

Above manual steps can be automated using `build-image.sh` script

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