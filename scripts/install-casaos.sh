#!/usr/bin/env bash
# Installs CasaOS (personal cloud / self-hosting dashboard).
set -e

curl -fsSL https://get.casaos.io | sudo bash

sudo systemctl status casaos --no-pager
echo "CasaOS should now be reachable at http://<server-local-ip>"
