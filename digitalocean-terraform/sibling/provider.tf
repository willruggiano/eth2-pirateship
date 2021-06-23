terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}

data "digitalocean_ssh_key" "barbosa-ssh-key" {
  name = "barbosa"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "beaconchain_id" {
  type = string
}

resource "digitalocean_volume" "beaconchain" {
  count                    = var.node_count
  region                   = "nyc1"
  name                     = "beaconchain-${count.index}"
  size                     = 100
  description              = "file system storage for beacon-chain data"
  snapshot_id              = var.beaconchain_id
  initial_filesystem_label = "beaconchain"
}

resource "digitalocean_droplet" "node" {
  count      = var.node_count
  image      = "ubuntu-20-04-x64"
  name       = "sibling-node-${count.index}"
  region     = "nyc1"
  size       = "s-4vcpu-8gb-intel"
  monitoring = true
  ssh_keys = [
    data.digitalocean_ssh_key.barbosa-ssh-key.id
  ]
  user_data = templatefile("${path.module}/../common/cloud-init.yaml", {
    beaconchain_volume_name = "beaconchain-${count.index}"
  })
}

resource "digitalocean_volume_attachment" "node" {
  count      = var.node_count
  droplet_id = digitalocean_droplet.node[count.index].id
  volume_id  = digitalocean_volume.beaconchain[count.index].id
}

output "instance_ip_addrs" {
  value = digitalocean_droplet.node.*.ipv4_address
}

resource "digitalocean_firewall" "node" {
  name = "sibling-mainnet"

  droplet_ids = digitalocean_droplet.node.*.id

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "13000"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "12000"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_project" "project" {
  name      = "sibling-mainnet"
  resources = digitalocean_droplet.node.*.urn
}

