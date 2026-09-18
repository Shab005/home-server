#!/usr/bin/env bash
# Installs Docker Engine + Compose plugin from Docker's official apt repo
# (not the outdated docker.io / docker-compose v1 packages in Debian's own repo).
# Safe to re-run: skips steps that are already done.
set -e

if command -v docker &> /dev/null; then
  echo "Docker is already installed ($(docker --version)). Skipping installation."
else
  sudo apt update
  sudo apt install -y ca-certificates curl gnupg

  sudo install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi

  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

sudo systemctl enable docker
sudo systemctl start docker

if groups "$USER" | grep -q '\bdocker\b'; then
  echo "$USER is already in the docker group."
else
  # Warning: the docker group is effectively root-equivalent — anyone in it
  # can mount the host filesystem via a container. Only add trusted users.
  sudo usermod -aG docker "$USER"
  echo "Added $USER to the docker group. Log out and back in for this to take effect."
fi

docker --version
docker compose version
