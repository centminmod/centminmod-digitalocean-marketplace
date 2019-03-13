#!/bin/bash
########################################################
# create droplet from snapshot image id
########################################################
# step 1. Get your SSHKEY ID from API Query
#  curl -sX GET -H "Content-Type: application/json" \ 
#    H "Authorization: Bearer $TOKEN" \ 
#    "https://api.digitalocean.com/v2/account/keys" | jq -r .
#
# step 2. export your SSHKEY ID and DO API Token. 
#  export TOKEN=your_do_api_token
#  export YOUR_SSHKEY_ID=your_ssh_key_id
#
# step 3. edit do_template function's region, size &
#         droplet parameters you want to use first
#
# step 4. run script passing hostname & snapshot image id
#  ./create_droplet.sh host.domain.com YOURIMAGE_ID
########################################################
DT=$(date +"%d%m%y-%H%M%S")
DROPLET_DATAFILE="droplet_data_${DT}.txt"
DO_HOSTNAME=$1
DO_IMAGE=${2:-"centos-7-x64"}

do_template() {
cat > create_droplet.json <<EOF
{
  "name": "$DO_HOSTNAME",
  "region": "sfo2",
  "size": "s-1vcpu-1gb",
  "image": "$DO_IMAGE",
  "backups": false,
  "private_networking": null,
  "ipv6": false,
  "monitoring": false,
  "ssh_keys": [
    $YOUR_SSHKEY_ID
  ]
}
EOF
}

do_create() {
echo
echo "creating new droplet vps server using image: $DO_IMAGE"
echo
# Get droplet option
DO_OPTION=$(tr -d '\n' < ./create_droplet.json | tr -d ' ')
#DO_OPTION=${DO_OPTION/'$DO_HOSTNAME'/$DO_HOSTNAME}
#DO_OPTION=${DO_OPTION/'$DO_IMAGE'/$DO_IMAGE}

# Create droplet
curl -sX POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d $DO_OPTION \
  "https://api.digitalocean.com/v2/droplets" | jq -r . | tee "$DROPLET_DATAFILE"

droplet_id=$(cat $DROPLET_DATAFILE | jq -r '.droplet.id')
droplet_name=$(cat $DROPLET_DATAFILE | jq -r '.droplet.name')
droplet_memory=$(cat $DROPLET_DATAFILE | jq -r '.droplet.memory')
droplet_vcpus=$(cat $DROPLET_DATAFILE | jq -r '.droplet.vcpus')
droplet_disk=$(cat $DROPLET_DATAFILE | jq -r '.droplet.disk')
droplet_status=$(cat $DROPLET_DATAFILE | jq -r '.droplet.status')
droplet_image_id=$(cat $DROPLET_DATAFILE | jq -r '.droplet.image.id')
droplet_image_name=$(cat $DROPLET_DATAFILE | jq -r '.droplet.image.name')
droplet_image_distribution=$(cat $DROPLET_DATAFILE | jq -r '.droplet.image.distribution')
droplet_region=$(cat $DROPLET_DATAFILE | jq -r '.droplet.region.slug')
droplet_region_features=$(cat $DROPLET_DATAFILE | jq -r '.droplet.region.features')
droplet_links_actions_id=$(cat $DROPLET_DATAFILE | jq -r '.links.actions[] | .id')

echo
echo "droplet_id=${droplet_id}"
echo "droplet_name=${droplet_name}"
echo "droplet_memory=${droplet_memory}"
echo "droplet_vcpus=${droplet_vcpus}"
echo "droplet_disk=${droplet_disk}"
echo "droplet_status=${droplet_status}"
echo "droplet_image_id=${droplet_image_id}"
echo "droplet_image_name=${droplet_image_name}"
echo "droplet_image_distribution=${droplet_image_distribution}"
echo "droplet_region=${droplet_region}"
echo "droplet_region_features=${droplet_region_features}"
echo "droplet_links_actions_id=${droplet_links_actions_id}"

echo
}

{
do_template
do_create
} 2>&1 | tee "created-${DROPLET_DATAFILE}"