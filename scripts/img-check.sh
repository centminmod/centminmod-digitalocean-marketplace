#!/bin/bash
############################################################
# https://github.com/digitalocean/marketplace-partners/blob/master/marketplace_docs/build-an-image.md
############################################################

mkdir -p /root/tools
cd /root/tools
git clone https://github.com/digitalocean/marketplace-partners
cd marketplace-partners/marketplace_validation
./img_check.sh
