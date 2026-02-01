# Backup and Restore Guide

Comprehensive guide for backup, recovery, and disaster recovery procedures for WALLIX Bastion 12.x.

---

## Table of Contents

1. [Backup Overview](#backup-overview)
2. [Backup Architecture](#backup-architecture)
3. [Full System Backup](#full-system-backup)
4. [Database Backup](#database-backup)
5. [Configuration Backup](#configuration-backup)
6. [Session Recording Backup](#session-recording-backup)
7. [Encryption Key Backup](#encryption-key-backup)
8. [Automated Backup Scripts](#automated-backup-scripts)
9. [Backup Verification](#backup-verification)
10. [Offsite Backup](#offsite-backup)
11. [Full System Restore](#full-system-restore)
12. [Selective Restore](#selective-restore)
13. [Point-in-Time Recovery](#point-in-time-recovery)
14. [Cross-Version Restore](#cross-version-restore)
15. [Backup Monitoring](#backup-monitoring)
16. [Backup Security](#backup-security)

---

## Backup Overview

### What to Backup

WALLIX Bastion contains several critical data components that require regular backups:

| Component | Location | Criticality | Frequency |
|-----------|----------|-------------|-----------|
| PostgreSQL Database | `/var/lib/postgresql/` | Critical | Daily |
| Configuration Files | `/etc/opt/wab/` | Critical | Daily + on change |
| Encryption Keys | `/var/opt/wab/keys/` | Critical | On change |
| Session Recordings | `/var/wab/recorded/` | High | Continuous |
| SSL Certificates | `/etc/ssl/wallix/` | High | On change |
| License Files | `/etc/opt/wab/license/` | Medium | On change |
| Custom Scripts | `/opt/wab/scripts/` | Medium | Weekly |
| Audit Logs | `/var/log/wab/` | High | Daily |

### The 3-2-1 Backup Rule

```
+==============================================================================+
|                         3-2-1 BACKUP STRATEGY                                 |
+==============================================================================+
|                                                                               |
|    +-----------------------------------------------------------------------+ |
|    |                                                                       | |
|    |        3                   2                      1                   | |
|    |      COPIES              MEDIA                 OFFSITE               | |
|    |                                                                       | |
|    |   +----------+      +------------+       +------------------+        | |
|    |   |          |      |            |       |                  |        | |
|    |   | Original |      | Local Disk |       | Cloud Storage    |        | |
|    |   | Data     |      | (NAS/SAN)  |       | (S3/Azure/GCP)   |        | |
|    |   |          |      |            |       |                  |        | |
|    |   +----------+      +------------+       | OR               |        | |
|    |   |          |      |            |       |                  |        | |
|    |   | Local    |      | Tape       |       | Remote Data      |        | |
|    |   | Backup   |      | Library    |       | Center           |        | |
|    |   |          |      |            |       |                  |        | |
|    |   +----------+      +------------+       +------------------+        | |
|    |                                                                       | |
|    +-----------------------------------------------------------------------+ |
|                                                                               |
|    IMPLEMENTATION:                                                           |
|    ===============                                                           |
|    * Copy 1: Production data on primary storage                             |
|    * Copy 2: Local backup on separate storage system                        |
|    * Copy 3: Offsite backup in different geographic location                |
|                                                                               |
+==============================================================================+
```

### Retention Policies

| Backup Type | Retention Period | Storage Location |
|-------------|------------------|------------------|
| Daily Incremental | 7 days | Local NAS |
| Daily Full | 30 days | Local NAS + Remote |
| Weekly Full | 90 days | Remote Storage |
| Monthly Full | 1 year | Offsite/Archive |
| Annual Archive | 7 years | Cold Storage |

### Recovery Point Objectives (RPO)

| Scenario | RPO Target | Backup Strategy |
|----------|------------|-----------------|
| Critical Production | < 1 hour | Continuous replication + hourly snapshots |
| Standard Production | < 4 hours | 4-hour incremental backups |
| Non-Critical | < 24 hours | Daily backups |
| Compliance Archive | N/A | Long-term retention only |

---

## Backup Architecture

### Backup Data Flow

```
+==============================================================================+
|                       BACKUP ARCHITECTURE OVERVIEW                            |
+==============================================================================+
|                                                                               |
|  WALLIX BASTION                                                               |
|  ===============                                                              |
|                                                                               |
|  +---------------------------+                                               |
|  |     WALLIX Bastion        |                                               |
|  |                           |                                               |
|  |  +---------------------+  |                                               |
|  |  | PostgreSQL Database |--+---> pg_dump / pg_basebackup                  |
|  |  +---------------------+  |              |                                |
|  |                           |              v                                |
|  |  +---------------------+  |     +------------------+                      |
|  |  | Configuration Files |--+---> | Local Backup     |                      |
|  |  +---------------------+  |     | /backup/wallix/  |                      |
|  |                           |     +--------+---------+                      |
|  |  +---------------------+  |              |                                |
|  |  | Encryption Keys     |--+              |                                |
|  |  +---------------------+  |              |                                |
|  |                           |              v                                |
|  |  +---------------------+  |     +------------------+      +-------------+ |
|  |  | Session Recordings  |--+---> | NAS Storage      |----->| Offsite     | |
|  |  +---------------------+  |     | (NFS/iSCSI)      |      | S3/Azure    | |
|  |                           |     +------------------+      | Tape        | |
|  |  +---------------------+  |                               +-------------+ |
|  |  | SSL Certificates    |--+                                               |
|  |  +---------------------+  |                                               |
|  |                           |                                               |
|  +---------------------------+                                               |
|                                                                               |
+==============================================================================+
```

### Component Dependencies

```
+==============================================================================+
|                     BACKUP COMPONENT DEPENDENCIES                             |
+==============================================================================+
|                                                                               |
|                        RESTORE ORDER (BOTTOM TO TOP)                         |
|                        =============================                         |
|                                                                               |
|            +-----------------------------------------------+                 |
|            |              Session Recordings               |   5. Last      |
|            +-----------------------------------------------+                 |
|                                     |                                        |
|                                     v                                        |
|            +-----------------------------------------------+                 |
|            |              Application Data                 |   4.           |
|            +-----------------------------------------------+                 |
|                                     |                                        |
|                                     v                                        |
|            +-----------------------------------------------+                 |
|            |              PostgreSQL Database              |   3.           |
|            +-----------------------------------------------+                 |
|                                     |                                        |
|                                     v                                        |
|            +-----------------------------------------------+                 |
|            |         Configuration Files + License         |   2.           |
|            +-----------------------------------------------+                 |
|                                     |                                        |
|                                     v                                        |
|            +-----------------------------------------------+                 |
|            |   Encryption Keys + SSL Certificates          |   1. First     |
|            +-----------------------------------------------+                 |
|                                                                               |
|    CRITICAL: Encryption keys must be restored BEFORE database!              |
|    Database is encrypted with these keys and will be unusable without them. |
|                                                                               |
+==============================================================================+
```

---

## Full System Backup

### Complete Backup Procedure

```bash
#!/bin/bash
# /opt/wab/scripts/full-backup.sh
# Complete WALLIX Bastion backup script

set -e  # Exit on any error

# Configuration
BACKUP_ROOT="/backup/wallix"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_ROOT}/${DATE}"
LOG_FILE="/var/log/wab/backup-${DATE}.log"
RETENTION_DAYS=30

# Create backup directory
mkdir -p "${BACKUP_DIR}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "Starting full WALLIX Bastion backup"

# 1. Stop non-essential services for consistency (optional)
log "Enabling maintenance mode..."
wabadmin maintenance-mode --enable --message "System backup in progress" 2>/dev/null || true

# 2. Backup PostgreSQL database
log "Backing up PostgreSQL database..."
sudo -u postgres pg_dump -Fc -Z 9 -f "${BACKUP_DIR}/database.dump" wab
log "Database backup completed: $(du -h ${BACKUP_DIR}/database.dump | cut -f1)"

# 3. Backup configuration files
log "Backing up configuration files..."
tar -czf "${BACKUP_DIR}/config.tar.gz" \
    --exclude='*.log' \
    --exclude='*.pid' \
    /etc/opt/wab/ \
    /etc/wallix/ \
    2>/dev/null || true
log "Configuration backup completed"

# 4. Backup encryption keys (encrypted with separate password)
log "Backing up encryption keys..."
tar -czf - /var/opt/wab/keys/ 2>/dev/null | \
    openssl enc -aes-256-gcm -salt -pbkdf2 -iter 100000 \
    -pass file:/root/.backup-key \
    -out "${BACKUP_DIR}/keys.tar.gz.enc"
log "Encryption keys backup completed"

# 5. Backup SSL certificates
log "Backing up SSL certificates..."
tar -czf "${BACKUP_DIR}/ssl-certs.tar.gz" \
    /etc/ssl/wallix/ \
    /var/opt/wab/ssl/ \
    2>/dev/null || true
log "SSL certificates backup completed"

# 6. Backup license files
log "Backing up license files..."
tar -czf "${BACKUP_DIR}/license.tar.gz" \
    /etc/opt/wab/license/ \
    2>/dev/null || true
log "License backup completed"

# 7. Create backup manifest
log "Creating backup manifest..."
cat > "${BACKUP_DIR}/manifest.json" << EOF
{
    "backup_date": "$(date -Iseconds)",
    "bastion_version": "$(wabadmin version 2>/dev/null || echo 'unknown')",
    "hostname": "$(hostname -f)",
    "components": {
        "database": "database.dump",
        "configuration": "config.tar.gz",
        "encryption_keys": "keys.tar.gz.enc",
        "ssl_certificates": "ssl-certs.tar.gz",
        "license": "license.tar.gz"
    }
}
EOF

# 8. Generate checksums
log "Generating checksums..."
cd "${BACKUP_DIR}"
sha256sum * > checksums.sha256
log "Checksums generated"

# 9. Create single archive
log "Creating consolidated backup archive..."
cd "${BACKUP_ROOT}"
tar -czf "wallix-full-backup-${DATE}.tar.gz" "${DATE}/"
rm -rf "${DATE}"

FINAL_BACKUP="${BACKUP_ROOT}/wallix-full-backup-${DATE}.tar.gz"
BACKUP_SIZE=$(du -h "${FINAL_BACKUP}" | cut -f1)
log "Backup archive created: ${FINAL_BACKUP} (${BACKUP_SIZE})"

# 10. Disable maintenance mode
log "Disabling maintenance mode..."
wabadmin maintenance-mode --disable 2>/dev/null || true

# 11. Cleanup old backups
log "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_ROOT}" -name "wallix-full-backup-*.tar.gz" -mtime +${RETENTION_DAYS} -delete

log "Full backup completed successfully"
echo "${FINAL_BACKUP}"
```

### Backup Output Verification

```bash
# Run the full backup
sudo /opt/wab/scripts/full-backup.sh

# Expected output:
# [2026-01-31 02:00:01] Starting full WALLIX Bastion backup
# [2026-01-31 02:00:02] Enabling maintenance mode...
# [2026-01-31 02:00:15] Backing up PostgreSQL database...
# [2026-01-31 02:02:30] Database backup completed: 1.2G
# [2026-01-31 02:02:31] Backing up configuration files...
# [2026-01-31 02:02:45] Configuration backup completed
# [2026-01-31 02:02:46] Backing up encryption keys...
# [2026-01-31 02:02:48] Encryption keys backup completed
# [2026-01-31 02:02:49] Backing up SSL certificates...
# [2026-01-31 02:02:50] SSL certificates backup completed
# [2026-01-31 02:02:51] Backing up license files...
# [2026-01-31 02:02:52] License backup completed
# [2026-01-31 02:02:53] Creating backup manifest...
# [2026-01-31 02:02:54] Generating checksums...
# [2026-01-31 02:02:55] Checksums generated
# [2026-01-31 02:03:10] Creating consolidated backup archive...
# [2026-01-31 02:03:45] Backup archive created: /backup/wallix/wallix-full-backup-20260131_020001.tar.gz (1.4G)
# [2026-01-31 02:03:46] Disabling maintenance mode...
# [2026-01-31 02:03:48] Cleaning up backups older than 30 days...
# [2026-01-31 02:03:49] Full backup completed successfully
# /backup/wallix/wallix-full-backup-20260131_020001.tar.gz
```

---

## Database Backup

### PostgreSQL pg_dump Backup

```bash
# Logical backup with pg_dump (recommended for smaller databases)
sudo -u postgres pg_dump -Fc -Z 9 -f /backup/wallix/database.dump wab

# Options explanation:
# -Fc : Custom format (compressed, supports parallel restore)
# -Z 9 : Maximum compression level
# -f  : Output file

# Verify backup integrity
sudo -u postgres pg_restore --list /backup/wallix/database.dump | head -20

# Expected output:
# ;
# ; Archive created at 2026-01-31 02:00:15 UTC
# ;     dbname: wab
# ;     TOC Entries: 847
# ;     Compression: 9
# ;     Dump Version: 15.4
# ;     Format: CUSTOM
# ;     Integer: 4 bytes
# ;     Offset: 8 bytes
# ;     Dumped from database version: 15.4
# ;     Dumped by pg_dump version: 15.4
# ;
# ; Selected TOC Entries:
# ;
# 3456; 1259 16385 TABLE public accounts postgres
# 3457; 1259 16392 TABLE public authorizations postgres
# ...
```

### PostgreSQL pg_basebackup (Physical Backup)

```bash
# Physical backup with pg_basebackup (recommended for large databases)
# Supports point-in-time recovery

# Create backup directory
mkdir -p /backup/wallix/basebackup

# Run physical backup with WAL files included
sudo -u postgres pg_basebackup \
    -D /backup/wallix/basebackup/$(date +%Y%m%d) \
    -Ft \
    -z \
    -Xs \
    -P \
    -v

# Options explanation:
# -D  : Target directory
# -Ft : Tar format
# -z  : Compress with gzip
# -Xs : Include WAL files using streaming
# -P  : Show progress
# -v  : Verbose output

# Expected output:
# pg_basebackup: initiating base backup, waiting for checkpoint to complete
# pg_basebackup: checkpoint completed
# pg_basebackup: write-ahead log start point: 0/2000028 on timeline 1
# pg_basebackup: starting background WAL receiver
# pg_basebackup: created temporary replication slot "pg_basebackup_12345"
# 24891/24891 kB (100%), 1/1 tablespace
# pg_basebackup: write-ahead log end point: 0/2000138
# pg_basebackup: waiting for background process to finish streaming ...
# pg_basebackup: syncing data to disk ...
# pg_basebackup: renaming backup_manifest.tmp to backup_manifest
# pg_basebackup: base backup completed
```

### Streaming Backup with WAL Archiving

```bash
# Configure WAL archiving in postgresql.conf
cat >> /etc/postgresql/15/main/postgresql.conf << 'EOF'

# WAL Archiving Configuration
archive_mode = on
archive_command = 'test ! -f /backup/wallix/wal/%f && cp %p /backup/wallix/wal/%f'
archive_timeout = 300
wal_level = replica
max_wal_senders = 3
wal_keep_size = 1GB
EOF

# Create WAL archive directory
mkdir -p /backup/wallix/wal
chown postgres:postgres /backup/wallix/wal

# Restart PostgreSQL to apply changes
systemctl restart postgresql

# Verify WAL archiving is working
sudo -u postgres psql -c "SELECT * FROM pg_stat_archiver;"

# Expected output:
#  archived_count | last_archived_wal |      last_archived_time       | failed_count | last_failed_wal | last_failed_time |          stats_reset
# ----------------+-------------------+-------------------------------+--------------+-----------------+------------------+-------------------------------
#              42 | 00000001000000000000002A | 2026-01-31 02:15:00.123456+00 |            0 |                 |                  | 2026-01-01 00:00:00.000000+00
```

---

## Configuration Backup

### Configuration Files to Include

```bash
#!/bin/bash
# /opt/wab/scripts/config-backup.sh
# WALLIX Bastion configuration backup

BACKUP_DIR="/backup/wallix/config/$(date +%Y%m%d)"
mkdir -p "${BACKUP_DIR}"

# Configuration directories
CONFIG_PATHS=(
    "/etc/opt/wab/"
    "/etc/wallix/"
    "/var/opt/wab/conf/"
    "/opt/wab/etc/"
)

# Create configuration backup
tar -czvf "${BACKUP_DIR}/configuration.tar.gz" \
    --exclude='*.log' \
    --exclude='*.pid' \
    --exclude='*.sock' \
    --exclude='cache/*' \
    --exclude='tmp/*' \
    "${CONFIG_PATHS[@]}" \
    2>/dev/null

# Backup specific configuration files
echo "=== Critical Configuration Files ===" > "${BACKUP_DIR}/config-inventory.txt"
for path in "${CONFIG_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "" >> "${BACKUP_DIR}/config-inventory.txt"
        echo "Directory: $path" >> "${BACKUP_DIR}/config-inventory.txt"
        find "$path" -type f -name "*.conf" -o -name "*.cfg" -o -name "*.ini" -o -name "*.yaml" 2>/dev/null \
            >> "${BACKUP_DIR}/config-inventory.txt"
    fi
done

# Create checksum
cd "${BACKUP_DIR}"
sha256sum configuration.tar.gz > checksum.sha256

echo "Configuration backup completed: ${BACKUP_DIR}"
```

### Configuration Files Reference

| File/Directory | Description | Critical |
|----------------|-------------|----------|
| `/etc/opt/wab/wab.conf` | Main configuration file | Yes |
| `/etc/opt/wab/cluster.conf` | HA cluster settings | Yes |
| `/etc/opt/wab/ldap.conf` | LDAP/AD configuration | Yes |
| `/etc/opt/wab/mfa.conf` | Multi-factor authentication | Yes |
| `/var/opt/wab/conf/plugins/` | Plugin configurations | Yes |
| `/var/opt/wab/conf/policies/` | Authorization policies | Yes |
| `/etc/wallix/webui/` | Web interface settings | Medium |

---

## Session Recording Backup

### Recording Storage Backup

```bash
#!/bin/bash
# /opt/wab/scripts/recording-backup.sh
# Session recording backup with archival

RECORDING_DIR="/var/wab/recorded"
BACKUP_DIR="/backup/wallix/recordings"
ARCHIVE_DIR="/archive/wallix/recordings"
RETENTION_DAYS_LOCAL=30
RETENTION_DAYS_ARCHIVE=365

mkdir -p "${BACKUP_DIR}" "${ARCHIVE_DIR}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Calculate recording storage usage
USAGE=$(du -sh "${RECORDING_DIR}" 2>/dev/null | cut -f1)
log "Current recording storage: ${USAGE}"

# Incremental backup of new recordings
log "Starting incremental recording backup..."
rsync -av --progress \
    --include='*/' \
    --include='*.wabsession' \
    --include='*.metadata' \
    --exclude='*' \
    "${RECORDING_DIR}/" \
    "${BACKUP_DIR}/"

# Archive recordings older than retention period
log "Archiving recordings older than ${RETENTION_DAYS_LOCAL} days..."
find "${RECORDING_DIR}" -type f -name "*.wabsession" -mtime +${RETENTION_DAYS_LOCAL} -print0 | \
while IFS= read -r -d '' file; do
    # Get relative path for archive structure
    rel_path="${file#${RECORDING_DIR}/}"
    archive_path="${ARCHIVE_DIR}/${rel_path}"
    archive_subdir=$(dirname "${archive_path}")

    # Create archive directory and move file
    mkdir -p "${archive_subdir}"
    mv "${file}" "${archive_path}"

    # Also move metadata if exists
    meta_file="${file%.wabsession}.metadata"
    if [ -f "${meta_file}" ]; then
        mv "${meta_file}" "${archive_subdir}/"
    fi
done

# Compress archived recordings
log "Compressing archived recordings..."
find "${ARCHIVE_DIR}" -type f -name "*.wabsession" ! -name "*.gz" -exec gzip {} \;

# Clean up very old archives
log "Removing archives older than ${RETENTION_DAYS_ARCHIVE} days..."
find "${ARCHIVE_DIR}" -type f -mtime +${RETENTION_DAYS_ARCHIVE} -delete
find "${ARCHIVE_DIR}" -type d -empty -delete

log "Recording backup completed"
```

### Recording Archive Procedure

```
+==============================================================================+
|                    SESSION RECORDING LIFECYCLE                                |
+==============================================================================+
|                                                                               |
|   DAY 0-30                  DAY 30-365                  DAY 365+             |
|   ========                  ===========                 ========             |
|                                                                               |
|   +------------+            +------------+            +------------+         |
|   |  Active    |   Archive  |  Archived  |   Delete   |  Deleted   |         |
|   |  Storage   | ---------> |  Storage   | ---------> |  (Purged)  |         |
|   |            |            |            |            |            |         |
|   | Hot Tier   |            | Cold Tier  |            | Per Policy |         |
|   | SSD/NVMe   |            | HDD/Object |            |            |         |
|   +------------+            +------------+            +------------+         |
|        |                          |                                          |
|        |                          |                                          |
|        v                          v                                          |
|   +------------+            +------------+                                   |
|   | Real-time  |            | On-demand  |                                   |
|   | Playback   |            | Retrieval  |                                   |
|   +------------+            +------------+                                   |
|                                                                               |
|   COMPLIANCE NOTE: Adjust retention based on regulatory requirements         |
|   - PCI-DSS: 1 year minimum                                                 |
|   - HIPAA: 6 years                                                          |
|   - SOX: 7 years                                                            |
|   - GDPR: As long as necessary for purpose                                  |
|                                                                               |
+==============================================================================+
```

---

## Encryption Key Backup

### Secure Key Export Procedure

```bash
#!/bin/bash
# /opt/wab/scripts/key-backup.sh
# Secure encryption key backup with key escrow support

set -e

KEY_DIR="/var/opt/wab/keys"
BACKUP_DIR="/backup/wallix/keys"
ESCROW_DIR="/secure/key-escrow"
DATE=$(date +%Y%m%d_%H%M%S)

# Ensure secure permissions
umask 077
mkdir -p "${BACKUP_DIR}" "${ESCROW_DIR}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Verify backup encryption key exists
if [ ! -f /root/.key-backup-password ]; then
    log "ERROR: Backup encryption key not found at /root/.key-backup-password"
    log "Generate one with: openssl rand -base64 32 > /root/.key-backup-password"
    exit 1
fi

log "Starting encryption key backup..."

# Create encrypted key backup
tar -czf - "${KEY_DIR}" 2>/dev/null | \
    openssl enc -aes-256-gcm -salt -pbkdf2 -iter 100000 \
    -pass file:/root/.key-backup-password \
    -out "${BACKUP_DIR}/keys-${DATE}.tar.gz.enc"

log "Encrypted key backup created: ${BACKUP_DIR}/keys-${DATE}.tar.gz.enc"

# Generate key checksum (of encrypted backup)
sha256sum "${BACKUP_DIR}/keys-${DATE}.tar.gz.enc" > "${BACKUP_DIR}/keys-${DATE}.sha256"

# Create key escrow copy (different encryption for separation of duties)
if [ -f /root/.escrow-public-key.pem ]; then
    log "Creating escrow copy with asymmetric encryption..."

    # Generate random symmetric key for this backup
    SYMMETRIC_KEY=$(openssl rand -hex 32)

    # Encrypt the backup with symmetric key
    tar -czf - "${KEY_DIR}" 2>/dev/null | \
        openssl enc -aes-256-gcm -salt -pass pass:"${SYMMETRIC_KEY}" \
        -out "${ESCROW_DIR}/keys-${DATE}.tar.gz.enc"

    # Encrypt the symmetric key with escrow public key
    echo "${SYMMETRIC_KEY}" | \
        openssl pkeyutl -encrypt -pubin -inkey /root/.escrow-public-key.pem \
        -out "${ESCROW_DIR}/keys-${DATE}.key.enc"

    # Clear symmetric key from memory
    unset SYMMETRIC_KEY

    log "Escrow copy created: ${ESCROW_DIR}/keys-${DATE}.tar.gz.enc"
fi

# Verify backup can be decrypted (test only, don't extract)
log "Verifying backup integrity..."
openssl enc -d -aes-256-gcm -salt -pbkdf2 -iter 100000 \
    -pass file:/root/.key-backup-password \
    -in "${BACKUP_DIR}/keys-${DATE}.tar.gz.enc" | \
    tar -tzf - > /dev/null

log "Backup verification successful"

# Retention: keep last 10 key backups
log "Applying retention policy..."
ls -t "${BACKUP_DIR}"/keys-*.tar.gz.enc 2>/dev/null | tail -n +11 | xargs -r rm -f
ls -t "${BACKUP_DIR}"/keys-*.sha256 2>/dev/null | tail -n +11 | xargs -r rm -f

log "Encryption key backup completed"
```

### Key Escrow Configuration

```
+==============================================================================+
|                       KEY ESCROW ARCHITECTURE                                 |
+==============================================================================+
|                                                                               |
|                    WALLIX BASTION                                            |
|                         |                                                     |
|                         v                                                     |
|              +--------------------+                                          |
|              |  Master Keys       |                                          |
|              |  /var/opt/wab/keys |                                          |
|              +----------+---------+                                          |
|                         |                                                     |
|           +-------------+-------------+                                      |
|           |                           |                                       |
|           v                           v                                       |
|    +--------------+           +--------------+                               |
|    |  Operational |           |  Escrow Copy |                               |
|    |  Backup      |           |  (Encrypted) |                               |
|    |              |           |              |                               |
|    |  Encrypted   |           |  Asymmetric  |                               |
|    |  with Admin  |           |  Encryption  |                               |
|    |  Password    |           |  with Escrow |                               |
|    |              |           |  Public Key  |                               |
|    +--------------+           +--------------+                               |
|           |                           |                                       |
|           v                           v                                       |
|    +--------------+           +--------------+                               |
|    |  Local       |           |  Secure      |                               |
|    |  Storage     |           |  Vault/HSM   |                               |
|    +--------------+           +--------------+                               |
|                                                                               |
|    KEY RECOVERY SCENARIOS:                                                   |
|    - Normal: Use operational backup with admin password                      |
|    - Disaster: Recover escrow copy with escrow private key                   |
|    - Escrow private key held by: Legal, CISO, or external custodian         |
|                                                                               |
+==============================================================================+
```

---

## Automated Backup Scripts

### Systemd Timer Configuration

```bash
# Create systemd service for backup
cat > /etc/systemd/system/wallix-backup.service << 'EOF'
[Unit]
Description=WALLIX Bastion Full Backup
After=network.target postgresql.service wallix-bastion.service

[Service]
Type=oneshot
ExecStart=/opt/wab/scripts/full-backup.sh
User=root
StandardOutput=append:/var/log/wab/backup.log
StandardError=append:/var/log/wab/backup-error.log
EOF

# Create systemd timer for daily backup at 2 AM
cat > /etc/systemd/system/wallix-backup.timer << 'EOF'
[Unit]
Description=Daily WALLIX Bastion Backup

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer
systemctl daemon-reload
systemctl enable wallix-backup.timer
systemctl start wallix-backup.timer

# Verify timer is active
systemctl list-timers wallix-backup.timer

# Expected output:
# NEXT                         LEFT          LAST                         PASSED       UNIT                 ACTIVATES
# Sat 2026-02-01 02:00:00 UTC  23h left      Fri 2026-01-31 02:00:00 UTC  1h ago       wallix-backup.timer  wallix-backup.service
```

### Cron Job Configuration

```bash
# Alternative: Cron-based backup schedule
# /etc/cron.d/wallix-backup

# Daily full backup at 2 AM
0 2 * * * root /opt/wab/scripts/full-backup.sh >> /var/log/wab/backup.log 2>&1

# Hourly configuration backup
0 * * * * root /opt/wab/scripts/config-backup.sh >> /var/log/wab/config-backup.log 2>&1

# Every 4 hours: database incremental backup
0 */4 * * * root /opt/wab/scripts/db-incremental.sh >> /var/log/wab/db-backup.log 2>&1

# Daily recording archival at 3 AM
0 3 * * * root /opt/wab/scripts/recording-backup.sh >> /var/log/wab/recording-backup.log 2>&1

# Weekly encryption key backup on Sunday at 4 AM
0 4 * * 0 root /opt/wab/scripts/key-backup.sh >> /var/log/wab/key-backup.log 2>&1

# Monthly offsite sync on 1st at 5 AM
0 5 1 * * root /opt/wab/scripts/offsite-sync.sh >> /var/log/wab/offsite-sync.log 2>&1
```

### Database Incremental Backup Script

```bash
#!/bin/bash
# /opt/wab/scripts/db-incremental.sh
# PostgreSQL incremental backup using WAL archiving

set -e

BACKUP_DIR="/backup/wallix/db-incremental"
WAL_ARCHIVE="/backup/wallix/wal"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "${BACKUP_DIR}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting database incremental backup..."

# Force WAL switch to ensure current transactions are archived
sudo -u postgres psql -c "SELECT pg_switch_wal();" > /dev/null

# Record current WAL position
WAL_POS=$(sudo -u postgres psql -t -c "SELECT pg_current_wal_lsn();")
log "Current WAL position: ${WAL_POS}"

# Create incremental backup manifest
cat > "${BACKUP_DIR}/incremental-${DATE}.manifest" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "wal_position": "${WAL_POS}",
    "hostname": "$(hostname -f)",
    "type": "incremental"
}
EOF

# Archive any pending WAL files
log "Archiving pending WAL files..."
sudo -u postgres pg_archivecleanup "${WAL_ARCHIVE}" "$(ls -t ${WAL_ARCHIVE}/*.gz 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo 'none')" 2>/dev/null || true

# Compress old WAL files
find "${WAL_ARCHIVE}" -type f -name "0000*" ! -name "*.gz" -mmin +60 -exec gzip {} \;

# Count archived WAL files since last full backup
WAL_COUNT=$(find "${WAL_ARCHIVE}" -type f -name "*.gz" | wc -l)
log "Total archived WAL files: ${WAL_COUNT}"

# Cleanup old manifests (keep last 100)
ls -t "${BACKUP_DIR}"/incremental-*.manifest 2>/dev/null | tail -n +101 | xargs -r rm -f

log "Incremental backup completed"
```

---

## Backup Verification

### Automated Verification Script

```bash
#!/bin/bash
# /opt/wab/scripts/verify-backup.sh
# Comprehensive backup verification

set -e

BACKUP_DIR="/backup/wallix"
VERIFY_DIR="/tmp/backup-verify-$$"
REPORT_FILE="/var/log/wab/backup-verify-$(date +%Y%m%d).log"

mkdir -p "${VERIFY_DIR}"
trap "rm -rf ${VERIFY_DIR}" EXIT

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${REPORT_FILE}"
}

verify_checksum() {
    local backup_file=$1
    local checksum_file="${backup_file%.tar.gz}.sha256"

    if [ -f "${checksum_file}" ]; then
        if sha256sum -c "${checksum_file}" > /dev/null 2>&1; then
            log "PASS: Checksum verification for $(basename ${backup_file})"
            return 0
        else
            log "FAIL: Checksum mismatch for $(basename ${backup_file})"
            return 1
        fi
    else
        log "WARN: No checksum file for $(basename ${backup_file})"
        return 0
    fi
}

verify_database() {
    local dump_file=$1
    log "Verifying database backup: $(basename ${dump_file})"

    # Check dump file can be read
    if sudo -u postgres pg_restore --list "${dump_file}" > /dev/null 2>&1; then
        local table_count=$(sudo -u postgres pg_restore --list "${dump_file}" | grep -c "TABLE")
        log "PASS: Database backup contains ${table_count} tables"
        return 0
    else
        log "FAIL: Cannot read database dump"
        return 1
    fi
}

verify_config() {
    local config_file=$1
    log "Verifying configuration backup: $(basename ${config_file})"

    # Extract and check for critical files
    tar -tzf "${config_file}" > "${VERIFY_DIR}/config-list.txt" 2>/dev/null

    local critical_files=("wab.conf" "cluster.conf" "ldap.conf")
    local found=0

    for cf in "${critical_files[@]}"; do
        if grep -q "${cf}" "${VERIFY_DIR}/config-list.txt"; then
            ((found++))
        fi
    done

    if [ ${found} -ge 1 ]; then
        log "PASS: Configuration backup contains ${found} critical files"
        return 0
    else
        log "WARN: Configuration backup may be incomplete"
        return 0
    fi
}

verify_keys() {
    local key_file=$1
    log "Verifying encryption key backup: $(basename ${key_file})"

    # Test decryption (requires backup password)
    if [ -f /root/.key-backup-password ]; then
        if openssl enc -d -aes-256-gcm -salt -pbkdf2 -iter 100000 \
            -pass file:/root/.key-backup-password \
            -in "${key_file}" 2>/dev/null | tar -tzf - > /dev/null 2>&1; then
            log "PASS: Encryption key backup is valid and decryptable"
            return 0
        else
            log "FAIL: Cannot decrypt key backup"
            return 1
        fi
    else
        log "SKIP: Backup password not available for key verification"
        return 0
    fi
}

# Main verification routine
log "=========================================="
log "WALLIX Bastion Backup Verification Report"
log "=========================================="
log ""

ERRORS=0

# Find latest full backup
LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/wallix-full-backup-*.tar.gz 2>/dev/null | head -1)

if [ -z "${LATEST_BACKUP}" ]; then
    log "ERROR: No full backup found in ${BACKUP_DIR}"
    exit 1
fi

log "Latest backup: ${LATEST_BACKUP}"
log "Backup date: $(stat -c %y "${LATEST_BACKUP}")"
log "Backup size: $(du -h "${LATEST_BACKUP}" | cut -f1)"
log ""

# Extract backup for verification
log "Extracting backup for verification..."
tar -xzf "${LATEST_BACKUP}" -C "${VERIFY_DIR}"

EXTRACTED_DIR=$(ls -d "${VERIFY_DIR}"/*/ | head -1)

# Verify each component
log ""
log "Component Verification:"
log "-----------------------"

if [ -f "${EXTRACTED_DIR}/database.dump" ]; then
    verify_database "${EXTRACTED_DIR}/database.dump" || ((ERRORS++))
else
    log "FAIL: Database backup not found"
    ((ERRORS++))
fi

if [ -f "${EXTRACTED_DIR}/config.tar.gz" ]; then
    verify_config "${EXTRACTED_DIR}/config.tar.gz" || ((ERRORS++))
else
    log "FAIL: Configuration backup not found"
    ((ERRORS++))
fi

if [ -f "${EXTRACTED_DIR}/keys.tar.gz.enc" ]; then
    verify_keys "${EXTRACTED_DIR}/keys.tar.gz.enc" || ((ERRORS++))
else
    log "FAIL: Encryption key backup not found"
    ((ERRORS++))
fi

if [ -f "${EXTRACTED_DIR}/checksums.sha256" ]; then
    log ""
    log "Checksum Verification:"
    log "----------------------"
    cd "${EXTRACTED_DIR}"
    while read -r line; do
        file=$(echo "$line" | awk '{print $2}')
        if [ -f "$file" ]; then
            if echo "$line" | sha256sum -c --status 2>/dev/null; then
                log "PASS: ${file}"
            else
                log "FAIL: ${file}"
                ((ERRORS++))
            fi
        fi
    done < checksums.sha256
fi

log ""
log "=========================================="
if [ ${ERRORS} -eq 0 ]; then
    log "VERIFICATION RESULT: ALL PASSED"
else
    log "VERIFICATION RESULT: ${ERRORS} ERRORS FOUND"
fi
log "=========================================="

exit ${ERRORS}
```

### Test Restore Procedure

```bash
#!/bin/bash
# /opt/wab/scripts/test-restore.sh
# Test restore to verify backup integrity (run on staging system only)

# WARNING: This script restores data - only run on test/staging systems!

if [ "$(hostname)" != "wallix-staging" ]; then
    echo "ERROR: This script should only run on staging system!"
    echo "Current hostname: $(hostname)"
    exit 1
fi

BACKUP_FILE=$1
RESTORE_DIR="/tmp/restore-test-$$"

if [ -z "${BACKUP_FILE}" ]; then
    echo "Usage: $0 <backup-file>"
    exit 1
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting test restore from: ${BACKUP_FILE}"

# Stop services
log "Stopping WALLIX services..."
systemctl stop wallix-bastion

# Extract backup
mkdir -p "${RESTORE_DIR}"
tar -xzf "${BACKUP_FILE}" -C "${RESTORE_DIR}"
EXTRACTED_DIR=$(ls -d "${RESTORE_DIR}"/*/ | head -1)

# Restore database
log "Restoring database..."
sudo -u postgres dropdb --if-exists wab_restore_test
sudo -u postgres createdb wab_restore_test
sudo -u postgres pg_restore -d wab_restore_test "${EXTRACTED_DIR}/database.dump"

# Verify database
log "Verifying restored database..."
ACCOUNT_COUNT=$(sudo -u postgres psql -t -d wab_restore_test -c "SELECT COUNT(*) FROM accounts;")
log "Restored accounts: ${ACCOUNT_COUNT}"

# Restore configuration (to temp location)
log "Restoring configuration..."
tar -xzf "${EXTRACTED_DIR}/config.tar.gz" -C "${RESTORE_DIR}"

# Verify configuration
if [ -f "${RESTORE_DIR}/etc/opt/wab/wab.conf" ]; then
    log "Configuration file restored successfully"
else
    log "WARNING: Main configuration file not found"
fi

# Cleanup
log "Cleaning up test restore..."
sudo -u postgres dropdb --if-exists wab_restore_test
rm -rf "${RESTORE_DIR}"

# Restart services
log "Restarting WALLIX services..."
systemctl start wallix-bastion

log "Test restore completed successfully"
```

---

## Offsite Backup

### AWS S3 Backup

```bash
#!/bin/bash
# /opt/wab/scripts/offsite-s3.sh
# Offsite backup to AWS S3

set -e

S3_BUCKET="s3://company-wallix-backups"
BACKUP_DIR="/backup/wallix"
DATE=$(date +%Y%m%d)
AWS_PROFILE="backup"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting offsite sync to S3..."

# Sync full backups
log "Syncing full backups..."
aws s3 sync "${BACKUP_DIR}/" "${S3_BUCKET}/backups/" \
    --profile "${AWS_PROFILE}" \
    --storage-class STANDARD_IA \
    --exclude "*" \
    --include "wallix-full-backup-*.tar.gz" \
    --no-progress

# Sync WAL archives for PITR
log "Syncing WAL archives..."
aws s3 sync "${BACKUP_DIR}/wal/" "${S3_BUCKET}/wal/" \
    --profile "${AWS_PROFILE}" \
    --storage-class STANDARD_IA \
    --no-progress

# Apply S3 lifecycle policy for old backups
log "Backups older than 90 days will be transitioned to Glacier automatically"

# Verify upload
LATEST_LOCAL=$(ls -t "${BACKUP_DIR}"/wallix-full-backup-*.tar.gz | head -1 | xargs basename)
if aws s3 ls "${S3_BUCKET}/backups/${LATEST_LOCAL}" --profile "${AWS_PROFILE}" > /dev/null 2>&1; then
    log "PASS: Latest backup verified in S3"
else
    log "FAIL: Latest backup not found in S3"
    exit 1
fi

log "Offsite S3 sync completed"
```

### Azure Blob Storage Backup

```bash
#!/bin/bash
# /opt/wab/scripts/offsite-azure.sh
# Offsite backup to Azure Blob Storage

set -e

STORAGE_ACCOUNT="companybackups"
CONTAINER="wallix-backups"
BACKUP_DIR="/backup/wallix"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting offsite sync to Azure Blob Storage..."

# Upload full backups
for backup in "${BACKUP_DIR}"/wallix-full-backup-*.tar.gz; do
    if [ -f "$backup" ]; then
        filename=$(basename "$backup")
        log "Uploading: ${filename}"

        az storage blob upload \
            --account-name "${STORAGE_ACCOUNT}" \
            --container-name "${CONTAINER}" \
            --name "backups/${filename}" \
            --file "${backup}" \
            --tier Cool \
            --only-show-errors
    fi
done

# Upload WAL archives
log "Syncing WAL archives..."
az storage blob upload-batch \
    --account-name "${STORAGE_ACCOUNT}" \
    --destination "${CONTAINER}/wal" \
    --source "${BACKUP_DIR}/wal" \
    --pattern "*.gz" \
    --tier Cool \
    --only-show-errors

log "Offsite Azure sync completed"
```

### NFS/Remote Server Backup

```bash
#!/bin/bash
# /opt/wab/scripts/offsite-nfs.sh
# Offsite backup to remote NFS server

set -e

REMOTE_SERVER="backup-server.company.com"
REMOTE_PATH="/backup/wallix"
BACKUP_DIR="/backup/wallix"
MOUNT_POINT="/mnt/offsite-backup"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Mount remote storage
if ! mountpoint -q "${MOUNT_POINT}"; then
    log "Mounting remote storage..."
    mount -t nfs "${REMOTE_SERVER}:${REMOTE_PATH}" "${MOUNT_POINT}"
fi

log "Starting offsite sync to NFS..."

# Sync backups with rsync
rsync -av --progress \
    --include='wallix-full-backup-*.tar.gz' \
    --include='keys-*.tar.gz.enc' \
    --exclude='*' \
    "${BACKUP_DIR}/" \
    "${MOUNT_POINT}/backups/"

# Sync WAL archives
rsync -av --progress \
    "${BACKUP_DIR}/wal/" \
    "${MOUNT_POINT}/wal/"

# Verify sync
LATEST_LOCAL=$(ls -t "${BACKUP_DIR}"/wallix-full-backup-*.tar.gz | head -1)
LATEST_REMOTE="${MOUNT_POINT}/backups/$(basename ${LATEST_LOCAL})"

if [ -f "${LATEST_REMOTE}" ]; then
    LOCAL_SIZE=$(stat -c%s "${LATEST_LOCAL}")
    REMOTE_SIZE=$(stat -c%s "${LATEST_REMOTE}")

    if [ "${LOCAL_SIZE}" -eq "${REMOTE_SIZE}" ]; then
        log "PASS: Backup verified on remote storage"
    else
        log "FAIL: Size mismatch - local: ${LOCAL_SIZE}, remote: ${REMOTE_SIZE}"
        exit 1
    fi
else
    log "FAIL: Backup not found on remote storage"
    exit 1
fi

# Unmount
umount "${MOUNT_POINT}"

log "Offsite NFS sync completed"
```

---

## Full System Restore

### Bare Metal Restore Procedure

```
+==============================================================================+
|                     FULL SYSTEM RESTORE PROCEDURE                             |
+==============================================================================+
|                                                                               |
|   PREREQUISITES                                                               |
|   =============                                                               |
|   [ ] Fresh Debian 12 installation completed                                  |
|   [ ] Network configured with correct IP address                              |
|   [ ] WALLIX Bastion packages installed (not configured)                      |
|   [ ] Backup files accessible                                                 |
|   [ ] Encryption key password available                                       |
|                                                                               |
|   RESTORE SEQUENCE                                                            |
|   ================                                                            |
|                                                                               |
|   Step 1: Prepare System                                                      |
|   Step 2: Restore Encryption Keys                                             |
|   Step 3: Restore SSL Certificates                                            |
|   Step 4: Restore PostgreSQL Database                                         |
|   Step 5: Restore Configuration Files                                         |
|   Step 6: Restore License                                                     |
|   Step 7: Verify and Start Services                                           |
|   Step 8: Restore Session Recordings (optional)                               |
|                                                                               |
+==============================================================================+
```

### Complete Restore Script

```bash
#!/bin/bash
# /opt/wab/scripts/full-restore.sh
# Complete WALLIX Bastion restore from backup

set -e

BACKUP_FILE=$1
KEY_PASSWORD_FILE=$2

if [ -z "${BACKUP_FILE}" ] || [ -z "${KEY_PASSWORD_FILE}" ]; then
    echo "Usage: $0 <backup-file.tar.gz> <key-password-file>"
    echo "Example: $0 /backup/wallix-full-backup-20260131.tar.gz /root/.key-password"
    exit 1
fi

RESTORE_DIR="/tmp/wallix-restore-$$"
trap "rm -rf ${RESTORE_DIR}" EXIT

log() {
    echo ""
    echo "========================================"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "========================================"
}

step() {
    echo ""
    echo ">>> $1"
}

# Pre-flight checks
log "PRE-FLIGHT CHECKS"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "ERROR: Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

if [ ! -f "${KEY_PASSWORD_FILE}" ]; then
    echo "ERROR: Key password file not found: ${KEY_PASSWORD_FILE}"
    exit 1
fi

# Stop services if running
step "Stopping WALLIX services..."
systemctl stop wallix-bastion 2>/dev/null || true
systemctl stop postgresql 2>/dev/null || true

# Extract backup
log "STEP 1: EXTRACTING BACKUP"
mkdir -p "${RESTORE_DIR}"
step "Extracting ${BACKUP_FILE}..."
tar -xzf "${BACKUP_FILE}" -C "${RESTORE_DIR}"
EXTRACTED_DIR=$(ls -d "${RESTORE_DIR}"/*/ | head -1)

# Verify manifest
if [ -f "${EXTRACTED_DIR}/manifest.json" ]; then
    echo "Backup manifest:"
    cat "${EXTRACTED_DIR}/manifest.json"
fi

# Restore encryption keys
log "STEP 2: RESTORING ENCRYPTION KEYS"
step "Decrypting and restoring encryption keys..."

# Backup existing keys if any
if [ -d /var/opt/wab/keys ]; then
    mv /var/opt/wab/keys /var/opt/wab/keys.backup.$(date +%Y%m%d_%H%M%S)
fi

# Decrypt and extract keys
openssl enc -d -aes-256-gcm -salt -pbkdf2 -iter 100000 \
    -pass file:"${KEY_PASSWORD_FILE}" \
    -in "${EXTRACTED_DIR}/keys.tar.gz.enc" | \
    tar -xzf - -C /

# Set permissions
chown -R wab:wab /var/opt/wab/keys 2>/dev/null || true
chmod 700 /var/opt/wab/keys
chmod 600 /var/opt/wab/keys/*

echo "Encryption keys restored"

# Restore SSL certificates
log "STEP 3: RESTORING SSL CERTIFICATES"
step "Extracting SSL certificates..."

tar -xzf "${EXTRACTED_DIR}/ssl-certs.tar.gz" -C /
chmod 755 /etc/ssl/wallix
chmod 644 /etc/ssl/wallix/*.crt
chmod 600 /etc/ssl/wallix/*.key

echo "SSL certificates restored"

# Restore database
log "STEP 4: RESTORING DATABASE"
step "Starting PostgreSQL..."
systemctl start postgresql

step "Dropping existing database..."
sudo -u postgres dropdb --if-exists wab 2>/dev/null || true

step "Creating fresh database..."
sudo -u postgres createdb wab

step "Restoring database from dump..."
sudo -u postgres pg_restore -d wab -v "${EXTRACTED_DIR}/database.dump" 2>&1 | tail -20

echo "Database restored"

# Restore configuration
log "STEP 5: RESTORING CONFIGURATION"
step "Extracting configuration files..."

# Backup existing config
if [ -d /etc/opt/wab ]; then
    mv /etc/opt/wab /etc/opt/wab.backup.$(date +%Y%m%d_%H%M%S)
fi

tar -xzf "${EXTRACTED_DIR}/config.tar.gz" -C /

# Fix permissions
chown -R root:wab /etc/opt/wab
chmod 750 /etc/opt/wab
find /etc/opt/wab -type f -exec chmod 640 {} \;

echo "Configuration restored"

# Restore license
log "STEP 6: RESTORING LICENSE"
step "Extracting license files..."
tar -xzf "${EXTRACTED_DIR}/license.tar.gz" -C / 2>/dev/null || echo "No license backup found"

echo "License restored"

# Update hostname if needed
log "STEP 7: VERIFYING CONFIGURATION"
step "Checking hostname configuration..."

CURRENT_HOSTNAME=$(hostname -f)
echo "Current hostname: ${CURRENT_HOSTNAME}"

read -p "Update configuration for new hostname? (y/N): " UPDATE_HOST
if [ "${UPDATE_HOST}" = "y" ]; then
    wabadmin config set --hostname "${CURRENT_HOSTNAME}" 2>/dev/null || true
fi

# Start services
log "STEP 8: STARTING SERVICES"
step "Starting WALLIX Bastion services..."
systemctl start wallix-bastion

# Wait for services to initialize
echo "Waiting for services to initialize..."
sleep 30

# Verify services
step "Verifying service status..."
systemctl status wallix-bastion --no-pager

# Run health check
log "STEP 9: VERIFICATION"
step "Running health check..."
wabadmin health-check 2>/dev/null || echo "Health check completed"

step "Verifying database connectivity..."
wabadmin status 2>/dev/null || echo "Status check completed"

log "RESTORE COMPLETED"
echo ""
echo "Next steps:"
echo "1. Verify user authentication works"
echo "2. Test session establishment to a target"
echo "3. Review audit logs for any errors"
echo "4. If this is a HA cluster, reconfigure replication"
echo ""
echo "If restoring session recordings, run:"
echo "  tar -xzf /backup/recordings.tar.gz -C /"
```

### Restore Output Example

```bash
# Run the restore
sudo /opt/wab/scripts/full-restore.sh \
    /backup/wallix/wallix-full-backup-20260131_020001.tar.gz \
    /root/.key-password

# Expected output:
# ========================================
# [2026-01-31 10:00:01] PRE-FLIGHT CHECKS
# ========================================
#
# >>> Stopping WALLIX services...
#
# ========================================
# [2026-01-31 10:00:05] STEP 1: EXTRACTING BACKUP
# ========================================
#
# >>> Extracting /backup/wallix/wallix-full-backup-20260131_020001.tar.gz...
# Backup manifest:
# {
#     "backup_date": "2026-01-31T02:00:01+00:00",
#     "bastion_version": "12.1.3",
#     "hostname": "wallix-prod.company.com",
#     ...
# }
#
# ========================================
# [2026-01-31 10:00:15] STEP 2: RESTORING ENCRYPTION KEYS
# ========================================
# ...
# [continuing through all steps]
# ...
#
# ========================================
# [2026-01-31 10:05:30] RESTORE COMPLETED
# ========================================
#
# Next steps:
# 1. Verify user authentication works
# 2. Test session establishment to a target
# 3. Review audit logs for any errors
# 4. If this is a HA cluster, reconfigure replication
```

---

## Selective Restore

### Database-Only Restore

```bash
#!/bin/bash
# Restore only the PostgreSQL database

BACKUP_FILE=$1
if [ -z "${BACKUP_FILE}" ]; then
    echo "Usage: $0 <database.dump>"
    exit 1
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting database-only restore..."

# Stop WALLIX services
log "Stopping WALLIX services..."
systemctl stop wallix-bastion

# Backup current database
log "Creating safety backup of current database..."
sudo -u postgres pg_dump -Fc wab > /tmp/wab-pre-restore-$(date +%Y%m%d_%H%M%S).dump

# Drop and recreate database
log "Dropping existing database..."
sudo -u postgres dropdb wab

log "Creating new database..."
sudo -u postgres createdb wab

# Restore from backup
log "Restoring database..."
sudo -u postgres pg_restore -d wab -v "${BACKUP_FILE}" 2>&1

# Verify restore
log "Verifying restore..."
TABLE_COUNT=$(sudo -u postgres psql -t -d wab -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
log "Restored ${TABLE_COUNT} tables"

# Start services
log "Starting WALLIX services..."
systemctl start wallix-bastion

log "Database restore completed"
```

### Configuration-Only Restore

```bash
#!/bin/bash
# Restore only configuration files

CONFIG_BACKUP=$1
if [ -z "${CONFIG_BACKUP}" ]; then
    echo "Usage: $0 <config.tar.gz>"
    exit 1
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting configuration-only restore..."

# Stop WALLIX services
log "Stopping WALLIX services..."
systemctl stop wallix-bastion

# Backup current configuration
log "Creating safety backup of current configuration..."
tar -czf /tmp/config-pre-restore-$(date +%Y%m%d_%H%M%S).tar.gz /etc/opt/wab/

# Extract configuration
log "Extracting configuration..."
tar -xzf "${CONFIG_BACKUP}" -C /

# Fix permissions
log "Setting permissions..."
chown -R root:wab /etc/opt/wab
chmod 750 /etc/opt/wab
find /etc/opt/wab -type f -exec chmod 640 {} \;

# Start services
log "Starting WALLIX services..."
systemctl start wallix-bastion

# Verify
log "Verifying configuration..."
wabadmin config --verify

log "Configuration restore completed"
```

### Session Recordings Restore

```bash
#!/bin/bash
# Restore session recordings

RECORDING_BACKUP=$1
if [ -z "${RECORDING_BACKUP}" ]; then
    echo "Usage: $0 <recordings.tar.gz>"
    exit 1
fi

RECORDING_DIR="/var/wab/recorded"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting session recordings restore..."

# Check available disk space
BACKUP_SIZE=$(stat -c%s "${RECORDING_BACKUP}")
AVAILABLE=$(df --output=avail -B1 "${RECORDING_DIR}" | tail -1)

if [ "${BACKUP_SIZE}" -gt "${AVAILABLE}" ]; then
    log "ERROR: Insufficient disk space"
    log "Backup size: $(numfmt --to=iec ${BACKUP_SIZE})"
    log "Available: $(numfmt --to=iec ${AVAILABLE})"
    exit 1
fi

# Extract recordings
log "Extracting recordings..."
tar -xzf "${RECORDING_BACKUP}" -C / --strip-components=0

# Fix permissions
log "Setting permissions..."
chown -R wab:wab "${RECORDING_DIR}"
find "${RECORDING_DIR}" -type d -exec chmod 750 {} \;
find "${RECORDING_DIR}" -type f -exec chmod 640 {} \;

# Reindex recordings in database
log "Reindexing recordings..."
wabadmin recordings --reindex 2>/dev/null || true

# Verify
RECORDING_COUNT=$(find "${RECORDING_DIR}" -name "*.wabsession" | wc -l)
log "Restored ${RECORDING_COUNT} session recordings"

log "Session recordings restore completed"
```

---

## Point-in-Time Recovery

### PITR Configuration

```bash
# Enable Point-in-Time Recovery prerequisites in postgresql.conf

cat >> /etc/postgresql/15/main/postgresql.conf << 'EOF'

# Point-in-Time Recovery Configuration
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /backup/wallix/wal/%f && cp %p /backup/wallix/wal/%f'
archive_timeout = 300
max_wal_senders = 5
wal_keep_size = 2GB
EOF

# Create WAL archive directory
mkdir -p /backup/wallix/wal
chown postgres:postgres /backup/wallix/wal

# Restart PostgreSQL
systemctl restart postgresql
```

### PITR Restore Procedure

```bash
#!/bin/bash
# /opt/wab/scripts/pitr-restore.sh
# Point-in-Time Recovery to specific timestamp

set -e

BASE_BACKUP=$1
TARGET_TIME=$2
WAL_ARCHIVE="/backup/wallix/wal"

if [ -z "${BASE_BACKUP}" ] || [ -z "${TARGET_TIME}" ]; then
    echo "Usage: $0 <base-backup-dir> <target-timestamp>"
    echo "Example: $0 /backup/wallix/basebackup/20260130 '2026-01-31 10:30:00'"
    exit 1
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting Point-in-Time Recovery..."
log "Base backup: ${BASE_BACKUP}"
log "Target time: ${TARGET_TIME}"

# Stop services
log "Stopping services..."
systemctl stop wallix-bastion
systemctl stop postgresql

# Backup current data directory
PG_DATA="/var/lib/postgresql/15/main"
log "Backing up current data directory..."
mv "${PG_DATA}" "${PG_DATA}.pre-pitr.$(date +%Y%m%d_%H%M%S)"

# Extract base backup
log "Extracting base backup..."
mkdir -p "${PG_DATA}"
tar -xzf "${BASE_BACKUP}/base.tar.gz" -C "${PG_DATA}"

# Extract pg_wal from backup
if [ -f "${BASE_BACKUP}/pg_wal.tar.gz" ]; then
    tar -xzf "${BASE_BACKUP}/pg_wal.tar.gz" -C "${PG_DATA}/pg_wal"
fi

# Create recovery configuration
log "Configuring recovery..."
cat > "${PG_DATA}/postgresql.auto.conf" << EOF
# Recovery configuration for PITR
restore_command = 'cp ${WAL_ARCHIVE}/%f %p'
recovery_target_time = '${TARGET_TIME}'
recovery_target_action = 'promote'
EOF

# Create recovery signal file
touch "${PG_DATA}/recovery.signal"

# Set permissions
chown -R postgres:postgres "${PG_DATA}"
chmod 700 "${PG_DATA}"

# Start PostgreSQL in recovery mode
log "Starting PostgreSQL in recovery mode..."
systemctl start postgresql

# Wait for recovery to complete
log "Waiting for recovery to complete..."
while [ -f "${PG_DATA}/recovery.signal" ]; do
    echo -n "."
    sleep 5
done
echo ""

# Verify recovery
log "Recovery completed. Verifying..."
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"

# Start WALLIX services
log "Starting WALLIX services..."
systemctl start wallix-bastion

log "Point-in-Time Recovery completed to ${TARGET_TIME}"
```

### PITR Recovery Example

```bash
# Scenario: Accidental deletion at 2026-01-31 10:45:00
# Recover to state just before: 2026-01-31 10:44:00

# 1. Find the appropriate base backup
ls -la /backup/wallix/basebackup/

# 2. Run PITR restore
sudo /opt/wab/scripts/pitr-restore.sh \
    /backup/wallix/basebackup/20260130 \
    '2026-01-31 10:44:00'

# Expected output:
# [2026-01-31 11:00:00] Starting Point-in-Time Recovery...
# [2026-01-31 11:00:00] Base backup: /backup/wallix/basebackup/20260130
# [2026-01-31 11:00:00] Target time: 2026-01-31 10:44:00
# [2026-01-31 11:00:01] Stopping services...
# [2026-01-31 11:00:05] Backing up current data directory...
# [2026-01-31 11:00:15] Extracting base backup...
# [2026-01-31 11:01:30] Configuring recovery...
# [2026-01-31 11:01:31] Starting PostgreSQL in recovery mode...
# [2026-01-31 11:01:35] Waiting for recovery to complete...
# ............
# [2026-01-31 11:03:15] Recovery completed. Verifying...
#  pg_is_in_recovery
# -------------------
#  f
# (1 row)
# [2026-01-31 11:03:16] Starting WALLIX services...
# [2026-01-31 11:03:45] Point-in-Time Recovery completed to 2026-01-31 10:44:00
```

---

## Cross-Version Restore

### Version Compatibility Matrix

| Backup Version | Restore Version | Method | Notes |
|----------------|-----------------|--------|-------|
| 12.0.x | 12.0.x | Direct | Full compatibility |
| 12.0.x | 12.1.x | Migration | Run upgrade after restore |
| 12.1.x | 12.1.x | Direct | Full compatibility |
| 11.x | 12.x | Not supported | Upgrade to 12.0 first |

### Cross-Version Restore Procedure

```bash
#!/bin/bash
# /opt/wab/scripts/cross-version-restore.sh
# Restore backup from different WALLIX Bastion version

set -e

BACKUP_FILE=$1
KEY_PASSWORD_FILE=$2

if [ -z "${BACKUP_FILE}" ] || [ -z "${KEY_PASSWORD_FILE}" ]; then
    echo "Usage: $0 <backup-file.tar.gz> <key-password-file>"
    exit 1
fi

RESTORE_DIR="/tmp/wallix-restore-$$"
trap "rm -rf ${RESTORE_DIR}" EXIT

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Extract backup
log "Extracting backup..."
mkdir -p "${RESTORE_DIR}"
tar -xzf "${BACKUP_FILE}" -C "${RESTORE_DIR}"
EXTRACTED_DIR=$(ls -d "${RESTORE_DIR}"/*/ | head -1)

# Check backup version
if [ -f "${EXTRACTED_DIR}/manifest.json" ]; then
    BACKUP_VERSION=$(grep -o '"bastion_version"[^,]*' "${EXTRACTED_DIR}/manifest.json" | cut -d'"' -f4)
    log "Backup version: ${BACKUP_VERSION}"
else
    log "WARNING: No manifest found, assuming compatible version"
    BACKUP_VERSION="unknown"
fi

# Get current installed version
CURRENT_VERSION=$(wabadmin version 2>/dev/null || echo "unknown")
log "Current version: ${CURRENT_VERSION}"

# Compare major versions
BACKUP_MAJOR=$(echo "${BACKUP_VERSION}" | cut -d. -f1)
CURRENT_MAJOR=$(echo "${CURRENT_VERSION}" | cut -d. -f1)

if [ "${BACKUP_MAJOR}" != "${CURRENT_MAJOR}" ]; then
    log "ERROR: Major version mismatch (${BACKUP_MAJOR} vs ${CURRENT_MAJOR})"
    log "Cross-major-version restore is not supported"
    log "Please install WALLIX Bastion ${BACKUP_MAJOR}.x first"
    exit 1
fi

# Proceed with standard restore
log "Versions compatible, proceeding with restore..."

# Stop services
systemctl stop wallix-bastion 2>/dev/null || true
systemctl stop postgresql 2>/dev/null || true

# Restore encryption keys
log "Restoring encryption keys..."
openssl enc -d -aes-256-gcm -salt -pbkdf2 -iter 100000 \
    -pass file:"${KEY_PASSWORD_FILE}" \
    -in "${EXTRACTED_DIR}/keys.tar.gz.enc" | \
    tar -xzf - -C /
chown -R wab:wab /var/opt/wab/keys 2>/dev/null || true

# Restore SSL certificates
log "Restoring SSL certificates..."
tar -xzf "${EXTRACTED_DIR}/ssl-certs.tar.gz" -C /

# Restore database
log "Restoring database..."
systemctl start postgresql
sudo -u postgres dropdb --if-exists wab
sudo -u postgres createdb wab
sudo -u postgres pg_restore -d wab "${EXTRACTED_DIR}/database.dump"

# Restore configuration
log "Restoring configuration..."
tar -xzf "${EXTRACTED_DIR}/config.tar.gz" -C /

# Restore license
log "Restoring license..."
tar -xzf "${EXTRACTED_DIR}/license.tar.gz" -C / 2>/dev/null || true

# Run database migration if needed
BACKUP_MINOR=$(echo "${BACKUP_VERSION}" | cut -d. -f2)
CURRENT_MINOR=$(echo "${CURRENT_VERSION}" | cut -d. -f2)

if [ "${BACKUP_MINOR}" -lt "${CURRENT_MINOR}" ]; then
    log "Running database migration from ${BACKUP_VERSION} to ${CURRENT_VERSION}..."
    wabadmin db-migrate --apply 2>/dev/null || true
fi

# Start services
log "Starting services..."
systemctl start wallix-bastion

# Run post-restore checks
log "Running post-restore verification..."
wabadmin health-check 2>/dev/null || true

log "Cross-version restore completed"
```

---

## Backup Monitoring

### Monitoring Script

```bash
#!/bin/bash
# /opt/wab/scripts/backup-monitor.sh
# Monitor backup status and send alerts

BACKUP_DIR="/backup/wallix"
ALERT_EMAIL="pam-admins@company.com"
ALERT_WEBHOOK="https://alerts.company.com/webhook/wallix"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

send_alert() {
    local severity=$1
    local message=$2

    # Email alert
    echo "${message}" | mail -s "[${severity}] WALLIX Backup Alert" "${ALERT_EMAIL}"

    # Webhook alert
    curl -s -X POST "${ALERT_WEBHOOK}" \
        -H "Content-Type: application/json" \
        -d "{\"severity\": \"${severity}\", \"message\": \"${message}\"}" \
        > /dev/null 2>&1 || true
}

# Check last backup age
LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/wallix-full-backup-*.tar.gz 2>/dev/null | head -1)

if [ -z "${LATEST_BACKUP}" ]; then
    send_alert "CRITICAL" "No backup found in ${BACKUP_DIR}"
    exit 1
fi

BACKUP_AGE_HOURS=$(( ($(date +%s) - $(stat -c %Y "${LATEST_BACKUP}")) / 3600 ))

if [ ${BACKUP_AGE_HOURS} -gt 48 ]; then
    send_alert "CRITICAL" "Last backup is ${BACKUP_AGE_HOURS} hours old"
elif [ ${BACKUP_AGE_HOURS} -gt 24 ]; then
    send_alert "WARNING" "Last backup is ${BACKUP_AGE_HOURS} hours old"
else
    log "Backup age OK: ${BACKUP_AGE_HOURS} hours"
fi

# Check backup storage capacity
USAGE_PERCENT=$(df --output=pcent "${BACKUP_DIR}" | tail -1 | tr -d ' %')

if [ ${USAGE_PERCENT} -gt 90 ]; then
    send_alert "CRITICAL" "Backup storage at ${USAGE_PERCENT}% capacity"
elif [ ${USAGE_PERCENT} -gt 80 ]; then
    send_alert "WARNING" "Backup storage at ${USAGE_PERCENT}% capacity"
else
    log "Storage capacity OK: ${USAGE_PERCENT}%"
fi

# Check backup integrity
if ! /opt/wab/scripts/verify-backup.sh > /dev/null 2>&1; then
    send_alert "CRITICAL" "Backup verification failed"
else
    log "Backup integrity OK"
fi

# Check WAL archiving (for PITR)
WAL_ARCHIVE_DIR="${BACKUP_DIR}/wal"
LATEST_WAL=$(ls -t "${WAL_ARCHIVE_DIR}"/*.gz 2>/dev/null | head -1)

if [ -n "${LATEST_WAL}" ]; then
    WAL_AGE_MINUTES=$(( ($(date +%s) - $(stat -c %Y "${LATEST_WAL}")) / 60 ))

    if [ ${WAL_AGE_MINUTES} -gt 30 ]; then
        send_alert "WARNING" "WAL archiving may be stalled - last archive ${WAL_AGE_MINUTES} minutes ago"
    else
        log "WAL archiving OK: ${WAL_AGE_MINUTES} minutes ago"
    fi
fi

log "Backup monitoring check completed"
```

### Prometheus Metrics Export

```bash
#!/bin/bash
# /opt/wab/scripts/backup-metrics.sh
# Export backup metrics for Prometheus

BACKUP_DIR="/backup/wallix"
METRICS_FILE="/var/lib/node_exporter/textfile_collector/wallix_backup.prom"

mkdir -p $(dirname "${METRICS_FILE}")

# Get metrics
LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/wallix-full-backup-*.tar.gz 2>/dev/null | head -1)
BACKUP_COUNT=$(ls "${BACKUP_DIR}"/wallix-full-backup-*.tar.gz 2>/dev/null | wc -l)
STORAGE_BYTES=$(du -sb "${BACKUP_DIR}" 2>/dev/null | cut -f1)

if [ -n "${LATEST_BACKUP}" ]; then
    BACKUP_SIZE=$(stat -c %s "${LATEST_BACKUP}")
    BACKUP_TIME=$(stat -c %Y "${LATEST_BACKUP}")
else
    BACKUP_SIZE=0
    BACKUP_TIME=0
fi

# Write metrics
cat > "${METRICS_FILE}" << EOF
# HELP wallix_backup_last_timestamp Unix timestamp of last backup
# TYPE wallix_backup_last_timestamp gauge
wallix_backup_last_timestamp ${BACKUP_TIME}

# HELP wallix_backup_last_size_bytes Size of last backup in bytes
# TYPE wallix_backup_last_size_bytes gauge
wallix_backup_last_size_bytes ${BACKUP_SIZE}

# HELP wallix_backup_count Total number of backup files
# TYPE wallix_backup_count gauge
wallix_backup_count ${BACKUP_COUNT}

# HELP wallix_backup_storage_bytes Total backup storage used in bytes
# TYPE wallix_backup_storage_bytes gauge
wallix_backup_storage_bytes ${STORAGE_BYTES}
EOF
```

### Alerting Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Backup age | > 24 hours | > 48 hours |
| Storage usage | > 80% | > 90% |
| WAL archive lag | > 15 minutes | > 30 minutes |
| Backup verification | N/A | Failed |
| Offsite sync age | > 24 hours | > 48 hours |

---

## Backup Security

### Encryption at Rest

```bash
# All backups should be encrypted before storage

# Generate backup encryption key (one-time setup)
openssl rand -base64 32 > /root/.backup-encryption-key
chmod 600 /root/.backup-encryption-key

# Encrypt backup file
openssl enc -aes-256-gcm -salt -pbkdf2 -iter 100000 \
    -pass file:/root/.backup-encryption-key \
    -in backup.tar.gz \
    -out backup.tar.gz.enc

# Decrypt backup file
openssl enc -d -aes-256-gcm -salt -pbkdf2 -iter 100000 \
    -pass file:/root/.backup-encryption-key \
    -in backup.tar.gz.enc \
    -out backup.tar.gz
```

### Access Control

```bash
# Secure backup directory permissions
chmod 700 /backup/wallix
chown root:root /backup/wallix

# Secure backup scripts
chmod 700 /opt/wab/scripts/*.sh
chown root:root /opt/wab/scripts/*.sh

# Secure encryption keys
chmod 600 /root/.backup-encryption-key
chmod 600 /root/.key-backup-password

# Audit backup access
auditctl -w /backup/wallix -p rwxa -k wallix_backup_access
```

### Security Best Practices

```
+==============================================================================+
|                     BACKUP SECURITY BEST PRACTICES                            |
+==============================================================================+
|                                                                               |
|    ENCRYPTION                                                                 |
|    ==========                                                                 |
|    [x] All backups encrypted with AES-256-GCM                                |
|    [x] Separate encryption keys for operational and escrow copies            |
|    [x] Key derivation using PBKDF2 with 100,000+ iterations                  |
|    [x] Encryption keys stored separately from backup data                    |
|                                                                               |
|    ACCESS CONTROL                                                            |
|    ==============                                                            |
|    [x] Backup directories accessible only by root                            |
|    [x] Backup scripts executable only by root                                |
|    [x] Service accounts with minimal privileges                              |
|    [x] MFA required for offsite backup access                                |
|                                                                               |
|    AUDIT & MONITORING                                                        |
|    ==================                                                        |
|    [x] All backup operations logged                                          |
|    [x] File access auditing enabled                                          |
|    [x] Backup verification logged and alerted                                |
|    [x] Offsite transfer logged                                               |
|                                                                               |
|    NETWORK SECURITY                                                          |
|    ================                                                          |
|    [x] TLS 1.3 for all backup transfers                                      |
|    [x] VPN or private links for offsite transfer                             |
|    [x] IP whitelisting for backup destinations                               |
|                                                                               |
|    KEY MANAGEMENT                                                            |
|    ==============                                                            |
|    [x] Encryption keys rotated annually                                      |
|    [x] Old keys retained for backup recovery                                 |
|    [x] Key escrow with separation of duties                                  |
|    [x] Emergency key recovery procedure documented                           |
|                                                                               |
+==============================================================================+
```

### Backup Audit Log

```bash
#!/bin/bash
# /opt/wab/scripts/backup-audit.sh
# Log all backup operations for audit trail

AUDIT_LOG="/var/log/wab/backup-audit.log"

log_audit() {
    local operation=$1
    local details=$2
    local status=$3

    echo "{
        \"timestamp\": \"$(date -Iseconds)\",
        \"operation\": \"${operation}\",
        \"user\": \"$(whoami)\",
        \"details\": \"${details}\",
        \"status\": \"${status}\",
        \"hostname\": \"$(hostname -f)\"
    }" >> "${AUDIT_LOG}"
}

# Use in backup scripts:
# source /opt/wab/scripts/backup-audit.sh
# log_audit "full_backup" "Started full system backup" "in_progress"
# ...
# log_audit "full_backup" "Backup completed: /backup/wallix/backup-20260131.tar.gz" "success"
```

---

## Quick Reference

### Backup Commands

```bash
# Full system backup
/opt/wab/scripts/full-backup.sh

# Database backup only
sudo -u postgres pg_dump -Fc -Z 9 wab > /backup/wallix/database.dump

# Configuration backup
tar -czf /backup/wallix/config.tar.gz /etc/opt/wab/

# Verify backup
/opt/wab/scripts/verify-backup.sh

# List backups
ls -lah /backup/wallix/wallix-full-backup-*.tar.gz
```

### Restore Commands

```bash
# Full system restore
/opt/wab/scripts/full-restore.sh /backup/wallix/backup.tar.gz /root/.key-password

# Database restore only
sudo -u postgres pg_restore -d wab /backup/wallix/database.dump

# Configuration restore
tar -xzf /backup/wallix/config.tar.gz -C /

# Point-in-time recovery
/opt/wab/scripts/pitr-restore.sh /backup/basebackup/20260130 '2026-01-31 10:44:00'
```

### Monitoring Commands

```bash
# Check backup status
/opt/wab/scripts/backup-monitor.sh

# Check backup age
stat -c %y /backup/wallix/wallix-full-backup-*.tar.gz | tail -1

# Check backup storage
df -h /backup/wallix

# Check WAL archiving
sudo -u postgres psql -c "SELECT * FROM pg_stat_archiver;"
```

---

## Related Documentation

- [10 - High Availability](../10-high-availability/README.md) - HA and DR architecture
- [30 - Operational Runbooks](../30-operational-runbooks/README.md) - Daily operations procedures
- [32 - Incident Response](../32-incident-response/README.md) - Security incident playbooks

---

## External References

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Administration Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
- [PostgreSQL Backup Documentation](https://www.postgresql.org/docs/15/backup.html)
- [PostgreSQL PITR Documentation](https://www.postgresql.org/docs/15/continuous-archiving.html)

---

*Document Version: 1.0*
*Last Updated: January 2026*
