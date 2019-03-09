# packer.io snapshot image builds

Using [packer.io to build Centmin Mod DigitalOcean snapshot images](https://github.com/centminmod/centminmod-digitalocean-marketplace/tree/master/packer).


# older scripts to prep already built droplets

```
mkdir -p /root/tools
git clone https://github.com/centminmod/centminmod-digitalocean-marketplace
cd centminmod-digitalocean-marketplace/scripts
./setup.sh
# ./cleanup-minimal.sh
./cleanup.sh
./img-check.sh
rm -rf /root/tools/
mkdir -p /root/tools
shutdown -h now
```