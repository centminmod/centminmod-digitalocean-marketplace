#!/bin/bash
############################################################
# https://github.com/digitalocean/marketplace-partners/blob/master/marketplace_docs/build-an-image.md
############################################################

mkdir -p /root/tools
cd /root/tools
if [ ! -d marketplace-partners ]; then
  git clone https://github.com/digitalocean/marketplace-partners
elif [ -d marketplace-partners ]; then
  git stash
  git pull
fi
cd marketplace-partners/marketplace_validation
./img_check.sh
