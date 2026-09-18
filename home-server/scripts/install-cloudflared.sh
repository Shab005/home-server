#!/usr/bin/env bash
# Installs cloudflared (Cloudflare Tunnel client).
set -e

sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared bookworm main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update
sudo apt install -y cloudflared

echo "cloudflared installed. Next steps:"
echo "  1. cloudflared tunnel login"
echo "  2. cloudflared tunnel create <TUNNEL_NAME>"
echo "  3. Copy configs/cloudflared/config.yml.example to ~/.cloudflared/config.yml and edit it"
