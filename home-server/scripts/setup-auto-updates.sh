#!/usr/bin/env bash
# Enables unattended-upgrades so Debian security patches install
# automatically without needing to remember to run apt upgrade.
set -e

sudo apt install -y unattended-upgrades apt-listchanges
sudo dpkg-reconfigure -plow unattended-upgrades

sudo systemctl enable unattended-upgrades
sudo systemctl status unattended-upgrades --no-pager
