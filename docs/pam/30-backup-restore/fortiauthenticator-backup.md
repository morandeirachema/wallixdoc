# FortiAuthenticator 6.4+ Backup and Recovery

## Production Backup Procedures for FortiAuthenticator 6.4+

This document covers the complete backup and recovery strategy for the
FortiAuthenticator 6.4+ appliances deployed as **per-site HA pairs** in the
Cyber VLAN at each of the 5 sites. Each site operates its own independent
FortiAuthenticator pair — there is no centralized shared appliance. Apply
these procedures to each site independently.

Loss of FortiAuthenticator data at a site requires re-enrolling all FortiToken
users for that site — a process that can take hours to days. Proper backup is
critical for each site's pair.

---

## Table of Contents

1. [Environment Overview](#environment-overview)
2. [What to Backup](#what-to-backup)
3. [Backup Architecture](#backup-architecture)
4. [Full Configuration Backup — Web UI](#full-configuration-backup--web-ui)
5. [Full Configuration Backup — CLI](#full-configuration-backup--cli)
6. [Automated Scheduled Backup](#automated-scheduled-backup)
7. [Backup Verification](#backup-verification)
8. [Restore Procedure](#restore-procedure)
9. [Disaster Recovery Scenarios](#disaster-recovery-scenarios)
10. [HA Sync vs Backup](#ha-sync-vs-backup)
11. [Backup Monitoring and Alerting](#backup-monitoring-and-alerting)
12. [Backup Retention Policy](#backup-retention-policy)
13. [Security Considerations](#security-considerations)
14. [Operational Checklist](#operational-checklist)
15. [Troubleshooting](#troubleshooting)

---

## Environment Overview

### FortiAuthenticator Deployment

```
+===============================================================================+
|                  FORTIAUTHENTICATOR 6.4+ DEPLOYMENT (PER SITE)                           |
+===============================================================================+
|                                                                               |
|  Appliance:       FortiAuthenticator 6.4+ (hardware)                          |
|  Firmware:        FortiAuthenticator v6.6.x                                   |
|  Role:            Per-site MFA provider (RADIUS + FortiToken TOTP)            |
|  Scope:           Cyber VLAN — isolated per site (X = site number 1-5)        |
|                                                                               |
|  +-----------------------------------+  +-----------------------------------+ |
|  |  PRIMARY                          |  |  SECONDARY (HA)                   | |
|  |  fortiauth-siteX.company.com      |  |  fortiauth-siteX-ha.company.com   | |
|  |  10.10.X.50  (Cyber VLAN)         |  |  10.10.X.51  (Cyber VLAN)         | |
|  |  Active                           |  |  Standby                          | |
|  +-----------------------------------+  +-----------------------------------+ |
|                                                                               |
|  Cyber VLAN Subnet (per site):   10.10.X.0/24                                 |
|  SFTP Backup Server:             10.20.0.50  (centralized — shared)           |
|  AD DC (Cyber VLAN):             10.10.X.60                                   |
|                                                                               |
+===============================================================================+
```

### RADIUS Clients Served

| Client                  | IP          | Purpose |
|-------------------------|-------------|---------|
| Bastion Site 1 (node 1) | 10.10.1.11  | MFA for PAM sessions |
| Bastion Site 1 (node 2) | 10.10.1.12  | MFA for PAM sessions |
| Bastion Site 2 (node 1) | 10.10.2.11  | MFA for PAM sessions |
| Bastion Site 2 (node 2) | 10.10.2.12  | MFA for PAM sessions |
| Bastion Site 3 (node 1) | 10.10.3.11  | MFA for PAM sessions |
| Bastion Site 3 (node 2) | 10.10.3.12  | MFA for PAM sessions |
| Bastion Site 4 (node 1) | 10.10.4.11  | MFA for PAM sessions |
| Bastion Site 4 (node 2) | 10.10.4.12  | MFA for PAM sessions |
| Bastion Site 5 (node 1) | 10.10.5.11  | MFA for PAM sessions |
| Bastion Site 5 (node 2) | 10.10.5.12  | MFA for PAM sessions |
| Access Manager 1        | 10.100.1.10 | MFA for web sessions |
| Access Manager 2        | 10.100.2.10 | MFA for web sessions |

---

## What to Backup

### Critical Data Components

| Component                  | Description                                     | Impact if Lost |
|----------------------------|-------------------------------------------------|----------------|
| **System Configuration**   | Network, DNS, NTP, admin accounts, SNMP, syslog | Appliance must be reconfigured from scratch |
| **RADIUS Configuration**   | RADIUS clients, shared secrets, policies        | All 12 RADIUS clients lose MFA capability |
| **FortiToken Assignments** | Token-to-user mappings, token seeds             | All users must re-enroll MFA tokens |
| **User Database**          | Local and remote user records, group mappings   | User identity data lost |
| **LDAP Remote User Sync**  | AD sync config, filters, schedule               | User sync stops until reconfigured |
| **Certificate Store**      | SSL/TLS certificates, CA chain, RADIUS certs    | HTTPS and RADIUS encryption broken |
| **HA Configuration**       | HA peer settings, sync configuration            | HA failover non-functional |
| **Audit Logs**             | Authentication logs, admin change logs          | Compliance audit trail lost |

### Data NOT Included in Configuration Backup

> **Important:** FortiAuthenticator configuration backups include token seeds and user data, but **not** the following:
>
> - Firmware image (must be downloaded separately from FortiGuard)
> - Historical logs beyond the backup moment (use syslog forwarding for long-term log retention)
> - FortiGuard connection state (re-established automatically after restore)

---

## Backup Architecture

```
+===============================================================================+
|                  FORTIAUTHENTICATOR BACKUP ARCHITECTURE                       |
+===============================================================================+
|                                                                               |
|  FortiAuthenticator 6.4+                                                      |
|  (10.10.X.50)                                                                 |
|       |                                                                       |
|       |--- Daily 02:00 -----> SFTP Server (10.20.0.50)                        |
|       |                       /backups/fortiauth/                             |
|       |                       +-- FAC_config_20260409_0200.bak                |
|       |                       +-- FAC_config_20260408_0200.bak                |
|       |                       +-- ...                                         |
|       |                       +-- FAC_config_20260327_0200.bak  (14-day)      |
|       |                                                                       |
|       |--- HA Sync ---------> FortiAuthenticator Secondary (10.10.X.51)       |
|       |                       (near-real-time replication)                    |
|       |                                                                       |
|       |--- On-demand -------> Admin Workstation (manual download)             |
|       |                       (before firmware upgrades / major changes)      |
|       |                                                                       |
|       +--- Syslog 514/UDP --> Syslog Server (10.20.0.50)                      |
|                               (continuous log forwarding)                     |
|                                                                               |
|  BACKUP STRATEGY:                                                             |
|  ================                                                             |
|  * HA sync:          Near-real-time  (protects against hardware failure)      |
|  * Scheduled backup: Daily at 02:00  (protects against data corruption)       |
|  * Manual backup:    Before changes  (protects against config errors)         |
|  * Log forwarding:   Continuous      (protects audit trail)                   |
|                                                                               |
+===============================================================================+
```

---

## Full Configuration Backup — Web UI

### Step-by-Step Procedure

```
1. Log in to FortiAuthenticator Web UI
   URL:  https://fortiauth.company.com  (10.10.X.50)
   User: admin

2. Navigate to:
   System > Administration > Backup & Restore

3. Select Backup Type:
   [x] Configuration
   [x] User data and FortiToken assignments
   [x] Certificates

4. Encryption:
   [x] Encrypt backup file
   Password: [use a strong password, store in password vault — _REDACTED]

   IMPORTANT: Without the encryption password, the backup file cannot
   be restored. Store this password separately from the backup files.

5. Click "Backup"

6. Save the file:
   Filename format: FAC-backup_full_YYYYMMDD_manual.bak
   Example:         FAC-backup_full_20260409_manual.bak

7. Transfer to backup server:
   scp FAC-backup_full_20260409_manual.bak backup-user@10.20.0.50:/backups/fortiauth/manual/
```

### When to Perform Manual Backup

| Trigger | Priority | Mandatory |
|---------|----------|-----------|
| Before firmware upgrade | Critical | Yes |
| Before adding/removing RADIUS clients | High | Yes |
| Before modifying RADIUS policies | High | Yes |
| Before HA configuration changes | Critical | Yes |
| Before bulk user import | High | Yes |
| After initial deployment and testing | Critical | Yes |
| Before certificate renewal | High | Yes |
| Monthly compliance snapshot | Medium | Recommended |

---

## Full Configuration Backup — CLI

### Interactive Backup via SSH

```bash
# SSH to FortiAuthenticator primary (10.10.X.50)
ssh admin@10.10.X.50

# Backup to SFTP server with encryption
execute backup config sftp 10.20.0.50 /backups/fortiauth/ backup-user _REDACTED

# Expected output:
# Please wait...
# Backing up system configuration, user data, and certificates...
# Transferring backup file to 10.20.0.50...
# Backup successful.

# Backup to TFTP (alternative, no encryption — lab only)
execute backup config tftp 10.20.0.50 FAC-backup_backup.bak
```

### Verify CLI Backup Completed

```bash
# On the SFTP server (10.20.0.50), verify the backup file arrived
ls -lh /backups/fortiauth/

# Expected output:
# -rw-r-----  1 backup-user backup   12M Apr  9 02:01 FAC_config_20260409_0200.bak
# -rw-r-----  1 backup-user backup   12M Apr  8 02:01 FAC_config_20260408_0200.bak

# Verify file is not zero-size or truncated
file /backups/fortiauth/FAC_config_20260409_0200.bak

# Expected: data (encrypted backup) or gzip compressed data (unencrypted)
```

---

## Automated Scheduled Backup

### Configure via CLI

```bash
# SSH to FortiAuthenticator primary (10.10.X.50)
ssh admin@10.10.X.50

# Configure scheduled backup
config system backup
  set status enable
  set protocol sftp
  set server "10.20.0.50"
  set port 22
  set username "backup-user"
  set password _REDACTED
  set directory "/backups/fortiauth"
  set hour 2
  set minute 0
  set max-backup 14
  set encrypt enable
  set encrypt-password _REDACTED
end

# Verify configuration
show system backup

# Expected output:
# config system backup
#     set status enable
#     set protocol sftp
#     set server "10.20.0.50"
#     set port 22
#     set username "backup-user"
#     set directory "/backups/fortiauth"
#     set hour 2
#     set minute 0
#     set max-backup 14
#     set encrypt enable
# end
```

### Configure via Web UI

```
1. Navigate to:
   System > Administration > Backup & Restore > Scheduled Backup

2. Configure:
   Status:          Enabled
   Protocol:        SFTP
   Server:          10.20.0.50
   Port:            22
   Username:        backup-user
   Password:        [_REDACTED]
   Directory:       /backups/fortiauth
   Schedule:        Daily at 02:00
   Max Backups:     14
   Encrypt:         Enabled
   Encrypt Password:[_REDACTED — store in vault]

3. Click "Apply"

4. Test by clicking "Backup Now"

5. Verify file arrived on SFTP server
```

### SFTP Server Preparation

```bash
# On the SFTP server (10.20.0.50), create the backup directory structure
sudo mkdir -p /backups/fortiauth/manual
sudo chown -R backup-user:backup /backups/fortiauth
sudo chmod 750 /backups/fortiauth

# Create dedicated backup user (if not already existing)
sudo useradd -m -d /home/backup-user -s /bin/bash backup-user
sudo passwd backup-user  # Set strong password — _REDACTED

# Configure SSH key authentication (recommended over password)
sudo -u backup-user mkdir -p /home/backup-user/.ssh
sudo -u backup-user chmod 700 /home/backup-user/.ssh

# Add the FortiAuthenticator SSH public key to authorized_keys
# (Extract from FortiAuth: System > Administration > SSH Keys)
echo "ssh-rsa AAAA... fortiauth-backup" | \
  sudo -u backup-user tee -a /home/backup-user/.ssh/authorized_keys
sudo -u backup-user chmod 600 /home/backup-user/.ssh/authorized_keys

# Set up log rotation for backup directory
cat <<'LOGROTATE' | sudo tee /etc/logrotate.d/fortiauth-backup
/backups/fortiauth/*.bak {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
}
LOGROTATE
```

---

## Backup Verification

### Daily Verification Script

```bash
#!/bin/bash
# /opt/scripts/verify-fortiauth-backup.sh
# Run via cron daily at 06:00 (after 02:00 backup window)

BACKUP_DIR="/backups/fortiauth"
MAX_AGE_HOURS=28    # Allow margin for backup duration
MIN_SIZE_KB=1024    # Minimum expected backup size (1 MB)
ALERT_EMAIL="pam-admin@company.com"
HOSTNAME=$(hostname)

check_backup() {
    # Find the most recent backup file
    LATEST=$(find "${BACKUP_DIR}" -name "FAC_config_*.bak" -type f \
        -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2)

    if [ -z "${LATEST}" ]; then
        echo "CRITICAL: No backup files found in ${BACKUP_DIR}"
        return 1
    fi

    # Check age
    FILE_AGE=$(( ($(date +%s) - $(stat -c %Y "${LATEST}")) / 3600 ))
    if [ "${FILE_AGE}" -gt "${MAX_AGE_HOURS}" ]; then
        echo "CRITICAL: Latest backup is ${FILE_AGE} hours old: ${LATEST}"
        return 1
    fi

    # Check size
    FILE_SIZE_KB=$(( $(stat -c %s "${LATEST}") / 1024 ))
    if [ "${FILE_SIZE_KB}" -lt "${MIN_SIZE_KB}" ]; then
        echo "WARNING: Backup file is only ${FILE_SIZE_KB} KB (expected > ${MIN_SIZE_KB} KB): ${LATEST}"
        return 1
    fi

    # Check backup count
    BACKUP_COUNT=$(find "${BACKUP_DIR}" -name "FAC_config_*.bak" -type f | wc -l)

    echo "OK: Latest backup: ${LATEST} (${FILE_SIZE_KB} KB, ${FILE_AGE}h ago, ${BACKUP_COUNT} total)"
    return 0
}

RESULT=$(check_backup)
STATUS=$?

if [ ${STATUS} -ne 0 ]; then
    echo "${RESULT}" | mail -s "[ALERT] FortiAuthenticator backup failure on ${HOSTNAME}" "${ALERT_EMAIL}"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${RESULT}" >> /var/log/fortiauth-backup-check.log
exit ${STATUS}
```

```bash
# Install cron job for verification
sudo crontab -l 2>/dev/null | {
    cat
    echo "0 6 * * * /opt/scripts/verify-fortiauth-backup.sh"
} | sudo crontab -
```

### Manual Verification Procedure

```bash
# 1. Check backup files exist and are recent
ls -lht /backups/fortiauth/FAC_config_*.bak | head -5

# Expected output:
# -rw-r-----  1 backup-user backup  12M Apr  9 02:01 FAC_config_20260409_0200.bak
# -rw-r-----  1 backup-user backup  12M Apr  8 02:01 FAC_config_20260408_0200.bak
# -rw-r-----  1 backup-user backup  11M Apr  7 02:01 FAC_config_20260407_0200.bak

# 2. Check file integrity (not zero-size, not truncated)
for f in /backups/fortiauth/FAC_config_*.bak; do
    SIZE=$(stat -c %s "$f")
    DATE=$(stat -c %y "$f" | cut -d' ' -f1)
    echo "${DATE}  $(basename $f)  ${SIZE} bytes"
done

# 3. Generate checksums for audit trail
sha256sum /backups/fortiauth/FAC_config_*.bak > /backups/fortiauth/checksums.sha256

# 4. Verify disk space on backup server
df -h /backups/fortiauth

# Expected: Sufficient free space for at least 14 daily backups (estimated 200 MB)
```

### Restore Test Procedure (Quarterly)

> **Critical:** Test restores quarterly on the secondary appliance (10.10.X.51) to validate backup integrity. Never test-restore on the active primary in production.

```
1. Temporarily disable HA sync on SECONDARY:
   SSH to 10.10.X.51:
   config system ha
     set mode standalone
   end

2. Restore backup file on SECONDARY:
   Web UI: System > Administration > Backup & Restore > Restore
   - Select a recent backup file
   - Enter encryption password
   - Click "Restore"
   - Appliance reboots automatically

3. After reboot, verify on SECONDARY:
   - User count matches primary
   - RADIUS client list is complete (all 12 entries)
   - FortiToken assignments are intact
   - RADIUS test authentication succeeds

4. Re-enable HA sync on SECONDARY:
   config system ha
     set mode active-passive
     set group-id 1
     set peer-ip 10.10.X.50
   end

5. Document test results:
   Date:          ________
   Backup file:   ________
   User count:    ________ (expected: matches primary)
   RADIUS clients:________ (expected: 12)
   Test auth:     PASS / FAIL
   Tested by:     ________
```

---

## Restore Procedure

### Full Restore — Web UI

```
PREREQUISITE: Have the backup encryption password available.
              Without it, encrypted backups cannot be restored.

1. Access FortiAuthenticator Web UI:
   URL:  https://fortiauth.company.com  (or https://10.10.X.50)

2. Navigate to:
   System > Administration > Backup & Restore

3. Click "Restore"

4. Select backup file:
   - Browse to the .bak file
   - Enter encryption password

5. Confirm restore:
   WARNING: This will overwrite all current configuration, users,
   and token assignments. The appliance will reboot.

6. Wait for reboot (approximately 3-5 minutes for hardware appliances)

7. Verify restoration:
   - Log in to Web UI
   - Check Dashboard > System Information
   - Verify user count
   - Verify RADIUS client list
   - Test RADIUS authentication from a Bastion node
```

### Full Restore — CLI

```bash
# SSH to FortiAuthenticator
ssh admin@10.10.X.50

# Restore from SFTP server
execute restore config sftp 10.20.0.50 /backups/fortiauth/FAC_config_20260409_0200.bak backup-user _REDACTED

# Expected output:
# This operation will overwrite the current configuration.
# Do you want to continue? (y/n) y
# Please wait...
# Restoring configuration...
# System is rebooting...

# After reboot (~3-5 minutes), reconnect and verify:
ssh admin@10.10.X.50
get system status

# Expected output:
# Version: FortiAuthenticator-VM v6.6.x
# Serial-Number: FAC3HDXXXXXXXX
# System time: 2026-04-09 06:15:32
```

### Post-Restore Verification Checklist

```bash
# Run all verifications from FortiAuthenticator CLI after restore:

# 1. Check system status
get system status

# 2. Check HA status
get system ha status
# Expected: peer is reachable, sync status OK

# 3. Verify RADIUS client count
# Via Web UI: Authentication > RADIUS Service > Clients
# Expected: 12 clients (10 Bastion nodes + 2 Access Managers)

# 4. Verify user/token count
# Via Web UI: Authentication > User Management > Local Users
# Compare count with pre-restore baseline

# 5. Test RADIUS authentication from a Bastion node
# On any Bastion (e.g., 10.10.1.11):
radtest testuser _REDACTED 10.10.X.50 0 _REDACTED
# Expected: Access-Accept (if user has valid token and provides OTP)

# 6. Verify AD sync is operational
# Via Web UI: Authentication > Remote User Sync Rules
# Check "Last Sync" timestamp — should show recent sync after restore

# 7. Verify NTP sync
get system ntp
# Expected: servers 10.20.0.20 and 10.20.0.21 reachable, time synced

# 8. Verify certificate status
# Via Web UI: Certificate Management > Local Certificates
# Check all certificates are valid and not expired
```

---

## Disaster Recovery Scenarios

### Scenario 1: Primary Hardware Failure

```
+===============================================================================+
|  SCENARIO: Primary FortiAuthenticator 6.4+ hardware failure                   |
+===============================================================================+
|                                                                               |
|  Impact:  MFA unavailable if HA is not configured                             |
|  RTO:     < 5 minutes (with HA) / 30-60 minutes (without HA)                  |
|  RPO:     Near-zero (with HA) / up to 24 hours (backup only)                  |
|                                                                               |
|  WITH HA (recommended):                                                       |
|  =====================                                                        |
|  1. Secondary (10.10.X.51) automatically promotes to active                   |
|  2. All RADIUS clients continue authenticating against secondary              |
|  3. No action required — failover is automatic                                |
|  4. Replace failed hardware, configure as new secondary                       |
|                                                                               |
|  WITHOUT HA (backup restore):                                                 |
|  ============================                                                 |
|  1. Deploy replacement hardware appliance or VM                                   |
|  2. Configure base network settings (IP, DNS, NTP, gateway)                   |
|  3. Restore latest backup from SFTP server                                    |
|  4. Verify RADIUS clients and user/token data                                 |
|  5. Test authentication from Bastion nodes                                    |
|                                                                               |
+===============================================================================+
```

### Scenario 2: Data Corruption

```
Symptoms:
- Users report MFA failures for previously working accounts
- FortiToken assignments disappear from Web UI
- RADIUS policy returns Access-Reject for valid users

Recovery Steps:
1. Confirm corruption (not a network or client-side issue)
2. Check HA peer — if secondary is healthy, failover and resync
3. If both appliances corrupted, restore from last known good backup:

   ssh admin@10.10.X.50
   execute restore config sftp 10.20.0.50 /backups/fortiauth/FAC_config_YYYYMMDD_0200.bak backup-user _REDACTED

4. After restore, verify user count and test authentication
5. Investigate root cause (firmware bug, disk issue, unauthorized change)
```

### Scenario 3: Firmware Upgrade Rollback

```
Pre-upgrade procedure:
1. Take manual backup BEFORE firmware upgrade (mandatory)
2. Document current firmware version
3. Document current user count and RADIUS client count

Rollback if upgrade fails:
1. If appliance is accessible:
   execute restore config sftp 10.20.0.50 /backups/fortiauth/manual/FAC-backup_pre-upgrade_YYYYMMDD.bak backup-user _REDACTED

2. If appliance is inaccessible (bricked):
   a. Connect via console cable (serial port on appliance rear panel)
   b. Boot into maintenance mode (hold button during POST)
   c. Reinstall previous firmware from USB/TFTP
   d. Restore configuration backup after firmware is running

3. After rollback, verify all RADIUS clients and token assignments
```

### Scenario 4: Complete Site Cyber VLAN Loss

```
If 10.10.X.0/24 Cyber VLAN is lost at a site (both FortiAuth appliances unavailable):

1. MFA is unavailable at that site only (other sites are unaffected)
2. Emergency: Enable MFA bypass on the affected site's Bastion nodes:
   # Via Web UI: Configuration > Authentication > External Authentication
   # Temporarily disable RADIUS MFA requirement

   # On each Bastion node (10 nodes total):
   # Via Web UI: Configuration > Authentication > External Authentication
   # Temporarily disable RADIUS MFA requirement
   # Document bypass activation time for compliance

3. Deploy replacement FortiAuthenticator (VM or hardware)
4. Assign IP 10.10.X.50, configure DNS, NTP, gateway
5. Restore from offsite backup copy
6. Reconfigure HA with new secondary
7. Verify and re-enable MFA on all Bastion nodes
8. Document incident for compliance audit
```

---

## HA Sync vs Backup

### Understanding the Difference

```
+===============================================================================+
|                  HA SYNC vs BACKUP — WHEN EACH PROTECTS YOU                   |
+===============================================================================+
|                                                                               |
|  Threat                        HA Sync    Backup    Best Protection           |
|  ======                        =======    ======    ===============           |
|  Hardware failure              YES        yes       HA sync (instant)         |
|  Power outage                  YES        yes       HA sync (instant)         |
|  Network partition             partial    yes       Both                      |
|  Configuration error           NO*        YES       Backup (rollback)         |
|  Accidental deletion           NO*        YES       Backup (rollback)         |
|  Data corruption               NO*        YES       Backup (known-good)       |
|  Ransomware / compromise       NO         YES**     Offline backup            |
|  Firmware upgrade failure      NO         YES       Pre-upgrade backup        |
|  Complete site destruction     NO         YES**     Offsite backup            |
|                                                                               |
|  * HA sync replicates the problem to the secondary immediately                |
|  ** Only if backup is stored offsite / air-gapped                             |
|                                                                               |
|  CONCLUSION: HA sync and backups serve DIFFERENT purposes.                    |
|  You need BOTH in production.                                                 |
|                                                                               |
+===============================================================================+
```

### HA Sync Configuration Reference

```bash
# Verify HA sync status on primary (10.10.X.50)
ssh admin@10.10.X.50

get system ha status

# Expected output:
# Mode: active-passive
# Group ID: 1
# Role: primary
# Peer: 10.10.X.51
# Peer status: up
# Last sync: 2026-04-09 08:45:12
# Sync status: synchronized
# Config checksum: a3b7c9... (should match peer)

# Verify on secondary (10.10.X.51)
ssh admin@10.10.X.51

get system ha status

# Expected output:
# Mode: active-passive
# Role: secondary
# Peer: 10.10.X.50
# Peer status: up
# Sync status: synchronized
# Config checksum: a3b7c9... (must match primary)
```

---

## Backup Monitoring and Alerting

### SNMP Monitoring

```bash
# Configure SNMP on FortiAuthenticator for backup monitoring
# Via CLI:
config system snmp sysinfo
  set status enable
  set contact-info "pam-admin@company.com"
  set location "Datacenter - Shared Infrastructure Rack"
end

config system snmp community
  edit 1
    set name "wallix-monitoring"
    config hosts
      edit 1
        set ip 10.20.0.50 255.255.255.255
      next
    end
    set events disk-low log-full
    set trap-v2c-status enable
  next
end
```

### Syslog Integration

```bash
# Forward FortiAuthenticator logs to syslog server for backup event tracking
config system log setting
  set log-to-syslog enable
  set syslog-server "10.20.0.50"
  set syslog-port 514
  set syslog-facility local7
  set syslog-level information
end

# On syslog server (10.20.0.50), filter for backup events:
grep -i "backup" /var/log/fortiauth/fortiauth.log

# Expected entries (daily):
# 2026-04-09T02:00:01 FAC-backup backup[]: Scheduled backup started
# 2026-04-09T02:01:15 FAC-backup backup[]: Backup completed, transferred to 10.20.0.50
```

### Nagios / Zabbix Check

```bash
#!/bin/bash
# /usr/lib/nagios/plugins/check_fortiauth_backup.sh
# Nagios/Zabbix plugin to monitor FortiAuthenticator backup freshness

BACKUP_DIR="/backups/fortiauth"
WARN_HOURS=26
CRIT_HOURS=50
MIN_SIZE=1048576  # 1 MB in bytes

LATEST=$(find "${BACKUP_DIR}" -name "FAC_config_*.bak" -type f \
    -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1)

if [ -z "${LATEST}" ]; then
    echo "CRITICAL - No FortiAuthenticator backup files found"
    exit 2
fi

FILE_PATH=$(echo "${LATEST}" | cut -d' ' -f2)
FILE_EPOCH=$(echo "${LATEST}" | cut -d'.' -f1)
NOW_EPOCH=$(date +%s)
AGE_HOURS=$(( (NOW_EPOCH - FILE_EPOCH) / 3600 ))
FILE_SIZE=$(stat -c %s "${FILE_PATH}")
FILE_NAME=$(basename "${FILE_PATH}")

if [ "${FILE_SIZE}" -lt "${MIN_SIZE}" ]; then
    echo "CRITICAL - Backup ${FILE_NAME} is only $(( FILE_SIZE / 1024 )) KB (minimum: $(( MIN_SIZE / 1024 )) KB)"
    exit 2
fi

if [ "${AGE_HOURS}" -gt "${CRIT_HOURS}" ]; then
    echo "CRITICAL - Latest backup is ${AGE_HOURS}h old: ${FILE_NAME}"
    exit 2
elif [ "${AGE_HOURS}" -gt "${WARN_HOURS}" ]; then
    echo "WARNING - Latest backup is ${AGE_HOURS}h old: ${FILE_NAME}"
    exit 1
fi

echo "OK - Backup ${FILE_NAME} ($(( FILE_SIZE / 1024 / 1024 )) MB, ${AGE_HOURS}h ago)"
exit 0
```

---

## Backup Retention Policy

| Backup Type | Retention | Storage | Responsible |
|-------------|-----------|---------|-------------|
| Automated daily (SFTP) | 14 days | SFTP server (10.20.0.50) | Automated (FortiAuth max-backup) |
| Pre-upgrade manual | 90 days | SFTP + offsite | PAM administrator |
| Pre-change manual | 30 days | SFTP server | PAM administrator |
| Quarterly compliance snapshot | 1 year | Offsite / cold storage | Security team |
| Annual archive | 7 years | Cold storage / tape | Compliance team |

### Storage Estimation

```
FortiAuthenticator 6.4+ backup size (typical):
  - Small deployment (< 100 users):    ~5 MB per backup
  - Medium deployment (100-500 users):  ~12 MB per backup
  - Large deployment (500-2000 users):  ~25 MB per backup

14-day automated retention:
  Medium deployment: 12 MB x 14 = ~170 MB

Annual storage (all types):
  Automated:    12 MB x 365 = ~4.3 GB (only 14 kept = 170 MB)
  Manual:       12 MB x ~20 = ~240 MB
  Compliance:   12 MB x 4   = ~48 MB
  Total active: ~460 MB
```

---

## Security Considerations

### Backup File Protection

```
+===============================================================================+
|                  BACKUP SECURITY REQUIREMENTS                                 |
+===============================================================================+
|                                                                               |
|  1. ENCRYPTION                                                                |
|     - Always encrypt backup files (set encrypt enable)                        |
|     - Use a strong encryption password (20+ characters)                       |
|     - Store encryption password in enterprise password vault                  |
|     - Never store password alongside backup files                             |
|                                                                               |
|  2. TRANSPORT SECURITY                                                        |
|     - Use SFTP (SSH) or SCP — never FTP or TFTP in production                 |
|     - Verify SFTP server host key on first connection                         |
|     - Use SSH key authentication where possible                               |
|                                                                               |
|  3. ACCESS CONTROL                                                            |
|     - Backup directory: chmod 750 (owner + group only)                        |
|     - Backup user: dedicated service account, no shell if possible            |
|     - Restrict backup server access to authorized administrators              |
|                                                                               |
|  4. AUDIT                                                                     |
|     - Log all backup and restore operations                                   |
|     - Monitor for unauthorized restore attempts                               |
|     - Include backup verification in security audit scope                     |
|                                                                               |
|  5. OFFSITE COPIES                                                            |
|     - Copy critical backups (pre-upgrade, compliance) to offsite storage      |
|     - Ensure offsite copies are also encrypted                                |
|     - Test offsite restore procedure annually                                 |
|                                                                               |
+===============================================================================+
```

### Sensitive Data in Backups

> **Warning:** FortiAuthenticator backups contain highly sensitive data:
>
> - FortiToken seeds (used to generate OTP codes)
> - RADIUS shared secrets
> - LDAP bind credentials
> - SSL private keys
> - User personal data (names, emails, phone numbers)
>
> Treat backup files with the same security classification as the FortiAuthenticator appliance itself. Unauthorized access to a backup file could allow an attacker to clone tokens and bypass MFA.

---

## Operational Checklist

### Daily (Automated)

- [ ] Scheduled backup runs at 02:00
- [ ] Backup verification script runs at 06:00
- [ ] No alert emails received

### Weekly

- [ ] Review backup log: `/var/log/fortiauth-backup-check.log`
- [ ] Verify backup count on SFTP server (expect 7+ files)
- [ ] Check SFTP server disk space: `df -h /backups/fortiauth`

### Monthly

- [ ] Compare backup file sizes (sudden changes may indicate issues)
- [ ] Verify backup encryption password is accessible in vault
- [ ] Review FortiAuthenticator admin audit log for unauthorized changes
- [ ] Verify HA sync status between primary and secondary

### Quarterly

- [ ] Perform test restore on secondary appliance (10.10.X.51)
- [ ] Document restore test results
- [ ] Verify user count and RADIUS client count match primary
- [ ] Test RADIUS authentication after restore
- [ ] Update this document if procedures have changed
- [ ] Archive compliance snapshot to offsite storage

### Annually

- [ ] Full disaster recovery drill (simulate primary loss)
- [ ] Review and update backup retention policy
- [ ] Rotate backup encryption password
- [ ] Verify offsite backup accessibility
- [ ] Update appliance hardware lifecycle plan

---

## Troubleshooting

### Backup Fails to Transfer

```bash
# Symptom: Backup runs but file does not appear on SFTP server

# 1. Test SFTP connectivity from FortiAuthenticator
# Via CLI:
execute ping 10.20.0.50
# Expected: packets received

# 2. Test SFTP authentication manually
# From a test machine on the same subnet:
sftp backup-user@10.20.0.50
# If password auth fails, check /etc/ssh/sshd_config on SFTP server:
#   PasswordAuthentication yes (or use key-based auth)

# 3. Check SFTP server disk space
ssh backup-user@10.20.0.50 "df -h /backups/fortiauth"
# If full, clean old backups or extend storage

# 4. Check SFTP directory permissions
ssh backup-user@10.20.0.50 "ls -ld /backups/fortiauth"
# Expected: drwxr-x--- backup-user backup
# Fix: chmod 750 /backups/fortiauth && chown backup-user:backup /backups/fortiauth

# 5. Check FortiAuthenticator system log
# Web UI: Log > System Events > filter by "backup"
# Look for error messages indicating transfer failure

# 6. Verify firewall rules allow SSH/SFTP (port 22) from 10.10.X.50 to 10.20.0.50
```

### Restore Fails

```bash
# Symptom: Restore operation fails or appliance does not come back

# 1. Wrong encryption password
#    Error: "Invalid password" or "Decryption failed"
#    Solution: Retrieve correct password from vault. There is no recovery
#    if the password is lost — use a different backup file.

# 2. Firmware version mismatch
#    Backups from newer firmware may not restore on older firmware.
#    Solution: Upgrade firmware first, then restore configuration.
#    Backups from older firmware generally restore on newer firmware.

# 3. Appliance does not boot after restore
#    a. Wait 10 minutes (restore can take time with large user databases)
#    b. Connect via console cable to see boot messages
#    c. If stuck, power cycle and attempt restore again
#    d. If repeated failure, factory reset and restore:
#       execute factoryreset
#       # After factory reset, restore backup via Web UI (https://10.10.X.50)

# 4. Partial restore (users missing)
#    Verify the backup file includes user data:
#    - Check backup was taken with "User data and FortiToken assignments" option
#    - Check backup file size (user data significantly increases file size)
#    - Try restoring a different backup file
```

### HA Sync Issues After Restore

```bash
# Symptom: After restoring primary, secondary does not sync

# 1. Check HA status on both appliances
ssh admin@10.10.X.50
get system ha status

ssh admin@10.10.X.51
get system ha status

# 2. If config checksums do not match, force resync
# On PRIMARY:
execute ha sync start

# 3. If sync fails, reconfigure HA on secondary
# On SECONDARY (10.10.X.51):
config system ha
  set mode active-passive
  set group-id 1
  set peer-ip 10.10.X.50
  set priority 100
end

# 4. Verify sync completes
# Wait 2-3 minutes, then check:
get system ha status
# Config checksum must match between primary and secondary
```

---

## See Also

**Related Sections:**
- [06 - FortiAuthenticator Integration](../06-authentication/fortiauthenticator-integration.md) - MFA setup and configuration
- [30 - Backup and Restore](./README.md) - WALLIX Bastion backup procedures
- [29 - Disaster Recovery](../29-disaster-recovery/README.md) - DR runbooks and RTO/RPO
- [11 - High Availability](../11-high-availability/README.md) - HA architecture

**Related Documentation:**
- [Install Guide](/install/HOWTO.md) - Multi-site deployment

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)
- [Fortinet FortiAuthenticator Admin Guide](https://docs.fortinet.com/product/fortiauthenticator)

---

*Document Version: 1.0*
*Last Updated: April 2026*
