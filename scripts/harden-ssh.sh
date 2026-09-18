#!/usr/bin/env bash
# Hardens sshd config: disables root login and password auth (key-based only).
# Run this ONLY after confirming your SSH key already works — if you lock
# yourself out, you'll need physical/console access to fix it.
set -e

read -p "Have you confirmed you can already log in with an SSH key (not a password)? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Set up key-based login first: ssh-copy-id <user>@<server-ip>"
  exit 1
fi

sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s)

sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

sudo sshd -t   # validate config before restarting — aborts here if syntax is broken
sudo systemctl restart ssh

echo "Done. Root login and password auth are now disabled. A backup of the old config is at /etc/ssh/sshd_config.bak.*"
