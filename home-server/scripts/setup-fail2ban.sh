#!/usr/bin/env bash
# Installs fail2ban and enables the default sshd jail, which bans an IP
# after repeated failed SSH login attempts.
set -e

sudo apt install -y fail2ban

sudo tee /etc/fail2ban/jail.local > /dev/null << 'JAIL'
[sshd]
enabled = true
maxretry = 5
bantime = 1h
findtime = 10m
JAIL

sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
