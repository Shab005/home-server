#!/usr/bin/env bash
# Installs Tailscale for private, direct remote access between your devices.
set -e

curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

echo "Tailscale installed. Run 'tailscale ip' to see this device's Tailscale address."
