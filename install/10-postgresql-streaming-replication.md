# PostgreSQL Streaming Replication Guide

## WALLIX Bastion 12.x Database High Availability

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Primary Node Configuration](#primary-node-configuration)
- [Standby Node Configuration](#standby-node-configuration)
- [Pacemaker Integration](#pacemaker-integration)
- [Monitoring and Verification](#monitoring-and-verification)
- [Failover Procedures](#failover-procedures)
- [Troubleshooting](#troubleshooting)

---

## Overview

WALLIX Bastion uses PostgreSQL streaming replication for database high availability. This provides:

- **Real-time synchronization** between primary and standby nodes
- **Automatic failover** with Pacemaker integration
- **Read-only queries** on standby nodes (hot standby)
- **Point-in-time recovery** capability

### Replication Architecture

```
+===============================================================================+
|                    POSTGRESQL STREAMING REPLICATION                           |
+===============================================================================+
|                                                                               |
|   PRIMARY NODE (wallix-a1)              STANDBY NODE (wallix-a2)             |
|   =====================                 ======================                |
|                                                                               |
|   +---------------------------+         +---------------------------+        |
|   |      PostgreSQL 15+       |         |      PostgreSQL 15+       |        |
|   |                           |         |                           |        |
|   |  +---------------------+  |   WAL   |  +---------------------+  |        |
|   |  |   WAL Writer        |--+-------->|  |   WAL Receiver      |  |        |
|   |  +---------------------+  |  Stream |  +---------------------+  |        |
|   |                           |  (5432) |                           |        |
|   |  +---------------------+  |         |  +---------------------+  |        |
|   |  |   Data Files        |  |         |  |   Data Files        |  |        |
|   |  |   (Read/Write)      |  |         |  |   (Read-Only)       |  |        |
|   |  +---------------------+  |         |  +---------------------+  |        |
|   |                           |         |                           |        |
|   +---------------------------+         +---------------------------+        |
|                                                                               |
|   Synchronous Commit: ON                Hot Standby: ON                      |
|   (Wait for standby ACK)                (Read queries allowed)               |
|                                                                               |
+===============================================================================+
```

### Key Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `wal_level` | replica | Enable WAL for replication |
| `max_wal_senders` | 5 | Maximum concurrent replication connections |
| `wal_keep_size` | 1GB | WAL retention for slow standbys |
| `synchronous_commit` | on | Wait for standby confirmation (zero data loss) |
| `hot_standby` | on | Allow read queries on standby |

---

## Prerequisites

### Network Requirements

```
+===============================================================================+
|                         NETWORK REQUIREMENTS                                  |
+===============================================================================+
|                                                                               |
|   +-------------------+                     +-------------------+            |
|   |   PRIMARY NODE    |                     |   STANDBY NODE    |            |
|   |   10.100.254.1    |<----- Port 5432 --->|   10.100.254.2    |            |
|   +-------------------+        (TCP)        +-------------------+            |
|                                                                               |
|   Latency: < 5ms recommended for synchronous replication                     |
|   Bandwidth: Sufficient for WAL traffic (depends on write load)              |
|                                                                               |
+===============================================================================+
```

| Requirement | Specification |
|-------------|---------------|
| **Port** | 5432/TCP open between nodes |
| **Network** | Dedicated replication network recommended |
| **Latency** | < 5ms for synchronous mode |
| **Firewall** | Allow PostgreSQL traffic between nodes |

### Storage Requirements

| Item | Minimum | Recommended |
|------|---------|-------------|
| **WAL Space** | 2GB | 5GB+ |
| **Data Space** | Same as primary | Same as primary + 20% |
| **IOPS** | Match primary | Match primary |

---

## Primary Node Configuration

### Step 1: Configure PostgreSQL for Replication

Edit `/etc/postgresql/15/main/postgresql.conf`:

```bash
cat >> /etc/postgresql/15/main/postgresql.conf << 'EOF'

# =============================================================================
# STREAMING REPLICATION - PRIMARY NODE SETTINGS
# =============================================================================

# WAL Settings
wal_level = replica                    # Enable replication WAL
max_wal_senders = 5                    # Max replication connections
wal_keep_size = 1GB                    # WAL retention for standbys

# Synchronous Replication
synchronous_commit = on                # Wait for standby ACK
synchronous_standby_names = 'wallix-a2' # Standby identifier

# Hot Standby Support
hot_standby = on                       # Allow reads on standby

# Archive Settings (optional but recommended)
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/archive/%f'
EOF
```

### Step 2: Configure Authentication

Edit `/etc/postgresql/15/main/pg_hba.conf`:

```bash
cat >> /etc/postgresql/15/main/pg_hba.conf << 'EOF'

# =============================================================================
# REPLICATION ACCESS
# =============================================================================

# Allow replication from standby node
host    replication     replicator      10.100.254.2/32         scram-sha-256

# Allow replication from cluster network (if using heartbeat network)
host    replication     replicator      192.168.100.0/24        scram-sha-256
EOF
```

### Step 3: Create Replication User

```bash
sudo -u postgres psql << 'EOF'
-- Create replication role with secure password
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'YourSecureReplicationPassword!';

-- Verify role creation
\du replicator
EOF
```

### Step 4: Create Archive Directory (Optional)

```bash
# Create WAL archive directory
mkdir -p /var/lib/postgresql/archive
chown postgres:postgres /var/lib/postgresql/archive
chmod 700 /var/lib/postgresql/archive
```

### Step 5: Restart PostgreSQL

```bash
systemctl restart postgresql

# Verify PostgreSQL is running
systemctl status postgresql

# Check for errors
journalctl -u postgresql -n 50
```

---

## Standby Node Configuration

### Step 1: Stop PostgreSQL

```bash
systemctl stop postgresql
```

### Step 2: Clear Existing Data

```bash
# CAUTION: This removes all existing data
rm -rf /var/lib/postgresql/15/main/*
```

### Step 3: Perform Base Backup

```bash
# Copy data from primary using pg_basebackup
sudo -u postgres pg_basebackup \
    -h 10.100.254.1 \
    -U replicator \
    -D /var/lib/postgresql/15/main \
    -P \
    -R \
    -X stream \
    -C -S wallix_a2_slot

# Options explained:
# -h: Primary host
# -U: Replication user
# -D: Data directory
# -P: Show progress
# -R: Create standby.signal and configure primary_conninfo
# -X stream: Stream WAL during backup
# -C -S: Create replication slot (prevents WAL deletion)
```

### Step 4: Configure Standby Settings

The `-R` flag creates the necessary files, but verify configuration:

```bash
# Check standby.signal exists
ls -la /var/lib/postgresql/15/main/standby.signal

# Verify postgresql.auto.conf has primary_conninfo
cat /var/lib/postgresql/15/main/postgresql.auto.conf
```

Add additional standby settings:

```bash
cat >> /etc/postgresql/15/main/postgresql.conf << 'EOF'

# =============================================================================
# STREAMING REPLICATION - STANDBY NODE SETTINGS
# =============================================================================

# Hot Standby
hot_standby = on                       # Allow read queries

# Connection to Primary
primary_conninfo = 'host=10.100.254.1 port=5432 user=replicator password=YourSecureReplicationPassword! application_name=wallix-a2'
primary_slot_name = 'wallix_a2_slot'

# Recovery Target (optional)
# recovery_target_timeline = 'latest'
EOF
```

### Step 5: Start PostgreSQL

```bash
systemctl start postgresql

# Verify standby mode
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
# Should return: t (true)
```

---

## Pacemaker Integration

### Resource Configuration

Configure Pacemaker to manage PostgreSQL with automatic failover:

```bash
# Create PostgreSQL resource with streaming replication
pcs resource create pgsql-cluster ocf:heartbeat:pgsql \
    pgctl="/usr/lib/postgresql/15/bin/pg_ctl" \
    pgdata="/var/lib/postgresql/15/main" \
    config="/etc/postgresql/15/main/postgresql.conf" \
    rep_mode="sync" \
    node_list="wallix-a1 wallix-a2" \
    primary_conninfo_opt="keepalives_idle=60 keepalives_interval=5 keepalives_count=5" \
    master_ip="10.100.1.100" \
    restore_command="cp /var/lib/postgresql/archive/%f %p" \
    op start timeout=60s \
    op stop timeout=60s \
    op promote timeout=60s \
    op demote timeout=60s \
    op monitor interval=10s role=Master timeout=30s \
    op monitor interval=30s role=Slave timeout=30s

# Configure as promotable resource (master/slave)
pcs resource promotable pgsql-cluster \
    promoted-max=1 \
    promoted-node-max=1 \
    clone-max=2 \
    clone-node-max=1 \
    notify=true

# Ensure VIP runs on the PostgreSQL primary
pcs constraint colocation add wallix-vip with pgsql-cluster-clone INFINITY with-rsc-role=Master
pcs constraint order promote pgsql-cluster-clone then start wallix-vip
```

### Failover Sequence

```
+===============================================================================+
|                         AUTOMATIC FAILOVER SEQUENCE                           |
+===============================================================================+
|                                                                               |
|   TIME    EVENT                                                               |
|   ----    -----                                                               |
|                                                                               |
|   T+0s    Primary node failure detected (heartbeat timeout)                  |
|           |                                                                   |
|           v                                                                   |
|   T+5s    Pacemaker validates failure (fencing if configured)                |
|           |                                                                   |
|           v                                                                   |
|   T+10s   Standby promoted to Primary                                        |
|           - standby.signal removed                                           |
|           - pg_ctl promote executed                                          |
|           - Timeline incremented                                             |
|           |                                                                   |
|           v                                                                   |
|   T+15s   VIP migrated to new Primary                                        |
|           |                                                                   |
|           v                                                                   |
|   T+20s   WALLIX services started on new Primary                             |
|           |                                                                   |
|           v                                                                   |
|   T+25s   Service fully restored                                             |
|                                                                               |
|   TOTAL FAILOVER TIME: ~25 seconds                                           |
|                                                                               |
+===============================================================================+
```

---

## Monitoring and Verification

### Check Replication Status

**On Primary Node:**

```bash
# View connected standbys
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"

# Expected output columns:
# - pid: Backend process ID
# - usename: replicator
# - application_name: wallix-a2
# - client_addr: 10.100.254.2
# - state: streaming
# - sync_state: sync (for synchronous) or async
```

**On Standby Node:**

```bash
# Verify recovery mode
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
# Returns: t

# Check replication lag
sudo -u postgres psql -c "SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;"

# View WAL receiver status
sudo -u postgres psql -c "SELECT * FROM pg_stat_wal_receiver;"
```

### Monitor Replication Lag

```bash
# Create monitoring script
cat > /usr/local/bin/check_pg_replication.sh << 'EOF'
#!/bin/bash

# Check if primary
IS_PRIMARY=$(sudo -u postgres psql -t -c "SELECT NOT pg_is_in_recovery();")

if [[ "$IS_PRIMARY" == *"t"* ]]; then
    echo "=== PRIMARY NODE ==="
    echo "Connected standbys:"
    sudo -u postgres psql -c "
        SELECT
            application_name,
            client_addr,
            state,
            sync_state,
            pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
        FROM pg_stat_replication;"
else
    echo "=== STANDBY NODE ==="
    echo "Replication status:"
    sudo -u postgres psql -c "
        SELECT
            sender_host,
            status,
            pg_wal_lsn_diff(latest_end_lsn, received_lsn) AS pending_bytes
        FROM pg_stat_wal_receiver;"

    echo ""
    echo "Replication lag:"
    sudo -u postgres psql -t -c "SELECT now() - pg_last_xact_replay_timestamp();"
fi
EOF

chmod +x /usr/local/bin/check_pg_replication.sh
```

### Replication Slots

```bash
# View replication slots (on primary)
sudo -u postgres psql -c "SELECT * FROM pg_replication_slots;"

# Create slot manually if needed
sudo -u postgres psql -c "SELECT pg_create_physical_replication_slot('wallix_a2_slot');"

# Drop unused slot (CAUTION: may cause WAL accumulation issues)
sudo -u postgres psql -c "SELECT pg_drop_replication_slot('old_slot_name');"
```

---

## Failover Procedures

### Automatic Failover (Pacemaker)

Pacemaker handles failover automatically. Monitor with:

```bash
# Check cluster status
pcs status

# View resource status
pcs resource status pgsql-cluster-clone

# Check failover history
pcs resource failcount show pgsql-cluster-clone
```

### Manual Failover

If Pacemaker is not managing PostgreSQL:

**On Standby (promote to primary):**

```bash
# Promote standby to primary
sudo -u postgres /usr/lib/postgresql/15/bin/pg_ctl promote \
    -D /var/lib/postgresql/15/main

# Or using SQL
sudo -u postgres psql -c "SELECT pg_promote();"

# Verify promotion
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
# Should return: f (false)
```

### Reinitialize Failed Primary as Standby

After failover, the old primary must be reinitialized as standby:

```bash
# On failed primary (now becoming standby)
systemctl stop postgresql

# Clear data
rm -rf /var/lib/postgresql/15/main/*

# Sync from new primary
sudo -u postgres pg_basebackup \
    -h 10.100.254.2 \
    -U replicator \
    -D /var/lib/postgresql/15/main \
    -P -R -X stream

# Update primary_conninfo to point to new primary
# Edit postgresql.auto.conf or postgresql.conf

# Start as standby
systemctl start postgresql
```

---

## Troubleshooting

### Common Issues

```
+===============================================================================+
|                         TROUBLESHOOTING GUIDE                                 |
+===============================================================================+

ISSUE: Replication not starting
-------------------------------
Symptoms: pg_stat_replication shows no rows

Check:
1. Network connectivity: ping 10.100.254.1
2. Port access: nc -zv 10.100.254.1 5432
3. pg_hba.conf allows replication from standby IP
4. Replicator password is correct
5. Firewall rules allow port 5432

Fix:
- Verify pg_hba.conf entry on primary
- Test connection: psql -h 10.100.254.1 -U replicator -d postgres

------------------------------------------------------------------------------

ISSUE: Replication lag increasing
---------------------------------
Symptoms: Lag keeps growing, sync_state shows 'async'

Check:
1. Network bandwidth between nodes
2. Disk I/O on standby
3. WAL generation rate on primary

Fix:
- Increase network bandwidth
- Upgrade standby storage
- Consider async replication if lag is acceptable

------------------------------------------------------------------------------

ISSUE: WAL segments accumulating on primary
-------------------------------------------
Symptoms: pg_wal directory growing, disk filling

Check:
1. Standby connected: SELECT * FROM pg_stat_replication;
2. Unused replication slots: SELECT * FROM pg_replication_slots;

Fix:
- Reconnect standby
- Drop unused slots: SELECT pg_drop_replication_slot('slot_name');
- Increase wal_keep_size if standbys are slow

------------------------------------------------------------------------------

ISSUE: Timeline mismatch after failover
---------------------------------------
Symptoms: Standby cannot connect, "timeline X not found" errors

Check:
1. Timeline on primary: SELECT timeline_id FROM pg_control_checkpoint();
2. recovery_target_timeline setting

Fix:
- Reinitialize standby with pg_basebackup
- Or use pg_rewind if available

+===============================================================================+
```

### Log Locations

```bash
# PostgreSQL logs
/var/log/postgresql/postgresql-15-main.log

# View recent errors
tail -100 /var/log/postgresql/postgresql-15-main.log | grep -i error

# Pacemaker logs
journalctl -u pacemaker -n 100

# Corosync logs
journalctl -u corosync -n 100
```

### Health Check Script

```bash
cat > /usr/local/bin/pg_health_check.sh << 'EOF'
#!/bin/bash

echo "=== PostgreSQL Replication Health Check ==="
echo "Date: $(date)"
echo ""

# Check PostgreSQL service
echo "1. Service Status:"
systemctl is-active postgresql && echo "   PostgreSQL: RUNNING" || echo "   PostgreSQL: STOPPED"

# Check recovery status
echo ""
echo "2. Node Role:"
RECOVERY=$(sudo -u postgres psql -t -c "SELECT pg_is_in_recovery();")
if [[ "$RECOVERY" == *"t"* ]]; then
    echo "   Role: STANDBY"
else
    echo "   Role: PRIMARY"
fi

# Check connections
echo ""
echo "3. Replication Status:"
if [[ "$RECOVERY" == *"f"* ]]; then
    sudo -u postgres psql -c "SELECT application_name, state, sync_state FROM pg_stat_replication;"
else
    sudo -u postgres psql -c "SELECT sender_host, status FROM pg_stat_wal_receiver;"
    echo ""
    echo "   Lag: $(sudo -u postgres psql -t -c "SELECT now() - pg_last_xact_replay_timestamp();")"
fi

# Check disk space
echo ""
echo "4. Disk Space:"
df -h /var/lib/postgresql | tail -1 | awk '{print "   Data: "$5" used ("$4" free)"}'

echo ""
echo "=== Check Complete ==="
EOF

chmod +x /usr/local/bin/pg_health_check.sh
```

---

## Quick Reference

### Commands Summary

| Task | Command |
|------|---------|
| Check replication (primary) | `psql -c "SELECT * FROM pg_stat_replication;"` |
| Check recovery status | `psql -c "SELECT pg_is_in_recovery();"` |
| Check replication lag | `psql -c "SELECT now() - pg_last_xact_replay_timestamp();"` |
| Promote standby | `pg_ctl promote -D /var/lib/postgresql/15/main` |
| Create replication slot | `psql -c "SELECT pg_create_physical_replication_slot('name');"` |
| View slots | `psql -c "SELECT * FROM pg_replication_slots;"` |
| Base backup | `pg_basebackup -h PRIMARY -U replicator -D /path -P -R` |

### Port Requirements

| Port | Protocol | Direction | Purpose |
|------|----------|-----------|---------|
| 5432 | TCP | Primary ↔ Standby | PostgreSQL streaming replication |

---

## References

- [PostgreSQL Streaming Replication Documentation](https://www.postgresql.org/docs/15/warm-standby.html)
- [pg_basebackup Manual](https://www.postgresql.org/docs/15/app-pgbasebackup.html)
- [Pacemaker PostgreSQL Resource Agent](https://github.com/ClusterLabs/resource-agents)

---

*Document Version: 1.0 | WALLIX Bastion 12.x | PostgreSQL 15+*
