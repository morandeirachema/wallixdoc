# Backup and Recovery Procedures

## Comprehensive Backup Strategy and Disaster Recovery for PAM4OT

This document provides detailed backup, restore, and disaster recovery procedures.

---

## Backup Architecture

```
+===============================================================================+
|                         PAM4OT BACKUP ARCHITECTURE                            |
+===============================================================================+

  PAM4OT Cluster                    Backup Storage                   Archive
  ==============                    ==============                   =======

  ┌─────────────┐                  ┌──────────────┐              ┌───────────┐
  │  Node 1     │                  │   Primary    │              │   Tape/   │
  │  (Primary)  │ ─── Daily ────> │   Backup     │ ── Weekly ─> │   Cloud   │
  │             │     Backup       │   Server     │    Archive   │   Storage │
  └─────────────┘                  │              │              └───────────┘
                                   │  - DB dumps  │
  ┌─────────────┐                  │  - Configs   │              ┌───────────┐
  │  Node 2     │ ─── Daily ────> │  - Sessions  │ ── Monthly ─>│   Offsite │
  │  (Replica)  │     Backup       │  - Keys      │    Archive   │   Vault   │
  └─────────────┘                  └──────────────┘              └───────────┘

+===============================================================================+
```

---

## Backup Components

### What to Backup

| Component | Location | Frequency | Retention |
|-----------|----------|-----------|-----------|
| PostgreSQL Database | /var/lib/postgresql/15/main | Daily | 30 days |
| Configuration Files | /etc/wab/ | Daily | 90 days |
| SSL Certificates | /etc/ssl/wab/ | Weekly | 1 year |
| Session Recordings | /var/wab/recorded/ | Daily incremental | Per policy |
| Credential Vault Keys | /var/wab/keys/ | Weekly | 1 year |
| Audit Logs | /var/log/wab*/ | Daily | 1 year |
| Custom Scripts | /opt/wab/scripts/ | Weekly | 90 days |
| Pacemaker Config | /var/lib/pacemaker/ | After changes | 90 days |

---

## Section 1: Database Backup

### Automated Daily Backup Script

```bash
#!/bin/bash
# /opt/wab/scripts/backup-database.sh

# Configuration
BACKUP_DIR="/backup/pam4ot/database"
RETENTION_DAYS=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/wabdb_${TIMESTAMP}.sql.gz"
LOG_FILE="/var/log/wab-backup/database-backup.log"

# Create directories
mkdir -p "${BACKUP_DIR}" /var/log/wab-backup

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "Starting database backup..."

# Check if running on primary
IS_PRIMARY=$(sudo -u postgres psql -t -c "SELECT NOT pg_is_in_recovery();")
if [[ "${IS_PRIMARY}" != *"t"* ]]; then
    log "This is not the primary node. Skipping database backup."
    exit 0
fi

# Create backup
log "Creating PostgreSQL dump..."
sudo -u postgres pg_dump wabdb | gzip > "${BACKUP_FILE}"

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    log "Backup completed: ${BACKUP_FILE} (${BACKUP_SIZE})"

    # Verify backup
    log "Verifying backup integrity..."
    gzip -t "${BACKUP_FILE}"
    if [ $? -eq 0 ]; then
        log "Backup verification passed."
    else
        log "ERROR: Backup verification failed!"
        exit 1
    fi
else
    log "ERROR: Backup failed!"
    exit 1
fi

# Cleanup old backups
log "Removing backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "wabdb_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

# Report status
BACKUP_COUNT=$(ls -1 "${BACKUP_DIR}"/wabdb_*.sql.gz 2>/dev/null | wc -l)
log "Backup complete. ${BACKUP_COUNT} backups in retention."

exit 0
```

### Manual Database Backup

```bash
# Full database backup
sudo -u postgres pg_dump wabdb > /backup/wabdb_manual_$(date +%Y%m%d).sql

# Compressed backup
sudo -u postgres pg_dump wabdb | gzip > /backup/wabdb_manual_$(date +%Y%m%d).sql.gz

# Custom format (allows selective restore)
sudo -u postgres pg_dump -Fc wabdb > /backup/wabdb_manual_$(date +%Y%m%d).dump

# Backup with global objects
sudo -u postgres pg_dumpall --globals-only > /backup/globals_$(date +%Y%m%d).sql
```

### Point-in-Time Recovery Setup

```bash
# Enable WAL archiving for PITR
# In /etc/postgresql/15/main/postgresql.conf:

archive_mode = on
archive_command = 'cp %p /backup/pam4ot/wal_archive/%f'
wal_level = replica

# Create archive directory
mkdir -p /backup/pam4ot/wal_archive
chown postgres:postgres /backup/pam4ot/wal_archive

# Restart PostgreSQL
systemctl restart postgresql
```

---

## Section 2: Configuration Backup

### Configuration Backup Script

```bash
#!/bin/bash
# /opt/wab/scripts/backup-config.sh

BACKUP_DIR="/backup/pam4ot/config"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/config_${TIMESTAMP}.tar.gz"
LOG_FILE="/var/log/wab-backup/config-backup.log"

mkdir -p "${BACKUP_DIR}" /var/log/wab-backup

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "Starting configuration backup..."

# Export PAM4OT configuration
log "Exporting PAM4OT configuration..."
wabadmin config export > /tmp/pam4ot-config.json

# Create tarball
log "Creating configuration archive..."
tar -czvf "${BACKUP_FILE}" \
    /etc/wab/ \
    /etc/ssl/wab/ \
    /var/wab/keys/ \
    /etc/pacemaker/ \
    /etc/corosync/ \
    /etc/postgresql/15/main/*.conf \
    /tmp/pam4ot-config.json \
    2>/dev/null

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    log "Configuration backup completed: ${BACKUP_FILE} (${BACKUP_SIZE})"
else
    log "ERROR: Configuration backup failed!"
    exit 1
fi

# Cleanup
rm /tmp/pam4ot-config.json

# Cleanup old backups (keep 90 days)
find "${BACKUP_DIR}" -name "config_*.tar.gz" -mtime +90 -delete

exit 0
```

---

## Section 3: Session Recording Backup

### Incremental Recording Backup

```bash
#!/bin/bash
# /opt/wab/scripts/backup-recordings.sh

BACKUP_DIR="/backup/pam4ot/recordings"
SOURCE_DIR="/var/wab/recorded"
TIMESTAMP=$(date +%Y%m%d)
LOG_FILE="/var/log/wab-backup/recording-backup.log"

mkdir -p "${BACKUP_DIR}" /var/log/wab-backup

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "Starting session recording backup..."

# Use rsync for incremental backup
rsync -av --progress \
    --exclude="*.tmp" \
    --link-dest="${BACKUP_DIR}/latest" \
    "${SOURCE_DIR}/" \
    "${BACKUP_DIR}/${TIMESTAMP}/"

if [ $? -eq 0 ]; then
    # Update latest symlink
    rm -f "${BACKUP_DIR}/latest"
    ln -s "${BACKUP_DIR}/${TIMESTAMP}" "${BACKUP_DIR}/latest"

    RECORDING_COUNT=$(find "${BACKUP_DIR}/${TIMESTAMP}" -name "*.rec" | wc -l)
    log "Recording backup completed: ${RECORDING_COUNT} recordings"
else
    log "ERROR: Recording backup failed!"
    exit 1
fi

# Cleanup old backups based on policy
# (Example: keep 90 days of recordings)
find "${BACKUP_DIR}" -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \;

exit 0
```

---

## Section 4: Full System Backup

### Complete Backup Script

```bash
#!/bin/bash
# /opt/wab/scripts/backup-full.sh

BACKUP_BASE="/backup/pam4ot"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/wab-backup/full-backup.log"
HOSTNAME=$(hostname)

mkdir -p "${BACKUP_BASE}" /var/log/wab-backup

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "=========================================="
log "Starting full PAM4OT backup on ${HOSTNAME}"
log "=========================================="

# Stop non-critical services during backup
log "Preparing for backup..."

# 1. Database backup
log "Backing up database..."
/opt/wab/scripts/backup-database.sh
DB_STATUS=$?

# 2. Configuration backup
log "Backing up configuration..."
/opt/wab/scripts/backup-config.sh
CONFIG_STATUS=$?

# 3. Recording backup
log "Backing up session recordings..."
/opt/wab/scripts/backup-recordings.sh
RECORDING_STATUS=$?

# 4. Backup credential vault keys
log "Backing up credential vault keys..."
KEYS_BACKUP="${BACKUP_BASE}/keys/vault_keys_${TIMESTAMP}.tar.gz.gpg"
mkdir -p "${BACKUP_BASE}/keys"
tar -czf - /var/wab/keys/ 2>/dev/null | \
    gpg --symmetric --cipher-algo AES256 -o "${KEYS_BACKUP}"
KEYS_STATUS=$?

# 5. Create backup manifest
MANIFEST="${BACKUP_BASE}/manifest_${TIMESTAMP}.txt"
cat > "${MANIFEST}" << EOF
PAM4OT BACKUP MANIFEST
======================
Date: $(date)
Hostname: ${HOSTNAME}
Backup Timestamp: ${TIMESTAMP}

Components:
- Database: $([ ${DB_STATUS} -eq 0 ] && echo "SUCCESS" || echo "FAILED")
- Configuration: $([ ${CONFIG_STATUS} -eq 0 ] && echo "SUCCESS" || echo "FAILED")
- Recordings: $([ ${RECORDING_STATUS} -eq 0 ] && echo "SUCCESS" || echo "FAILED")
- Vault Keys: $([ ${KEYS_STATUS} -eq 0 ] && echo "SUCCESS" || echo "FAILED")

Backup Locations:
- Database: ${BACKUP_BASE}/database/
- Config: ${BACKUP_BASE}/config/
- Recordings: ${BACKUP_BASE}/recordings/
- Keys: ${KEYS_BACKUP}

Verification:
Run: /opt/wab/scripts/verify-backup.sh ${TIMESTAMP}
EOF

log "Backup manifest created: ${MANIFEST}"

# Summary
if [ ${DB_STATUS} -eq 0 ] && [ ${CONFIG_STATUS} -eq 0 ] && [ ${RECORDING_STATUS} -eq 0 ]; then
    log "Full backup completed successfully."
    exit 0
else
    log "WARNING: Some backup components failed. Check logs."
    exit 1
fi
```

---

## Section 5: Restore Procedures

### Database Restore

```bash
# Stop PAM4OT services
systemctl stop wallix-bastion

# Restore from SQL dump
sudo -u postgres psql -c "DROP DATABASE IF EXISTS wabdb_restore;"
sudo -u postgres psql -c "CREATE DATABASE wabdb_restore;"
gunzip -c /backup/pam4ot/database/wabdb_20250128_010000.sql.gz | \
    sudo -u postgres psql wabdb_restore

# Verify restore
sudo -u postgres psql wabdb_restore -c "SELECT COUNT(*) FROM users;"

# If verified, swap databases
sudo -u postgres psql << EOF
ALTER DATABASE wabdb RENAME TO wabdb_old;
ALTER DATABASE wabdb_restore RENAME TO wabdb;
EOF

# Start services
systemctl start wallix-bastion

# Verify PAM4OT
wabadmin status
```

### Point-in-Time Recovery

```bash
# PITR to specific timestamp

# 1. Stop PostgreSQL
systemctl stop postgresql

# 2. Move current data
mv /var/lib/postgresql/15/main /var/lib/postgresql/15/main_old

# 3. Restore base backup
tar -xzf /backup/pam4ot/basebackup/base_20250127.tar.gz -C /var/lib/postgresql/15/

# 4. Create recovery configuration
cat > /var/lib/postgresql/15/main/recovery.signal << EOF
EOF

cat > /var/lib/postgresql/15/main/postgresql.auto.conf << EOF
restore_command = 'cp /backup/pam4ot/wal_archive/%f %p'
recovery_target_time = '2025-01-28 14:30:00'
recovery_target_action = 'promote'
EOF

# 5. Set ownership
chown -R postgres:postgres /var/lib/postgresql/15/main

# 6. Start PostgreSQL
systemctl start postgresql

# 7. Monitor recovery
tail -f /var/log/postgresql/postgresql-15-main.log
```

### Configuration Restore

```bash
# Extract configuration backup
tar -xzvf /backup/pam4ot/config/config_20250128_010000.tar.gz -C /tmp/config_restore/

# Restore specific files
cp /tmp/config_restore/etc/wab/* /etc/wab/
cp /tmp/config_restore/etc/ssl/wab/* /etc/ssl/wab/

# Or import PAM4OT configuration
wabadmin config import < /tmp/config_restore/tmp/pam4ot-config.json

# Restart services
systemctl restart wallix-bastion
```

### Full System Restore

```bash
# FULL RESTORE PROCEDURE
# Estimated time: 1-2 hours depending on data size

# Prerequisites:
# - Fresh PAM4OT installation completed
# - Backup files accessible
# - Network connectivity verified

# Step 1: Stop all services
systemctl stop wallix-bastion
systemctl stop postgresql

# Step 2: Restore database
# (Follow Database Restore steps above)

# Step 3: Restore configuration
tar -xzvf /backup/pam4ot/config/config_YYYYMMDD.tar.gz -C /

# Step 4: Restore vault keys
gpg --decrypt /backup/pam4ot/keys/vault_keys_YYYYMMDD.tar.gz.gpg | \
    tar -xzf - -C /

# Step 5: Restore session recordings
rsync -av /backup/pam4ot/recordings/latest/ /var/wab/recorded/

# Step 6: Fix permissions
chown -R wabuser:wabgroup /var/wab/
chown -R postgres:postgres /var/lib/postgresql/

# Step 7: Start services
systemctl start postgresql
systemctl start wallix-bastion

# Step 8: Verify
wabadmin status
wabadmin license-info
```

---

## Section 6: Backup Verification

### Backup Verification Script

```bash
#!/bin/bash
# /opt/wab/scripts/verify-backup.sh

BACKUP_BASE="/backup/pam4ot"
TIMESTAMP=$1

if [ -z "${TIMESTAMP}" ]; then
    TIMESTAMP=$(ls -1t "${BACKUP_BASE}/database/" | head -1 | cut -d'_' -f2)
fi

echo "Verifying backup from timestamp: ${TIMESTAMP}"

ERRORS=0

# Check database backup
echo -n "Database backup: "
DB_FILE=$(ls -1t "${BACKUP_BASE}/database/wabdb_${TIMESTAMP}"*.sql.gz 2>/dev/null | head -1)
if [ -f "${DB_FILE}" ]; then
    gzip -t "${DB_FILE}" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "OK ($(du -h "${DB_FILE}" | cut -f1))"
    else
        echo "CORRUPTED"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "MISSING"
    ERRORS=$((ERRORS + 1))
fi

# Check configuration backup
echo -n "Configuration backup: "
CONFIG_FILE=$(ls -1t "${BACKUP_BASE}/config/config_${TIMESTAMP}"*.tar.gz 2>/dev/null | head -1)
if [ -f "${CONFIG_FILE}" ]; then
    tar -tzf "${CONFIG_FILE}" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "OK ($(du -h "${CONFIG_FILE}" | cut -f1))"
    else
        echo "CORRUPTED"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "MISSING"
    ERRORS=$((ERRORS + 1))
fi

# Check recordings
echo -n "Session recordings: "
RECORDING_DIR="${BACKUP_BASE}/recordings/latest"
if [ -L "${RECORDING_DIR}" ] && [ -d "$(readlink -f "${RECORDING_DIR}")" ]; then
    REC_COUNT=$(find "${RECORDING_DIR}" -name "*.rec" 2>/dev/null | wc -l)
    echo "OK (${REC_COUNT} recordings)"
else
    echo "MISSING OR BROKEN SYMLINK"
    ERRORS=$((ERRORS + 1))
fi

# Summary
echo ""
if [ ${ERRORS} -eq 0 ]; then
    echo "Backup verification: PASSED"
    exit 0
else
    echo "Backup verification: FAILED (${ERRORS} errors)"
    exit 1
fi
```

---

## Section 7: Disaster Recovery

### DR Checklist

```
DISASTER RECOVERY CHECKLIST
===========================

BEFORE DISASTER (Preparation):
[ ] Daily backups running and verified
[ ] Offsite backup copies current (< 24h)
[ ] DR site PAM4OT installed (if applicable)
[ ] Recovery procedures documented and tested
[ ] Contact list updated
[ ] RTO/RPO requirements documented

DURING DISASTER:
[ ] Assess damage and scope
[ ] Activate incident response
[ ] Notify stakeholders
[ ] Determine recovery strategy
[ ] Begin recovery procedures

RECOVERY OPTIONS:
1. Restore to same hardware (fastest)
2. Restore to new hardware at same site
3. Restore to DR site
4. Cloud-based recovery

POST-RECOVERY:
[ ] Verify all services operational
[ ] Test authentication
[ ] Test session connectivity
[ ] Verify audit trail continuity
[ ] Update DNS if needed
[ ] Notify users of restoration
```

### Recovery Time Objectives

| Scenario | RTO Target | RPO Target | Recovery Method |
|----------|------------|------------|-----------------|
| Single node failure | 5 minutes | 0 (HA) | Automatic failover |
| Database corruption | 1 hour | 1 hour | PITR recovery |
| Full site failure | 4 hours | 24 hours | DR site activation |
| Ransomware | 8 hours | 24 hours | Clean restore from backup |

---

## Section 8: Cron Schedule

### Backup Cron Jobs

```bash
# /etc/cron.d/pam4ot-backup

# Database backup - Daily at 1:00 AM
0 1 * * * root /opt/wab/scripts/backup-database.sh >> /var/log/wab-backup/cron.log 2>&1

# Configuration backup - Daily at 2:00 AM
0 2 * * * root /opt/wab/scripts/backup-config.sh >> /var/log/wab-backup/cron.log 2>&1

# Session recording backup - Daily at 3:00 AM
0 3 * * * root /opt/wab/scripts/backup-recordings.sh >> /var/log/wab-backup/cron.log 2>&1

# Full backup - Weekly on Sunday at 4:00 AM
0 4 * * 0 root /opt/wab/scripts/backup-full.sh >> /var/log/wab-backup/cron.log 2>&1

# Backup verification - Daily at 6:00 AM
0 6 * * * root /opt/wab/scripts/verify-backup.sh >> /var/log/wab-backup/cron.log 2>&1

# Offsite sync - Daily at 5:00 AM
0 5 * * * root rsync -avz /backup/pam4ot/ backup-server:/backup/pam4ot-$(hostname)/ >> /var/log/wab-backup/cron.log 2>&1
```

---

## Appendix: Quick Commands

```bash
# Manual backup commands
/opt/wab/scripts/backup-database.sh
/opt/wab/scripts/backup-config.sh
/opt/wab/scripts/backup-recordings.sh
/opt/wab/scripts/backup-full.sh

# Verify backup
/opt/wab/scripts/verify-backup.sh

# Check backup status
ls -lh /backup/pam4ot/database/
ls -lh /backup/pam4ot/config/
du -sh /backup/pam4ot/recordings/

# View backup logs
tail -f /var/log/wab-backup/database-backup.log
tail -f /var/log/wab-backup/full-backup.log

# Export config for backup
wabadmin config export > /tmp/pam4ot-config.json

# Import config from backup
wabadmin config import < /tmp/pam4ot-config.json
```

---

<p align="center">
  <a href="./README.md">← Back to Runbooks</a>
</p>
