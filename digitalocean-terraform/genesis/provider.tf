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

resource "digitalocean_volume" "docker" {
  region      = "nyc1"
  name        = "docker"
  size        = 1000
  description = "file system storage for docker volume data"
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
    docker_mount_name  = "docker",
  })
}

resource "digitalocean_volume_attachment" "node" {
  droplet_id = digitalocean_droplet.node.id
  volume_id  = digitalocean_volume.docker.id
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

