#!/usr/bin/env bash
# Basic rsync backup: copies the shared folder and CasaOS/Docker data to a
# second location (an external drive, a NAS, or a remote host over SSH).
# This is NOT a substitute for testing restores — periodically verify you
# can actually read files back from the backup destination.
set -e

# Edit this to a mounted external drive, e.g. /mnt/backup-drive
# or a remote path, e.g. user@remote-host:/path/to/backup
BACKUP_DEST="/mnt/backup-drive/home-server-backup"

SOURCES=(
  "/srv/shared"
  "/srv/DATA"
)

mkdir -p "$BACKUP_DEST" 2>/dev/null || true

for src in "${SOURCES[@]}"; do
  if [ -d "$src" ]; then
    echo "Backing up $src ..."
    rsync -avh --delete "$src" "$BACKUP_DEST/"
  else
    echo "Skipping $src (not found)"
  fi
done

echo "Backup finished at $(date). Destination: $BACKUP_DEST"
echo "Reminder: periodically test that files can actually be restored from here."
