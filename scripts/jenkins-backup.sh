#!/usr/bin/env bash
# Block 22 — back up the parts of JENKINS_HOME that matter, and nothing else.
# Usage: sudo ./scripts/jenkins-backup.sh     (cron: 15 2 * * * ...)
set -euo pipefail

JENKINS_HOME="${JENKINS_HOME:-/var/lib/jenkins}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/jenkins}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="${BACKUP_DIR}/jenkins-${STAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

# Quiesce so nothing changes mid-copy
systemctl stop jenkins

tar --exclude='jobs/*/builds/*/archive' \
    --exclude='jobs/*/workspace*' \
    --exclude='workspace/*' \
    --exclude='caches/*' \
    --exclude='logs/*' \
    --exclude='tools/*' \
    -czf "$OUT" -C "$JENKINS_HOME" .

systemctl start jenkins

# master.key is the crown jewels: keep it separate and private
cp "$JENKINS_HOME/secrets/master.key" "${BACKUP_DIR}/master.key-${STAMP}"
chmod 600 "${BACKUP_DIR}/master.key-${STAMP}"

find "$BACKUP_DIR" -name 'jenkins-*.tar.gz' -mtime +$RETENTION_DAYS -delete
echo "Backup written: $OUT ($(du -h "$OUT" | cut -f1))"
echo "Test your restore: tar -tzf $OUT | head"
