```
mkdir -p /root/tools
git clone https://github.com/centminmod/centminmod-digitalocean-marketplace
cd centminmod-digitalocean-marketplace/scripts
./setup.sh
./cleanup.sh
./img-check.sh
rm -rf /root/tools/
mkdir -p /root/tools
```