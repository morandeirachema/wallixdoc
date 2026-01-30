# MariaDB HA Database Replication Guide

## WALLIX Bastion 12.x Database High Availability

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Master/Master Configuration](#mastermaster-configuration)
- [Master/Slave Configuration](#masterslave-configuration)
- [SSH Tunnel Setup](#ssh-tunnel-setup)
- [Monitoring and Verification](#monitoring-and-verification)
- [Failover Procedures](#failover-procedures)
- [Troubleshooting](#troubleshooting)

---

## Overview

WALLIX Bastion uses MariaDB for database operations with two replication modes for high availability:

- **Master/Master**: Both nodes can accept writes (Active-Active)
- **Master/Slave(s)**: One writable primary with read-only replicas (Active-Passive)

### Key Components

| Component | Purpose |
|-----------|---------|
| `bastion-replication` | CLI tool to configure and manage replication |
| `autossh` | Maintains persistent SSH tunnels for secure replication |
| `/etc/sqlreplication` | Configuration directory for replication settings |

### Replication Architecture

```
+===============================================================================+
|                    MARIADB HA DATABASE REPLICATION                            |
+===============================================================================+
|                                                                               |
|   MASTER NODE (wallix-a1)               MASTER NODE (wallix-a2)              |
|   ====================                  ====================                  |
|                                                                               |
|   +---------------------------+         +---------------------------+         |
|   |        MariaDB            |         |        MariaDB            |         |
|   |                           |         |                           |         |
|   |  +---------------------+  |  SSH    |  +---------------------+  |         |
|   |  |   Port 3306         |<-+- Tunnel-+->|   Port 3306         |  |         |
|   |  |   (Local DB)        |  | (2242)  |  |   (Local DB)        |  |         |
|   |  +---------------------+  |         |  +---------------------+  |         |
|   |                           |         |                           |         |
|   |  +---------------------+  |         |  +---------------------+  |         |
|   |  |   Port 3307         |  |         |  |   Port 3307         |  |         |
|   |  |   (Remote Forward)  |  |         |  |   (Remote Forward)  |  |         |
|   |  +---------------------+  |         |  +---------------------+  |         |
|   |                           |         |                           |         |
|   +---------------------------+         +---------------------------+         |
|                                                                               |
|   Bidirectional Replication via SSH Tunnels                                  |
|   Port 3307 (outbound) --> SSH Tunnel --> Port 3306 (inbound)                |
|                                                                               |
+===============================================================================+
```

### Port Reference

| Port | Direction | Purpose |
|------|-----------|---------|
| 3306 | Inbound | MariaDB local connections |
| 3307 | Outbound | MariaDB replication source |
| 2242 | Bidirectional | SSH tunnel for secure replication |

---

## Prerequisites

### Network Requirements

```
+===============================================================================+
|                         NETWORK REQUIREMENTS                                  |
+===============================================================================+
|                                                                               |
|   +-------------------+                     +-------------------+             |
|   |   MASTER NODE 1   |                     |   MASTER NODE 2   |             |
|   |   10.100.254.1    |<---- Port 2242 ---->|   10.100.254.2    |             |
|   +-------------------+    (SSH Tunnel)     +-------------------+             |
|                                                                               |
|   Internal Communication:                                                     |
|   - Port 3306: Local MariaDB                                                  |
|   - Port 3307: Replication traffic (via SSH tunnel)                          |
|                                                                               |
+===============================================================================+
```

| Requirement | Specification |
|-------------|---------------|
| **SSH Port** | 2242/TCP open between nodes |
| **Network** | Dedicated replication network recommended |
| **Latency** | < 10ms for synchronous mode |
| **Firewall** | Allow SSH (2242) between nodes |

### Software Requirements

- WALLIX Bastion 12.x installed on both nodes
- SSH key-based authentication configured
- `autossh` package installed (included with Bastion)

---

## Master/Master Configuration

Master/Master mode provides Active-Active replication where both nodes can accept writes.

### Step 1: Prepare Both Nodes

Ensure both WALLIX Bastion nodes are installed and operational:

```bash
# Verify WALLIX Bastion status on both nodes
systemctl status wallix-bastion
wabadmin status
```

### Step 2: Configure SSH Key Authentication

Generate and exchange SSH keys between nodes:

```bash
# On Node 1 (wallix-a1)
ssh-keygen -t ed25519 -f /var/wab/.ssh/replication_key -N ""

# Copy public key to Node 2
ssh-copy-id -i /var/wab/.ssh/replication_key.pub -p 2242 wabadmin@10.100.254.2

# Repeat on Node 2 for bidirectional access
```

### Step 3: Initialize Replication

Use the `bastion-replication` command to configure Master/Master replication:

```bash
# On Node 1 (wallix-a1) - Initialize as first master
bastion-replication init --mode master-master --peer 10.100.254.2

# Follow the prompts to complete configuration
```

### Step 4: Join Second Node

```bash
# On Node 2 (wallix-a2) - Join as second master
bastion-replication join --peer 10.100.254.1
```

### Step 5: Verify Configuration

```bash
# Check replication status on both nodes
bastion-replication status

# Expected output shows:
# - Mode: Master/Master
# - Peer: Connected
# - Sync Status: OK
```

---

## Master/Slave Configuration

Master/Slave mode provides Active-Passive replication with one writable master.

### Step 1: Configure Primary (Master)

```bash
# On Primary Node
bastion-replication init --mode master-slave --role master
```

### Step 2: Configure Secondary (Slave)

```bash
# On Secondary Node
bastion-replication join --peer 10.100.254.1 --role slave
```

### Step 3: Add Additional Slaves (Optional)

```bash
# On additional slave nodes
bastion-replication join --peer 10.100.254.1 --role slave
```

---

## SSH Tunnel Setup

WALLIX Bastion uses SSH tunnels to secure MariaDB replication traffic.

### How It Works

```
+===============================================================================+
|                         SSH TUNNEL ARCHITECTURE                               |
+===============================================================================+
|                                                                               |
|   NODE 1                                   NODE 2                             |
|   ------                                   ------                             |
|                                                                               |
|   MariaDB (3306)                           MariaDB (3306)                     |
|        |                                        ^                             |
|        v                                        |                             |
|   localhost:3307  -----> SSH Tunnel -----> localhost:3306                     |
|                          (Port 2242)                                          |
|                                                                               |
|   The autossh service maintains persistent tunnels                            |
|   Replication connects to localhost:3307 which forwards to remote:3306       |
|                                                                               |
+===============================================================================+
```

### Autossh Service

The `autossh` service automatically maintains SSH tunnels:

```bash
# Check autossh status
systemctl status autossh-replication

# View tunnel connections
ss -tlnp | grep 3307

# Restart if needed
systemctl restart autossh-replication
```

### Configuration Files

Replication configuration is stored in `/etc/sqlreplication`:

```bash
# View replication configuration
ls -la /etc/sqlreplication/

# Key files:
# - replication.conf     : Main configuration
# - peers.conf           : Peer node definitions
# - ssh_config           : SSH tunnel settings
```

---

## Monitoring and Verification

### Check Replication Status

```bash
# Primary method - use bastion-replication
bastion-replication status

# View detailed status
bastion-replication status --verbose
```

### MariaDB Replication Status

**On Master Node (in Master/Slave mode):**

```bash
# Check master status
sudo mysql -e "SHOW MASTER STATUS\G"

# View connected slaves
sudo mysql -e "SHOW SLAVE HOSTS;"
```

**On Slave Node:**

```bash
# Check slave status
sudo mysql -e "SHOW SLAVE STATUS\G"

# Key fields to monitor:
# - Slave_IO_Running: Yes
# - Slave_SQL_Running: Yes
# - Seconds_Behind_Master: 0 (ideally)
```

### Create Monitoring Script

```bash
cat > /usr/local/bin/check_mariadb_replication.sh << 'EOF'
#!/bin/bash

echo "=== MariaDB Replication Health Check ==="
echo "Date: $(date)"
echo ""

# Check replication service
echo "1. Replication Service Status:"
bastion-replication status | head -10

# Check autossh tunnel
echo ""
echo "2. SSH Tunnel Status:"
if systemctl is-active autossh-replication > /dev/null 2>&1; then
    echo "   autossh: RUNNING"
    ss -tlnp | grep 3307 | awk '{print "   Tunnel: "$4}'
else
    echo "   autossh: STOPPED"
fi

# Check MariaDB
echo ""
echo "3. MariaDB Status:"
if systemctl is-active mariadb > /dev/null 2>&1; then
    echo "   MariaDB: RUNNING"
else
    echo "   MariaDB: STOPPED"
fi

# Check slave status (if applicable)
echo ""
echo "4. Replication Lag:"
LAG=$(sudo mysql -N -e "SHOW SLAVE STATUS\G" 2>/dev/null | grep "Seconds_Behind_Master" | awk '{print $2}')
if [ -n "$LAG" ]; then
    echo "   Seconds Behind Master: $LAG"
else
    echo "   Node is Master or replication not configured"
fi

echo ""
echo "=== Check Complete ==="
EOF

chmod +x /usr/local/bin/check_mariadb_replication.sh
```

---

## Failover Procedures

### Automatic Failover with Pacemaker

When integrated with Pacemaker, failover is automatic:

```bash
# Check cluster status
crm status

# View resource status
crm resource status

# Check failover history
crm resource failcount show
```

### Manual Failover (Master/Slave)

If manual failover is required:

**Step 1: Stop Applications on Failed Master**

```bash
# On failed master (if accessible)
systemctl stop wallix-bastion
```

**Step 2: Promote Slave to Master**

```bash
# On slave being promoted
bastion-replication promote

# This will:
# - Stop slave replication
# - Configure node as new master
# - Update configuration
```

**Step 3: Verify New Master**

```bash
# Verify promotion
bastion-replication status

# Check MariaDB is writable
sudo mysql -e "SELECT @@read_only;"
# Should return 0 (writable)
```

### Reinitialize Failed Master as Slave

After recovery, add the old master back as a slave:

```bash
# On recovered node
bastion-replication join --peer NEW_MASTER_IP --role slave

# Or reinitialize completely
bastion-replication reinit --peer NEW_MASTER_IP --role slave
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
Symptoms: bastion-replication status shows "Disconnected"

Check:
1. SSH connectivity: ssh -p 2242 wabadmin@PEER_IP
2. Autossh service: systemctl status autossh-replication
3. Port 3307 listening: ss -tlnp | grep 3307
4. Firewall allows port 2242

Fix:
- Restart autossh: systemctl restart autossh-replication
- Check SSH keys: ssh-keygen -y -f /var/wab/.ssh/replication_key
- Verify peer configuration in /etc/sqlreplication/peers.conf

------------------------------------------------------------------------------

ISSUE: Slave replication stopped
--------------------------------
Symptoms: SHOW SLAVE STATUS shows Slave_SQL_Running: No

Check:
1. View error: sudo mysql -e "SHOW SLAVE STATUS\G" | grep Last_Error
2. Check binary log position

Fix:
- Skip error (if safe): sudo mysql -e "SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1; START SLAVE;"
- Or reinitialize slave: bastion-replication reinit --role slave

------------------------------------------------------------------------------

ISSUE: Replication lag increasing
---------------------------------
Symptoms: Seconds_Behind_Master keeps growing

Check:
1. Network latency between nodes
2. Disk I/O on slave
3. Long-running transactions on master

Fix:
- Investigate slow queries: sudo mysql -e "SHOW PROCESSLIST;"
- Increase network bandwidth
- Optimize slow queries on master

------------------------------------------------------------------------------

ISSUE: SSH tunnel disconnecting
-------------------------------
Symptoms: Intermittent replication failures

Check:
1. autossh logs: journalctl -u autossh-replication
2. Network stability between nodes
3. SSH configuration

Fix:
- Increase SSH keepalive: Add to /etc/sqlreplication/ssh_config:
  ServerAliveInterval 30
  ServerAliveCountMax 3
- Restart autossh service

+===============================================================================+
```

### Log Locations

```bash
# WALLIX Bastion logs
/var/log/wab/wabaudit.log

# MariaDB logs
/var/log/mysql/error.log

# Autossh logs
journalctl -u autossh-replication

# Replication-specific logs
/var/log/wab/replication.log
```

### Health Check Commands

```bash
# Complete health check
bastion-replication health

# Test connectivity to peer
bastion-replication test-connection

# Verify data consistency
bastion-replication verify
```

---

## Database Password Management

### Change Database Root Password

Use the WALLIX-provided command for password changes:

```bash
# Change database root password securely
WABChangeDbRootPassword

# Follow the prompts to set new password
# This updates all necessary configuration files
```

---

## Quick Reference

### Commands Summary

| Task | Command |
|------|---------|
| Check replication status | `bastion-replication status` |
| Initialize replication | `bastion-replication init --mode [mode]` |
| Join cluster | `bastion-replication join --peer [IP]` |
| Promote slave to master | `bastion-replication promote` |
| Reinitialize node | `bastion-replication reinit` |
| Check MariaDB slave status | `sudo mysql -e "SHOW SLAVE STATUS\G"` |
| Check MariaDB master status | `sudo mysql -e "SHOW MASTER STATUS\G"` |
| Restart replication tunnel | `systemctl restart autossh-replication` |

### Port Requirements

| Port | Protocol | Direction | Purpose |
|------|----------|-----------|---------|
| 3306 | TCP | Local | MariaDB database connections |
| 3307 | TCP | Via tunnel | Replication source (outbound to remote 3306) |
| 2242 | TCP | Bidirectional | SSH tunnel for secure replication |

### Configuration Locations

| Path | Purpose |
|------|---------|
| `/etc/sqlreplication/` | Replication configuration directory |
| `/var/lib/mysql/` | MariaDB data directory |
| `/var/wab/.ssh/` | SSH keys for replication tunnels |

---

## References

- WALLIX Bastion 12.0.2 Deployment Guide - HA Database Replication (Pages 25-26)
- MariaDB Replication Documentation: https://mariadb.com/kb/en/replication/
- WALLIX Support Portal: https://support.wallix.com

---

*Document Version: 2.0 | WALLIX Bastion 12.x | MariaDB HA Database Replication*
