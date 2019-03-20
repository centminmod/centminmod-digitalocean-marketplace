Below is example of first SSH login to a DigitalOcean droplet created with Centmin Mod LEMP stack prebuilt image from DigitalOcean Marketplace.

There are initial user interactive question prompts and routines to initially setup and customise the new droplet VPS server.

Normal SSH login motd banner

```
===============================================================================
 - Hostname......: centos7-packer-droplet on CentOS Linux 7.6.1810 
 - Users.........: Currently 1 user(s) logged on (includes: root)
===============================================================================
 - CPU usage.....: 0.41, 0.29, 0.11 (1, 5, 15 min)
 - Processes.....: 106 running
 - System uptime.: 0 days 0 hours 1 minutes 48 seconds
===============================================================================
              total        used        free      shared  buff/cache   available
Mem:            985         248         522          15         214         519
Swap:          1023           0        1023
===============================================================================
Filesystem     Type      Size  Used Avail Use% Mounted on
devtmpfs       devtmpfs  467M     0  467M   0% /dev
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

===============================================================================
 Centmin Mod local code is up to date at /usr/local/src/centminmod
 no available updates at this time...
===============================================================================
```

Start of first SSH login routine which asks for primary & secondary email addresses for future alert features when they are setup

```
===============================================================================
* Getting Started Guide - https://centminmod.com/getstarted.html
* Centmin Mod FAQ - https://centminmod.com/faq.html
* Centmin Mod Config Files - https://centminmod.com/configfiles.html
* Change Log - https://centminmod.com/changelog.html
* Community Forums https://community.centminmod.com  [ << Register ]
===============================================================================


Running a number of tasks required to initially setup your server


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

Primary: myemail@domain.com
setup at /etc/centminmod/email-primary.ini

  myemail@domain.com

Secondary: myotheremail@domain2.com
setup at /etc/centminmod/email-secondary.ini

  myotheremail@domain2.com

```

Partially do Getting Started Guide step 1 at https://centminmod.com/getstarted.html. You'd still need to update this hostname with valid DNS A record as well.

```
--------------------------------------------------------------------
Setup main hostname as per Getting Started Guide Step 1
https://centminmod.com/getstarted.html

Main hostname is not same as desired site domain name but
used for where server statistics files get hosted as outlined
here https://community.centminmod.com/threads/1513/

It's usually something like host.domain.com
--------------------------------------------------------------------

Enter desired main hostname for this VPS: host.domain.com

updated main hostname nginx vhost at
/usr/local/nginx/conf/conf.d/virtual.conf

```

When you SSH login, your detected IP address is whitelisted in CSF Firewall to ensure you do not get accidentally blocked.

```
--------------------------------------------------------------------
Whitelist IP in CSF Firewall
--------------------------------------------------------------------
Adding 45.xxx.xxx.xxx to csf.allow and iptables ACCEPT...
csf: IPSET adding [45.xxx.xxx.xxx] to set [chain_ALLOW]

```

Centmin Mod 123.09beta01 and newer local code is updated via `cmupdate` command as Centmin Mod's menu and scripts are github repo backed at /usr/local/src/centminmod.

```
--------------------------------------------------------------------
Ensure centmin mod up to date
--------------------------------------------------------------------
Cloning into 'centminmod'...
remote: Enumerating objects: 469, done.
remote: Counting objects: 100% (469/469), done.
remote: Compressing objects: 100% (427/427), done.
remote: Total 469 (delta 108), reused 162 (delta 21), pack-reused 0
Receiving objects: 100% (469/469), 23.22 MiB | 0 bytes/s, done.
Resolving deltas: 100% (108/108), done.

Completed. Fresh /usr/local/src/centminmod code base in place

```

A `yum -y update` run is made to ensure latest yum updates are done.

```
--------------------------------------------------------------------
Ensure yum packages are up to date

Loaded plugins: fastestmirror, priorities, versionlock
Loading mirror speeds from cached hostfile
 * base: mirror.sjc02.svwh.net
 * elrepo: repos.lax-noc.com
 * epel: mirror.sjc02.svwh.net
 * extras: mirror.sjc02.svwh.net
 * remi: mirrors.mediatemple.net
 * updates: mirror.fileplanet.com
akopytov_sysbench/x86_64/signature                                                                                                                                                                                                 |  833 B  00:00:00     
akopytov_sysbench/x86_64/signature                                                                                                                                                                                                 | 1.0 kB  00:00:00 !!! 
akopytov_sysbench-source/signature                                                                                                                                                                                                 |  833 B  00:00:00     
akopytov_sysbench-source/signature                                                                                                                                                                                                 | 1.0 kB  00:00:00 !!! 
244 packages excluded due to repository priority protections
No packages marked for update

--------------------------------------------------------------------
```

Centmin Mod installs outlined [here](https://centminmod.com/install.html) for curl installer usually auto optimise your nginx, php-fpm, mariadb mysql settings based on detected server environment resources available i.e. cpu, memory and disk space and disk I/O performance. But DigitalOcean prebuilt images are built using the smallest droplet size. So on first SSH login, an auto re-tuning is required to retune settings based on the droplet size and resource parameters detected.

```
--------------------------------------------------------------------
auto tune Centmin Mod LEMP stack settings
based on detected server environment
--------------------------------------------------------------------
auto tune nginx

auto tune php
contents of /etc/centminmod/php.d/a_customphp.ini

date.timezone = UTC
max_execution_time = 60
short_open_tag = On
realpath_cache_size = 512k
realpath_cache_ttl = 14400
upload_max_filesize = 48M
memory_limit = 48M
post_max_size = 48M
expose_php = Off
mail.add_x_header = Off
max_input_nesting_level = 128
max_input_vars = 10000
mysqlnd.net_cmd_buffer_size = 16384
mysqlnd.collect_memory_statistics = Off
mysqlnd.mempool_default_size = 16000
always_populate_raw_post_data=-1

auto tune mysql
Full Reads: 56496
Full Writes: 23883

set innodb_flush_neighbors = 0

innodb_io_capacity = 1700

+------------------------+-------+
/etc/my.cnf adjustment
+------------------------+-------+
existing value: 
Variable_name   Value
innodb_io_capacity      2100
innodb_io_capacity_max  4200
new value: 
Variable_name   Value
innodb_io_capacity      1700
innodb_io_capacity_max  3400

+------------------------+-------+
innodb io threads adjustment
+------------------------+-------+
existing value:
+------------------------+-------+
innodb_read_io_threads = 2
innodb_write_io_threads = 2
+------------------------+-------+
new value:
+------------------------+-------+
innodb_read_io_threads = 2
innodb_write_io_threads = 2
+------------------------+-------+

Restart MySQL server for io thread changes

```

Pure-ftpd self-signed SSL cert and dhparam file needs regenerating for the users droplet

```
--------------------------------------------------------------------
regenerate pure-ftpd ssl cert /etc/ssl/private/pure-ftpd-dhparams.pem
please wait... can take a few minutes depending on speed of server
--------------------------------------------------------------------

--------------------------------------------------------------------
regenerating pure-ftpd self-signed ssl certificate
--------------------------------------------------------------------
Generating a 1024 bit RSA private key
........++++++
........................++++++
writing new private key to '/etc/pki/pure-ftpd/pure-ftpd.pem'
-----
```

Need to regenerate the memcached statistic file's filename, and user/password details

```
--------------------------------------------------------------------
Memcached Server Admin Login File: /usr/local/nginx/html/memcache_82465bf64b70c928.php
Memcached Server Admin Login: /memcache_82465bf64b70c928.php
new memcached username: memadminuJoWca4zEY
new memcached password: tBpTwch38SptnD29LvHZDvjug
--------------------------------------------------------------------
```

Need to regenerate the Zend Opcache statistic file's filename, and user/password details

```
--------------------------------------------------------------------
Generate Zend Opcache Admin password
--------------------------------------------------------------------

reset initial /usr/local/nginx/html/opcache.php


/usr/local/nginx/conf/htpasswd_opcache contents:
opadmindCx8NDerzAzSgw:$apr1$Q/KfJ2TM$52JKsB3M02OnHxt2DAL.T/

-------------------------------------------------------
File Location: /usr/local/nginx/html/b3769ea602a411ef_opcache.php
Password protected /b3769ea602a411ef_opcache.php
-------------------------------------------------------
Username: opadmindCx8NDerzAzSgw
Password: wSGa36j0NwVN9UFLowKPgcmQYzWtA
-------------------------------------------------------
```

Need to regenerate the phpinfo file's filename, and user/password details

```
--------------------------------------------------------------------
PHP Info Login File: /usr/local/nginx/html/af15b1a6_phpi.php
PHP Info Login: /af15b1a6_phpi.php
PHP Info Login username: phpiadminx4jDMTPZ00H436s
PHP Info Login password: d1hJEASP1U5tQkhJQ87oZTH2w
--------------------------------------------------------------------
```

Need to regenerate the MariaDB MySQL root user/password details

```
--------------------------------------------------------------------
Generate mysql root password
--------------------------------------------------------------------

setup mysql root password

--------------------------------------------------------------------
New MySQL root user password: 5lA8SRV7Bi452GhsN3Fr7YuVNfVq
--------------------------------------------------------------------

--------------------------------------------------------------------
/root/.my.cnf updated
--------------------------------------------------------------------

[client]
user=root
password=5lA8RV7Bi452GhsN3Fr7YuVNfVq

```

Optionally prompt if users want to enable php-fpm statistics and systemd php-fpm statistics output display.

```
--------------------------------------------------------------------
enable php-fpm status for localhost only ?
as per https://centminmod.com/phpfpm.html#phpstatus
--------------------------------------------------------------------
Do you want to enable php-fpm status page ? [y/n]: y

php-fpm status enabled

curl -s localhost/phpstatus
pool:                 www
process manager:      ondemand
start time:           20/Mar/2019:22:03:47 +0000
start since:          0
accepted conn:        1
listen queue:         0
max listen queue:     0
listen queue len:     511
idle processes:       0
active processes:     1
total processes:      1
max active processes: 1
max children reached: 0
slow requests:        0

shortcut command = fpmstats

--------------------------------------------------------------------
cleanup /root/.bashrc
--------------------------------------------------------------------
```

Ask if users want to setup DigitalOcean Spaces and s3cmd

```
--------------------------------------------------------------------
setup DigitalOcean Spaces + s3cmd
https://www.digitalocean.com/docs/spaces/resources/s3cmd/
--------------------------------------------------------------------

Do you want to setup DigitalOcean Spaces & s3cdm ? [y/n]: n

skipping DigitalOcean Spaces & s3cmd setup


===============================================================================
* Getting Started Guide - https://centminmod.com/getstarted.html
* Centmin Mod FAQ - https://centminmod.com/faq.html
* Centmin Mod Config Files - https://centminmod.com/configfiles.html
* Change Log - https://centminmod.com/changelog.html
* Community Forums https://community.centminmod.com  [ << Register ]
===============================================================================
```

If you answered yes to setting up DigitalOcean Spaces & s3cmd

```

--------------------------------------------------------------------
setup DigitalOcean Spaces + s3cmd
https://www.digitalocean.com/docs/spaces/resources/s3cmd/
--------------------------------------------------------------------

Do you want to setup DigitalOcean Spaces & s3cdm ? [y/n]: y

installing s3cmd via yum
please wait...

success: s3cmd installed

setup s3cmd --configure options for DO Spaces
s3cmd configuration will be saved to /root/.s3cfg

will need on hand the following details

1. DO Spaces Access Key
2. DO Spaces Secret Key
3. DO Spaces Endpoint i.e. sfo2.digitaloceanspaces.com
4. Desired s3cmd Encryption password you want to set

Enter your DO Spaces Access Key : XXXX

Enter your DO Spaces Secret Key : XXXXXX

Enter your DO Spaces Endpoint : sfo2.digitaloceanspaces.com

Enter desired Encryption password : XXXXXXXX

test s3cmd credentials
list DO Spaces

s3cmd ls
2019-03-16 12:37  s3://DO_SPACES_NAME
```

Optionally upload all those regenerated passwords saved files to your DigitalOcean Spaces.

```
Do you want to upload regenerated passwords to DO Spaces ?
Upload passwords to s3://DO_SPACES_NAME/opt-centminmod-host.domain.com/ ? [y/n]: y

s3cmd put *.txt s3://DO_SPACES_NAME/opt-centminmod-host.domain.com/
upload: 'memcache-admin-login.txt' -> 's3://DO_SPACES_NAME/opt-centminmod-host.domain.com/memcache-admin-login.txt'  [1 of 4]
 381 of 381   100% in    0s     7.29 kB/s  done
upload: 'mysql-root-password.txt' -> 's3://DO_SPACES_NAME/opt-centminmod-host.domain.com/mysql-root-password.txt'  [2 of 4]
 57 of 57   100% in    0s   358.78 B/s  done
upload: 'php-info-password.txt' -> 's3://DO_SPACES_NAME/opt-centminmod-host.domain.com/php-info-password.txt'  [3 of 4]
 335 of 335   100% in    0s     4.17 kB/s  done
upload: 'zend-opcache-admin-login.txt' -> 's3://DO_SPACES_NAME/opt-centminmod-host.domain.com/zend-opcache-admin-login.txt'  [4 of 4]
 355 of 355   100% in    0s  1441.35 B/s  done

s3cmd ls s3://DO_SPACES_NAME/opt-centminmod-host.domain.com/ -r
2019-03-16 13:50       381   s3://DO_SPACES_NAME/opt-centminmod-host.domain.com/memcache-admin-login.txt
2019-03-16 13:50        57   s3://DO_SPACES_NAME/opt-centminmod-host.domain.com/mysql-root-password.txt
2019-03-16 13:50       335   s3://DO_SPACES_NAME/opt-centminmod-host.domain.com/php-info-password.txt
2019-03-16 13:50       355   s3://DO_SPACES_NAME/opt-centminmod-host.domain.com/zend-opcache-admin-login.txt
```

Links for Centmin Mod

```
===============================================================================
* Getting Started Guide - https://centminmod.com/getstarted.html
* Centmin Mod FAQ - https://centminmod.com/faq.html
* Centmin Mod Config Files - https://centminmod.com/configfiles.html
* Change Log - https://centminmod.com/changelog.html
* Community Forums https://community.centminmod.com  [ << Register ]
===============================================================================
```