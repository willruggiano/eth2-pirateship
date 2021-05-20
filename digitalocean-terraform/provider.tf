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

resource "digitalocean_volume" "clef" {
  region      = "nyc1"
  name        = "clef"
  size        = 10
  description = "file system storage for clef"
}

resource "digitalocean_volume" "geth" {
  region      = "nyc1"
  name        = "geth"
  size        = 100
  description = "file system storage for geth"
}

resource "digitalocean_droplet" "node" {
  image      = "ubuntu-20-04-x64"
  name       = "eth-node"
  region     = "nyc1"
  size       = "s-4vcpu-8gb"
  backups    = true
  monitoring = true
  ssh_keys = [
    data.digitalocean_ssh_key.barbosa-ssh-key.id
  ]
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    chain         = "goerli",
    chainid       = 5,
    clef_data_dir = "/mnt/${digitalocean_volume.clef.name}",
    geth_data_dir = "/mnt/${digitalocean_volume.geth.name}"
  })
}

resource "digitalocean_volume_attachment" "node-clef" {
  droplet_id = digitalocean_droplet.node.id
  volume_id  = digitalocean_volume.clef.id
}

resource "digitalocean_volume_attachment" "node-geth" {
  droplet_id = digitalocean_droplet.node.id
  volume_id  = digitalocean_volume.geth.id
}

output "instance_ip_addr" {
  value = digitalocean_droplet.node.ipv4_address
}

resource "digitalocean_droplet_snapshot" "node" {
  droplet_id = digitalocean_droplet.node.id
  name       = "node-snapshot-01"
}

resource "digitalocean_firewall" "node" {
  name = "default-firewall"

  droplet_ids = [digitalocean_droplet.node.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "30303"
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
  name = "eth-pirateship"
  resources = [
    digitalocean_droplet.node.urn
  ]
}

