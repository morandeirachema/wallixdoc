# Operational Runbooks

This section provides step-by-step operational procedures for managing WALLIX Bastion in production environments.

---

## Table of Contents

1. [Daily Operations Checklist](#daily-operations-checklist)
2. [Weekly Health Checks](#weekly-health-checks)
3. [Monthly Maintenance](#monthly-maintenance)
4. [Quarterly Reviews](#quarterly-reviews)
5. [Password Rotation Procedures](#password-rotation-procedures)
6. [Backup & Recovery Procedures](#backup--recovery-procedures)
7. [Database Maintenance](#database-maintenance)
8. [Cluster Maintenance](#cluster-maintenance)
9. [Certificate Management](#certificate-management)
10. [Log Management](#log-management)
11. [Emergency Procedures](#emergency-procedures)

---

## Daily Operations Checklist

### Morning Health Check (5-10 minutes)

```
┌─────────────────────────────────────────────────────────────────┐
│                    DAILY HEALTH CHECK                           │
├─────────────────────────────────────────────────────────────────┤
│  □ 1. Verify service status                                    │
│  □ 2. Check cluster health (if HA)                             │
│  □ 3. Review disk space usage                                  │
│  □ 4. Check active sessions count                              │
│  □ 5. Review failed login attempts                             │
│  □ 6. Check pending approval requests                          │
│  □ 7. Verify replication status (if multi-site)                │
│  □ 8. Review alerting system status                            │
└─────────────────────────────────────────────────────────────────┘
```

#### Step-by-Step Procedure

**1. Verify Service Status**
```bash
# Check WALLIX Bastion service
systemctl status wallix-bastion

# Quick status overview
wabadmin status

# Expected output: All services should show "active (running)"
```

**2. Check Cluster Health (HA Deployments)**
```bash
# View cluster status
crm status

# Check for any failed resources
crm_mon -1 | grep -E "(Failed|Stopped)"

# Expected: All resources "Started", no failures
```

**3. Review Disk Space**
```bash
# Check disk usage
df -h /var/lib/wallix /var/log/wallix

# Check session recording storage
du -sh /var/lib/wallix/recordings/

# Alert thresholds:
# - Warning: > 70% used
# - Critical: > 85% used
```

**4. Check Active Sessions**
```bash
# List active sessions
wabadmin sessions --status active

# Count active sessions
wabadmin sessions --status active | wc -l
```

**5. Review Failed Login Attempts**
```bash
# Check recent failed logins (last 24 hours)
wabadmin audit --filter "event_type=authentication_failure" --last 24h

# Alert if > 10 failures from same IP
wabadmin audit --filter "event_type=authentication_failure" --last 24h | \
  awk '{print $3}' | sort | uniq -c | sort -rn | head -10
```

**6. Check Pending Approvals**
```bash
# List pending approval requests
wabadmin approvals --status pending

# Alert if requests older than 4 hours
```

**7. Verify Replication Status**
```bash
# Check MariaDB replication lag
sudo mysql -e "SHOW SLAVE STATUS\G"

# Check sync status
wabadmin sync-status

# Alert if lag > 1MB or state != 'streaming'
```

**8. Review Alerting System**
```bash
# Verify SNMP agent running (if configured)
systemctl status snmpd

# Check syslog forwarding (if configured)
logger -p local0.info "WALLIX health check test"
# Verify message appears in SIEM
```

### Daily Checklist Template

| Time | Task | Status | Notes |
|------|------|--------|-------|
| 08:00 | Service status check | ☐ | |
| 08:05 | Cluster health | ☐ | |
| 08:10 | Disk space review | ☐ | |
| 08:15 | Active sessions | ☐ | |
| 08:20 | Failed logins review | ☐ | |
| 08:25 | Pending approvals | ☐ | |
| 08:30 | Replication status | ☐ | |
| 17:00 | End of day audit review | ☐ | |

---

## Weekly Health Checks

### Weekly Maintenance Window (30-60 minutes)

```
┌─────────────────────────────────────────────────────────────────┐
│                    WEEKLY HEALTH CHECK                          │
├─────────────────────────────────────────────────────────────────┤
│  □ 1. Full system health assessment                            │
│  □ 2. Password rotation status review                          │
│  □ 3. Session recording integrity check                        │
│  □ 4. License usage review                                     │
│  □ 5. Security patch assessment                                │
│  □ 6. Backup verification                                      │
│  □ 7. Performance baseline review                              │
│  □ 8. Audit log review                                         │
│  □ 9. User access review (sample)                              │
│  □ 10. LDAP/AD sync verification                               │
└─────────────────────────────────────────────────────────────────┘
```

#### Detailed Procedures

**1. Full System Health Assessment**
```bash
# Comprehensive status
wabadmin health-check

# System resources
top -bn1 | head -20
free -h
iostat -x 1 3

# Network connectivity to targets (sample)
wabadmin connectivity-test --sample 10
```

**2. Password Rotation Status**
```bash
# Check accounts with rotation enabled
wabadmin accounts --filter "auto_rotation=true" --status

# List accounts with failed rotations
wabadmin accounts --filter "rotation_status=failed"

# List accounts approaching password expiry
wabadmin accounts --filter "password_age > 80%"
```

**3. Session Recording Integrity**
```bash
# Verify recording integrity for recent sessions
wabadmin recordings --verify --last 7d

# Check for orphaned recordings
wabadmin recordings --orphaned

# Storage growth rate
du -sh /var/lib/wallix/recordings/
# Compare with last week
```

**4. License Usage Review**
```bash
# Current license usage
wabadmin license-info

# License capacity report
wabadmin license-usage --report

# Alert if usage > 80% of licensed capacity
```

**5. Security Patch Assessment**
```bash
# Check for available updates
apt update
apt list --upgradable 2>/dev/null | grep -E "(wallix|security)"

# Review WALLIX security bulletins
# https://support.wallix.com/security-bulletins
```

**6. Backup Verification**
```bash
# List recent backups
ls -la /var/backup/wallix/

# Verify backup integrity
wabadmin backup --verify --latest

# Test restore to staging (monthly - see monthly procedures)
```

**7. Performance Baseline**
```bash
# Session establishment time
wabadmin performance --metric session_establishment --last 7d

# Average session latency
wabadmin performance --metric latency --last 7d

# Compare with baseline - alert if > 20% degradation
```

**8. Audit Log Review**
```bash
# Summary of events by type
wabadmin audit --summary --last 7d

# Privileged operations review
wabadmin audit --filter "event_type=admin_action" --last 7d

# Failed operations
wabadmin audit --filter "status=failed" --last 7d
```

**9. User Access Review (Sample)**
```bash
# List users with admin privileges
wabadmin users --filter "role=admin"

# Check for dormant accounts (no login > 30 days)
wabadmin users --filter "last_login > 30d"

# Review recently added users
wabadmin users --filter "created_date < 7d"
```

**10. LDAP/AD Sync Verification**
```bash
# Check last sync status
wabadmin ldap-sync --status

# Force sync and verify
wabadmin ldap-sync --run --verify

# Compare user counts
wabadmin users --count
# Compare with AD user count
```

### Weekly Checklist Template

| Day | Task | Owner | Status | Notes |
|-----|------|-------|--------|-------|
| Mon | Full health assessment | | ☐ | |
| Mon | Password rotation review | | ☐ | |
| Tue | Recording integrity | | ☐ | |
| Tue | License review | | ☐ | |
| Wed | Security patches | | ☐ | |
| Wed | Backup verification | | ☐ | |
| Thu | Performance review | | ☐ | |
| Thu | Audit log review | | ☐ | |
| Fri | User access review | | ☐ | |
| Fri | LDAP sync verification | | ☐ | |

---

## Monthly Maintenance

### Monthly Maintenance Procedures (2-4 hours)

```
┌─────────────────────────────────────────────────────────────────┐
│                   MONTHLY MAINTENANCE                           │
├─────────────────────────────────────────────────────────────────┤
│  □ 1. Full backup with offsite copy                            │
│  □ 2. Backup restore test (staging)                            │
│  □ 3. Database optimization                                    │
│  □ 4. Log rotation and archival                                │
│  □ 5. Certificate expiry review                                │
│  □ 6. Security vulnerability scan                              │
│  □ 7. Capacity planning review                                 │
│  □ 8. Full user access review                                  │
│  □ 9. Policy and authorization review                          │
│  □ 10. Documentation update                                    │
│  □ 11. Disaster recovery test (quarterly)                      │
└─────────────────────────────────────────────────────────────────┘
```

#### Detailed Procedures

**1. Full Backup with Offsite Copy**
```bash
# Create full backup
wabadmin backup --full --output /var/backup/wallix/monthly/

# Encrypt backup for offsite transfer
gpg --encrypt --recipient backup@company.com \
  /var/backup/wallix/monthly/wallix-backup-$(date +%Y%m%d).tar.gz

# Transfer to offsite storage
rsync -avz --progress \
  /var/backup/wallix/monthly/*.gpg \
  backup-server:/offsite/wallix/

# Verify transfer
sha256sum /var/backup/wallix/monthly/*.tar.gz > checksums.txt
# Compare with remote checksums
```

**2. Backup Restore Test**
```bash
# On staging environment:
# 1. Stop services
systemctl stop wallix-bastion

# 2. Restore backup
wabadmin restore --input /path/to/backup.tar.gz --verify

# 3. Start services
systemctl start wallix-bastion

# 4. Verify functionality
wabadmin health-check
wabadmin connectivity-test --sample 5

# 5. Document results
# Record: restore time, issues encountered, verification status
```

**3. Database Optimization**
```bash
# Analyze tables
sudo mysql wallix -e "ANALYZE TABLE users, sessions, audit_log;"

# Optimize tables
sudo mysql wallix -e "OPTIMIZE TABLE users, sessions, audit_log;"

# Check for table sizes
sudo mysql wallix -e "
SELECT table_name,
  ROUND(((data_length + index_length) / 1024 / 1024), 2) AS total_size_mb,
  ROUND((data_length / 1024 / 1024), 2) AS data_size_mb,
  ROUND((index_length / 1024 / 1024), 2) AS index_size_mb
FROM information_schema.tables
WHERE table_schema = 'wallix'
ORDER BY (data_length + index_length) DESC
LIMIT 20;"

# Repair tables if needed (during maintenance window)
sudo mysql wallix -e "CHECK TABLE users, sessions, audit_log;"
```

**4. Log Rotation and Archival**
```bash
# Force log rotation
logrotate -f /etc/logrotate.d/wallix

# Archive old logs (> 90 days)
find /var/log/wallix -name "*.gz" -mtime +90 -exec mv {} /archive/wallix/logs/ \;

# Compress archived logs
tar -czvf /archive/wallix/logs-$(date +%Y%m).tar.gz /archive/wallix/logs/*.gz

# Verify archive
tar -tzvf /archive/wallix/logs-$(date +%Y%m).tar.gz | head

# Clean up
rm -f /archive/wallix/logs/*.gz
```

**5. Certificate Expiry Review**
```bash
# Check all certificates
wabadmin certificates --list --expiry

# Identify certificates expiring within 60 days
wabadmin certificates --list --expiring 60d

# For each expiring certificate:
# 1. Generate renewal request
# 2. Submit to CA
# 3. Schedule installation

# Check SSL certificate
echo | openssl s_client -connect localhost:443 2>/dev/null | \
  openssl x509 -noout -dates
```

**6. Security Vulnerability Scan**
```bash
# Update vulnerability database
apt update

# Check for security updates
apt list --upgradable 2>/dev/null | grep -i security

# Run security audit
lynis audit system --quick

# Review findings and remediate critical issues
```

**7. Capacity Planning Review**
```bash
# Current resource usage trends
wabadmin report --type capacity --period 30d

# Session growth rate
wabadmin report --type sessions --period 30d --trend

# Storage growth projection
wabadmin report --type storage --period 30d --projection 90d

# License usage trend
wabadmin report --type license --period 30d --trend
```

**8. Full User Access Review**
```bash
# Export all users with their access
wabadmin users --export --format csv > /tmp/user-access-review.csv

# Identify privileged users
wabadmin users --filter "role IN (admin,auditor,approver)" --export

# Review and validate with department heads
# Document approved users and any changes required
```

---

## Password Rotation Procedures

### Automatic Password Rotation

**Enable Automatic Rotation for an Account**
```bash
# Via CLI
wabadmin account set <account_id> \
  --auto-rotation enabled \
  --rotation-period 30d \
  --rotation-time "02:00"

# Verify configuration
wabadmin account show <account_id> --rotation-config
```

**Monitor Rotation Status**
```bash
# Check rotation queue
wabadmin rotation --queue

# View rotation history
wabadmin rotation --history --last 7d

# Check failed rotations
wabadmin rotation --failed
```

### Manual Password Rotation

**Single Account Rotation**
```bash
# 1. Initiate rotation
wabadmin account rotate <account_id>

# 2. Verify new password works
wabadmin account test <account_id>

# 3. Check rotation status
wabadmin account show <account_id> --last-rotation
```

**Bulk Password Rotation**
```bash
# Rotate all accounts in a target group
wabadmin rotation --target-group "production-servers" --execute

# Rotate all accounts with passwords > 90 days old
wabadmin rotation --filter "password_age > 90d" --execute

# Dry run first
wabadmin rotation --filter "password_age > 90d" --dry-run
```

### Rotation Failure Remediation

```
┌─────────────────────────────────────────────────────────────────┐
│                ROTATION FAILURE DECISION TREE                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Rotation Failed                                                │
│       │                                                         │
│       ▼                                                         │
│  Check connectivity to target                                   │
│       │                                                         │
│       ├─── Connection failed ──► Check network/firewall         │
│       │                                                         │
│       ├─── Auth failed ──► Verify current password in vault     │
│       │                         │                               │
│       │                         └─► Manual password reset       │
│       │                                                         │
│       ├─── Permission denied ──► Check account privileges       │
│       │                                                         │
│       └─── Timeout ──► Check target system load                 │
│                        Increase timeout if needed               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Remediation Steps**
```bash
# 1. Identify failure reason
wabadmin rotation --show <rotation_id> --verbose

# 2. Test connectivity
wabadmin connectivity-test --account <account_id>

# 3. Verify current credentials
wabadmin account checkout <account_id> --verify-only

# 4. If credentials invalid, perform emergency rotation
wabadmin account rotate <account_id> --force --new-password "$(pwgen -s 24 1)"

# 5. Retry original rotation
wabadmin rotation --retry <rotation_id>
```

---

## Backup & Recovery Procedures

### Backup Types

| Backup Type | Frequency | Retention | Contents |
|-------------|-----------|-----------|----------|
| Configuration | Daily | 30 days | Config files, policies, authorizations |
| Database | Daily | 30 days | MariaDB dump |
| Full | Weekly | 90 days | All data, recordings, configs |
| Offsite | Monthly | 1 year | Encrypted full backup |

### Backup Procedure

**Daily Configuration Backup**
```bash
#!/bin/bash
# /opt/scripts/daily-backup.sh

BACKUP_DIR="/var/backup/wallix/daily"
DATE=$(date +%Y%m%d)

# Create backup
wabadmin backup --config-only --output "${BACKUP_DIR}/config-${DATE}.tar.gz"

# Verify backup
wabadmin backup --verify "${BACKUP_DIR}/config-${DATE}.tar.gz"

# Clean old backups (> 30 days)
find "${BACKUP_DIR}" -name "config-*.tar.gz" -mtime +30 -delete

# Log result
logger -t wallix-backup "Daily config backup completed: config-${DATE}.tar.gz"
```

**Weekly Full Backup**
```bash
#!/bin/bash
# /opt/scripts/weekly-backup.sh

BACKUP_DIR="/var/backup/wallix/weekly"
DATE=$(date +%Y%m%d)

# Stop non-essential services (optional, for consistency)
# wabadmin maintenance-mode --enable

# Create full backup
wabadmin backup --full --output "${BACKUP_DIR}/full-${DATE}.tar.gz"

# Include session recordings
tar -czvf "${BACKUP_DIR}/recordings-${DATE}.tar.gz" \
  /var/lib/wallix/recordings/

# Verify backup
wabadmin backup --verify "${BACKUP_DIR}/full-${DATE}.tar.gz"

# Re-enable services
# wabadmin maintenance-mode --disable

# Clean old backups (> 90 days)
find "${BACKUP_DIR}" -name "full-*.tar.gz" -mtime +90 -delete

# Log result
logger -t wallix-backup "Weekly full backup completed: full-${DATE}.tar.gz"
```

### Recovery Procedures

**Configuration Recovery (Partial)**
```bash
# 1. Stop services
systemctl stop wallix-bastion

# 2. Restore configuration only
wabadmin restore --config-only --input /var/backup/wallix/daily/config-YYYYMMDD.tar.gz

# 3. Start services
systemctl start wallix-bastion

# 4. Verify
wabadmin health-check
```

**Full System Recovery**
```bash
# 1. Prepare new system (if needed)
# Install Debian 12, basic packages

# 2. Stop services
systemctl stop wallix-bastion

# 3. Restore full backup
wabadmin restore --full --input /var/backup/wallix/weekly/full-YYYYMMDD.tar.gz

# 4. Restore recordings (if needed)
tar -xzvf /var/backup/wallix/weekly/recordings-YYYYMMDD.tar.gz -C /

# 5. Update hostname/IP if changed
wabadmin config set --hostname new-hostname.example.com

# 6. Start services
systemctl start wallix-bastion

# 7. Verify all functionality
wabadmin health-check
wabadmin connectivity-test --all
```

**Database-Only Recovery**
```bash
# 1. Stop WALLIX services
systemctl stop wallix-bastion

# 2. Restore MariaDB
sudo mysql wallix < /var/backup/wallix/database-YYYYMMDD.sql

# 3. Start services
systemctl start wallix-bastion

# 4. Verify data integrity
wabadmin verify --database
```

---

## Database Maintenance

### Routine Maintenance

**Daily: Check Database Health**
```bash
# Check connections
sudo mysql -e "SHOW STATUS LIKE 'Threads_connected';"

# Check database size
sudo mysql -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb FROM information_schema.tables WHERE table_schema = 'wallix';"

# Check for long-running queries
sudo mysql -e "
SELECT id, user, host, db, time, state, info
FROM information_schema.processlist
WHERE command != 'Sleep' AND time > 300;"
```

**Weekly: Analyze and Optimize**
```bash
# Analyze all tables
sudo mysql wallix -e "ANALYZE TABLE users, sessions, audit_log;"

# Optimize tables
sudo mysql wallix -e "OPTIMIZE TABLE users, sessions, audit_log;"
```

**Monthly: Full Optimization and Check**
```bash
# During maintenance window only!
# This may lock tables temporarily

# Full optimization (reclaims space)
sudo mysql wallix -e "OPTIMIZE TABLE users, sessions, audit_log, devices, accounts;"

# Check tables for errors
sudo mysql wallix -e "CHECK TABLE users, sessions, audit_log;"

# Update statistics
sudo mysql wallix -e "ANALYZE TABLE users, sessions, audit_log;"
```

### Replication Health

**Check Replication Status**
```bash
# On primary
sudo mysql -e "SHOW MASTER STATUS;"

# Check replication lag
sudo mysql -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master)"

# On standby
sudo mysql -e "SHOW SLAVE STATUS\G"
```

**Alert Thresholds**

| Metric | Warning | Critical |
|--------|---------|----------|
| Replication lag | > 1 MB | > 10 MB |
| Connection count | > 80% max | > 95% max |
| Database size growth | > 10%/week | > 25%/week |
| Long-running queries | > 5 min | > 15 min |

---

## Cluster Maintenance

### Rolling Restart Procedure

```
┌─────────────────────────────────────────────────────────────────┐
│              CLUSTER ROLLING RESTART PROCEDURE                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Verify cluster health                                       │
│       │                                                         │
│       ▼                                                         │
│  2. Put Node B in standby                                       │
│       │                                                         │
│       ▼                                                         │
│  3. Verify failover to Node A                                   │
│       │                                                         │
│       ▼                                                         │
│  4. Perform maintenance on Node B                               │
│       │                                                         │
│       ▼                                                         │
│  5. Bring Node B online                                         │
│       │                                                         │
│       ▼                                                         │
│  6. Verify Node B healthy                                       │
│       │                                                         │
│       ▼                                                         │
│  7. Put Node A in standby                                       │
│       │                                                         │
│       ▼                                                         │
│  8. Perform maintenance on Node A                               │
│       │                                                         │
│       ▼                                                         │
│  9. Bring Node A online                                         │
│       │                                                         │
│       ▼                                                         │
│  10. Verify cluster healthy                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Step-by-Step Commands**
```bash
# 1. Verify cluster health
crm status
crm_verify -L

# 2. Put Node B in standby
crm node standby node-b

# 3. Verify failover
crm status  # All resources should be on node-a

# 4. Perform maintenance on Node B
ssh node-b
apt update && apt upgrade -y
systemctl restart wallix-bastion
exit

# 5. Bring Node B online
crm node online node-b

# 6. Wait and verify Node B
sleep 60
crm status

# 7. Put Node A in standby
crm node standby node-a

# 8. Perform maintenance on Node A
ssh node-a
apt update && apt upgrade -y
systemctl restart wallix-bastion
exit

# 9. Bring Node A online
crm node online node-a

# 10. Final verification
crm status
wabadmin health-check
```

---

## Certificate Management

### Certificate Inventory

| Certificate | Location | Purpose | Renewal Period |
|-------------|----------|---------|----------------|
| Web SSL | /etc/wallix/ssl/server.crt | HTTPS interface | Annual |
| LDAP Client | /etc/wallix/ssl/ldap-client.crt | LDAP/AD connection | Annual |
| Syslog TLS | /etc/wallix/ssl/syslog.crt | Secure logging | Annual |
| API Client | /etc/wallix/ssl/api-client.crt | API authentication | Annual  |
| MariaDB | /var/lib/mysql/ssl/ | Database encryption | Annual |

### Certificate Renewal Procedure

```bash
# 1. Generate CSR
openssl req -new -key /etc/wallix/ssl/server.key \
  -out /tmp/server.csr \
  -subj "/CN=bastion.example.com/O=Company/C=US"

# 2. Submit to CA (internal or external)
# Obtain signed certificate

# 3. Backup current certificate
cp /etc/wallix/ssl/server.crt /etc/wallix/ssl/server.crt.bak.$(date +%Y%m%d)

# 4. Install new certificate
cp /path/to/new/server.crt /etc/wallix/ssl/server.crt

# 5. Verify certificate chain
openssl verify -CAfile /etc/wallix/ssl/ca-chain.crt /etc/wallix/ssl/server.crt

# 6. Reload services
systemctl reload wallix-bastion

# 7. Verify new certificate
echo | openssl s_client -connect localhost:443 2>/dev/null | \
  openssl x509 -noout -subject -dates
```

---

## Log Management

### Log Locations

| Log | Path | Retention |
|-----|------|-----------|
| Application | /var/log/wallix/application.log | 90 days |
| Audit | /var/log/wallix/audit.log | 1 year |
| Session | /var/log/wallix/sessions.log | 1 year |
| Authentication | /var/log/wallix/auth.log | 90 days |
| API | /var/log/wallix/api.log | 30 days |
| MariaDB | /var/log/mysql/ | 30 days |

### Log Rotation Configuration

```
# /etc/logrotate.d/wallix
/var/log/wallix/*.log {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
    create 640 wallix wallix
    postrotate
        systemctl reload wallix-bastion > /dev/null 2>&1 || true
    endscript
}

/var/log/wallix/audit.log {
    daily
    rotate 365
    compress
    delaycompress
    missingok
    notifempty
    create 640 wallix wallix
}
```

### Log Archival Procedure

```bash
#!/bin/bash
# /opt/scripts/archive-logs.sh

ARCHIVE_DIR="/archive/wallix/logs"
YEAR_MONTH=$(date +%Y%m)

# Archive logs older than 90 days
find /var/log/wallix -name "*.gz" -mtime +90 -exec mv {} ${ARCHIVE_DIR}/ \;

# Compress monthly archive
cd ${ARCHIVE_DIR}
tar -czvf logs-${YEAR_MONTH}.tar.gz *.gz
rm -f *.gz

# Transfer to long-term storage
rsync -avz logs-${YEAR_MONTH}.tar.gz archive-server:/long-term/wallix/

# Verify transfer
if ssh archive-server "test -f /long-term/wallix/logs-${YEAR_MONTH}.tar.gz"; then
    rm -f logs-${YEAR_MONTH}.tar.gz
    logger -t wallix-archive "Log archive completed: logs-${YEAR_MONTH}.tar.gz"
else
    logger -t wallix-archive -p local0.error "Log archive transfer failed!"
fi
```

---

## Emergency Procedures

### Service Not Starting

```bash
# 1. Check service status
systemctl status wallix-bastion -l

# 2. Check logs
journalctl -u wallix-bastion --since "1 hour ago" -n 100

# 3. Check disk space
df -h

# 4. Check database connectivity
sudo mysql -e "SELECT 1;"

# 5. Verify configuration
wabadmin config --verify

# 6. If configuration issue, restore last known good
wabadmin restore --config-only --input /var/backup/wallix/daily/config-YYYYMMDD.tar.gz

# 7. Restart service
systemctl start wallix-bastion
```

### Cluster Split-Brain Recovery

```bash
# 1. Identify current state
crm status

# 2. Identify which node has latest data
# Check MariaDB on each node
sudo mysql -e "SHOW SLAVE STATUS\G" | grep "Exec_Master_Log_Pos"

# 3. Force one node as primary
crm node standby <outdated-node>

# 4. Clean up resources
crm resource cleanup

# 5. Bring standby back
crm node online <outdated-node>

# 6. Verify synchronization
crm status
wabadmin sync-status
```

### Emergency Session Termination

```bash
# List all active sessions
wabadmin sessions --status active

# Terminate specific session
wabadmin session kill <session_id>

# Terminate all sessions for a user
wabadmin sessions --filter "user=compromised_user" --kill-all

# Terminate all sessions (emergency)
wabadmin sessions --kill-all --confirm
```

### Emergency Access Bypass

```bash
# WARNING: Use only in documented emergency scenarios
# Requires local console access

# 1. Access local console (not via WALLIX)
# SSH directly to target or use ILO/DRAC/IPMI

# 2. Document the bypass
# - Reason for bypass
# - Time of bypass
# - Actions taken
# - Person authorizing

# 3. After emergency, review all actions
wabadmin audit --target <target> --time-range "emergency_start,emergency_end"

# 4. Reset any credentials that may have been exposed
wabadmin account rotate <account_id> --force
```

---

## Vendor Maintenance Procedures

### Scheduled Vendor Access Windows

```
+===============================================================================+
|                   VENDOR MAINTENANCE PROCEDURES                              |
+===============================================================================+

  PRE-MAINTENANCE CHECKLIST
  =========================

  Before granting vendor access:
  +------------------------------------------------------------------------+
  | [ ] Verify valid change ticket/work order                              |
  | [ ] Confirm scheduled maintenance window                               |
  | [ ] Notify affected system owners                                      |
  | [ ] Create/enable time-limited authorization                           |
  | [ ] Enable enhanced monitoring for vendor sessions                     |
  | [ ] Assign internal observer (4-eyes if required)                      |
  | [ ] Document expected activities                                       |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CREATE TEMPORARY VENDOR ACCESS
  ==============================

  Via CLI:
  +------------------------------------------------------------------------+
  | # Create time-limited authorization for vendor                         |
  | wabadmin authorization create \                                        |
  |   --name "vendor-maint-CHG123456" \                                    |
  |   --user-group "vendor-company-name" \                                 |
  |   --target-group "maintenance-targets" \                               |
  |   --start-time "2024-01-27T22:00:00" \                                 |
  |   --end-time "2024-01-28T02:00:00" \                                   |
  |   --approval-required true \                                           |
  |   --recording true \                                                   |
  |   --description "Maintenance window CHG123456"                         |
  |                                                                        |
  | # Verify authorization created                                         |
  | wabadmin authorization show "vendor-maint-CHG123456"                   |
  +------------------------------------------------------------------------+

  Via API:
  +------------------------------------------------------------------------+
  | curl -X POST "https://wallix/api/v2/authorizations" \                  |
  |   -H "Authorization: Bearer $TOKEN" \                                  |
  |   -H "Content-Type: application/json" \                                |
  |   -d '{                                                                |
  |     "name": "vendor-maint-CHG123456",                                  |
  |     "user_group": "vendor-company-name",                               |
  |     "target_group": "maintenance-targets",                             |
  |     "valid_from": "2024-01-27T22:00:00Z",                              |
  |     "valid_until": "2024-01-28T02:00:00Z",                             |
  |     "approval_required": true,                                         |
  |     "is_recorded": true                                                |
  |   }'                                                                   |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  DURING MAINTENANCE MONITORING
  =============================

  +------------------------------------------------------------------------+
  | # Monitor active vendor sessions                                       |
  | watch -n 10 'wabadmin sessions --filter "user_group=vendor-*"'         |
  |                                                                        |
  | # Real-time session view (if Web UI available)                         |
  | # Navigate to: Monitoring > Active Sessions > Filter by user group     |
  |                                                                        |
  | # Enable command alerts for specific patterns                          |
  | wabadmin alert create \                                                |
  |   --name "vendor-critical-commands" \                                  |
  |   --session-filter "user_group=vendor-*" \                             |
  |   --command-pattern "(rm -rf|shutdown|reboot|format)" \                |
  |   --action "notify,log"                                                |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  POST-MAINTENANCE CLEANUP
  ========================

  +------------------------------------------------------------------------+
  | # Disable/delete temporary authorization                               |
  | wabadmin authorization delete "vendor-maint-CHG123456"                 |
  |                                                                        |
  | # Verify no active vendor sessions                                     |
  | wabadmin sessions --filter "user_group=vendor-*" --status active       |
  |                                                                        |
  | # Rotate passwords on accessed accounts                                |
  | wabadmin rotation --target-group "maintenance-targets" --execute       |
  |                                                                        |
  | # Generate maintenance activity report                                 |
  | wabadmin report --type session-activity \                              |
  |   --filter "user_group=vendor-*" \                                     |
  |   --time-range "2024-01-27T22:00:00,2024-01-28T02:00:00" \             |
  |   --output "/reports/vendor-maint-CHG123456.pdf"                       |
  |                                                                        |
  | # Review and archive session recordings                                |
  | wabadmin recordings --tag "CHG123456" \                                |
  |   --time-range "2024-01-27T22:00:00,2024-01-28T02:00:00"               |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Disaster Recovery Scenarios

### DR Scenario Runbooks

```
+===============================================================================+
|                   DISASTER RECOVERY SCENARIOS                                |
+===============================================================================+

  SCENARIO 1: PRIMARY SITE FAILURE
  ================================

  Symptoms:
  - Primary WALLIX cluster unreachable
  - Users cannot authenticate
  - Active sessions disconnected

  Recovery Steps:
  +------------------------------------------------------------------------+
  | # 1. Verify primary site is truly unavailable                          |
  | ping primary-wallix.company.com                                        |
  | telnet primary-wallix.company.com 443                                  |
  |                                                                        |
  | # 2. On secondary site - promote to primary                            |
  | # (Requires manual intervention for safety)                            |
  | wabadmin dr-promote --confirm                                          |
  |                                                                        |
  | # 3. Update DNS to point to secondary site                             |
  | # (Or update load balancer configuration)                              |
  |                                                                        |
  | # 4. Verify secondary is operational                                   |
  | wabadmin status                                                        |
  | wabadmin health-check                                                  |
  |                                                                        |
  | # 5. Notify users of failover                                          |
  | # 6. Monitor for issues                                                |
  | # 7. Document incident                                                 |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SCENARIO 2: DATABASE CORRUPTION
  ===============================

  Symptoms:
  - Service errors mentioning database
  - Authentication failures
  - Missing data in UI

  Recovery Steps:
  +------------------------------------------------------------------------+
  | # 1. Stop WALLIX services                                              |
  | systemctl stop wallix-bastion                                          |
  |                                                                        |
  | # 2. Check database status                                             |
  | sudo mysql -e "SELECT 1;"                                              |
  | sudo mysql -e "SHOW SLAVE STATUS\G"                                    |
  |                                                                        |
  | # 3. If replication is available, failover to standby                  |
  | # On standby server:                                                   |
  | sudo mysql -e "STOP SLAVE; RESET SLAVE ALL;"                           |
  |                                                                        |
  | # 4. If no standby, restore from backup                                |
  | sudo mysql wallix < /var/backup/wallix/database-YYYYMMDD.sql           |
  |                                                                        |
  | # 5. Start WALLIX services                                             |
  | systemctl start wallix-bastion                                         |
  |                                                                        |
  | # 6. Verify data integrity                                             |
  | wabadmin verify --database                                             |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SCENARIO 3: CERTIFICATE EXPIRATION (EMERGENCY)
  ==============================================

  Symptoms:
  - HTTPS certificate warnings/errors
  - Users cannot access Web UI
  - API calls failing with SSL errors

  Recovery Steps:
  +------------------------------------------------------------------------+
  | # 1. Generate self-signed certificate (temporary)                      |
  | openssl req -x509 -nodes -days 30 -newkey rsa:4096 \                   |
  |   -keyout /tmp/emergency.key -out /tmp/emergency.crt \                 |
  |   -subj "/CN=wallix.company.com"                                       |
  |                                                                        |
  | # 2. Backup current certificates                                       |
  | cp /etc/wallix/ssl/server.crt /etc/wallix/ssl/server.crt.expired       |
  | cp /etc/wallix/ssl/server.key /etc/wallix/ssl/server.key.expired       |
  |                                                                        |
  | # 3. Install emergency certificate                                     |
  | cp /tmp/emergency.crt /etc/wallix/ssl/server.crt                       |
  | cp /tmp/emergency.key /etc/wallix/ssl/server.key                       |
  | chmod 640 /etc/wallix/ssl/server.*                                     |
  |                                                                        |
  | # 4. Restart services                                                  |
  | systemctl restart wallix-bastion                                       |
  |                                                                        |
  | # 5. Verify access (users will see certificate warning)                |
  | curl -k https://localhost/api/health                                   |
  |                                                                        |
  | # 6. Expedite proper certificate renewal                               |
  | # Generate CSR and submit to CA immediately                            |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SCENARIO 4: CREDENTIAL VAULT BREACH SUSPECTED
  =============================================

  Symptoms:
  - Unauthorized access detected
  - Suspicious audit log entries
  - Security alert from SIEM

  Recovery Steps:
  +------------------------------------------------------------------------+
  | # 1. IMMEDIATELY terminate all active sessions                         |
  | wabadmin sessions --kill-all --confirm                                 |
  |                                                                        |
  | # 2. Disable all vendor and external accounts                          |
  | wabadmin users --filter "type=external" --disable-all                  |
  |                                                                        |
  | # 3. Rotate ALL managed credentials                                    |
  | wabadmin rotation --all --force --execute                              |
  |                                                                        |
  | # 4. Change master encryption key (if key compromise suspected)        |
  | wabadmin key-management rotate-master-key --confirm                    |
  |                                                                        |
  | # 5. Export audit logs for investigation                               |
  | wabadmin audit --export --all --output /forensics/audit-export.json    |
  |                                                                        |
  | # 6. Notify security team and management                               |
  | # 7. Begin forensic investigation                                      |
  | # 8. Follow incident response procedures                               |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Monitoring Alert Response

### Alert Response Procedures

```
+===============================================================================+
|                   ALERT RESPONSE PROCEDURES                                  |
+===============================================================================+

  CRITICAL ALERTS - IMMEDIATE RESPONSE
  ====================================

  ALERT: Service Down
  +------------------------------------------------------------------------+
  | Trigger: wallix-bastion service not running                            |
  | Response Time: Immediate (< 5 minutes)                                 |
  |                                                                        |
  | Steps:                                                                 |
  | 1. Check service status: systemctl status wallix-bastion               |
  | 2. Check logs: journalctl -u wallix-bastion --since "10 min ago"       |
  | 3. Check disk space: df -h                                             |
  | 4. Check database: sudo mysql -e "SELECT 1;"                           |
  | 5. Attempt restart: systemctl restart wallix-bastion                   |
  | 6. If fails, check for config errors: wabadmin config --verify         |
  | 7. Escalate if not resolved in 15 minutes                              |
  +------------------------------------------------------------------------+

  ALERT: Cluster Node Failure
  +------------------------------------------------------------------------+
  | Trigger: Pacemaker reports node offline or failed resources            |
  | Response Time: Immediate (< 5 minutes)                                 |
  |                                                                        |
  | Steps:                                                                 |
  | 1. Check cluster status: crm status                                    |
  | 2. Verify services on surviving node are running                       |
  | 3. Check network between nodes: ping <other-node>                      |
  | 4. Check corosync: corosync-quorumtool -s                              |
  | 5. If node is recoverable, bring online: crm node online <node>        |
  | 6. If not recoverable, clean up: crm resource cleanup                  |
  | 7. Plan node recovery during maintenance window                        |
  +------------------------------------------------------------------------+

  ALERT: Multiple Authentication Failures
  +------------------------------------------------------------------------+
  | Trigger: > 10 failed logins from same IP in 5 minutes                  |
  | Response Time: < 15 minutes                                            |
  |                                                                        |
  | Steps:                                                                 |
  | 1. Identify source IP and user                                         |
  | 2. Check if legitimate user with wrong password                        |
  | 3. If suspicious, block IP at firewall                                 |
  | 4. Check for account lockout: wabadmin user show <username>            |
  | 5. Review full audit for the IP                                        |
  | 6. If attack, notify security team                                     |
  | 7. Consider adding IP to permanent block list                          |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  HIGH ALERTS - RESPONSE WITHIN 1 HOUR
  ====================================

  ALERT: Password Rotation Failures
  +------------------------------------------------------------------------+
  | Trigger: Multiple rotation failures for same account                   |
  | Response Time: < 1 hour                                                |
  |                                                                        |
  | Steps:                                                                 |
  | 1. Identify failed account: wabadmin rotation --failed                 |
  | 2. Check error details in rotation log                                 |
  | 3. Test connectivity to target: wabadmin connectivity-test <target>    |
  | 4. Verify rotation credentials are valid                               |
  | 5. Attempt manual rotation: wabadmin account rotate <account> --verbose|
  | 6. If network issue, coordinate with network team                      |
  | 7. Update ticket system with status                                    |
  +------------------------------------------------------------------------+

  ALERT: High Disk Usage
  +------------------------------------------------------------------------+
  | Trigger: Disk usage > 80%                                              |
  | Response Time: < 1 hour                                                |
  |                                                                        |
  | Steps:                                                                 |
  | 1. Identify largest consumers: du -sh /var/lib/wallix/*                |
  | 2. Check recording storage: du -sh /var/lib/wallix/recordings/         |
  | 3. Check log files: du -sh /var/log/wallix/                            |
  | 4. If recordings, apply retention policy                               |
  | 5. If logs, force rotation: logrotate -f /etc/logrotate.d/wallix       |
  | 6. If database, consider archiving old data                            |
  | 7. Plan storage expansion if recurring                                 |
  +------------------------------------------------------------------------+

  ALERT: Replication Lag
  +------------------------------------------------------------------------+
  | Trigger: MariaDB replication lag > 5 minutes                           |
  | Response Time: < 1 hour                                                |
  |                                                                        |
  | Steps:                                                                 |
  | 1. Check replication status on primary                                 |
  | 2. Check network between primary and standby                           |
  | 3. Check standby server health (CPU, disk I/O)                         |
  | 4. Check for long-running queries blocking replication                 |
  | 5. If network issue, coordinate with network team                      |
  | 6. If standby overloaded, consider query offloading                    |
  | 7. Document and monitor trend                                          |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MEDIUM ALERTS - RESPONSE WITHIN 24 HOURS
  ========================================

  ALERT: Certificate Expiring
  +------------------------------------------------------------------------+
  | Trigger: Certificate expires in < 30 days                              |
  | Response Time: < 24 hours (start renewal process)                      |
  |                                                                        |
  | Steps:                                                                 |
  | 1. Identify expiring certificate                                       |
  | 2. Generate CSR for renewal                                            |
  | 3. Submit to CA for new certificate                                    |
  | 4. Schedule installation during maintenance window                     |
  | 5. Update certificate tracking system                                  |
  +------------------------------------------------------------------------+

  ALERT: License Threshold
  +------------------------------------------------------------------------+
  | Trigger: License usage > 80% of capacity                               |
  | Response Time: < 24 hours                                              |
  |                                                                        |
  | Steps:                                                                 |
  | 1. Review current license usage: wabadmin license-info                 |
  | 2. Identify growth trend                                               |
  | 3. Review and remove unused accounts/devices                           |
  | 4. Contact WALLIX sales for license expansion quote                    |
  | 5. Plan capacity increase before hitting limit                         |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Detailed Runbooks

For specific operational scenarios, see these detailed guides:

| Runbook | Description |
|---------|-------------|
| [Backup & Recovery](./backup-recovery.md) | Comprehensive backup strategy and restore procedures |
| [Failover Testing](./failover-testing.md) | HA cluster failover validation procedures |
| [Alert Escalation](./alert-escalation.md) | Alert response procedures and escalation paths |
| [Breakglass Procedures](./breakglass-procedures.md) | Emergency access when normal auth fails |
| [Emergency Vendor Access](./emergency-vendor-access.md) | OT emergency vendor access procedures |

---

## Appendix: Quick Reference Commands

### Service Management
```bash
systemctl start wallix-bastion
systemctl stop wallix-bastion
systemctl restart wallix-bastion
systemctl status wallix-bastion
```

### Status Commands
```bash
wabadmin status
wabadmin health-check
wabadmin license-info
crm status
```

### User Management
```bash
wabadmin users --list
wabadmin user add <username>
wabadmin user disable <username>
wabadmin user delete <username>
```

### Session Management
```bash
wabadmin sessions --active
wabadmin session kill <id>
wabadmin recordings --list
```

### Backup/Restore
```bash
wabadmin backup --full --output /path/to/backup.tar.gz
wabadmin restore --full --input /path/to/backup.tar.gz
wabadmin backup --verify /path/to/backup.tar.gz
```

---

## Next Steps

Continue to [31 - FAQ & Known Issues](../31-faq-known-issues/README.md) for common questions and troubleshooting tips.

---

*Document Version: 1.0*
*Last Updated: January 2026*
