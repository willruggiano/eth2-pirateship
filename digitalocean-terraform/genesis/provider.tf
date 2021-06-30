terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}

data "digitalocean_ssh_key" "barbosa" {
  name = "barbosa"
}

data "digitalocean_ssh_key" "blackbeard" {
  name = "blackbeard"
}

data "digitalocean_ssh_key" "ljs" {
  name = "ljs"
}

resource "digitalocean_volume" "beaconchain" {
  region      = "nyc1"
  name        = "beaconchain"
  size        = 100
  description = "file system storage for beacon-chain data"
}

resource "digitalocean_volume" "eth1" {
  region      = "nyc1"
  name        = "eth1"
  size        = 100
  description = "file system storage for eth1 chain data"
}

resource "digitalocean_droplet" "node" {
  image      = "ubuntu-20-04-x64"
  name       = "genesis-node"
  region     = "nyc1"
  size       = "s-4vcpu-8gb-intel"
  monitoring = true
  ssh_keys = [
    data.digitalocean_ssh_key.barbosa.id,
    data.digitalocean_ssh_key.blackbeard.id,
    data.digitalocean_ssh_key.ljs.id
  ]
  user_data = templatefile("${path.module}/../common/cloud-init.yaml", {
    barbosa_ssh_key    = data.digitalocean_ssh_key.barbosa.public_key,
    blackbeard_ssh_key = data.digitalocean_ssh_key.blackbeard.public_key,
    ljs_ssh_key        = data.digitalocean_ssh_key.ljs.public_key,
    eth2_mount_name    = "beaconchain",
    eth1_mount_name    = "eth1"
  })
}

resource "digitalocean_volume_attachment" "eth2" {
  droplet_id = digitalocean_droplet.node.id
  volume_id  = digitalocean_volume.beaconchain.id
}

resource "digitalocean_volume_attachment" "eth1" {
  droplet_id = digitalocean_droplet.node.id
  volume_id  = digitalocean_volume.eth1.id
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

