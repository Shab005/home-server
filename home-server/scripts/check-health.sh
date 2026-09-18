#!/usr/bin/env bash
# Quick status check: disk space, disk health (SMART), and the services
# this project depends on. Safe to run any time, changes nothing.

echo "=== Disk space ==="
df -h / /srv 2>/dev/null

echo
echo "=== Disk health (SMART) ==="
for disk in $(lsblk -dno NAME | grep -v loop); do
  echo "--- /dev/$disk ---"
  sudo smartctl -H "/dev/$disk" 2>/dev/null | grep -E "SMART overall-health|PASSED|FAILED" || echo "smartctl not available or unsupported for this disk"
done

echo
echo "=== Service status ==="
for svc in ssh smbd docker casaos cloudflared tailscaled fail2ban ufw unattended-upgrades; do
  if systemctl list-unit-files | grep -q "^${svc}.service"; then
    status=$(systemctl is-active "$svc" 2>/dev/null)
    echo "$svc: $status"
  fi
done
