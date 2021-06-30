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

resource "digitalocean_volume" "beaconchain" {
  region      = "nyc1"
  name        = "beaconchain"
  size        = 100
  description = "file system storage for beacon-chain data"
}

resource "digitalocean_droplet" "node" {
  image      = "ubuntu-20-04-x64"
  name       = "genesis-node"
  region     = "nyc1"
  size       = "s-4vcpu-8gb-intel"
  monitoring = true
  ssh_keys = [
    data.digitalocean_ssh_key.barbosa-ssh-key.id
  ]
  user_data = file("${path.module}/../common/cloud-init.yaml")
}

resource "digitalocean_volume_attachment" "node" {
  droplet_id = digitalocean_droplet.node.id
  volume_id  = digitalocean_volume.beaconchain.id
}

output "instance_ip_addr" {
  value = digitalocean_droplet.node.ipv4_address
}

resource "digitalocean_firewall" "node" {
  name = "genesis-mainnet"

  droplet_ids = [digitalocean_droplet.node.id]

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
  name = "genesis-mainnet"
  resources = [
    digitalocean_droplet.node.urn
  ]
}

