# Disaster Recovery Runbook

This comprehensive runbook provides step-by-step procedures for disaster recovery of WALLIX Bastion 12.x deployments. It covers all failure scenarios from single node recovery to complete multi-site failover.

---

## Table of Contents

1. [DR Overview](#dr-overview)
2. [DR Architecture](#dr-architecture)
3. [Failure Scenarios](#failure-scenarios)
4. [Pre-Disaster Preparation](#pre-disaster-preparation)
5. [Single Node Recovery](#single-node-recovery)
6. [HA Cluster Failover](#ha-cluster-failover)
7. [Multi-Site Failover](#multi-site-failover)
8. [Database Recovery](#database-recovery)
9. [Configuration Recovery](#configuration-recovery)
10. [Encryption Key Recovery](#encryption-key-recovery)
11. [Session Recording Recovery](#session-recording-recovery)
12. [Split-Brain Recovery](#split-brain-recovery)
13. [Network Isolation Recovery](#network-isolation-recovery)
14. [Post-Recovery Validation](#post-recovery-validation)
15. [DR Testing Procedures](#dr-testing-procedures)

---

## DR Overview

### RTO/RPO Definitions

| Metric | Definition | WALLIX Target |
|--------|------------|---------------|
| **RTO** (Recovery Time Objective) | Maximum acceptable time to restore service | Varies by scenario |
| **RPO** (Recovery Point Objective) | Maximum acceptable data loss (time) | Varies by configuration |
| **MTTR** (Mean Time To Repair) | Average time to restore service | Tracked per incident |
| **MTBF** (Mean Time Between Failures) | Average uptime between failures | Target: 99.99% |

### Recovery Tiers

```
+==============================================================================+
|                         RECOVERY TIER DEFINITIONS                             |
+==============================================================================+
|                                                                               |
|  TIER 1: CRITICAL (RTO < 15 min, RPO = 0)                                    |
|  ========================================                                     |
|  - Active user sessions                                                       |
|  - Authentication services                                                    |
|  - Password checkout operations                                               |
|  - Active session recordings                                                  |
|                                                                               |
|  TIER 2: HIGH PRIORITY (RTO < 1 hour, RPO < 5 min)                           |
|  =================================================                            |
|  - Credential vault access                                                    |
|  - Password rotation operations                                               |
|  - Audit logging                                                              |
|  - Session metadata                                                           |
|                                                                               |
|  TIER 3: STANDARD (RTO < 4 hours, RPO < 1 hour)                              |
|  ===============================================                              |
|  - Historical session recordings                                              |
|  - Reporting and analytics                                                    |
|  - Non-critical integrations                                                  |
|                                                                               |
|  TIER 4: LOW PRIORITY (RTO < 24 hours, RPO < 24 hours)                       |
|  =====================================================                        |
|  - Archived recordings                                                        |
|  - Historical audit data                                                      |
|  - Statistical reports                                                        |
|                                                                               |
+==============================================================================+
```

### RTO Estimates by Scenario

| Scenario | Estimated RTO | RPO | Complexity |
|----------|---------------|-----|------------|
| Single node restart | 5-10 minutes | 0 | Low |
| HA automatic failover | 30-60 seconds | 0 (sync mode) | Automatic |
| HA manual failover | 5-15 minutes | 0 (sync mode) | Low |
| Single node from backup | 30-60 minutes | Last backup | Medium |
| Database point-in-time recovery | 1-2 hours | Chosen point | Medium |
| Multi-site failover | 15-30 minutes | < 5 minutes (async) | Medium |
| Complete rebuild from backup | 2-4 hours | Last backup | High |
| Encryption key recovery (HSM) | 1-4 hours | 0 | High |
| Split-brain resolution | 30-60 minutes | Varies | High |

---

## DR Architecture

### Multi-Site DR Architecture

```
+==============================================================================+
|                      DISASTER RECOVERY ARCHITECTURE                           |
+==============================================================================+
|                                                                               |
|     SITE A (PRIMARY)                          SITE B (DR)                    |
|     Headquarters                              Secondary Data Center           |
|     ================                          =====================          |
|                                                                               |
|  +---------------------------+            +---------------------------+      |
|  |   WALLIX HA CLUSTER       |            |   WALLIX HA CLUSTER       |      |
|  |   (Active)                |            |   (Standby)               |      |
|  |                           |            |                           |      |
|  |  +-------+   +-------+   |            |  +-------+   +-------+   |      |
|  |  | Node1 |   | Node2 |   |            |  | Node1 |   | Node2 |   |      |
|  |  | (Pri) |<->| (Sec) |   |            |  | (Pri) |<->| (Sec) |   |      |
|  |  +-------+   +-------+   |            |  +-------+   +-------+   |      |
|  |       |                  |            |       |                  |      |
|  |  +----+----+             |            |  +----+----+             |      |
|  |  |PostgreSQL|            |            |  |PostgreSQL|            |      |
|  |  |(Primary) |<-----------+------------+->|(Replica) |            |      |
|  |  +---------+  Async Repl |            |  +---------+             |      |
|  +---------------------------+            +---------------------------+      |
|           |                                        |                         |
|           |                                        |                         |
|  +---------------------------+            +---------------------------+      |
|  |   BACKUP STORAGE          |            |   BACKUP STORAGE          |      |
|  |   /backup/wallix/         |            |   /backup/wallix/         |      |
|  |                           |   rsync    |                           |      |
|  |   - Daily configs         |<---------->|   - Replicated backups    |      |
|  |   - Weekly full           |            |   - Offsite copies        |      |
|  |   - WAL archives          |            |   - WAL archives          |      |
|  +---------------------------+            +---------------------------+      |
|                                                                               |
|  +---------------------------------------------------------------------------+
|  |                         OFFSITE BACKUP (CLOUD/TAPE)                       |
|  |                                                                           |
|  |   - Monthly encrypted backups                                             |
|  |   - Master key escrow                                                     |
|  |   - Configuration archives                                                |
|  |   - Retention: 1 year+                                                    |
|  +---------------------------------------------------------------------------+
|                                                                               |
|  NETWORK CONNECTIVITY                                                         |
|  ====================                                                         |
|                                                                               |
|  Site A <-------- Dedicated Link (1Gbps) --------> Site B                    |
|                   Latency: < 50ms                                             |
|                   Encrypted: TLS 1.3                                          |
|                                                                               |
|  DNS/GSLB: bastion.company.com                                               |
|            |                                                                  |
|            +--> site-a.bastion.company.com (Primary)                         |
|            +--> site-b.bastion.company.com (DR)                              |
|                                                                               |
+==============================================================================+
```

### Backup Storage Layout

```
+==============================================================================+
|                         BACKUP STORAGE STRUCTURE                              |
+==============================================================================+
|                                                                               |
|  /backup/wallix/                                                              |
|  |                                                                            |
|  +-- daily/                                                                   |
|  |   +-- config-20260130.tar.gz                                              |
|  |   +-- config-20260129.tar.gz                                              |
|  |   +-- ... (30 days retention)                                             |
|  |                                                                            |
|  +-- weekly/                                                                  |
|  |   +-- full-20260126.tar.gz                                                |
|  |   +-- full-20260119.tar.gz                                                |
|  |   +-- ... (12 weeks retention)                                            |
|  |                                                                            |
|  +-- monthly/                                                                 |
|  |   +-- full-202601.tar.gz.gpg                                              |
|  |   +-- full-202512.tar.gz.gpg                                              |
|  |   +-- ... (12 months retention)                                           |
|  |                                                                            |
|  +-- wal-archive/                                                             |
|  |   +-- 000000010000000000000001                                            |
|  |   +-- 000000010000000000000002                                            |
|  |   +-- ... (7 days retention)                                              |
|  |                                                                            |
|  +-- keys/                                                                    |
|  |   +-- master-key-escrow.gpg (encrypted)                                   |
|  |   +-- key-rotation-history.txt                                            |
|  |                                                                            |
|  +-- checksums/                                                               |
|      +-- sha256sums-20260130.txt                                             |
|      +-- verification-log.txt                                                |
|                                                                               |
+==============================================================================+
```

---

## Failure Scenarios

### Scenario Classification Matrix

```
+==============================================================================+
|                         FAILURE SCENARIO MATRIX                               |
+==============================================================================+
|                                                                               |
|  CATEGORY 1: HARDWARE FAILURES                                                |
|  =============================                                                |
|                                                                               |
|  +----------------+--------+-------------+----------------------------------+ |
|  | Failure        | Impact | RTO Target  | Recovery Method                  | |
|  +----------------+--------+-------------+----------------------------------+ |
|  | Disk failure   | Medium | 30-60 min   | HA failover, replace disk        | |
|  | Memory failure | Medium | 30-60 min   | HA failover, replace hardware    | |
|  | CPU failure    | Medium | 30-60 min   | HA failover, replace hardware    | |
|  | Network card   | Medium | 15-30 min   | HA failover, replace NIC         | |
|  | Power supply   | Low    | 5-15 min    | HA failover (if redundant PSU)   | |
|  | Complete node  | High   | 15-30 min   | HA failover, rebuild node        | |
|  | Storage array  | Critical| 1-4 hours  | Restore from backup              | |
|  +----------------+--------+-------------+----------------------------------+ |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  CATEGORY 2: SOFTWARE FAILURES                                                |
|  =============================                                                |
|                                                                               |
|  +----------------+--------+-------------+----------------------------------+ |
|  | Failure        | Impact | RTO Target  | Recovery Method                  | |
|  +----------------+--------+-------------+----------------------------------+ |
|  | Service crash  | Medium | 5-10 min    | Automatic restart, HA failover   | |
|  | Config error   | Medium | 15-30 min   | Restore config from backup       | |
|  | Failed upgrade | High   | 30-60 min   | Rollback to previous version     | |
|  | OS crash       | High   | 30-60 min   | HA failover, reboot/reinstall    | |
|  | Kernel panic   | High   | 15-30 min   | HA failover, reboot              | |
|  +----------------+--------+-------------+----------------------------------+ |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  CATEGORY 3: DATA CORRUPTION                                                  |
|  ===========================                                                  |
|                                                                               |
|  +----------------+--------+-------------+----------------------------------+ |
|  | Failure        | Impact | RTO Target  | Recovery Method                  | |
|  +----------------+--------+-------------+----------------------------------+ |
|  | Table corrupt  | High   | 1-2 hours   | PITR or restore from backup      | |
|  | Index corrupt  | Medium | 30-60 min   | REINDEX or restore               | |
|  | WAL corrupt    | Critical| 1-4 hours  | Restore from backup              | |
|  | Config corrupt | Medium | 15-30 min   | Restore config backup            | |
|  | Key corrupt    | Critical| 1-4 hours  | Key escrow recovery              | |
|  +----------------+--------+-------------+----------------------------------+ |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  CATEGORY 4: SITE-LEVEL FAILURES                                              |
|  ================================                                             |
|                                                                               |
|  +----------------+--------+-------------+----------------------------------+ |
|  | Failure        | Impact | RTO Target  | Recovery Method                  | |
|  +----------------+--------+-------------+----------------------------------+ |
|  | Power outage   | High   | 15-30 min   | Multi-site failover              | |
|  | Network outage | High   | 15-30 min   | Multi-site failover              | |
|  | Natural disaster| Critical| 30-60 min | DR site activation               | |
|  | Ransomware     | Critical| 2-24 hours | Clean restore from backup        | |
|  | Complete site  | Critical| 30-60 min  | DR site activation               | |
|  +----------------+--------+-------------+----------------------------------+ |
|                                                                               |
+==============================================================================+
```

### Decision Tree: Which Recovery Procedure?

```
+==============================================================================+
|                         RECOVERY DECISION TREE                                |
+==============================================================================+
|                                                                               |
|                         WALLIX Service Unavailable                            |
|                                   |                                           |
|                                   v                                           |
|                    +-----------------------------+                            |
|                    | Is this a single node or HA? |                           |
|                    +-----------------------------+                            |
|                      |                       |                                |
|               Single Node              HA Cluster                             |
|                      |                       |                                |
|                      v                       v                                |
|           +-----------------+     +------------------------+                  |
|           | Go to Section 5 |     | Both nodes affected?   |                  |
|           | Single Node     |     +------------------------+                  |
|           | Recovery        |       |                  |                      |
|           +-----------------+    No |               Yes |                     |
|                                     v                   v                     |
|                         +----------------+    +------------------+            |
|                         | Go to Section 6|    | Database OK?     |            |
|                         | HA Failover    |    +------------------+            |
|                         +----------------+      |            |                |
|                                               Yes |          No |             |
|                                                   v            v              |
|                                       +-------------+  +---------------+      |
|                                       | Cluster     |  | Go to Sec 8   |      |
|                                       | Recovery    |  | DB Recovery   |      |
|                                       | (Sec 6)     |  +---------------+      |
|                                       +-------------+                         |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|                          Multi-Site Scenario                                  |
|                                   |                                           |
|                                   v                                           |
|                    +-----------------------------+                            |
|                    | Primary site accessible?     |                           |
|                    +-----------------------------+                            |
|                      |                       |                                |
|                    Yes                      No                                |
|                      |                       |                                |
|                      v                       v                                |
|           +-----------------+     +------------------------+                  |
|           | Normal operation|     | Go to Section 7        |                  |
|           | Check local HA  |     | Multi-Site Failover    |                  |
|           +-----------------+     +------------------------+                  |
|                                                                               |
+==============================================================================+
```

---

## Pre-Disaster Preparation

### Documentation Checklist

Maintain and regularly update the following documentation:

```
+==============================================================================+
|                    PRE-DISASTER DOCUMENTATION CHECKLIST                       |
+==============================================================================+
|                                                                               |
|  CRITICAL DOCUMENTS (Update Monthly)                                          |
|  ===================================                                          |
|                                                                               |
|  [ ] Network topology diagram with all IPs                                   |
|  [ ] Server hardware specifications                                          |
|  [ ] Cluster configuration parameters                                        |
|  [ ] PostgreSQL replication configuration                                    |
|  [ ] Backup schedule and retention policies                                  |
|  [ ] Recovery procedure runbooks (this document)                             |
|  [ ] Contact list for DR team                                                |
|  [ ] Vendor support contact information                                      |
|  [ ] License files and activation keys                                       |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  STORED SECURELY OFFSITE                                                      |
|  =======================                                                      |
|                                                                               |
|  [ ] Master encryption key escrow                                            |
|  [ ] Root/admin passwords (sealed envelope or vault)                         |
|  [ ] HSM recovery credentials                                                |
|  [ ] SSL certificate private keys (encrypted)                                |
|  [ ] PostgreSQL replication credentials                                      |
|  [ ] Backup encryption keys                                                  |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  VERIFIED QUARTERLY                                                           |
|  =================                                                            |
|                                                                               |
|  [ ] Backup restore test completed                                           |
|  [ ] DR failover test completed                                              |
|  [ ] Contact list accuracy verified                                          |
|  [ ] Documentation reviewed and updated                                      |
|  [ ] Recovery time objectives met in testing                                 |
|                                                                               |
+==============================================================================+
```

### Pre-Disaster Verification Commands

Run these commands regularly to ensure DR readiness:

```bash
# Verify backup integrity
wabadmin backup --verify --latest
echo "Exit code: $? (0 = success)"

# Check replication status
sudo -u postgres psql -c "SELECT client_addr, state, sync_state,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;"

# Verify cluster health
crm status
crm_verify -L

# Check disk space for backups
df -h /backup/wallix/

# Verify backup files exist
ls -la /backup/wallix/daily/ | tail -5
ls -la /backup/wallix/weekly/ | tail -5

# Test backup decryption (for encrypted backups)
gpg --list-packets /backup/wallix/monthly/latest.tar.gz.gpg 2>&1 | head -5

# Verify shared storage accessibility
df -h /var/wab/recorded
touch /var/wab/recorded/.dr-test && rm /var/wab/recorded/.dr-test
echo "Shared storage: OK"
```

### Backup Verification Script

```bash
#!/bin/bash
# /opt/scripts/verify-dr-readiness.sh

echo "=========================================="
echo "DR Readiness Verification - $(date)"
echo "=========================================="

ERRORS=0

# Check 1: Latest backup exists and is recent
echo -n "1. Latest backup exists (< 24h old): "
LATEST_BACKUP=$(find /backup/wallix/daily -name "*.tar.gz" -mtime -1 | head -1)
if [ -n "$LATEST_BACKUP" ]; then
    echo "OK - $LATEST_BACKUP"
else
    echo "FAILED - No recent backup found"
    ((ERRORS++))
fi

# Check 2: Backup integrity
echo -n "2. Backup integrity: "
if wabadmin backup --verify --latest > /dev/null 2>&1; then
    echo "OK"
else
    echo "FAILED"
    ((ERRORS++))
fi

# Check 3: PostgreSQL replication
echo -n "3. PostgreSQL replication: "
REP_STATE=$(sudo -u postgres psql -t -c "SELECT state FROM pg_stat_replication LIMIT 1;" 2>/dev/null | tr -d ' ')
if [ "$REP_STATE" = "streaming" ]; then
    echo "OK - streaming"
else
    echo "WARNING - State: $REP_STATE"
fi

# Check 4: Cluster status
echo -n "4. Cluster health: "
if crm_verify -L > /dev/null 2>&1; then
    echo "OK"
else
    echo "FAILED"
    ((ERRORS++))
fi

# Check 5: Shared storage
echo -n "5. Shared storage: "
if touch /var/wab/recorded/.dr-test 2>/dev/null && rm /var/wab/recorded/.dr-test; then
    echo "OK"
else
    echo "FAILED"
    ((ERRORS++))
fi

# Check 6: DR site connectivity (if applicable)
echo -n "6. DR site connectivity: "
if ping -c 1 -W 5 dr-site.company.com > /dev/null 2>&1; then
    echo "OK"
else
    echo "FAILED or N/A"
fi

echo "=========================================="
echo "Errors found: $ERRORS"
if [ $ERRORS -eq 0 ]; then
    echo "DR Readiness: PASSED"
    exit 0
else
    echo "DR Readiness: FAILED"
    exit 1
fi
```

---

## Single Node Recovery

### Scenario: Complete Node Failure (No HA)

**RTO Target:** 30-60 minutes
**RPO:** Last backup

```
+==============================================================================+
|                    SINGLE NODE RECOVERY PROCEDURE                             |
+==============================================================================+
|                                                                               |
|  PHASE 1: ASSESSMENT (5-10 min)                                              |
|  ==============================                                               |
|                                                                               |
|  1. Confirm node is truly down                                               |
|  2. Determine cause (hardware, software, power)                              |
|  3. Decide: repair or rebuild                                                |
|  4. Locate most recent backup                                                |
|                                                                               |
|  PHASE 2: INFRASTRUCTURE PREP (10-20 min)                                    |
|  ========================================                                     |
|                                                                               |
|  1. Prepare new hardware/VM if needed                                        |
|  2. Install Debian 12                                                        |
|  3. Configure network (same IP)                                              |
|  4. Verify backup accessibility                                              |
|                                                                               |
|  PHASE 3: RESTORATION (15-30 min)                                            |
|  ================================                                             |
|                                                                               |
|  1. Install WALLIX Bastion                                                   |
|  2. Stop services                                                            |
|  3. Restore from backup                                                      |
|  4. Restore encryption keys                                                  |
|  5. Start services                                                           |
|                                                                               |
|  PHASE 4: VALIDATION (5-10 min)                                              |
|  ==============================                                               |
|                                                                               |
|  1. Verify all services running                                              |
|  2. Test authentication                                                      |
|  3. Test session establishment                                               |
|  4. Verify recordings accessible                                             |
|                                                                               |
+==============================================================================+
```

### Step-by-Step Recovery Commands

**Phase 1: Assessment**

```bash
# From management station, verify node is down
ping -c 5 wallix.company.com
curl -k --connect-timeout 5 https://wallix.company.com/api/health

# Attempt out-of-band access if available
# IPMI/ILO/DRAC console access

# If node is accessible but services are down
ssh root@wallix.company.com
systemctl status wallix-bastion
journalctl -u wallix-bastion --since "1 hour ago" -n 100
```

**Phase 2: Infrastructure Preparation**

```bash
# On new/rebuilt server

# 1. Set hostname
hostnamectl set-hostname wallix.company.com

# 2. Configure network (example)
cat > /etc/network/interfaces.d/wallix << 'EOF'
auto eth0
iface eth0 inet static
    address 10.100.1.100
    netmask 255.255.255.0
    gateway 10.100.1.1
    dns-nameservers 10.100.1.2
EOF

systemctl restart networking

# 3. Verify backup storage is accessible
mount -t nfs backup-server:/backup /mnt/backup
ls -la /mnt/backup/wallix/weekly/
```

**Phase 3: Restoration**

```bash
# 1. Install WALLIX Bastion
curl -fsSL https://repo.wallix.com/wallix.gpg | gpg --dearmor -o /usr/share/keyrings/wallix.gpg

cat > /etc/apt/sources.list.d/wallix.list << 'EOF'
deb [signed-by=/usr/share/keyrings/wallix.gpg] https://repo.wallix.com/bastion/12.1 bookworm main
EOF

apt update
apt install -y wallix-bastion

# 2. Stop services
systemctl stop wallix-bastion

# 3. Restore from backup
# Identify latest backup
LATEST_BACKUP=$(ls -t /mnt/backup/wallix/weekly/full-*.tar.gz | head -1)
echo "Restoring from: $LATEST_BACKUP"

# Perform restore
wabadmin restore --full --input "$LATEST_BACKUP"

# 4. Restore encryption keys (if stored separately)
# CRITICAL: Keys must be restored before starting services
tar -xzf /mnt/backup/wallix/keys/master-key-backup.tar.gz -C /

# 5. Verify permissions
chown -R wallix:wallix /var/lib/wallix
chmod 700 /var/lib/wallix/keys

# 6. Start services
systemctl start wallix-bastion
```

**Phase 4: Validation**

```bash
# 1. Verify services are running
systemctl status wallix-bastion
wabadmin status

# Expected output:
# WALLIX Bastion Status: RUNNING
# Database: Connected
# License: Valid (expires: YYYY-MM-DD)
# Recording Storage: Mounted

# 2. Full health check
wabadmin health-check

# 3. Test authentication (via API)
curl -k -X POST https://localhost/api/v3.12/auth \
    -H "Content-Type: application/json" \
    -d '{"user": "admin", "password": "ADMIN_PASSWORD"}'

# 4. Test session connectivity
wabadmin connectivity-test --sample 5

# 5. Verify recordings are accessible
ls -la /var/wab/recorded/
wabadmin recordings --list --last 5

# 6. Document recovery
echo "Recovery completed at $(date)" >> /var/log/wallix/recovery.log
echo "Restored from: $LATEST_BACKUP" >> /var/log/wallix/recovery.log
```

---

## HA Cluster Failover

### Automatic Failover (Default Behavior)

WALLIX HA clusters with Pacemaker automatically handle failovers:

```
+==============================================================================+
|                    AUTOMATIC FAILOVER SEQUENCE                                |
+==============================================================================+
|                                                                               |
|  TIME      EVENT                                                              |
|  ----      -----                                                              |
|                                                                               |
|  T+0s      Primary node failure detected by Pacemaker                        |
|            - Heartbeat timeout (default: 10s)                                |
|            - Health check failure (3 consecutive)                            |
|                                                                               |
|  T+5s      Failure validation                                                |
|            - Pacemaker confirms failure                                       |
|            - STONITH/fencing triggered (if configured)                       |
|                                                                               |
|  T+10s     PostgreSQL promotion                                              |
|            - Standby promoted to primary                                      |
|            - pg_promote() executed                                            |
|            - WAL timeline incremented                                         |
|                                                                               |
|  T+15s     Service migration                                                 |
|            - WALLIX services started on new primary                          |
|            - Service health verified                                          |
|                                                                               |
|  T+20s     VIP migration                                                     |
|            - Virtual IP moved to new primary                                 |
|            - ARP announcement sent                                            |
|                                                                               |
|  T+25-30s  Service restored                                                  |
|            - Clients reconnect automatically                                  |
|            - New sessions can be established                                  |
|                                                                               |
|  TOTAL:    ~30 seconds (typical)                                             |
|                                                                               |
+==============================================================================+
```

### Monitoring Automatic Failover

```bash
# Watch cluster status during failover
watch -n 2 'pcs status'

# Check failover history
pcs resource failcount show

# View cluster events
journalctl -u pacemaker --since "10 minutes ago" | grep -i failover

# Verify current resource locations
pcs resource status

# Expected output after failover:
# * wallix-vip    (ocf:heartbeat:IPaddr2):     Started wallix-a2-hb
# * wallix-service (systemd:wabengine):        Started wallix-a2-hb
# * pgsql-primary (ocf:heartbeat:pgsql):       Master wallix-a2-hb
```

### Manual Failover Procedure

**When to use:** Planned maintenance, testing, or when automatic failover fails.

```bash
# 1. Verify current cluster state
pcs status

# 2. Check which node is primary
pcs resource status pgsql-primary

# 3. Initiate controlled failover (moves resources to secondary)
# Method A: Put primary in standby
pcs node standby wallix-a1-hb

# Wait for failover to complete
sleep 30

# Verify resources moved
pcs status

# 4. Alternative Method B: Move specific resources
pcs resource move wallix-vip wallix-a2-hb
pcs resource move wallix-service wallix-a2-hb

# 5. Verify services on new primary
ssh wallix-a2-hb 'wabadmin status'

# 6. Clear location constraints after maintenance
pcs resource clear wallix-vip
pcs resource clear wallix-service
```

### Failed Primary Node Recovery

After failover, recover the failed primary as a new secondary:

```bash
# On the failed/recovered node (wallix-a1)

# 1. Check current state
pcs status
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"

# 2. If PostgreSQL is running as old primary, stop it
systemctl stop postgresql

# 3. Reinitialize as standby
rm -rf /var/lib/postgresql/15/main/*

sudo -u postgres pg_basebackup \
    -h wallix-a2-hb \
    -U replicator \
    -D /var/lib/postgresql/15/main \
    -P -R -X stream

# 4. Start PostgreSQL as standby
systemctl start postgresql

# 5. Verify replication is working
sudo -u postgres psql -c "SELECT * FROM pg_stat_wal_receiver;"

# Expected output:
#  status  | sender_host  | sender_port
# ---------+--------------+-------------
#  streaming| wallix-a2-hb | 5432

# 6. Bring node back into cluster
pcs node unstandby wallix-a1-hb

# 7. Verify cluster is healthy
pcs status
crm_verify -L
```

---

## Multi-Site Failover

### Site A to Site B Failover Procedure

**RTO Target:** 15-30 minutes
**RPO:** < 5 minutes (async replication lag)

```
+==============================================================================+
|                    MULTI-SITE FAILOVER PROCEDURE                              |
+==============================================================================+
|                                                                               |
|  PRE-FAILOVER CHECKLIST                                                       |
|  ======================                                                       |
|                                                                               |
|  [ ] Confirm Site A is truly unavailable (not just network issue)            |
|  [ ] Verify Site B cluster is healthy                                        |
|  [ ] Check replication lag before last sync                                  |
|  [ ] Notify stakeholders of impending failover                               |
|  [ ] Ensure DR team is available                                             |
|                                                                               |
|  FAILOVER STEPS                                                               |
|  ==============                                                               |
|                                                                               |
|  Step 1: Assess replication status                                           |
|  Step 2: Promote Site B database                                             |
|  Step 3: Start Site B WALLIX services                                        |
|  Step 4: Update DNS/GSLB                                                     |
|  Step 5: Verify service availability                                         |
|  Step 6: Notify users                                                        |
|                                                                               |
+==============================================================================+
```

### Step-by-Step Multi-Site Failover

**Step 1: Assess Replication Status (Site B)**

```bash
# On Site B primary node

# Check if replication was connected before failure
sudo -u postgres psql -c "SELECT * FROM pg_stat_wal_receiver;"

# Check last received LSN
sudo -u postgres psql -c "SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();"

# Check replication lag at last sync
sudo -u postgres psql -c "SELECT now() - pg_last_xact_replay_timestamp() AS lag;"

# Document the potential data loss window
echo "Last sync: $(sudo -u postgres psql -t -c 'SELECT pg_last_xact_replay_timestamp();')"
```

**Step 2: Promote Site B Database**

```bash
# Promote PostgreSQL on Site B
# WARNING: This is irreversible. Ensure Site A is truly unavailable.

# Method 1: Using pg_ctl
sudo -u postgres /usr/lib/postgresql/15/bin/pg_ctl promote \
    -D /var/lib/postgresql/15/main

# Method 2: Using SQL (PostgreSQL 12+)
sudo -u postgres psql -c "SELECT pg_promote();"

# Verify promotion succeeded
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
# Should return: f (false = no longer in recovery = now primary)

# Check timeline advanced
sudo -u postgres psql -c "SELECT timeline_id FROM pg_control_checkpoint();"
```

**Step 3: Start Site B WALLIX Services**

```bash
# If using Pacemaker cluster at Site B
pcs resource cleanup
pcs status

# If standalone or services not started
systemctl start wallix-bastion

# Verify services are running
wabadmin status

# Expected output:
# WALLIX Bastion Status: RUNNING
# Database: Connected (Primary mode)
# License: Valid
# Cluster: Active (DR Mode)
```

**Step 4: Update DNS/GSLB**

```bash
# Option 1: Update DNS A record
# Contact DNS administrator or use automation:
# Example using AWS Route53 CLI
aws route53 change-resource-record-sets \
    --hosted-zone-id Z123456789 \
    --change-batch '{
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "bastion.company.com",
                "Type": "A",
                "TTL": 60,
                "ResourceRecords": [{"Value": "10.200.1.100"}]
            }
        }]
    }'

# Option 2: Update GSLB health check
# Disable Site A in load balancer
# Enable Site B as primary

# Option 3: Manual DNS propagation check
dig bastion.company.com @8.8.8.8
dig bastion.company.com @1.1.1.1
```

**Step 5: Verify Service Availability**

```bash
# From external location
curl -k --connect-timeout 10 https://bastion.company.com/api/health

# Expected response:
# {"status": "healthy", "node": "wallix-b1", "cluster_role": "primary"}

# Test authentication
curl -k -X POST https://bastion.company.com/api/v3.12/auth \
    -H "Content-Type: application/json" \
    -d '{"user": "admin", "password": "ADMIN_PASSWORD"}'

# Test SSH proxy (from allowed client)
ssh -o ProxyCommand="ssh -W %h:%p user@bastion.company.com" user@target-server

# Full health check
wabadmin health-check
wabadmin connectivity-test --sample 10
```

**Step 6: Post-Failover Documentation**

```bash
# Create incident record
cat >> /var/log/wallix/dr-events.log << EOF

DR FAILOVER EVENT
================
Date: $(date)
Event: Site A to Site B failover
Reason: [Document reason]
Initiated by: [Name]
Replication lag at failover: [Document]
Services restored at: $(date)
Users notified: [Yes/No]
EOF

# Verify all critical functions
wabadmin sessions --status active  # Should show any active sessions
wabadmin audit --last 10           # Verify audit logging working
wabadmin recordings --verify       # Verify recording functionality
```

### Failback Procedure (Site B to Site A)

After Site A is recovered:

```bash
# 1. On Site A, reinitialize as replica of Site B
systemctl stop wallix-bastion
systemctl stop postgresql

rm -rf /var/lib/postgresql/15/main/*

sudo -u postgres pg_basebackup \
    -h site-b-primary \
    -U replicator \
    -D /var/lib/postgresql/15/main \
    -P -R -X stream

systemctl start postgresql

# Verify replication from Site B
sudo -u postgres psql -c "SELECT * FROM pg_stat_wal_receiver;"

# 2. Plan maintenance window for failback
# 3. During window, promote Site A and demote Site B
# 4. Update DNS back to Site A
# 5. Verify service restoration
```

---

## Database Recovery

### PostgreSQL Point-in-Time Recovery (PITR)

**When to use:** Data corruption, accidental deletion, need to recover to specific time.

**RTO Target:** 1-2 hours
**RPO:** Any point with available WAL

```
+==============================================================================+
|                    POINT-IN-TIME RECOVERY PROCEDURE                           |
+==============================================================================+
|                                                                               |
|  REQUIREMENTS                                                                 |
|  ============                                                                 |
|                                                                               |
|  1. Base backup (pg_basebackup)                                              |
|  2. WAL archive from backup time to recovery target                          |
|  3. archive_mode = on in PostgreSQL config                                   |
|  4. Archive storage accessible                                               |
|                                                                               |
|  RECOVERY STEPS                                                               |
|  ==============                                                               |
|                                                                               |
|  1. Stop all services                                                        |
|  2. Backup current (corrupt) state                                           |
|  3. Restore base backup                                                      |
|  4. Configure recovery.signal                                                |
|  5. Start PostgreSQL (recovery mode)                                         |
|  6. Wait for recovery to complete                                            |
|  7. Verify data integrity                                                    |
|  8. Start WALLIX services                                                    |
|                                                                               |
+==============================================================================+
```

**Step-by-Step PITR**

```bash
# 1. Stop all services
systemctl stop wallix-bastion
systemctl stop postgresql

# 2. Backup current (corrupt) state for investigation
sudo -u postgres pg_dump wallix > /tmp/corrupt-state-$(date +%Y%m%d-%H%M%S).sql 2>&1

# Also backup data directory
tar -czf /tmp/corrupt-pgdata-$(date +%Y%m%d-%H%M%S).tar.gz \
    /var/lib/postgresql/15/main/

# 3. Restore base backup
# Clear current data
rm -rf /var/lib/postgresql/15/main/*

# Restore from base backup
tar -xzf /backup/wallix/weekly/full-basebackup.tar.gz \
    -C /var/lib/postgresql/15/main/

# 4. Configure recovery parameters
cat > /var/lib/postgresql/15/main/postgresql.auto.conf << 'EOF'
restore_command = 'cp /backup/wallix/wal-archive/%f %p'
recovery_target_time = '2026-01-30 14:30:00 UTC'
recovery_target_action = 'promote'
EOF

# Create recovery signal file
touch /var/lib/postgresql/15/main/recovery.signal

# 5. Set ownership
chown -R postgres:postgres /var/lib/postgresql/15/main

# 6. Start PostgreSQL in recovery mode
systemctl start postgresql

# Monitor recovery progress
tail -f /var/log/postgresql/postgresql-15-main.log &
LOG_PID=$!

# Wait for recovery to complete
# Look for: "database system is ready to accept connections"

# 7. Verify recovery completed
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
# Should return: f (false)

kill $LOG_PID

# 8. Verify data integrity
wabadmin verify --database

# Check for expected data
sudo -u postgres psql -d wallix -c "SELECT COUNT(*) FROM users;"
sudo -u postgres psql -d wallix -c "SELECT COUNT(*) FROM sessions;"

# 9. Start WALLIX services
systemctl start wallix-bastion

# 10. Full validation
wabadmin health-check
```

### Database Corruption Handling

**Quick Repair for Minor Corruption**

```bash
# Stop WALLIX services
systemctl stop wallix-bastion

# Check for corruption
sudo -u postgres pg_dump wallix > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Database corruption detected"
fi

# Attempt repair
sudo -u postgres psql -d wallix -c "REINDEX DATABASE wallix;"
sudo -u postgres psql -d wallix -c "VACUUM FULL ANALYZE;"

# Restart and verify
systemctl start wallix-bastion
wabadmin verify --database
```

**Full Recovery for Major Corruption**

```bash
# 1. Stop all services
systemctl stop wallix-bastion
systemctl stop postgresql

# 2. Attempt to dump what data we can salvage
sudo -u postgres pg_dump wallix > /tmp/salvaged-$(date +%Y%m%d).sql 2>&1

# 3. Drop and recreate database
sudo -u postgres dropdb wallix
sudo -u postgres createdb wallix

# 4. Restore from most recent clean backup
sudo -u postgres pg_restore -d wallix \
    /backup/wallix/weekly/database-latest.dump

# 5. Start PostgreSQL
systemctl start postgresql

# 6. Verify restore
sudo -u postgres psql -d wallix -c "SELECT COUNT(*) FROM users;"

# 7. Start WALLIX
systemctl start wallix-bastion

# 8. Full validation
wabadmin health-check
wabadmin verify --all
```

---

## Configuration Recovery

### Recovery from Backup

```bash
# 1. Stop services
systemctl stop wallix-bastion

# 2. Identify latest config backup
ls -la /backup/wallix/daily/

# 3. Restore configuration only
wabadmin restore --config-only \
    --input /backup/wallix/daily/config-YYYYMMDD.tar.gz

# 4. Verify configuration
wabadmin config --verify

# 5. Start services
systemctl start wallix-bastion

# 6. Verify functionality
wabadmin health-check
```

### Recovery from Scratch (No Backup)

When no backup is available, rebuild configuration manually:

```bash
# 1. Install fresh WALLIX Bastion
apt install -y wallix-bastion

# 2. Initialize with new configuration
wabadmin init --fresh

# 3. Install license
cp /path/to/license.key /etc/opt/wab/license.key
wabadmin license-install /etc/opt/wab/license.key

# 4. Configure authentication (example: LDAP)
wabadmin config set auth.ldap.enabled true
wabadmin config set auth.ldap.server "ldaps://dc.company.com:636"
wabadmin config set auth.ldap.base_dn "DC=company,DC=com"
wabadmin config set auth.ldap.bind_dn "CN=wallix-svc,OU=Service,DC=company,DC=com"
wabadmin config set auth.ldap.bind_password "LDAP_PASSWORD"

# 5. Configure SSL certificate
cp /path/to/server.crt /etc/wallix/ssl/server.crt
cp /path/to/server.key /etc/wallix/ssl/server.key

# 6. Restart services
systemctl restart wallix-bastion

# 7. Reconfigure via Web UI or API
# - Users and groups
# - Targets and devices
# - Authorizations
# - Policies
```

### Configuration Verification Commands

```bash
# Verify all configuration is valid
wabadmin config --verify

# Expected output:
# Configuration verification: PASSED
# - Database connection: OK
# - Authentication settings: OK
# - SSL certificates: OK
# - License: Valid
# - Encryption keys: OK

# Test specific components
wabadmin connectivity-test --all
wabadmin auth-test ldap
wabadmin ssl-verify
```

---

## Encryption Key Recovery

### Master Key Recovery Scenarios

```
+==============================================================================+
|                    ENCRYPTION KEY RECOVERY SCENARIOS                          |
+==============================================================================+
|                                                                               |
|  SCENARIO 1: Key File Corruption                                             |
|  ===============================                                              |
|                                                                               |
|  Symptoms:                                                                    |
|  - Service fails to start with "key decryption error"                        |
|  - Unable to access credential vault                                         |
|  - Session recordings unplayable                                             |
|                                                                               |
|  Recovery Method:                                                             |
|  - Restore key file from secure backup                                       |
|  - Use key escrow if backup unavailable                                      |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  SCENARIO 2: Key Never Backed Up                                             |
|  ===============================                                              |
|                                                                               |
|  Impact:                                                                      |
|  - ALL encrypted data is PERMANENTLY LOST                                    |
|  - All stored passwords unrecoverable                                        |
|  - Session recordings unplayable                                             |
|                                                                               |
|  Recovery:                                                                    |
|  - Generate new keys                                                         |
|  - Re-register all managed credentials manually                              |
|  - Accept data loss                                                          |
|                                                                               |
+==============================================================================+
```

### Standard Key Recovery from Backup

```bash
# 1. Stop all services
systemctl stop wallix-bastion

# 2. Backup current (potentially corrupt) keys
cp -a /var/lib/wallix/keys /var/lib/wallix/keys.backup.$(date +%Y%m%d)

# 3. Restore keys from secure backup
# Keys are typically in encrypted archive
gpg --decrypt /backup/wallix/keys/master-key-escrow.gpg | \
    tar -xzf - -C /var/lib/wallix/

# 4. Verify key file permissions
ls -la /var/lib/wallix/keys/
chmod 600 /var/lib/wallix/keys/*
chown wallix:wallix /var/lib/wallix/keys/*

# 5. Verify key integrity
wabadmin key-verify

# Expected output:
# Master key: OK
# Credential encryption key: OK
# Session recording key: OK

# 6. Start services
systemctl start wallix-bastion

# 7. Verify vault access
wabadmin vault-test
```

### HSM Key Recovery

For deployments using Hardware Security Modules:

```bash
# 1. Verify HSM connectivity
pkcs11-tool --module /usr/lib/pkcs11/hsm.so --list-slots

# 2. Check key availability in HSM
pkcs11-tool --module /usr/lib/pkcs11/hsm.so \
    --login --pin <HSM_PIN> \
    --list-objects --type privkey

# 3. If HSM has failed, restore to backup HSM
# Contact HSM vendor for specific procedures

# 4. Update WALLIX configuration for new HSM
wabadmin config set hsm.slot_id <NEW_SLOT>
wabadmin config set hsm.key_label <KEY_LABEL>

# 5. Verify HSM integration
wabadmin hsm-test

# 6. Restart services
systemctl restart wallix-bastion
```

### Emergency Key Rotation

If key compromise is suspected:

```bash
# WARNING: This will require re-encrypting all data

# 1. Stop services
systemctl stop wallix-bastion

# 2. Export all credentials (encrypted with old key)
wabadmin vault-export --output /tmp/vault-export.enc

# 3. Generate new master key
wabadmin key-generate --type master --force

# 4. Re-import credentials (will re-encrypt with new key)
wabadmin vault-import --input /tmp/vault-export.enc

# 5. Securely delete old export
shred -u /tmp/vault-export.enc

# 6. Update key backup
wabadmin key-backup --output /backup/wallix/keys/master-key-$(date +%Y%m%d).gpg

# 7. Start services
systemctl start wallix-bastion

# 8. Verify all credentials accessible
wabadmin vault-verify --all
```

---

## Session Recording Recovery

### Missing Recording Recovery

```bash
# 1. Check recording storage mount
df -h /var/wab/recorded
mount | grep recorded

# 2. If unmounted, remount
mount -a

# 3. Verify recording files exist
ls -la /var/wab/recorded/

# 4. Check for orphaned recordings
wabadmin recordings --orphaned

# 5. Reindex recordings database
wabadmin recordings --reindex

# 6. Verify recordings accessible
wabadmin recordings --list --last 20
wabadmin recordings --verify --sample 5
```

### Storage Corruption Recovery

```bash
# 1. Check filesystem
fsck -n /dev/sdb1  # Check without modifying (assuming recordings on /dev/sdb1)

# 2. If errors found, unmount and repair
systemctl stop wallix-bastion
umount /var/wab/recorded
fsck -y /dev/sdb1

# 3. Remount
mount /var/wab/recorded

# 4. Verify mount
df -h /var/wab/recorded

# 5. Check for damaged recordings
wabadmin recordings --verify --all

# 6. Flag corrupted recordings
wabadmin recordings --mark-corrupt --list-damaged

# 7. Restart services
systemctl start wallix-bastion
```

### Recording Recovery from Backup

```bash
# 1. Identify backup containing recordings
ls -la /backup/wallix/recordings/

# 2. Restore specific recording
tar -xzf /backup/wallix/recordings/recordings-YYYYMMDD.tar.gz \
    -C /var/wab/recorded/ \
    --strip-components=3

# 3. Reindex
wabadmin recordings --reindex

# 4. Verify restored recording
wabadmin recordings --verify <recording_id>
```

---

## Split-Brain Recovery

### Identifying Split-Brain Condition

```bash
# On each node, check cluster perception
crm status
corosync-quorumtool -s

# Check for split-brain indicators:
# - Both nodes show as primary
# - No quorum on either node
# - VIP responding on both nodes (rare)
```

### Split-Brain Resolution Procedure

```
+==============================================================================+
|                    SPLIT-BRAIN RECOVERY PROCEDURE                             |
+==============================================================================+
|                                                                               |
|  CRITICAL: Split-brain can cause data divergence. Handle carefully!          |
|                                                                               |
|  STEP 1: IDENTIFY AUTHORITATIVE NODE                                         |
|  ====================================                                         |
|                                                                               |
|  Criteria for selecting primary:                                              |
|  1. Node with most recent data (check PostgreSQL LSN)                        |
|  2. Node with more active sessions at split time                             |
|  3. Node designated as primary in DR plan                                    |
|                                                                               |
|  STEP 2: ISOLATE NON-AUTHORITATIVE NODE                                      |
|  ======================================                                       |
|                                                                               |
|  STEP 3: RESTORE CLUSTER COMMUNICATION                                       |
|  ======================================                                       |
|                                                                               |
|  STEP 4: RESYNCHRONIZE DATA                                                  |
|  ==========================                                                   |
|                                                                               |
|  STEP 5: VALIDATE AND RESUME                                                 |
|  ===========================                                                  |
|                                                                               |
+==============================================================================+
```

**Step-by-Step Resolution**

```bash
# STEP 1: Identify which node has most recent data

# On Node A:
sudo -u postgres psql -c "SELECT pg_current_wal_lsn();"
# Example: 0/12345678

# On Node B:
sudo -u postgres psql -c "SELECT pg_current_wal_lsn();"
# Example: 0/12345600

# Node A has higher LSN = more recent data

# STEP 2: Isolate non-authoritative node (Node B)

# On Node B:
pcs cluster stop
systemctl stop wallix-bastion
systemctl stop postgresql

# STEP 3: Verify authoritative node (Node A) is healthy

# On Node A:
wabadmin status
pcs status

# Ensure Node A is operating as standalone if needed
pcs property set no-quorum-policy=ignore

# STEP 4: Resynchronize Node B

# On Node B:
rm -rf /var/lib/postgresql/15/main/*

sudo -u postgres pg_basebackup \
    -h wallix-a1 \
    -U replicator \
    -D /var/lib/postgresql/15/main \
    -P -R -X stream

# Start PostgreSQL as replica
systemctl start postgresql

# Verify replication
sudo -u postgres psql -c "SELECT * FROM pg_stat_wal_receiver;"

# STEP 5: Rejoin cluster

# On Node B:
pcs cluster start

# On Node A (verify cluster reformed):
pcs status

# Restore quorum policy
pcs property set no-quorum-policy=stop

# Verify cluster health
crm_verify -L
wabadmin health-check
```

### Preventing Split-Brain

```bash
# Configure STONITH/fencing (recommended for production)
pcs stonith create fence-node-a fence_ipmilan \
    pcmk_host_list="wallix-a1" \
    ipaddr="10.100.1.10-ipmi" \
    login="admin" \
    passwd="IPMI_PASSWORD" \
    lanplus=true

pcs stonith create fence-node-b fence_ipmilan \
    pcmk_host_list="wallix-a2" \
    ipaddr="10.100.1.11-ipmi" \
    login="admin" \
    passwd="IPMI_PASSWORD" \
    lanplus=true

pcs property set stonith-enabled=true
```

---

## Network Isolation Recovery

### Scenario: PAM Unreachable from Users

```
+==============================================================================+
|                    NETWORK ISOLATION RECOVERY                                 |
+==============================================================================+
|                                                                               |
|  SYMPTOMS                                                                     |
|  ========                                                                     |
|                                                                               |
|  - Users cannot connect to WALLIX                                            |
|  - SSH proxy timeouts                                                        |
|  - Web UI not loading                                                        |
|  - But WALLIX servers are running (verified via console)                     |
|                                                                               |
|  POSSIBLE CAUSES                                                              |
|  ===============                                                              |
|                                                                               |
|  1. Firewall blocking traffic                                                |
|  2. Network switch/router failure                                            |
|  3. VIP not responding                                                       |
|  4. DNS resolution failure                                                   |
|  5. Load balancer failure                                                    |
|                                                                               |
+==============================================================================+
```

### Diagnosis Commands

```bash
# From WALLIX server console

# 1. Check network interfaces
ip addr show
ip route show

# 2. Check if services are listening
ss -tlnp | grep -E "(443|22|3389)"

# 3. Check VIP status (if HA)
ip addr show | grep "10.100.1.100"
arping -I eth0 10.100.1.100

# 4. Test outbound connectivity
ping -c 3 8.8.8.8
ping -c 3 10.100.1.1  # Default gateway

# 5. Check firewall rules
iptables -L -n
ufw status

# 6. Check from external location
# ping bastion.company.com
# telnet bastion.company.com 443
# traceroute bastion.company.com
```

### Emergency Access Bypass

When WALLIX is unreachable but targets need immediate access:

```
+==============================================================================+
|                    EMERGENCY ACCESS BYPASS PROCEDURE                          |
+==============================================================================+
|                                                                               |
|  WARNING: Use ONLY in documented emergencies. All bypass access must be:     |
|  - Authorized by management                                                   |
|  - Documented with start/end times                                           |
|  - Audited manually                                                          |
|  - Followed by credential rotation                                           |
|                                                                               |
+==============================================================================+
```

```bash
# 1. Document the emergency
cat >> /var/log/emergency-access.log << EOF
EMERGENCY ACCESS BYPASS
Date: $(date)
Authorized by: [Name]
Reason: WALLIX unreachable due to [reason]
Duration: [Expected]
Targets accessed:
EOF

# 2. Use break-glass credentials
# Retrieve emergency passwords from secure vault (physical safe, etc.)
# Access targets directly (not through WALLIX)

# 3. After emergency, rotate all used credentials
wabadmin account rotate <account_id> --force

# 4. Document all actions taken during bypass
# 5. Review and update emergency procedures
```

### VIP Recovery

```bash
# If VIP is missing from all nodes

# 1. Check cluster status
pcs status

# 2. Manually add VIP if needed
ip addr add 10.100.1.100/24 dev eth0

# 3. Send gratuitous ARP
arping -c 4 -U -I eth0 10.100.1.100

# 4. Verify connectivity
ping -c 3 10.100.1.100

# 5. Fix cluster resource
pcs resource cleanup wallix-vip
pcs resource refresh wallix-vip
```

---

## Post-Recovery Validation

### Complete Validation Checklist

```bash
#!/bin/bash
# /opt/scripts/post-recovery-validation.sh

echo "========================================"
echo "POST-RECOVERY VALIDATION"
echo "Date: $(date)"
echo "========================================"

PASSED=0
FAILED=0

run_check() {
    local name="$1"
    local cmd="$2"
    echo -n "Checking $name... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo "PASSED"
        ((PASSED++))
    else
        echo "FAILED"
        ((FAILED++))
    fi
}

# Core Services
run_check "WALLIX service running" "systemctl is-active wallix-bastion"
run_check "PostgreSQL running" "systemctl is-active postgresql"
run_check "Health check" "wabadmin health-check"

# Database
run_check "Database connection" "sudo -u postgres psql -c 'SELECT 1;'"
run_check "Database integrity" "wabadmin verify --database"

# Authentication
run_check "LDAP connectivity" "wabadmin auth-test ldap"
run_check "Local auth working" "wabadmin auth-test local"

# Cluster (if applicable)
if pcs status > /dev/null 2>&1; then
    run_check "Cluster health" "crm_verify -L"
    run_check "Cluster resources" "pcs resource status | grep -q Started"
    run_check "Replication" "sudo -u postgres psql -c 'SELECT state FROM pg_stat_replication;' | grep -q streaming"
fi

# Storage
run_check "Recording storage" "touch /var/wab/recorded/.test && rm /var/wab/recorded/.test"
run_check "Recordings accessible" "wabadmin recordings --verify --sample 3"

# Network
run_check "HTTPS responding" "curl -k --connect-timeout 5 https://localhost/api/health"
run_check "SSH proxy" "nc -z localhost 22"

# License
run_check "License valid" "wabadmin license-check"

# Encryption
run_check "Vault accessible" "wabadmin vault-test"
run_check "Keys valid" "wabadmin key-verify"

echo "========================================"
echo "PASSED: $PASSED"
echo "FAILED: $FAILED"
echo "========================================"

if [ $FAILED -gt 0 ]; then
    echo "WARNING: Some checks failed. Review before returning to production."
    exit 1
else
    echo "All checks passed. System ready for production."
    exit 0
fi
```

### Verification Commands

```bash
# Run full validation
/opt/scripts/post-recovery-validation.sh

# Individual component checks

# 1. Service status
wabadmin status
systemctl status wallix-bastion

# 2. Database health
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
sudo -u postgres psql -d wallix -c "SELECT COUNT(*) FROM users;"
sudo -u postgres psql -d wallix -c "SELECT COUNT(*) FROM sessions WHERE end_time IS NULL;"

# 3. Cluster status (if HA)
pcs status
crm_verify -L

# 4. Replication status
sudo -u postgres psql -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"

# 5. Storage verification
df -h /var/wab/recorded
ls -la /var/wab/recorded/ | head -10

# 6. Test connectivity to targets
wabadmin connectivity-test --sample 10

# 7. Test session establishment
# Manual test: establish SSH and RDP sessions

# 8. Verify audit logging
wabadmin audit --last 10

# 9. Verify recording
wabadmin recordings --list --last 5
```

---

## DR Testing Procedures

### DR Test Types

| Test Type | Frequency | Duration | Impact |
|-----------|-----------|----------|--------|
| Backup verification | Weekly | 15 min | None |
| HA failover test | Monthly | 30 min | Brief outage |
| Multi-site failover | Quarterly | 2-4 hours | Planned outage |
| Full DR exercise | Annually | 8+ hours | Planned outage |
| Tabletop exercise | Quarterly | 2-4 hours | None |

### Non-Disruptive DR Testing

**Backup Verification Test (No Impact)**

```bash
#!/bin/bash
# Weekly backup verification test

echo "DR TEST: Backup Verification"
echo "Date: $(date)"

# 1. Verify backup exists
LATEST=$(ls -t /backup/wallix/weekly/full-*.tar.gz | head -1)
echo "Latest backup: $LATEST"

# 2. Verify backup integrity
echo "Verifying integrity..."
wabadmin backup --verify "$LATEST"

# 3. Test restore to isolated environment (if available)
# On DR test VM:
# wabadmin restore --full --input "$LATEST" --dry-run

# 4. Verify backup age
BACKUP_AGE=$(( ($(date +%s) - $(stat -c %Y "$LATEST")) / 86400 ))
if [ $BACKUP_AGE -gt 7 ]; then
    echo "WARNING: Backup is $BACKUP_AGE days old"
fi

echo "Backup verification complete"
```

### HA Failover Test (Brief Outage)

```bash
#!/bin/bash
# Monthly HA failover test
# SCHEDULE DURING MAINTENANCE WINDOW

echo "========================================"
echo "DR TEST: HA Failover"
echo "Date: $(date)"
echo "========================================"

# 1. Document current state
echo "Pre-test state:"
pcs status
PRIMARY=$(pcs resource status | grep "Master" | awk '{print $NF}')
echo "Current primary: $PRIMARY"

# 2. Count active sessions
SESSIONS=$(wabadmin sessions --status active --count)
echo "Active sessions: $SESSIONS"

if [ "$SESSIONS" -gt 0 ]; then
    echo "WARNING: Active sessions exist. Notify users before proceeding."
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 3. Initiate failover
echo "Initiating failover..."
FAILOVER_START=$(date +%s)

pcs node standby $PRIMARY

# 4. Wait for failover
sleep 30

# 5. Verify failover completed
FAILOVER_END=$(date +%s)
FAILOVER_TIME=$((FAILOVER_END - FAILOVER_START))

echo "Failover completed in $FAILOVER_TIME seconds"

# 6. Verify services on new primary
wabadmin status
wabadmin health-check

# 7. Test functionality
echo "Testing session establishment..."
wabadmin connectivity-test --sample 3

# 8. Restore original primary
echo "Restoring original primary..."
pcs node unstandby $PRIMARY

sleep 30

# 9. Verify cluster healthy
pcs status
crm_verify -L

# 10. Document results
cat >> /var/log/wallix/dr-tests.log << EOF

HA FAILOVER TEST
================
Date: $(date)
Original Primary: $PRIMARY
Failover Time: $FAILOVER_TIME seconds
Result: $(if crm_verify -L > /dev/null 2>&1; then echo "PASSED"; else echo "FAILED"; fi)
EOF

echo "DR test complete"
```

### Multi-Site Failover Test

**Quarterly test with planned outage:**

```bash
#!/bin/bash
# Quarterly multi-site DR test
# REQUIRES CHANGE MANAGEMENT APPROVAL

echo "========================================"
echo "DR TEST: Multi-Site Failover"
echo "Date: $(date)"
echo "This test will cause service interruption"
echo "========================================"

# Pre-test checklist
echo "PRE-TEST CHECKLIST:"
echo "[ ] Change ticket approved"
echo "[ ] Users notified"
echo "[ ] DR team available"
echo "[ ] Rollback procedure ready"
read -p "All items confirmed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# 1. Document baseline
echo "Recording baseline..."
wabadmin status > /tmp/dr-test-baseline.txt
pcs status >> /tmp/dr-test-baseline.txt

# 2. Check Site B readiness
echo "Checking Site B readiness..."
ssh site-b-primary 'wabadmin status'
ssh site-b-primary 'sudo -u postgres psql -c "SELECT pg_is_in_recovery();"'

# 3. Check replication lag
LAG=$(ssh site-b-primary 'sudo -u postgres psql -t -c "SELECT now() - pg_last_xact_replay_timestamp();"')
echo "Current replication lag: $LAG"

# 4. Simulate Site A failure
echo "Simulating Site A failure..."
FAILOVER_START=$(date +%s)

# Stop Site A services
systemctl stop wallix-bastion
systemctl stop postgresql

# 5. Promote Site B
echo "Promoting Site B..."
ssh site-b-primary 'sudo -u postgres psql -c "SELECT pg_promote();"'
ssh site-b-primary 'systemctl start wallix-bastion'

# 6. Update DNS (test DNS or /etc/hosts)
echo "Updating test DNS..."
# For test: update /etc/hosts on test clients

# 7. Verify Site B operational
FAILOVER_END=$(date +%s)
FAILOVER_TIME=$((FAILOVER_END - FAILOVER_START))

echo "Verifying Site B..."
ssh site-b-primary 'wabadmin status'
ssh site-b-primary 'wabadmin health-check'

# 8. Test functionality
echo "Testing from client..."
# Test authentication, sessions, etc.

# 9. Document results
RTO_MET="NO"
if [ $FAILOVER_TIME -lt 1800 ]; then  # 30 minutes
    RTO_MET="YES"
fi

# 10. Failback to Site A
echo "Initiating failback..."
# [Failback procedure]

# 11. Final verification
wabadmin status
pcs status

echo "========================================"
echo "DR TEST RESULTS"
echo "========================================"
echo "Failover Time: $FAILOVER_TIME seconds"
echo "RTO Target (30 min): $RTO_MET"
echo "Replication Lag (RPO): $LAG"
echo "========================================"
```

### Tabletop Exercise Template

```
+==============================================================================+
|                    DR TABLETOP EXERCISE                                       |
+==============================================================================+

SCENARIO: [Describe disaster scenario]

PARTICIPANTS:
- Incident Commander:
- Technical Lead:
- Operations:
- Management:

TIMELINE:

T+0:00  - Incident discovered
         Question: Who is notified first?
         Question: What is the first action?

T+0:15  - Initial assessment complete
         Question: What information is needed?
         Question: Is this a DR event or local recovery?

T+0:30  - Decision point: Failover?
         Question: Who makes the decision?
         Question: What criteria are used?

T+1:00  - DR procedure initiated
         Question: What are the steps?
         Question: Who performs each step?

T+2:00  - Services restored at DR site
         Question: How is success verified?
         Question: Who is notified?

DISCUSSION POINTS:
1. Did we have all necessary information?
2. Were roles and responsibilities clear?
3. What gaps were identified?
4. What improvements are needed?

ACTION ITEMS:
- [ ] [Action item from exercise]
- [ ] [Action item from exercise]
- [ ] [Action item from exercise]

+==============================================================================+
```

---

## References

- WALLIX Documentation Portal: https://pam.wallix.one/documentation
- PostgreSQL Point-in-Time Recovery: https://www.postgresql.org/docs/15/continuous-archiving.html
- Pacemaker Documentation: https://clusterlabs.org/pacemaker/doc/
- NIST SP 800-34: Contingency Planning Guide: https://csrc.nist.gov/publications/detail/sp/800-34/rev-1/final

---

*Document Version: 1.0*
*Last Updated: January 2026*
*Review Frequency: Quarterly*
*Owner: IT Operations / Disaster Recovery Team*
