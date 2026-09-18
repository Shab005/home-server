#!/usr/bin/env bash
# Sets up a basic UFW firewall: deny everything inbound by default,
# allow SSH only from the Tailscale interface, and allow the ports
# actually needed for Samba and CasaOS on the local network.
set -e

sudo apt install -y ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH: restrict to the Tailscale interface only (tailscale0).
# If you're not using Tailscale for SSH, replace this with a rule
# scoped to your local subnet instead of opening it to 0.0.0.0/0.
sudo ufw allow in on tailscale0 to any port 22 proto tcp

# CasaOS dashboard + Samba, local network only — adjust the subnet
# to match your own network.
sudo ufw allow from 192.168.1.0/24 to any port 80 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 139,445 proto tcp

sudo ufw enable
sudo ufw status verbose
