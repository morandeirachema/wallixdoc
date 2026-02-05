# Active-Passive WALLIX Bastion Hardware Appliance Cluster

> Step-by-step deployment guide for Active-Passive high availability configuration with automatic failover using Pacemaker and MariaDB replication

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Active-Passive cluster deployment for WALLIX Bastion HW appliances |
| **Configuration** | 2 appliances per site: 1 Primary (Active) + 1 Standby (Passive) |
| **Failover Time** | 30-60 seconds automatic |
| **Complexity** | Medium (simpler than Active-Active) |
| **Best For** | Sites with < 100 concurrent sessions, simplicity priority |
| **Version** | WALLIX Bastion 12.1.x |
| **Last Updated** | February 2026 |

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Initial Appliance Setup](#initial-appliance-setup)
4. [Network Configuration](#network-configuration)
5. [MariaDB Master-Slave Replication](#mariadb-master-slave-replication)
6. [Pacemaker Cluster Setup](#pacemaker-cluster-setup)
7. [Virtual IP Configuration](#virtual-ip-configuration)
8. [WALLIX Bastion Configuration](#wallix-bastion-configuration)
9. [Standby Node Synchronization](#standby-node-synchronization)
10. [Failover Testing](#failover-testing)
11. [Failback Procedures](#failback-procedures)
12. [Performance Tuning](#performance-tuning)
13. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### 1.1 Active-Passive Cluster Design

```
+===============================================================================+
|  ACTIVE-PASSIVE WALLIX BASTION CLUSTER ARCHITECTURE                           |
+===============================================================================+
|                                                                               |
|                         +--------------------------+                          |
|                         |  Virtual IP (Floating)   |                          |
|                         |  Managed by Pacemaker    |                          |
|                         |                          |                          |
|                         |  VIP: 10.10.X.10         |                          |
|                         +-----------+--------------+                          |
|                                     |                                         |
|                    +----------------+                                         |
|                    |                                                          |
|                    v                                                          |
|  +--------------------------------+                                           |
|  |  WALLIX BASTION NODE 1         |                                           |
|  |  (PRIMARY - ACTIVE)            |                                           |
|  |                                |                                           |
|  |  IP: 10.10.X.11                |          +--------------------------------+|
|  |  VIP: 10.10.X.10 (current)     |          |  WALLIX BASTION NODE 2         ||
|  |  IPMI: 10.10.X.211             |          |  (STANDBY - PASSIVE)           ||
|  |  Load: 100% traffic            |          |                                ||
|  |                                |          |  IP: 10.10.X.12                ||
|  |  +---------------------------+ |          |  VIP: - (not assigned)         ||
|  |  | WALLIX Bastion            | |          |  IPMI: 10.10.X.212             ||
|  |  | Services (Running)        | |          |  Load: 0% (idle)               ||
|  |  |                           | |          |                                ||
|  |  | - Session Manager         | |          |  +---------------------------+||
|  |  | - Password Manager        | |          |  | WALLIX Bastion            |||
|  |  | - Web UI                  | |          |  | Services (Stopped)        |||
|  |  | - API Server              | |          |  |                           |||
|  |  +---------------------------+ |          |  | - Session Manager (OFF)   |||
|  |                                |          |  | - Password Manager (OFF)  |||
|  |  +---------------------------+ |          |  | - Web UI (OFF)            |||
|  |  | MariaDB 10.11+            | |          |  | - API Server (OFF)        |||
|  |  | (PRIMARY)                 | |          |  +---------------------------+||
|  |  |                           | |          |                                ||
|  |  | Async Replication --------+-+--------->|  +---------------------------+||
|  |  | Binary Log: ON            | |          |  | MariaDB 10.11+            |||
|  |  | Server ID: 1              | |          |  | (REPLICA - Read-only)     |||
|  |  +---------------------------+ |          |  |                           |||
|  |                                |          |  | Relay Log: ON             |||
|  |  +---------------------------+ |          |  | Server ID: 2              |||
|  |  | Pacemaker Resources       | |          |  +---------------------------+||
|  |  | - VIP (10.10.X.10)        | |          |                                ||
|  |  | - WALLIX Services (ON)    | |          |  +---------------------------+||
|  |  +---------------------------+ |          |  | Pacemaker Resources       |||
|  |                                |          |  | - VIP (not assigned)      |||
|  +--------------------------------+          |  | - WALLIX Services (OFF)   |||
|                    |                         |  +---------------------------+||
|                    |                         |                                ||
|                    |                         +--------------------------------+|
|                    |                                         |                 |
|                    +----------------+------------------------+                 |
|                                     |                                          |
|                         +-----------+--------------+                           |
|                         |  Shared Storage (NAS)    |                           |
|                         |  Session Recordings      |                           |
|                         |  /var/wab/recorded       |                           |
|                         |  NFS/iSCSI Mount         |                           |
|                         +--------------------------+                           |
|                                                                                |
|  HEARTBEAT MONITORING (Dedicated Network - VLAN X+100)                         |
|  ====================                                                          |
|  Node 1 (192.168.100.11) <--- Corosync Heartbeat (every 1s) ---> Node 2       |
|                                      UDP 5405                                  |
|                                                                                |
|  FAILOVER PROCESS (Automatic)                                                  |
|  ============================                                                  |
|    0s --------> Node 1 fails (hardware/network/service)                        |
|    3s --------> Node 2 detects 3 consecutive missed heartbeats                 |
|    8s --------> STONITH fence primary via IPMI (optional but recommended)      |
|    15s -------> MariaDB replica promoted to primary (READ_ONLY=OFF)            |
|    25s -------> WALLIX Bastion services started on Node 2                      |
|    35s -------> VIP migrated to Node 2, gratuitous ARP sent                    |
|    45s -------> Node 2 ready to accept new sessions                            |
|                                                                                |
|  TOTAL FAILOVER TIME: 30-60 seconds                                            |
|                                                                                |
+===============================================================================+
```

### 1.2 Key Characteristics

| Aspect | Details |
|--------|---------|
| **Primary Node** | Handles 100% of traffic, all services running |
| **Standby Node** | Idle (0% load), services stopped, database replicating |
| **Virtual IP** | Floating IP managed by Pacemaker, assigned to active node |
| **Database Replication** | MariaDB async replication (Primary → Replica) |
| **Failover Trigger** | Heartbeat timeout, service failure, manual failover |
| **Failover Time** | 30-60 seconds (includes DB promotion, service start, VIP migration) |
| **Session Impact** | Active sessions disconnected, users must reconnect |
| **Data Loss Risk** | Minimal (up to ~5 seconds of replication lag) |

### 1.3 When to Use Active-Passive

**Recommended for:**
- Sites with < 100 concurrent sessions
- Single-node capacity sufficient for peak load
- Simplicity and ease of management priority
- Teams with standard Linux HA experience (not distributed systems experts)
- 99.5-99.9% availability SLA acceptable
- 30-60 second failover window acceptable

**Not recommended for:**
- Sites with > 100 concurrent sessions (use Active-Active)
- Requirement for sub-second failover
- Zero-downtime maintenance windows
- 99.99% availability SLA

---

## Prerequisites

### 2.1 Hardware Requirements (Per Site)

#### WALLIX Bastion Appliances (2x)

| Component | Specification | Notes |
|-----------|---------------|-------|
| **Model** | WALLIX Bastion HW Appliance | Specific model TBD by WALLIX sales |
| **CPU** | 8+ cores (physical) | Intel Xeon or AMD EPYC recommended |
| **RAM** | 16+ GB | 32 GB for large session volumes |
| **Disk** | 500 GB+ SSD | 1 TB+ for extensive session recordings |
| **Network** | 2x 1 GbE (bonded) | Redundant NICs for HA |
| **IPMI/iLO** | Required | For STONITH fencing |
| **Form Factor** | 1U or 2U rackmount | Depends on appliance model |

#### Shared Storage (NFS or iSCSI)

| Component | Specification | Notes |
|-----------|---------------|-------|
| **Capacity** | 1 TB+ | Session recording storage |
| **Performance** | 1000+ IOPS | SSD-backed recommended |
| **Redundancy** | RAID 10 or RAID 6 | Data protection |
| **Protocol** | NFS v4 or iSCSI | Both supported by WALLIX |
| **Network** | Dedicated VLAN | Isolated storage network |

### 2.2 Network Requirements

#### Production Network (VLAN X)

| Component | IP Address | Purpose |
|-----------|------------|---------|
| Node 1 Primary IP | 10.10.X.11/24 | Production interface |
| Node 2 Primary IP | 10.10.X.12/24 | Production interface |
| Virtual IP (VIP) | 10.10.X.10/24 | User-facing floating IP |
| Default Gateway | 10.10.X.1 | Fortigate firewall |

#### Heartbeat Network (VLAN X+100, Dedicated)

| Component | IP Address | Purpose |
|-----------|------------|---------|
| Node 1 Heartbeat | 192.168.100.11/24 | Cluster communication |
| Node 2 Heartbeat | 192.168.100.12/24 | Cluster communication |

**CRITICAL**: Heartbeat network MUST be physically separate or on dedicated VLAN to prevent false failovers.

#### IPMI/Out-of-Band Management

| Component | IP Address | Purpose |
|-----------|------------|---------|
| Node 1 IPMI | 10.10.X.211/24 | STONITH fencing, remote management |
| Node 2 IPMI | 10.10.X.212/24 | STONITH fencing, remote management |

### 2.3 Software Requirements

#### Operating System (Pre-installed on Appliances)

WALLIX Bastion appliances come with Debian 12 (Bookworm) pre-installed and hardened.

**NOTE**: Most configuration is done via `wabadmin` CLI and Web UI, not direct OS access.

#### Clustering Components (Verify Installation)

```bash
# SSH to appliance as admin user
ssh admin@10.10.X.11

# Check if Pacemaker/Corosync are available
wabadmin cluster-status
# Or via direct check (if shell access available):
dpkg -l | grep -E "pacemaker|corosync|pcs"
```

Expected packages on WALLIX Bastion 12.1.x:
- pacemaker >= 2.1
- corosync >= 3.1
- pcs (Pacemaker Configuration System)
- fence-agents (STONITH agents)
- fence-agents-ipmilan (IPMI fencing)

### 2.4 Access Requirements

| Service | Credentials | Purpose |
|---------|-------------|---------|
| **WALLIX admin account** | admin / (initial password) | Web UI and CLI access |
| **IPMI access** | ADMIN / (appliance-specific) | Fencing via ipmitool |
| **MariaDB root** | root / (auto-generated) | Database replication setup |
| **NFS/iSCSI** | mount credentials | Shared storage access |
| **Firewall rules** | Pre-configured | See [01-network-design.md](01-network-design.md) |

### 2.5 Prerequisites Checklist

- [ ] 2x WALLIX Bastion HW appliances racked and powered on
- [ ] IPMI/iLO configured with network access (10.10.X.211, 10.10.X.212)
- [ ] Production network configured (VLAN X, IPs .11, .12, .10 reserved)
- [ ] Heartbeat network configured (VLAN X+100, IPs 192.168.100.11, 192.168.100.12)
- [ ] Shared NFS/iSCSI storage mounted on both nodes at `/var/wab/recorded`
- [ ] DNS A records created: bastion-node1, bastion-node2, bastion-vip
- [ ] Firewall rules configured (see [01-network-design.md](01-network-design.md))
- [ ] NTP servers reachable from both nodes
- [ ] FortiAuthenticator RADIUS accessible (10.20.0.60)
- [ ] Active Directory LDAPS accessible (10.20.0.10:636)
- [ ] HAProxy load balancer configured to point to VIP (10.10.X.10)

---

## Initial Appliance Setup

### 3.1 Node 1 (Primary) Initial Configuration

#### 3.1.1 Connect to Appliance Console

```bash
# Via IPMI/iLO console or serial connection
# Initial login: admin / (default password)

# Change default password immediately
passwd
# Enter new strong password
```

#### 3.1.2 Configure Network Interfaces

```bash
# Configure primary production interface (bond0)
wabadmin network-config --interface bond0 --ip 10.10.X.11/24 --gateway 10.10.X.1

# Configure heartbeat interface (bond1)
wabadmin network-config --interface bond1 --ip 192.168.100.11/24 --no-gateway

# Set hostname
wabadmin hostname-set bastion-node1.wallix.company.local

# Configure DNS servers
wabadmin dns-set --primary 10.20.0.10 --secondary 10.20.0.11

# Verify configuration
wabadmin network-status
```

Expected output:
```
Interface: bond0
  IP: 10.10.X.11/24
  Gateway: 10.10.X.1
  Status: UP

Interface: bond1
  IP: 192.168.100.11/24
  Status: UP

Hostname: bastion-node1.wallix.company.local
DNS: 10.20.0.10, 10.20.0.11
```

#### 3.1.3 Configure NTP

```bash
# Configure NTP servers
wabadmin ntp-set --servers 10.20.0.20,10.20.0.21

# Force time sync
wabadmin ntp-sync

# Verify NTP status
wabadmin ntp-status
```

Expected output:
```
NTP Status: Synchronized
Reference ID: 10.20.0.20
Stratum: 3
Offset: -0.003 seconds
```

#### 3.1.4 Mount Shared Storage

```bash
# Mount NFS shared storage for session recordings
wabadmin storage-mount --type nfs --server 10.10.X.50 --path /wallix/recordings --mountpoint /var/wab/recorded

# Verify mount
df -h | grep recorded
```

Expected output:
```
10.10.X.50:/wallix/recordings  1.0T  100G  924G  10% /var/wab/recorded
```

### 3.2 Node 2 (Standby) Initial Configuration

Repeat the same steps as Node 1 with the following changes:

```bash
# Network configuration
wabadmin network-config --interface bond0 --ip 10.10.X.12/24 --gateway 10.10.X.1
wabadmin network-config --interface bond1 --ip 192.168.100.12/24 --no-gateway

# Hostname
wabadmin hostname-set bastion-node2.wallix.company.local

# NTP, DNS, and storage configuration identical to Node 1
```

### 3.3 Verify Connectivity Between Nodes

```bash
# From Node 1 (10.10.X.11)
ping -c 4 10.10.X.12
# Expected: 4 packets transmitted, 4 received, 0% packet loss

ping -c 4 192.168.100.12
# Expected: 4 packets transmitted, 4 received, 0% packet loss

# From Node 2 (10.10.X.12)
ping -c 4 10.10.X.11
ping -c 4 192.168.100.11
```

### 3.4 IPMI/Fencing Validation

```bash
# From Node 1, test IPMI access to Node 2
ipmitool -I lanplus -H 10.10.X.212 -U ADMIN -P <password> chassis power status
# Expected: Chassis Power is on

# Test power cycle (DO NOT RUN IN PRODUCTION)
# ipmitool -I lanplus -H 10.10.X.212 -U ADMIN -P <password> chassis power cycle

# From Node 2, test IPMI access to Node 1
ipmitool -I lanplus -H 10.10.X.211 -U ADMIN -P <password> chassis power status
```

**CRITICAL**: IPMI fencing is essential to prevent split-brain scenarios where both nodes think they are primary.

---

## Network Configuration

### 4.1 Interface Bonding (Redundant NICs)

WALLIX Bastion appliances typically come pre-configured with bonded interfaces for redundancy.

#### 4.1.1 Verify Bond Configuration

```bash
# Check bond status
wabadmin network-bond-status

# Or via system command (if shell access available)
cat /proc/net/bonding/bond0
```

Expected output:
```
Bonding Mode: active-backup (mode 1)
Primary Slave: eth0
Currently Active Slave: eth0
MII Status: up
Slave Interface: eth0
  MII Status: up
  Link Failure Count: 0
Slave Interface: eth1
  MII Status: up
  Link Failure Count: 0
```

#### 4.1.2 Bond Configuration Details

| Parameter | bond0 (Production) | bond1 (Heartbeat) |
|-----------|-------------------|-------------------|
| **Mode** | active-backup (1) | active-backup (1) |
| **Primary Slave** | eth0 | eth2 |
| **MII Monitoring** | 100ms | 100ms |
| **Fail Over MAC** | active | active |

### 4.2 Firewall Rules (Cluster Communication)

Ensure the following ports are open between Node 1 and Node 2:

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Node 1 (192.168.100.11) | Node 2 (192.168.100.12) | 5405 | UDP | Corosync unicast |
| Node 2 (192.168.100.12) | Node 1 (192.168.100.11) | 5405 | UDP | Corosync unicast |
| Node 1 (10.10.X.11) | Node 2 (10.10.X.12) | 2224 | TCP | PCSD (Pacemaker web UI) |
| Node 1 (10.10.X.11) | Node 2 (10.10.X.12) | 3121 | TCP | Pacemaker remote |
| Node 1 (10.10.X.11) | Node 2 (10.10.X.12) | 3306 | TCP | MariaDB replication |

```bash
# Verify firewall allows cluster traffic (from Node 1)
nc -zv 192.168.100.12 5405
nc -zv 10.10.X.12 2224
nc -zv 10.10.X.12 3306
```

### 4.3 Routing and Default Gateway

```bash
# Verify default route (Node 1 and Node 2)
ip route show

# Expected output:
# default via 10.10.X.1 dev bond0
# 10.10.X.0/24 dev bond0 proto kernel scope link src 10.10.X.11
# 192.168.100.0/24 dev bond1 proto kernel scope link src 192.168.100.11
```

---

## MariaDB Master-Slave Replication

### 5.1 Architecture: Primary → Replica Async Replication

```
+===============================================================================+
|  MARIADB REPLICATION TOPOLOGY                                                 |
+===============================================================================+
|                                                                               |
|  Node 1 (Primary)                       Node 2 (Replica)                      |
|  +---------------------------+          +---------------------------+         |
|  | MariaDB 10.11+            |          | MariaDB 10.11+            |         |
|  | Server ID: 1              |          | Server ID: 2              |         |
|  | Binary Log: ON            |          | Relay Log: ON             |         |
|  | READ_ONLY: OFF            |          | READ_ONLY: ON             |         |
|  |                           |          |                           |         |
|  | Writes: Allowed           |  Async   | Writes: Blocked           |         |
|  | Reads: Allowed            | -------> | Reads: Allowed            |         |
|  |                           |   Rep    |                           |         |
|  | Binary Logs:              |   3306   | Relay Logs:               |         |
|  |   mysql-bin.000001        |          |   relay-bin.000001        |         |
|  |   mysql-bin.000002        |          |   relay-bin.000002        |         |
|  +---------------------------+          +---------------------------+         |
|                                                                               |
|  REPLICATION FLOW                                                             |
|  ================                                                             |
|  1. Write transaction on Node 1                                              |
|  2. Written to binary log (mysql-bin)                                         |
|  3. Sent to Node 2 asynchronously                                             |
|  4. Node 2 writes to relay log                                                |
|  5. Node 2 applies to database (with slight lag)                              |
|                                                                               |
|  FAILOVER PROCESS                                                             |
|  ================                                                             |
|  1. Pacemaker detects Node 1 failure                                          |
|  2. Node 2 promotes: SET GLOBAL READ_ONLY=OFF                                 |
|  3. Node 2 becomes new primary (accepts writes)                               |
|                                                                               |
+===============================================================================+
```

### 5.2 Configure MariaDB on Node 1 (Primary)

#### 5.2.1 Edit MariaDB Configuration

**NOTE**: On WALLIX Bastion appliances, use `wabadmin` to configure MariaDB settings.

```bash
# SSH to Node 1
ssh admin@10.10.X.11

# Configure MariaDB for replication
wabadmin db-config --server-id 1 --binlog-enable --binlog-format row

# Restart MariaDB to apply changes
wabadmin db-restart
```

Alternatively, if direct file editing is available:

```bash
# Edit /etc/mysql/mariadb.conf.d/50-server.cnf
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

Add/modify:
```ini
[mysqld]
server-id                = 1
log_bin                  = /var/log/mysql/mysql-bin.log
binlog_format            = ROW
binlog_expire_logs_days  = 7
max_binlog_size          = 100M

# Replication safety
sync_binlog              = 1
innodb_flush_log_at_trx_commit = 1

# Bind to all interfaces (for replication)
bind-address             = 0.0.0.0
```

```bash
# Restart MariaDB
systemctl restart mariadb
```

#### 5.2.2 Create Replication User

```bash
# Connect to MariaDB as root
wabadmin db-shell
# Or: mysql -u root -p

# Create replication user
CREATE USER 'repl_user'@'10.10.X.12' IDENTIFIED BY 'StrongReplPassword123!';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'10.10.X.12';
FLUSH PRIVILEGES;

# Get binary log position for initial sync
SHOW MASTER STATUS;
```

**IMPORTANT**: Record the output of `SHOW MASTER STATUS`:
```
+------------------+----------+--------------+------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+------------------+----------+--------------+------------------+
| mysql-bin.000001 |      328 |              |                  |
+------------------+----------+--------------+------------------+
```

You will need `File` and `Position` values for Node 2 configuration.

### 5.3 Configure MariaDB on Node 2 (Replica)

#### 5.3.1 Edit MariaDB Configuration

```bash
# SSH to Node 2
ssh admin@10.10.X.12

# Configure MariaDB as replica
wabadmin db-config --server-id 2 --relay-log-enable --read-only

# Restart MariaDB
wabadmin db-restart
```

Alternatively, manual configuration:

```bash
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

Add/modify:
```ini
[mysqld]
server-id                = 2
relay-log                = /var/log/mysql/relay-bin
relay_log_index          = /var/log/mysql/relay-bin.index
read_only                = 1

# Bind to all interfaces
bind-address             = 0.0.0.0
```

```bash
systemctl restart mariadb
```

#### 5.3.2 Initialize Replication from Node 1

```bash
# Option 1: Use wabadmin (if available)
wabadmin db-replication-setup \
  --master-host 10.10.X.11 \
  --master-user repl_user \
  --master-password 'StrongReplPassword123!' \
  --master-log-file mysql-bin.000001 \
  --master-log-pos 328

# Option 2: Manual MariaDB commands
mysql -u root -p

CHANGE MASTER TO
  MASTER_HOST='10.10.X.11',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='StrongReplPassword123!',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=328;

START SLAVE;

# Verify replication status
SHOW SLAVE STATUS\G
```

Expected output (key fields):
```
Slave_IO_State: Waiting for master to send event
Master_Host: 10.10.X.11
Master_User: repl_user
Master_Log_File: mysql-bin.000001
Relay_Log_File: relay-bin.000002
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Seconds_Behind_Master: 0
Last_IO_Error:
Last_SQL_Error:
```

**CRITICAL**: Both `Slave_IO_Running` and `Slave_SQL_Running` MUST be "Yes".

### 5.4 Verify Replication Functionality

```bash
# On Node 1 (Primary), create test database
mysql -u root -p

CREATE DATABASE repl_test;
USE repl_test;
CREATE TABLE test (id INT PRIMARY KEY, data VARCHAR(100));
INSERT INTO test VALUES (1, 'Replication test');
```

```bash
# On Node 2 (Replica), verify data appeared
mysql -u root -p

USE repl_test;
SELECT * FROM test;
```

Expected output:
```
+----+------------------+
| id | data             |
+----+------------------+
|  1 | Replication test |
+----+------------------+
```

```bash
# Clean up test database (on Node 1)
DROP DATABASE repl_test;
```

### 5.5 Monitor Replication Lag

```bash
# Create monitoring script: /usr/local/bin/check-replication.sh

#!/bin/bash
LAG=$(mysql -u root -p'RootPassword' -e "SHOW SLAVE STATUS\G" | grep "Seconds_Behind_Master:" | awk '{print $2}')

if [ "$LAG" == "NULL" ]; then
  echo "ERROR: Replication stopped!"
  exit 2
elif [ "$LAG" -gt 10 ]; then
  echo "WARNING: Replication lag is ${LAG} seconds"
  exit 1
else
  echo "OK: Replication lag is ${LAG} seconds"
  exit 0
fi
```

```bash
chmod +x /usr/local/bin/check-replication.sh

# Run manually to test
/usr/local/bin/check-replication.sh

# Add to cron for monitoring (every 5 minutes)
echo "*/5 * * * * /usr/local/bin/check-replication.sh >> /var/log/replication-check.log 2>&1" | crontab -
```

---

## Pacemaker Cluster Setup

### 6.1 Pacemaker Cluster Overview

Pacemaker manages:
1. Virtual IP (VIP) assignment to active node
2. WALLIX Bastion services (start/stop)
3. Failover detection and orchestration
4. STONITH fencing (via IPMI)

### 6.2 Install Pacemaker (If Not Pre-installed)

**NOTE**: WALLIX Bastion appliances typically have Pacemaker pre-installed.

```bash
# Verify installation (both nodes)
dpkg -l | grep -E "pacemaker|corosync|pcs"

# If not installed (unlikely on appliances):
# apt update
# apt install -y pacemaker corosync pcs fence-agents-ipmilan
```

### 6.3 Configure Corosync (Cluster Communication)

#### 6.3.1 Generate Corosync Authentication Key

```bash
# On Node 1 ONLY, generate cluster auth key
corosync-keygen

# This creates /etc/corosync/authkey

# Copy authkey to Node 2
scp /etc/corosync/authkey admin@10.10.X.12:/etc/corosync/authkey
```

#### 6.3.2 Configure Corosync on Both Nodes

**File**: `/etc/corosync/corosync.conf`

```bash
# On Node 1 and Node 2, create identical configuration
sudo nano /etc/corosync/corosync.conf
```

Content:
```
totem {
    version: 2
    cluster_name: wallix-bastion-cluster
    transport: udpu
    interface {
        ringnumber: 0
        # Use heartbeat network
        bindnetaddr: 192.168.100.0
        broadcast: yes
        mcastport: 5405
    }
}

nodelist {
    node {
        ring0_addr: 192.168.100.11
        name: bastion-node1
        nodeid: 1
    }
    node {
        ring0_addr: 192.168.100.12
        name: bastion-node2
        nodeid: 2
    }
}

quorum {
    provider: corosync_votequorum
    two_node: 1
}

logging {
    to_logfile: yes
    logfile: /var/log/corosync/corosync.log
    to_syslog: yes
    timestamp: on
}
```

**Key parameters:**
- `transport: udpu` - Unicast UDP (no multicast required)
- `bindnetaddr: 192.168.100.0` - Heartbeat network
- `two_node: 1` - Special quorum for 2-node clusters (avoids split-brain)

#### 6.3.3 Start Corosync on Both Nodes

```bash
# Enable and start Corosync (Node 1 and Node 2)
systemctl enable corosync
systemctl start corosync

# Verify Corosync status
systemctl status corosync

# Check cluster membership
corosync-cmapctl | grep members
```

Expected output:
```
runtime.members.1.ip (str) = r(0) ip(192.168.100.11)
runtime.members.2.ip (str) = r(0) ip(192.168.100.12)
runtime.members.1.status (str) = joined
runtime.members.2.status (str) = joined
```

### 6.4 Configure Pacemaker

#### 6.4.1 Start Pacemaker on Both Nodes

```bash
# Enable and start Pacemaker (Node 1 and Node 2)
systemctl enable pacemaker
systemctl start pacemaker

# Verify Pacemaker status
systemctl status pacemaker

# Check cluster status
crm status
```

Expected output:
```
Cluster Summary:
  * Stack: corosync
  * Current DC: bastion-node1 (version 2.1.x)
  * 2 nodes configured
  * 0 resource instances configured

Node List:
  * Online: [ bastion-node1 bastion-node2 ]
```

#### 6.4.2 Configure Cluster Properties

```bash
# Set cluster-wide properties (run on Node 1 only)
crm configure property stonith-enabled=true
crm configure property no-quorum-policy=ignore
crm configure property start-failure-is-fatal=false
crm configure property cluster-recheck-interval=60s

# Verify properties
crm configure show
```

### 6.5 Configure STONITH Fencing (IPMI)

STONITH (Shoot The Other Node In The Head) prevents split-brain by forcefully powering off failed nodes.

#### 6.5.1 Create STONITH Resources

```bash
# Configure IPMI fencing for Node 1 (managed by Node 2)
crm configure primitive fence_node1 stonith:fence_ipmilan \
  params \
    pcmk_host_list="bastion-node1" \
    ipaddr="10.10.X.211" \
    login="ADMIN" \
    passwd="IpmiPassword123!" \
    lanplus=1 \
  op monitor interval=60s

# Configure IPMI fencing for Node 2 (managed by Node 1)
crm configure primitive fence_node2 stonith:fence_ipmilan \
  params \
    pcmk_host_list="bastion-node2" \
    ipaddr="10.10.X.212" \
    login="ADMIN" \
    passwd="IpmiPassword123!" \
    lanplus=1 \
  op monitor interval=60s

# Ensure fencing devices run on opposite nodes
crm configure location fence_node1-location fence_node1 -inf: bastion-node1
crm configure location fence_node2-location fence_node2 -inf: bastion-node2

# Verify STONITH configuration
crm resource status
```

#### 6.5.2 Test STONITH Fencing (Caution!)

```bash
# Test fencing Node 2 from Node 1 (DO NOT RUN ON PRIMARY NODE!)
# This will POWER OFF Node 2!

# stonith_admin --fence bastion-node2 --verbose

# Expected: Node 2 powers off via IPMI
# Wait 30 seconds, then power on Node 2 manually or via IPMI:
# ipmitool -I lanplus -H 10.10.X.212 -U ADMIN -P IpmiPassword123! chassis power on
```

**WARNING**: Only test fencing in maintenance window. Never fence the active primary node.

---

## Virtual IP Configuration

### 7.1 Create VIP Resource in Pacemaker

The Virtual IP (VIP) will float between nodes and is the user-facing entry point.

```bash
# Create VIP resource (run on Node 1)
crm configure primitive vip_wallix ocf:heartbeat:IPaddr2 \
  params \
    ip=10.10.X.10 \
    cidr_netmask=24 \
    nic=bond0 \
  op monitor interval=10s

# Verify VIP resource created
crm resource status vip_wallix
```

Expected output:
```
vip_wallix     (ocf::heartbeat:IPaddr2):       Started bastion-node1
```

### 7.2 Verify VIP Assignment

```bash
# On Node 1, check if VIP is assigned
ip addr show bond0 | grep 10.10.X.10

# Expected output:
# inet 10.10.X.10/24 scope global secondary bond0:0
```

```bash
# From external machine, ping VIP
ping -c 4 10.10.X.10

# Expected: Replies from 10.10.X.10
```

### 7.3 VIP Failover Test (Manual)

```bash
# Move VIP to Node 2 manually (for testing)
crm resource move vip_wallix bastion-node2

# Wait 10 seconds, then check VIP location
crm resource status vip_wallix
# Expected: vip_wallix (ocf::heartbeat:IPaddr2): Started bastion-node2

# On Node 2, verify VIP assigned
ip addr show bond0 | grep 10.10.X.10

# Move VIP back to Node 1
crm resource move vip_wallix bastion-node1

# Clear location constraint (allows automatic failover)
crm resource clear vip_wallix
```

---

## WALLIX Bastion Configuration

### 8.1 Configure Node 1 (Primary) as Active

#### 8.1.1 Initial WALLIX Bastion Setup

```bash
# Access Web UI
https://10.10.X.10

# Initial wizard (first-time setup):
# - Set admin password
# - Upload license file
# - Configure hostname: bastion-vip.wallix.company.local
# - Configure email/SMTP for alerts
```

#### 8.1.2 Configure High Availability Mode

```bash
# Via CLI on Node 1
wabadmin ha-enable --mode active-passive --peer-ip 10.10.X.12

# Verify HA status
wabadmin ha-status
```

Expected output:
```
HA Mode: Active-Passive
Local Node: bastion-node1 (PRIMARY)
Peer Node: bastion-node2 (STANDBY)
VIP: 10.10.X.10
Cluster Status: Online
Database Replication: Active (Lag: 0 seconds)
```

#### 8.1.3 Create Pacemaker Resource for WALLIX Services

```bash
# Create resource to manage WALLIX Bastion services
crm configure primitive wallix_service ocf:heartbeat:anything \
  params \
    binfile="/usr/bin/wabadmin" \
    cmdline_options="service-start" \
  op start timeout=90s \
  op stop timeout=60s \
  op monitor interval=30s timeout=20s

# Group VIP and WALLIX service together (they move together during failover)
crm configure group wallix_group vip_wallix wallix_service

# Set preferred node (Node 1 = primary)
crm configure location wallix_group-prefers-node1 wallix_group 100: bastion-node1

# Verify configuration
crm status
```

Expected output:
```
Resource Group: wallix_group
  * vip_wallix         (ocf::heartbeat:IPaddr2):       Started bastion-node1
  * wallix_service     (ocf::heartbeat:anything):      Started bastion-node1
```

### 8.2 Configure Authentication (FortiAuthenticator + AD)

#### 8.2.1 RADIUS Configuration (MFA)

```bash
# Web UI: Configuration → Authentication → RADIUS

# Add FortiAuthenticator primary
RADIUS Server 1:
  IP: 10.20.0.60
  Port: 1812
  Shared Secret: <FortiAuth shared secret>
  Timeout: 5 seconds

# Add FortiAuthenticator secondary
RADIUS Server 2:
  IP: 10.20.0.61
  Port: 1812
  Shared Secret: <FortiAuth shared secret>
  Timeout: 5 seconds
```

#### 8.2.2 LDAP Configuration (User Directory)

```bash
# Web UI: Configuration → Authentication → LDAP

# Add Active Directory
LDAP Server:
  Hostname: 10.20.0.10
  Port: 636 (LDAPS)
  Base DN: dc=company,dc=local
  Bind DN: cn=wallixsvc,ou=Service Accounts,dc=company,dc=local
  Bind Password: <service account password>
  User Filter: (&(objectClass=user)(sAMAccountName={0}))
  Group Filter: (member={0})
```

### 8.3 Configure Session Recording Storage

```bash
# Verify shared NFS mount
df -h | grep recorded

# Configure recording storage in Web UI
# Configuration → Recordings → Storage
Recording Path: /var/wab/recorded
Format: MP4 (H.264)
Encryption: AES-256-GCM
Retention: 90 days
```

---

## Standby Node Synchronization

### 9.1 Prepare Node 2 (Standby)

Node 2 should replicate configuration from Node 1 automatically via MariaDB replication.

#### 9.1.1 Verify Configuration Sync

```bash
# On Node 2, check if WALLIX database is synchronized
wabadmin db-shell

USE wallix;
SHOW TABLES;
# Expected: Same tables as Node 1

SELECT COUNT(*) FROM users;
# Expected: Same count as Node 1
```

#### 9.1.2 Verify WALLIX Services Are Stopped on Standby

```bash
# On Node 2, verify services are NOT running (Pacemaker controls them)
wabadmin service-status

# Expected output:
# WALLIX Bastion Services: STOPPED (standby mode)
# Reason: Managed by Pacemaker, VIP not assigned to this node
```

### 9.2 Encryption Key Synchronization

CRITICAL: Encryption keys must be identical on both nodes.

```bash
# On Node 1, export encryption keys
wabadmin keys-export --output /tmp/wallix-keys.tar.gz.enc

# Copy to Node 2
scp /tmp/wallix-keys.tar.gz.enc admin@10.10.X.12:/tmp/

# On Node 2, import encryption keys
wabadmin keys-import --input /tmp/wallix-keys.tar.gz.enc

# Verify keys match
wabadmin keys-verify --peer 10.10.X.11
# Expected: Keys verified, checksum match
```

### 9.3 License Synchronization

```bash
# License is stored in database and replicated automatically
# Verify on Node 2
wabadmin license-info

# Expected: Same license details as Node 1
```

---

## Failover Testing

### 10.1 Automatic Failover Test (Simulated Node 1 Failure)

#### 10.1.1 Baseline: Verify Cluster Healthy

```bash
# On Node 1, check cluster status before test
crm status

# Expected:
# Resource Group: wallix_group
#   * vip_wallix      (ocf::heartbeat:IPaddr2):  Started bastion-node1
#   * wallix_service  (ocf::heartbeat:anything): Started bastion-node1
# Online: [ bastion-node1 bastion-node2 ]
```

#### 10.1.2 Simulate Node 1 Network Failure

```bash
# On Node 1, bring down production interface (simulates failure)
# WARNING: This will disconnect your SSH session!

sudo ip link set bond0 down

# Cluster will detect heartbeat loss within 3-6 seconds
```

#### 10.1.3 Monitor Failover from Node 2

```bash
# On Node 2, watch cluster status
watch -n 1 'crm status'

# Timeline:
# T+0s:   Node 1 disappears from cluster
# T+3s:   Node 2 detects heartbeat timeout
# T+8s:   STONITH fence Node 1 (if configured, powers off Node 1)
# T+15s:  MariaDB promoted on Node 2: SET GLOBAL READ_ONLY=OFF
# T+25s:  WALLIX services started on Node 2
# T+35s:  VIP assigned to Node 2
# T+45s:  Node 2 ready to accept connections
```

Expected final state:
```
Resource Group: wallix_group
  * vip_wallix      (ocf::heartbeat:IPaddr2):  Started bastion-node2
  * wallix_service  (ocf::heartbeat:anything): Started bastion-node2

Node List:
  * Online: [ bastion-node2 ]
  * OFFLINE: [ bastion-node1 ]
```

#### 10.1.4 Verify Failover Success

```bash
# From external machine, test VIP connectivity
ping -c 4 10.10.X.10
# Expected: Replies continue (VIP now on Node 2)

# Test Web UI
curl -k https://10.10.X.10/health
# Expected: HTTP 200 OK

# On Node 2, verify VIP assigned
ip addr show bond0 | grep 10.10.X.10
# Expected: inet 10.10.X.10/24

# Verify MariaDB is writable
mysql -u root -p -e "SELECT @@read_only;"
# Expected: 0 (read_only is OFF)
```

#### 10.1.5 Restore Node 1 (Failback Preparation)

```bash
# On Node 1 console (via IPMI/serial)
# Bring network back up
sudo ip link set bond0 up

# Verify IP address assigned
ip addr show bond0

# Wait for cluster to detect Node 1 is back
# (Do NOT failback yet, see Section 11)
```

### 10.2 Manual Failover Test (Controlled)

```bash
# Move resource group to Node 2 manually
crm resource move wallix_group bastion-node2

# Wait 30-60 seconds, verify failover
crm status

# Expected:
# Resource Group: wallix_group
#   * vip_wallix      (ocf::heartbeat:IPaddr2):  Started bastion-node2
#   * wallix_service  (ocf::heartbeat:anything): Started bastion-node2

# Clear location constraint (allows automatic failover)
crm resource clear wallix_group
```

### 10.3 Service Failure Test (WALLIX Services Crash)

```bash
# On Node 1, kill WALLIX Bastion service
sudo killall -9 wabservices

# Pacemaker will attempt to restart service automatically
# If restart fails 3 times, Pacemaker will failover to Node 2

# Monitor with:
watch -n 1 'crm status'
```

---

## Failback Procedures

### 11.1 When to Failback

Failback is the process of returning to the original primary node (Node 1) after a failure event.

**Recommended approach**: Manual failback during maintenance window.

**Reasons**:
- Verify Node 1 is fully recovered
- Minimize risk of repeated failovers
- Controlled timing (low-traffic period)

### 11.2 Verify Node 1 is Healthy

```bash
# On Node 1, check system health
wabadmin health-check

# Verify MariaDB replication is working (Node 1 is now replica)
mysql -u root -p

SHOW SLAVE STATUS\G
# Expected:
# Slave_IO_Running: Yes
# Slave_SQL_Running: Yes
# Seconds_Behind_Master: 0
```

### 11.3 Manual Failback to Node 1

#### 11.3.1 Announce Maintenance Window

```
Maintenance Window: 30 minutes
Expected Outage: 30-60 seconds (during VIP migration)
Impacted Services: Active WALLIX sessions (users must reconnect)
```

#### 11.3.2 Execute Failback

```bash
# On Node 1 or Node 2, move resource group back to Node 1
crm resource move wallix_group bastion-node1

# Monitor progress
watch -n 1 'crm status'

# Timeline:
# T+0s:   Pacemaker stops WALLIX services on Node 2
# T+10s:  VIP released from Node 2
# T+15s:  MariaDB on Node 2: SET GLOBAL READ_ONLY=ON
# T+20s:  MariaDB on Node 1: SET GLOBAL READ_ONLY=OFF (promotion)
# T+30s:  WALLIX services started on Node 1
# T+40s:  VIP assigned to Node 1
# T+50s:  Node 1 ready to accept connections
```

Expected final state:
```
Resource Group: wallix_group
  * vip_wallix      (ocf::heartbeat:IPaddr2):  Started bastion-node1
  * wallix_service  (ocf::heartbeat:anything): Started bastion-node1

Node List:
  * Online: [ bastion-node1 bastion-node2 ]
```

#### 11.3.3 Clear Location Constraint

```bash
# After successful failback, clear constraint to allow auto-failover
crm resource clear wallix_group

# Verify no location constraints remain
crm configure show | grep location
```

#### 11.3.4 Verify Services

```bash
# Test VIP connectivity
ping -c 4 10.10.X.10

# Test Web UI
curl -k https://10.10.X.10/health

# Test SSH session
ssh user@10.10.X.10

# Verify MariaDB replication (Node 2 is replica again)
# On Node 2:
mysql -u root -p -e "SHOW SLAVE STATUS\G"
# Expected: Slave_IO_Running: Yes, Slave_SQL_Running: Yes
```

### 11.4 Automatic Failback (Not Recommended)

**Warning**: Automatic failback can cause "ping-pong" failovers if Node 1 is unstable.

If you still want automatic failback:

```bash
# Set resource-stickiness to allow failback
crm configure rsc_defaults resource-stickiness=0

# This allows resources to move back to preferred node automatically
```

**Best Practice**: Keep resource-stickiness high (default) and failback manually.

---

## Performance Tuning

### 12.1 MariaDB Replication Optimization

#### 12.1.1 Binary Log Performance

```bash
# Edit /etc/mysql/mariadb.conf.d/50-server.cnf

[mysqld]
# Reduce binlog sync overhead (slight risk of data loss)
sync_binlog              = 10  # Default: 1 (sync every commit)

# Increase binlog cache
binlog_cache_size        = 1M

# Use faster checksum algorithm
binlog_checksum          = CRC32
```

#### 12.1.2 InnoDB Performance

```ini
# Allocate 60-70% of RAM to InnoDB buffer pool
innodb_buffer_pool_size  = 10G  # For 16 GB RAM appliance

# Enable parallel threads for I/O
innodb_read_io_threads   = 8
innodb_write_io_threads  = 8

# Increase log file size
innodb_log_file_size     = 512M
```

```bash
# Restart MariaDB after changes
systemctl restart mariadb
```

### 12.2 Pacemaker Tuning

```bash
# Reduce failover detection time (faster but more false positives)
crm configure property cluster-recheck-interval=30s  # Default: 60s

# Increase max failover attempts before giving up
crm configure rsc_defaults migration-threshold=5  # Default: 3

# Set timeout for resource operations
crm configure op_defaults timeout=90s
```

### 12.3 Corosync Heartbeat Tuning

```bash
# Edit /etc/corosync/corosync.conf

totem {
    # Reduce heartbeat interval (faster failover detection)
    token: 3000             # Default: 5000ms
    token_retransmits_before_loss_const: 10

    # Consensus timeout
    consensus: 4000         # Default: 6000ms
}
```

```bash
# Restart Corosync after changes (ON BOTH NODES)
systemctl restart corosync
systemctl restart pacemaker
```

### 12.4 Network Performance

#### 12.4.1 Enable Jumbo Frames (If Supported)

```bash
# On both nodes, set MTU to 9000
wabadmin network-mtu --interface bond0 --mtu 9000
wabadmin network-mtu --interface bond1 --mtu 9000

# Verify
ip link show bond0 | grep mtu
# Expected: mtu 9000
```

#### 12.4.2 Optimize TCP Settings

```bash
# Edit /etc/sysctl.conf

# Increase network buffer sizes
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Enable TCP window scaling
net.ipv4.tcp_window_scaling = 1

# Apply changes
sysctl -p
```

---

## Troubleshooting

### 13.1 Common Issues and Solutions

#### Issue 1: Split-Brain (Both Nodes Think They Are Primary)

**Symptoms:**
- VIP assigned on both Node 1 and Node 2
- Both nodes have `READ_ONLY=OFF` in MariaDB
- Cluster status shows two separate clusters

**Diagnosis:**
```bash
# On Node 1 and Node 2, check VIP
ip addr show bond0 | grep 10.10.X.10

# Check MariaDB read-only status
mysql -u root -p -e "SELECT @@read_only;"

# Check cluster membership
crm status
corosync-cmapctl | grep members
```

**Resolution:**
```bash
# 1. Stop Pacemaker on Node 2 (less critical node)
ssh admin@10.10.X.12
sudo systemctl stop pacemaker

# 2. Force MariaDB read-only on Node 2
mysql -u root -p -e "SET GLOBAL READ_ONLY=ON;"

# 3. Release VIP from Node 2 manually
sudo ip addr del 10.10.X.10/24 dev bond0

# 4. Restart Pacemaker on Node 2
sudo systemctl start pacemaker

# 5. Verify cluster re-forms
crm status
```

**Prevention:**
- Ensure STONITH fencing is configured and working
- Use dedicated heartbeat network (bond1, VLAN X+100)
- Enable split-brain prevention: `no-quorum-policy=ignore` for 2-node clusters

#### Issue 2: Replication Stopped

**Symptoms:**
```bash
# On Node 2 (replica)
mysql -u root -p

SHOW SLAVE STATUS\G
# Slave_IO_Running: No
# Slave_SQL_Running: No
# Last_IO_Error: Lost connection to MySQL server
```

**Diagnosis:**
```bash
# Check network connectivity to Node 1
ping -c 4 10.10.X.11
nc -zv 10.10.X.11 3306

# Check MariaDB process on Node 1
ssh admin@10.10.X.11 'systemctl status mariadb'

# Check replication user exists
mysql -h 10.10.X.11 -u repl_user -p'StrongReplPassword123!' -e "SELECT 1;"
```

**Resolution:**
```bash
# On Node 2, restart replication
mysql -u root -p

STOP SLAVE;

# Re-sync from current primary position
# First, get current position from Node 1
mysql -h 10.10.X.11 -u root -p -e "SHOW MASTER STATUS;"
# Note: File and Position

# Configure replica to restart from current position
CHANGE MASTER TO
  MASTER_LOG_FILE='mysql-bin.000005',
  MASTER_LOG_POS=12345;

START SLAVE;

SHOW SLAVE STATUS\G
# Verify: Slave_IO_Running: Yes, Slave_SQL_Running: Yes
```

#### Issue 3: Failover Loops (Ping-Pong)

**Symptoms:**
- Resources fail over from Node 1 → Node 2 → Node 1 repeatedly
- Cluster logs show repeated start/stop of `wallix_service`

**Diagnosis:**
```bash
# Check Pacemaker logs
journalctl -u pacemaker -f

# Check resource failure count
crm resource failcount wallix_service show bastion-node1
```

**Resolution:**
```bash
# 1. Put cluster in maintenance mode
crm configure property maintenance-mode=true

# 2. Clear failcounts
crm resource cleanup wallix_service

# 3. Investigate root cause (check WALLIX logs)
wabadmin logs --service wallix --lines 100

# 4. Fix underlying issue (e.g., missing dependency, config error)

# 5. Disable maintenance mode
crm configure property maintenance-mode=false
```

#### Issue 4: VIP Not Responding (ARP Cache Issue)

**Symptoms:**
- Cluster shows VIP assigned, but ping fails
- `ip addr show` confirms VIP on interface

**Diagnosis:**
```bash
# On active node, verify VIP assigned
ip addr show bond0 | grep 10.10.X.10

# Check ARP table on client machine
arp -a | grep 10.10.X.10

# Expected: VIP should map to MAC address of active node's bond0
```

**Resolution:**
```bash
# On active node, send gratuitous ARP
arping -c 5 -I bond0 10.10.X.10

# Alternatively, restart VIP resource to trigger gratuitous ARP
crm resource restart vip_wallix
```

#### Issue 5: STONITH Fencing Fails

**Symptoms:**
```bash
crm status
# Failed Fencing Actions:
#   * fence bastion-node2 (on bastion-node1): failed
```

**Diagnosis:**
```bash
# Test IPMI connectivity manually
ipmitool -I lanplus -H 10.10.X.212 -U ADMIN -P 'IpmiPassword123!' chassis power status

# Check fence agent logs
journalctl -u pacemaker | grep -i stonith
```

**Resolution:**
```bash
# 1. Verify IPMI credentials correct
# 2. Verify IPMI network reachable
ping -c 4 10.10.X.212

# 3. Test fencing manually
stonith_admin --fence bastion-node2 --verbose

# 4. If fencing consistently fails, temporarily disable STONITH (NOT RECOMMENDED)
crm configure property stonith-enabled=false

# 5. Fix IPMI issue, then re-enable STONITH
crm configure property stonith-enabled=true
```

### 13.2 Diagnostic Commands

#### Cluster Health

```bash
# Overall cluster status
crm status

# Detailed configuration
crm configure show

# Check for failed actions
crm_mon -1Af

# Pacemaker logs
journalctl -u pacemaker -n 100

# Corosync logs
journalctl -u corosync -n 100
```

#### MariaDB Replication

```bash
# Replication status (on replica node)
mysql -u root -p -e "SHOW SLAVE STATUS\G"

# Replication lag
mysql -u root -p -e "SHOW SLAVE STATUS\G" | grep "Seconds_Behind_Master"

# Binary log position (on primary)
mysql -u root -p -e "SHOW MASTER STATUS;"

# Check for replication errors
mysql -u root -p -e "SHOW SLAVE STATUS\G" | grep -E "Last_IO_Error|Last_SQL_Error"
```

#### Network Connectivity

```bash
# Test cluster heartbeat
ping -c 4 192.168.100.12

# Test MariaDB replication port
nc -zv 10.10.X.11 3306

# Test Pacemaker communication
nc -zv 10.10.X.11 2224
nc -zv 10.10.X.11 3121

# Check Corosync connectivity
corosync-cfgtool -s
```

#### WALLIX Bastion

```bash
# Check service status
wabadmin service-status

# View recent logs
wabadmin logs --lines 50

# Database connectivity
wabadmin db-test

# License status
wabadmin license-info

# HA status
wabadmin ha-status
```

---

## Backup and Recovery

### 13.3 Backup Procedures

#### Database Backup (Nightly)

```bash
# Create backup script: /usr/local/bin/backup-wallix-db.sh

#!/bin/bash
BACKUP_DIR="/var/backups/wallix"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/wallix-db-$DATE.sql.gz"

mkdir -p $BACKUP_DIR

# Backup all databases
mysqldump -u root -p'RootPassword' --all-databases --single-transaction | gzip > $BACKUP_FILE

# Rotate old backups (keep 7 days)
find $BACKUP_DIR -name "wallix-db-*.sql.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_FILE"
```

```bash
chmod +x /usr/local/bin/backup-wallix-db.sh

# Schedule via cron (2 AM daily)
echo "0 2 * * * /usr/local/bin/backup-wallix-db.sh" | crontab -
```

#### Configuration Backup

```bash
# Backup WALLIX configuration
wabadmin config-export --output /var/backups/wallix/config-$(date +%Y%m%d).tar.gz

# Backup encryption keys
wabadmin keys-export --output /var/backups/wallix/keys-$(date +%Y%m%d).tar.gz.enc
```

---

## Related Documentation

- [02-ha-architecture.md](02-ha-architecture.md) - Active-Active vs Active-Passive comparison
- [06-bastion-active-active.md](06-bastion-active-active.md) - Active-Active cluster setup (alternative)
- [01-network-design.md](01-network-design.md) - Network topology and port requirements
- [11-high-availability](../docs/pam/11-high-availability/README.md) - Detailed HA concepts

---

## References

### Official Documentation

- WALLIX Bastion 12.x Admin Guide: https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf
- MariaDB Replication: https://mariadb.com/kb/en/standard-replication/
- Pacemaker Documentation: https://clusterlabs.org/pacemaker/doc/
- Corosync Configuration: https://corosync.github.io/corosync/

### External Resources

- Red Hat HA Cluster Guide: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/configuring_and_managing_high_availability_clusters
- STONITH Fencing Agents: https://github.com/ClusterLabs/fence-agents

---

**Document Version**: 1.0
**Last Updated**: February 2026
**Deployment Model**: Active-Passive (2-node cluster)
**Tested On**: WALLIX Bastion 12.1.x with Debian 12

---

**Next Steps:**

1. **Proceed to testing**: [10-testing-validation.md](10-testing-validation.md)
2. **Configure HAProxy**: [05-haproxy-setup.md](05-haproxy-setup.md)
3. **Set up monitoring**: [/docs/pam/12-monitoring-observability/](../docs/pam/12-monitoring-observability/README.md)
