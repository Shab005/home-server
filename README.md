[English](https://github.com/Shab005/home-server/blob/main/README.md) | [فارسی](https://github.com/Shab005/home-server/blob/main/README.fa_IR.md)

# 🏠 Home Server — Debian + CasaOS + Remote Access

A self-hosted home server built on an old PC: local file sharing, a Docker-based management dashboard (CasaOS), and remote access from anywhere without opening a single port on the router.

Two separate access paths are used on purpose, each solving a different problem:

- **Cloudflare Tunnel** — public access to specific services (e.g. a web dashboard) through a real domain, with no exposed router ports and no public IP required.
- **Tailscale** — a private mesh VPN between your own devices, for direct access (including SSH) that doesn't go through any third party.

## Features

- Static local IP so nothing breaks after a reboot
- SSH access for remote management
- Samba file share, usable like a network drive from Windows/macOS/Linux
- Docker + CasaOS as the app management layer
- Public access via Cloudflare Tunnel, no NAT/port-forwarding needed
- Private access via Tailscale for direct, low-latency connections
- Hardening: firewall (UFW), fail2ban, automatic security updates, SSH key-only login
- Basic backup and health-check scripts
- Data stored on a separate, larger partition instead of the OS disk

## Repo Layout

```
home-server/
├── README.md
├── README.fa_IR.md
├── .gitignore
├── configs/
│   ├── cloudflared/config.yml.example
│   ├── samba/smb.conf.example
│   └── network/20-static-enp2s0.network
├── scripts/
│   ├── install-docker.sh
│   ├── install-casaos.sh
│   ├── install-cloudflared.sh
│   ├── install-tailscale.sh
│   ├── setup-firewall.sh
│   ├── setup-fail2ban.sh
│   ├── setup-auto-updates.sh
│   ├── harden-ssh.sh
│   ├── backup.sh
│   └── check-health.sh
└── docs/
    ├── troubleshooting.md
    └── security.md
```

Everything under `configs/` is a `.example` file — copy it, fill in your own values, and never commit the real one. Read a script before running it; none of them are meant to be piped blindly into a shell. Install scripts are safe to re-run (they skip steps already done).

## Setup

### 1. Update the system

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git nano net-tools screen unzip samba openssh-server
```

### 2. Set a static local IP

The server needs a fixed address so Samba, CasaOS, and the tunnel config don't break the next time it reboots or the router reassigns leases.

**Before touching anything**, check which network manager is actually active — disabling the wrong one, or getting the interface name wrong, can drop your connection:

```bash
systemctl is-active NetworkManager networking dhcpcd 2>/dev/null
ip link show
```

Edit the config (see [`configs/network/20-static-enp2s0.network`](configs/network/20-static-enp2s0.network) — rename both the file and the `Name=` line to match **your actual interface**, not the example):

```bash
sudo nano /etc/systemd/network/20-static-<your-interface>.network
```

```bash
sudo systemctl disable networking NetworkManager dhcpcd 2>/dev/null
sudo systemctl stop networking NetworkManager dhcpcd 2>/dev/null
sudo systemctl enable systemd-networkd --now
sudo systemctl restart systemd-networkd
sudo reboot
```

If this breaks connectivity, boot with physical/console access and re-enable whichever service `systemctl is-active` showed as running before you started (e.g. `sudo systemctl enable --now NetworkManager`). An alternative that avoids touching the OS network stack entirely: set a **DHCP reservation** for this device's MAC address on your router instead.

### 3. Enable SSH

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

### 4. Samba file share

Makes a folder on the server available over the network like a NAS drive. This example assumes a single trusted user — see the comments in [`configs/samba/smb.conf.example`](configs/samba/smb.conf.example) if multiple people need write access.

```bash
sudo apt install samba -y
sudo mkdir -p /srv/shared
sudo chown <USER>:<USER> /srv/shared
sudo smbpasswd -a <USER>
```

Append the example config to `/etc/samba/smb.conf`, then:

```bash
sudo systemctl restart smbd
sudo systemctl enable smbd
```

Access from Windows: `\\<server-ip>\Shared`. From Linux/KDE (Dolphin) or macOS (Finder): `smb://<server-ip>/Shared`. To test from the server itself without any GUI: `sudo apt install -y smbclient && smbclient -L localhost -U <USER>`.

### 5. Docker

⚠️ This adds your user to the `docker` group, which is effectively root-equivalent (a container can mount the host filesystem). Only do this for trusted users.

```bash
bash scripts/install-docker.sh
```

### 6. CasaOS

A web dashboard for installing and managing Docker apps. CasaOS's own installer already sets up Docker from the official repo, so if you're only installing CasaOS you can skip step 5.

```bash
bash scripts/install-casaos.sh
```

Dashboard: `http://<server-local-ip>`

### 7. Cloudflare Tunnel

Most home connections sit behind NAT with no public IP, so there's nothing to forward a port to. Cloudflare Tunnel opens an outbound connection from the server to Cloudflare's network, and traffic reaches your services through a domain — no inbound ports, no public IP needed.

```bash
bash scripts/install-cloudflared.sh
```

> If `apt install cloudflared` says "Unable to locate package", run `sudo apt update` again after the repo file exists, then install.

```bash
cloudflared tunnel login
cloudflared tunnel create <TUNNEL_NAME>
```

Copy [`configs/cloudflared/config.yml.example`](configs/cloudflared/config.yml.example) to `~/.cloudflared/config.yml` and fill in your values, then:

```bash
sudo mkdir -p /etc/cloudflared
sudo cp ~/.cloudflared/config.yml /etc/cloudflared/
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
cloudflared tunnel route dns <TUNNEL_NAME> app.example.com
```

> ⚠️ **A tunnel makes a service reachable — it does not make it secure.** If you're exposing an admin panel like CasaOS this way, put **Cloudflare Access** in front of the hostname (Zero Trust → Access → Applications, free for personal use) so it requires a login before anyone reaches it. See [`docs/security.md`](docs/security.md).
>
> SSH is intentionally not routed through this tunnel at all.

### 8. Tailscale

A private mesh VPN between your own devices — direct, low-latency access (including SSH) that doesn't route through a third party.

```bash
bash scripts/install-tailscale.sh
```

### 9. Harden the server

```bash
bash scripts/setup-auto-updates.sh   # automatic security patches
bash scripts/setup-fail2ban.sh       # bans IPs after repeated failed SSH logins
```

`scripts/harden-ssh.sh` disables root login and password authentication — **run it only after confirming key-based SSH login already works** (`ssh-copy-id` first).

The firewall script can lock you out of SSH if misconfigured:
- Keep your current SSH session open in one terminal
- Run the script from a second terminal
- Test a **new** SSH connection before closing the first one
- If it fails, run `sudo ufw disable` from the still-open session

```bash
bash scripts/setup-firewall.sh
```

Edit it first if your LAN subnet isn't `192.168.1.0/24` or your Tailscale interface isn't `tailscale0`.

### 10. Backups and health checks

```bash
bash scripts/check-health.sh   # disk space, SMART health, service status — read-only
bash scripts/backup.sh         # rsync copy to a destination you configure inside the script
```

These are intentionally basic. Periodically test that a file can actually be restored from the backup destination — a backup that's never been restored is unverified.

### 11. Move data to a larger partition (optional)

```bash
sudo systemctl stop docker
sudo mv /var/lib/docker /srv/docker
sudo ln -s /srv/docker /var/lib/docker

sudo systemctl stop casaos
sudo mv /DATA /srv/DATA
sudo ln -s /srv/DATA /DATA

sudo systemctl start docker
sudo systemctl start casaos
```

Stop both services first (as above) — moving data out from under a running service can corrupt it. Make sure the destination is actually mounted before creating the symlink, or it'll silently point at empty space on the root disk.

## Security

See [`docs/security.md`](docs/security.md) for the full list. Highlights: SSH only over Tailscale, never commit tunnel/Tailscale credentials, the `docker` group is root-equivalent, and a tunnel hostname pointed at an admin panel needs Cloudflare Access in front of it.

## Known limitations

- No RAID / disk redundancy — a hardware decision left to you.
- `scripts/backup.sh` is a basic rsync copy, not a full backup system (no versioning, no offsite automation).
- Samba's example config assumes a single trusted user, not a multi-user group model.
- Terminal emulators with a `TERM` value the server doesn't recognize (e.g. `xterm-ghostty`) show a harmless `unknown terminal type` warning during interactive installers.

## Troubleshooting

See [`docs/troubleshooting.md`](docs/troubleshooting.md).

## License

Personal documentation. Third-party services (Cloudflare, Tailscale, CasaOS) are covered by their own terms.
