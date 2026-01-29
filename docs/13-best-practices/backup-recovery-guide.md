# Backup and Recovery Guide

## Comprehensive Data Protection for WALLIX PAM4OT

This guide covers backup strategies, procedures, and disaster recovery for WALLIX deployments.

---

## Backup Overview

```
+===============================================================================+
|                   WHAT TO BACKUP                                              |
+===============================================================================+

  CRITICAL (Required for recovery)
  ================================

  +----------------+------------------+------------------+------------------+
  | Component      | Location         | Frequency        | Retention        |
  +----------------+------------------+------------------+------------------+
  | Database       | PostgreSQL       | Daily            | 30 days          |
  | Configuration  | /etc/opt/wab/    | Daily + changes  | 30 days          |
  | Encryption Keys| /var/opt/wab/keys| Weekly           | Permanent        |
  | Certificates   | /etc/opt/wab/ssl | Monthly          | Until expiry     |
  +----------------+------------------+------------------+------------------+

  IMPORTANT (Needed for full restoration)
  =======================================

  +----------------+------------------+------------------+------------------+
  | Component      | Location         | Frequency        | Retention        |
  +----------------+------------------+------------------+------------------+
  | Recordings     | /var/wab/recorded| Weekly archive   | Per policy       |
  | Audit Logs     | /var/log/wab*/   | Daily            | 90 days          |
  | License        | System           | After changes    | Current          |
  +----------------+------------------+------------------+------------------+

+===============================================================================+
```

---

## Backup Procedures

### 1. Database Backup

#### Automated Daily Backup Script

```bash
#!/bin/bash
# /opt/wallix/scripts/backup-database.sh
# Run daily via cron

set -euo pipefail

# Configuration
BACKUP_DIR="/var/backup/wallix/database"
RETENTION_DAYS=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="wallix_db_${TIMESTAMP}.sql.gz"

# Create backup directory if needed
mkdir -p "${BACKUP_DIR}"

# Create compressed database backup
echo "[$(date)] Starting database backup..."
sudo -u postgres pg_dump wabdb | gzip > "${BACKUP_DIR}/${BACKUP_FILE}"

# Verify backup was created
if [ -s "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    echo "[$(date)] Backup created: ${BACKUP_FILE}"
    # Get size
    SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
    echo "[$(date)] Backup size: ${SIZE}"
else
    echo "[$(date)] ERROR: Backup failed or empty"
    exit 1
fi

# Cleanup old backups
echo "[$(date)] Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "wallix_db_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

# Verify at least one backup exists
BACKUP_COUNT=$(find "${BACKUP_DIR}" -name "wallix_db_*.sql.gz" | wc -l)
echo "[$(date)] Total backups retained: ${BACKUP_COUNT}"

echo "[$(date)] Database backup complete"
```

#### Cron Configuration

```bash
# Add to /etc/cron.d/wallix-backup
# Database backup - daily at 2:00 AM
0 2 * * * root /opt/wallix/scripts/backup-database.sh >> /var/log/wallix-backup.log 2>&1
```

### 2. Configuration Backup

```bash
#!/bin/bash
# /opt/wallix/scripts/backup-config.sh

set -euo pipefail

BACKUP_DIR="/var/backup/wallix/config"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="wallix_config_${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

echo "[$(date)] Backing up configuration..."

# Create config backup
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" \
    /etc/opt/wab/ \
    /var/opt/wab/keys/ \
    /etc/ssl/wallix/ \
    2>/dev/null || true

# Verify
if [ -s "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    echo "[$(date)] Config backup created: ${BACKUP_FILE}"
else
    echo "[$(date)] ERROR: Config backup failed"
    exit 1
fi

# Cleanup old backups (keep 30 days)
find "${BACKUP_DIR}" -name "wallix_config_*.tar.gz" -mtime +30 -delete

echo "[$(date)] Configuration backup complete"
```

### 3. Recording Archive

```bash
#!/bin/bash
# /opt/wallix/scripts/archive-recordings.sh
# Run weekly - moves old recordings to archive storage

set -euo pipefail

RECORDING_DIR="/var/wab/recorded"
ARCHIVE_DIR="/mnt/archive/wallix-recordings"  # NFS or external storage
ARCHIVE_AGE_DAYS=30  # Archive recordings older than 30 days

mkdir -p "${ARCHIVE_DIR}"

echo "[$(date)] Starting recording archive..."

# Find and archive old recordings
find "${RECORDING_DIR}" -name "*.wab" -mtime +${ARCHIVE_AGE_DAYS} | while read -r file; do
    # Create year/month directory structure
    YEAR=$(date -r "$file" +%Y)
    MONTH=$(date -r "$file" +%m)
    DEST_DIR="${ARCHIVE_DIR}/${YEAR}/${MONTH}"
    mkdir -p "${DEST_DIR}"

    # Move to archive
    mv "$file" "${DEST_DIR}/"
    echo "Archived: $(basename "$file")"
done

# Create index of archived recordings
find "${ARCHIVE_DIR}" -name "*.wab" -printf "%T+ %p\n" | sort > "${ARCHIVE_DIR}/index.txt"

echo "[$(date)] Recording archive complete"
```

### 4. Full System Backup

```bash
#!/bin/bash
# /opt/wallix/scripts/backup-full.sh
# Weekly full backup

set -euo pipefail

BACKUP_DIR="/var/backup/wallix/full"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="wallix_full_${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

echo "[$(date)] Starting full system backup..."

# Stop services for consistent backup
echo "[$(date)] Stopping services..."
systemctl stop wabengine

# Create full backup
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" \
    /etc/opt/wab/ \
    /var/opt/wab/ \
    /var/lib/postgresql/ \
    /var/log/wabengine/ \
    /var/log/wabaudit/ \
    --exclude="/var/wab/recorded/*" \
    2>/dev/null

# Restart services
echo "[$(date)] Restarting services..."
systemctl start wabengine

# Verify backup
if [ -s "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
    echo "[$(date)] Full backup created: ${BACKUP_FILE} (${SIZE})"
else
    echo "[$(date)] ERROR: Full backup failed"
    exit 1
fi

# Cleanup (keep 4 weeks)
find "${BACKUP_DIR}" -name "wallix_full_*.tar.gz" -mtime +28 -delete

echo "[$(date)] Full backup complete"
```

---

## Backup Schedule Summary

```
+===============================================================================+
|                   RECOMMENDED BACKUP SCHEDULE                                 |
+===============================================================================+

  DAILY (2:00 AM)
  ===============
  - Database backup (pg_dump)
  - Configuration backup
  - Audit log rotation

  WEEKLY (Sunday 3:00 AM)
  =======================
  - Full system backup (services stopped briefly)
  - Recording archive (move to long-term storage)
  - Backup verification test

  MONTHLY (First Sunday)
  ======================
  - Certificate backup
  - License backup
  - Off-site backup copy
  - DR test (recommended)

  Cron Configuration:
  0 2 * * * /opt/wallix/scripts/backup-database.sh
  0 2 * * * /opt/wallix/scripts/backup-config.sh
  0 3 * * 0 /opt/wallix/scripts/backup-full.sh
  0 4 * * 0 /opt/wallix/scripts/archive-recordings.sh

+===============================================================================+
```

---

## Recovery Procedures

### Scenario 1: Database Corruption

**Symptoms**: Service won't start, database errors in logs

**Recovery Steps**:

```bash
# 1. Stop WALLIX services
systemctl stop wabengine

# 2. Stop PostgreSQL
systemctl stop postgresql

# 3. Backup corrupted database (for analysis)
mv /var/lib/postgresql/15/main /var/lib/postgresql/15/main.corrupted

# 4. Reinitialize database
sudo -u postgres pg_ctl init -D /var/lib/postgresql/15/main

# 5. Start PostgreSQL
systemctl start postgresql

# 6. Restore from backup
# Find latest backup
LATEST=$(ls -t /var/backup/wallix/database/wallix_db_*.sql.gz | head -1)
echo "Restoring from: ${LATEST}"

# Create database
sudo -u postgres createdb wabdb

# Restore
zcat "${LATEST}" | sudo -u postgres psql wabdb

# 7. Start WALLIX
systemctl start wabengine

# 8. Verify
waservices status
```

### Scenario 2: Complete Server Failure

**Recovery Steps**:

```bash
# On NEW server:

# 1. Install base OS (Debian 12)
# Follow: install/00-debian-luks-installation.md

# 2. Install WALLIX package
# (Get package from WALLIX support)
dpkg -i wallix-pam4ot_*.deb

# 3. Stop services
systemctl stop wabengine
systemctl stop postgresql

# 4. Restore configuration
tar -xzf /path/to/wallix_config_TIMESTAMP.tar.gz -C /

# 5. Restore database
# Initialize PostgreSQL first if needed
sudo -u postgres createdb wabdb
zcat /path/to/wallix_db_TIMESTAMP.sql.gz | sudo -u postgres psql wabdb

# 6. Restore encryption keys (CRITICAL)
# Keys must match what was used to encrypt credentials
tar -xzf /path/to/wallix_config_*.tar.gz -C / var/opt/wab/keys/

# 7. Update IP/hostname if changed
# Edit /etc/opt/wab/wabengine.conf

# 8. Install license
# System > License > Upload

# 9. Start services
systemctl start postgresql
systemctl start wabengine

# 10. Verify
waservices status
# Test login via web UI
# Test session to target
```

### Scenario 3: Encryption Key Loss

**WARNING**: If encryption keys are lost and no backup exists, credentials in the vault CANNOT be recovered.

**Prevention**:
```bash
# Always backup keys to secure, separate location
cp -a /var/opt/wab/keys/ /secure/offline/storage/

# Store key backup password in secure vault (e.g., physical safe)
```

**Recovery (if backup exists)**:
```bash
# 1. Restore key directory from backup
tar -xzf wallix_config_backup.tar.gz -C / var/opt/wab/keys/

# 2. Restart services
systemctl restart wabengine

# 3. Verify credential access
# Try launching session with vaulted credentials
```

### Scenario 4: Restore Specific Recording

```bash
# 1. Find recording in archive
grep "username.*target" /mnt/archive/wallix-recordings/index.txt

# 2. Copy back to active storage
cp /mnt/archive/wallix-recordings/2024/01/session_12345.wab /var/wab/recorded/

# 3. Recording is now viewable in Audit > Sessions
```

---

## Backup Verification

### Automated Backup Test Script

```bash
#!/bin/bash
# /opt/wallix/scripts/verify-backup.sh
# Run weekly after backup

set -euo pipefail

echo "[$(date)] Starting backup verification..."

ERRORS=0

# Check database backup exists and is recent
DB_BACKUP=$(ls -t /var/backup/wallix/database/wallix_db_*.sql.gz 2>/dev/null | head -1)
if [ -z "$DB_BACKUP" ]; then
    echo "ERROR: No database backup found"
    ERRORS=$((ERRORS + 1))
else
    # Check backup is less than 25 hours old
    AGE=$(( ($(date +%s) - $(stat -c %Y "$DB_BACKUP")) / 3600 ))
    if [ "$AGE" -gt 25 ]; then
        echo "ERROR: Database backup is ${AGE} hours old"
        ERRORS=$((ERRORS + 1))
    else
        echo "OK: Database backup exists (${AGE}h old)"
    fi

    # Check backup is not empty
    SIZE=$(stat -c %s "$DB_BACKUP")
    if [ "$SIZE" -lt 1000 ]; then
        echo "ERROR: Database backup appears empty (${SIZE} bytes)"
        ERRORS=$((ERRORS + 1))
    else
        echo "OK: Database backup size $(du -h "$DB_BACKUP" | cut -f1)"
    fi
fi

# Check config backup
CONFIG_BACKUP=$(ls -t /var/backup/wallix/config/wallix_config_*.tar.gz 2>/dev/null | head -1)
if [ -z "$CONFIG_BACKUP" ]; then
    echo "ERROR: No configuration backup found"
    ERRORS=$((ERRORS + 1))
else
    echo "OK: Configuration backup exists"
fi

# Verify backup can be extracted (test integrity)
if [ -n "$DB_BACKUP" ]; then
    if gzip -t "$DB_BACKUP" 2>/dev/null; then
        echo "OK: Database backup integrity verified"
    else
        echo "ERROR: Database backup corrupted"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ -n "$CONFIG_BACKUP" ]; then
    if tar -tzf "$CONFIG_BACKUP" >/dev/null 2>&1; then
        echo "OK: Configuration backup integrity verified"
    else
        echo "ERROR: Configuration backup corrupted"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Report
echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "[$(date)] Backup verification PASSED"
    exit 0
else
    echo "[$(date)] Backup verification FAILED with ${ERRORS} errors"
    exit 1
fi
```

### Monthly DR Test Procedure

```
+===============================================================================+
|                   MONTHLY DR TEST CHECKLIST                                   |
+===============================================================================+

  Date: ___________  Performed by: ___________

  PREPARATION
  ===========
  [ ] DR test environment available
  [ ] Latest backups copied to DR site
  [ ] Test plan approved

  RESTORE TEST
  ============
  [ ] Database restored successfully
  [ ] Configuration restored successfully
  [ ] Services start without errors
  [ ] Web UI accessible
  [ ] Admin login works
  [ ] Audit logs accessible
  [ ] Session recording playback works

  FUNCTIONAL TEST
  ===============
  [ ] Launch test SSH session
  [ ] Launch test RDP session
  [ ] Credential injection works
  [ ] Session recording captured

  TIMING
  ======
  - Database restore time: _____ minutes
  - Full recovery time: _____ minutes
  - Total RTO achieved: _____ minutes

  SIGN-OFF
  ========
  Test result: [ ] PASS  [ ] FAIL

  Notes:
  _____________________________________________________
  _____________________________________________________

  Tester: ___________  Date: ___________

+===============================================================================+
```

---

## Off-Site Backup

### Secure Remote Backup Script

```bash
#!/bin/bash
# /opt/wallix/scripts/offsite-backup.sh

REMOTE_HOST="backup.company.com"
REMOTE_USER="wallix-backup"
REMOTE_DIR="/backup/wallix"
LOCAL_BACKUP="/var/backup/wallix"

# Sync to remote (using SSH key authentication)
rsync -avz --delete \
    -e "ssh -i /root/.ssh/backup_key -o StrictHostKeyChecking=yes" \
    "${LOCAL_BACKUP}/" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

echo "[$(date)] Off-site sync complete"
```

### Cloud Backup (AWS S3 Example)

```bash
#!/bin/bash
# /opt/wallix/scripts/s3-backup.sh

S3_BUCKET="s3://company-backups/wallix"
LOCAL_BACKUP="/var/backup/wallix"

# Sync to S3 (requires aws-cli and credentials)
aws s3 sync "${LOCAL_BACKUP}/" "${S3_BUCKET}/" \
    --storage-class STANDARD_IA \
    --sse AES256

echo "[$(date)] S3 sync complete"
```

---

## Retention Policy

```
+===============================================================================+
|                   BACKUP RETENTION POLICY                                     |
+===============================================================================+

  DATA TYPE                 | LOCAL     | OFF-SITE  | ARCHIVE
  --------------------------|-----------|-----------|----------
  Database (daily)          | 30 days   | 90 days   | 1 year
  Configuration (daily)     | 30 days   | 90 days   | 1 year
  Full backup (weekly)      | 4 weeks   | 12 weeks  | 1 year
  Session recordings        | 30 days   | -         | Per policy*
  Audit logs                | 90 days   | 1 year    | Per policy*

  * Session recording and audit log retention depends on compliance
    requirements (e.g., NERC CIP = 3 years, FDA = 7 years)

+===============================================================================+
```

---

## Quick Reference

### Emergency Recovery Commands

```bash
# Check latest backup
ls -lt /var/backup/wallix/database/ | head -5

# Quick database restore
systemctl stop wabengine
sudo -u postgres dropdb wabdb
sudo -u postgres createdb wabdb
zcat /var/backup/wallix/database/wallix_db_LATEST.sql.gz | sudo -u postgres psql wabdb
systemctl start wabengine

# Verify service health
waservices status

# Check database connectivity
sudo -u postgres psql wabdb -c "SELECT count(*) FROM devices;"
```

---

<p align="center">
  <a href="./README.md">Best Practices</a> •
  <a href="../10-high-availability/README.md">High Availability</a> •
  <a href="../12-troubleshooting/README.md">Troubleshooting</a>
</p>
