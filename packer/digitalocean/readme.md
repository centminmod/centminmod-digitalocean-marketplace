# Create droplet via DigitalOcean API

## step 1. 

Get your SSHKEY ID from API Query

```
curl -sX GET -H "Content-Type: application/json" \ 
             -H "Authorization: Bearer $TOKEN" \ 
             "https://api.digitalocean.com/v2/account/keys" | jq -r .
```
## step 2. 

Export your SSHKEY ID and DO API Token. 

```
export TOKEN=your_do_api_token
export YOUR_SSHKEY_ID=your_ssh_key_id
```

## step 3. 

Edit `create_droplet.sh` within `do_template` function's region, size & droplet parameters you want to use first

```
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
```

## step 4. 

Creating a new droplet server from snapshot image id by running script passing desired hostname `host.domain.com` and snapshot image id i.e. `446XXXXX`

```
./create_droplet.sh host.domain.com 446XXXXX

creating new droplet vps server using image: 446XXXXX

{
  "droplet": {
    "id": 1362XXXXXX,
    "name": "host.domain.com",
    "memory": 1024,
    "vcpus": 1,
    "disk": 25,
    "locked": true,
    "status": "new",
    "kernel": null,
    "created_at": "2019-03-13T13:11:40Z",
    "features": [],
    "backup_ids": [],
    "next_backup_window": null,
    "snapshot_ids": [],
    "image": {
      "id": 446XXXXX,
      "name": "446XXXXX-centos7-packer-php72-redis-systemd-130319-082043",
      "distribution": "CentOS",
      "slug": null,
      "public": false,
      "regions": [
        "sfo2"
      ],
      "created_at": "2019-03-13T08:53:37Z",
      "min_disk_size": 25,
      "type": "snapshot",
      "size_gigabytes": 5.24,
      "description": null,
      "tags": [],
      "status": "available",
      "error_message": ""
    },
    "volume_ids": [],
    "size": {
      "slug": "s-1vcpu-1gb",
      "memory": 1024,
      "vcpus": 1,
      "disk": 25,
      "transfer": 1,
      "price_monthly": 5,
      "price_hourly": 0.00744,
      "regions": [
        "ams2",
        "ams3",
        "blr1",
        "fra1",
        "lon1",
        "nyc1",
        "nyc2",
        "nyc3",
        "sfo1",
        "sfo2",
        "sgp1",
        "tor1"
      ],
      "available": true
    },
    "size_slug": "s-1vcpu-1gb",
    "networks": {
      "v4": [],
      "v6": []
    },
    "region": {
      "name": "San Francisco 2",
      "slug": "sfo2",
      "features": [
        "private_networking",
        "backups",
        "ipv6",
        "metadata",
        "install_agent",
        "storage",
        "image_transfer"
      ],
      "available": true,
      "sizes": [
        "c-16",
        "c-2",
        "c-4",
        "c-8",
        "512mb",
        "s-1vcpu-1gb",
        "1gb",
        "s-3vcpu-1gb",
        "s-1vcpu-2gb",
        "s-2vcpu-2gb",
        "2gb",
        "s-1vcpu-3gb",
        "s-2vcpu-4gb",
        "4gb",
        "s-4vcpu-8gb",
        "m-1vcpu-8gb",
        "8gb",
        "s-6vcpu-16gb",
        "16gb",
        "m-16gb",
        "s-8vcpu-32gb",
        "32gb",
        "m-32gb",
        "48gb",
        "s-12vcpu-48gb",
        "s-16vcpu-64gb",
        "64gb",
        "m-64gb",
        "c-32",
        "s-20vcpu-96gb",
        "s-24vcpu-128gb",
        "s-32vcpu-192gb"
      ]
    },
    "tags": []
  },
  "links": {
    "actions": [
      {
        "id": 6471XXXXX,
        "rel": "create",
        "href": "https://api.digitalocean.com/v2/actions/6471XXXXX"
      }
    ]
  }
}

droplet_id=1362XXXXXX
droplet_name=host.domain.com
droplet_memory=1024
droplet_vcpus=1
droplet_disk=25
droplet_status=new
droplet_image_id=446XXXXX
droplet_image_name=446XXXXX-centos7-packer-php72-redis-systemd-130319-082043
droplet_image_distribution=CentOS
droplet_region=sfo2
droplet_region_features=[
  "private_networking",
  "backups",
  "ipv6",
  "metadata",
  "install_agent",
  "storage",
  "image_transfer"
]
droplet_links_actions_id=6471XXXXX
```