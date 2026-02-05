# 06 - Active-Active WALLIX Bastion HW Appliance Cluster Setup

> Comprehensive guide for deploying Active-Active High Availability clusters using WALLIX Bastion hardware appliances

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Active-Active HA cluster configuration for WALLIX Bastion HW appliances |
| **Deployment Model** | 2 hardware appliances per site in Active-Active mode |
| **Version** | WALLIX Bastion 12.1.x |
| **Prerequisites** | [02-ha-architecture.md](02-ha-architecture.md), [01-network-design.md](01-network-design.md) |
| **Last Updated** | February 2026 |

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites & Planning](#prerequisites--planning)
3. [Initial Appliance Setup](#initial-appliance-setup)
4. [Network Configuration](#network-configuration)
5. [MariaDB Galera Cluster Configuration](#mariadb-galera-cluster-configuration)
6. [Pacemaker/Corosync Cluster Management](#pacemakercorosync-cluster-management)
7. [Split-Brain Prevention](#split-brain-prevention)
8. [WALLIX Bastion Configuration Sync](#wallix-bastion-configuration-sync)
9. [HAProxy Load Balancer Integration](#haproxy-load-balancer-integration)
10. [Testing Load Balancing](#testing-load-balancing)
11. [Failover Testing](#failover-testing)
12. [Performance Tuning](#performance-tuning)
13. [Troubleshooting](#troubleshooting)
14. [Operational Procedures](#operational-procedures)

---

## Architecture Overview

### 1.1 Active-Active Cluster Design

```
+===============================================================================+
|  ACTIVE-ACTIVE WALLIX BASTION CLUSTER                                        |
+===============================================================================+
|                                                                               |
|                        +--------------------------+                           |
|                        |    HAProxy (HA Pair)     |                           |
|                        |  Load Balancer           |                           |
|                        |                          |                           |
|                        |  VIP: 10.10.X.100        |                           |
|                        |  Keepalived VRRP         |                           |
|                        +-----------+--------------+                           |
|                                    |                                          |
|                   +----------------+----------------+                         |
|                   |                                 |                         |
|                   v                                 v                         |
| +--------------------------------+ +--------------------------------+         |
| |  WALLIX BASTION NODE 1         | |  WALLIX BASTION NODE 2         |         |
| |  (ACTIVE - HW Appliance)       | |  (ACTIVE - HW Appliance)       |         |
| |                                | |                                |         |
| |  IP: 10.10.X.11                | |  IP: 10.10.X.12                |         |
| |  Load: 50% traffic             | |  Load: 50% traffic             |         |
| |  IPMI: 10.10.X.111             | |  IPMI: 10.10.X.112             |         |
| |                                | |                                |         |
| |  +---------------------------+ | |  +---------------------------+ |         |
| |  | WALLIX Bastion            | | |  | WALLIX Bastion            | |         |
| |  | Services (Running)        | | |  | Services (Running)        | |         |
| |  |                           | | |  |                           | |         |
| |  | - Session Manager         | | |  | - Session Manager         | |         |
| |  | - Password Manager        | | |  | - Password Manager        | |         |
| |  | - Web UI                  | | |  | - Web UI                  | |         |
| |  | - REST API                | | |  | - REST API                | |         |
| |  +---------------------------+ | |  +---------------------------+ |         |
| |                                | |                                |         |
| |  +---------------------------+ | |  +---------------------------+ |         |
| |  | MariaDB Galera            | | |  | MariaDB Galera            | |         |
| |  | (PRIMARY/PRIMARY)         |<+-+->| (PRIMARY/PRIMARY)         | |         |
| |  |                           | | |  |                           | |         |
| |  | Multi-Master Replication  | | |  | Multi-Master Replication  | |         |
| |  | Synchronous commit        | | |  | Synchronous commit        | |         |
| |  | Port 3306, 4567-4568      | | |  | Port 3306, 4567-4568      | |         |
| |  +---------------------------+ | |  +---------------------------+ |         |
| |                                | |                                |         |
| |  +---------------------------+ | |  +---------------------------+ |         |
| |  | Pacemaker/Corosync        | | |  | Pacemaker/Corosync        | |         |
| |  | Cluster Manager           |<+-+->| Cluster Manager           | |         |
| |  | PCSD: 2224                | | |  | PCSD: 2224                | |         |
| |  | Corosync: 5404-5406 UDP   | | |  | Corosync: 5404-5406 UDP   | |         |
| |  +---------------------------+ | |  +---------------------------+ |         |
| |                                | |                                |         |
| +--------------------------------+ +--------------------------------+         |
|                   |                                 |                         |
|                   +----------------+----------------+                         |
|                                    |                                          |
|                        +-----------+--------------+                           |
|                        |  Shared Storage (NAS)    |                           |
|                        |  Session Recordings      |                           |
|                        |  /var/wab/recorded       |                           |
|                        |  NFS v4 with NFSv4 ACLs  |                           |
|                        +--------------------------+                           |
|                                                                               |
|  KEY CHARACTERISTICS                                                          |
|  ===================                                                          |
|  - Both nodes actively serving traffic (50/50 split)                          |
|  - Sub-second transparent failover                                            |
|  - Multi-master database with synchronous replication                         |
|  - Quorum-based split-brain prevention                                        |
|  - STONITH fencing via IPMI for hardware appliances                           |
|  - Shared NAS for session recordings                                          |
|                                                                               |
+===============================================================================+
```

### 1.2 Traffic Flow

```
+===============================================================================+
|  TRAFFIC FLOW IN ACTIVE-ACTIVE MODE                                          |
+===============================================================================+
|                                                                               |
|  USER REQUEST                                                                 |
|  ============                                                                 |
|                                                                               |
|  1. User → HAProxy VIP (10.10.X.100:443)                                     |
|     - HTTPS connection established                                            |
|     - SSL termination at HAProxy (optional) or passthrough                    |
|                                                                               |
|  2. HAProxy → Backend Selection                                               |
|     - Algorithm: roundrobin or leastconn                                      |
|     - Health check: GET /health (every 2s)                                    |
|     - Session persistence: cookie insertion (SERVERID)                        |
|                                                                               |
|  3. Request Distribution:                                                     |
|     - User A → Node 1 (10.10.X.11)                                           |
|     - User B → Node 2 (10.10.X.12)                                           |
|     - User C → Node 1 (10.10.X.11)                                           |
|     - User D → Node 2 (10.10.X.12)                                           |
|                                                                               |
|  4. Database Sync:                                                            |
|     - User A creates session on Node 1                                        |
|     - Database write replicated to Node 2 (synchronous)                       |
|     - Both nodes have consistent view                                         |
|                                                                               |
|  5. Session Recording:                                                        |
|     - Both nodes write to shared NFS                                          |
|     - File locking prevents conflicts                                         |
|     - Recordings accessible from both nodes                                   |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  FAILOVER SCENARIO                                                            |
|  ================                                                             |
|                                                                               |
|  Node 1 Failure:                                                              |
|  - HAProxy detects health check failure (< 1 second)                          |
|  - Node 1 removed from backend pool immediately                               |
|  - All new traffic directed to Node 2                                         |
|  - Existing sessions on Node 1: HTTP sessions continue (cookie-based)         |
|  - SSH/RDP sessions: may disconnect (protocol limitation)                     |
|                                                                               |
|  Database Impact:                                                             |
|  - Node 2 Galera detects Node 1 down                                          |
|  - Cluster size reduced from 2 to 1                                           |
|  - Node 2 continues serving (still has quorum with quorum device)             |
|  - No data loss (synchronous replication)                                     |
|                                                                               |
+===============================================================================+
```

### 1.3 Comparison to Active-Passive

| Aspect | Active-Active | Active-Passive |
|--------|---------------|----------------|
| **Node Utilization** | 100% (both serving) | 50% (standby idle) |
| **Failover Time** | < 1 second | 30-60 seconds |
| **Session Continuity** | Full (HTTP), Partial (SSH/RDP) | None (all disconnect) |
| **Configuration Complexity** | High | Medium |
| **Database** | Multi-master (Galera) | Master-Replica (async) |
| **Conflict Resolution** | Automatic (last-write-wins) | Not applicable |
| **Split-Brain Risk** | Higher (requires quorum) | Lower |
| **Recommended Load** | > 100 concurrent sessions | < 100 concurrent sessions |

---

## Prerequisites & Planning

### 2.1 Hardware Requirements

#### WALLIX Bastion Hardware Appliances

| Specification | Requirement | Notes |
|---------------|-------------|-------|
| **Model** | WALLIX Bastion HW 1U/2U appliance | Vendor-supplied hardware |
| **CPU** | 8+ cores (16+ recommended) | Higher core count for 100+ sessions |
| **RAM** | 32 GB minimum (64 GB recommended) | Galera requires additional memory |
| **Storage** | 500 GB SSD (RAID 1) | OS + database + local cache |
| **Network** | 2x 10GbE (bonded) | Primary + heartbeat networks |
| **IPMI/iLO** | Dedicated out-of-band management | Required for STONITH fencing |
| **Power Supply** | Redundant PSU | High availability |

#### Shared Storage (NAS)

| Specification | Requirement | Notes |
|---------------|-------------|-------|
| **Protocol** | NFSv4 or iSCSI | NFSv4 recommended for ACLs |
| **Capacity** | 10 TB+ | Depends on recording retention |
| **Performance** | 10,000 IOPS minimum | SSD/NVMe for low latency |
| **Redundancy** | RAID 10 or RAID 6 | Data protection |
| **Network** | 10GbE dedicated VLAN | Isolate storage traffic |

### 2.2 Software Requirements

| Component | Version | Purpose |
|-----------|---------|---------|
| **WALLIX Bastion** | 12.1.x | PAM application |
| **MariaDB** | 10.11.6+ | Database |
| **Galera Cluster** | 26.4.16+ | Multi-master replication |
| **Pacemaker** | 2.1.5+ | Cluster resource manager |
| **Corosync** | 3.1.7+ | Cluster communication |
| **fence-agents** | 4.12+ | STONITH fencing (IPMI) |
| **HAProxy** | 2.8+ | Load balancer (separate hosts) |

**Installation Note**: WALLIX hardware appliances come with pre-installed OS and software. Verify versions:

```bash
wabadmin version
systemctl status wallix-bastion
mariadb --version
crm --version
corosync -v
```

### 2.3 Network Requirements

#### IP Addressing (Per Site)

| Component | IP Address | Purpose |
|-----------|------------|---------|
| **HAProxy VIP** | 10.10.X.100 | User entry point |
| **HAProxy-1** | 10.10.X.5 | Load balancer primary |
| **HAProxy-2** | 10.10.X.6 | Load balancer backup |
| **Bastion Node 1** | 10.10.X.11 | Primary node |
| **Bastion Node 2** | 10.10.X.12 | Secondary node |
| **Node 1 IPMI** | 10.10.X.111 | Out-of-band management |
| **Node 2 IPMI** | 10.10.X.112 | Out-of-band management |
| **NAS Storage** | 10.10.X.200 | Shared recordings |
| **Quorum Device** | 10.10.X.250 | Split-brain prevention (optional) |

#### Firewall Rules

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| HAProxy-1/2 | Bastion-1/2 | 443 | TCP | Backend health checks |
| Bastion-1 | Bastion-2 | 3306 | TCP | MariaDB replication |
| Bastion-1 | Bastion-2 | 4567 | TCP | Galera cluster sync |
| Bastion-1 | Bastion-2 | 4568 | TCP | Galera IST (Incremental State Transfer) |
| Bastion-1 | Bastion-2 | 4444 | TCP | Galera SST (State Snapshot Transfer) |
| Bastion-1 | Bastion-2 | 2224 | TCP | PCSD (Pacemaker web UI) |
| Bastion-1 | Bastion-2 | 3121 | TCP | Pacemaker cluster communication |
| Bastion-1 | Bastion-2 | 5404-5406 | UDP | Corosync heartbeat |
| Admin Workstation | Node 1/2 IPMI | 623 | UDP | IPMI over LAN |
| Bastion-1/2 | NAS Storage | 2049 | TCP | NFS |
| Bastion-1/2 | NAS Storage | 111 | TCP/UDP | RPC portmapper |

**CRITICAL**: Create a dedicated VLAN for cluster heartbeat traffic (Corosync, PCSD) isolated from user traffic.

### 2.4 Pre-Deployment Checklist

- [ ] Hardware appliances racked, powered, and connected to network
- [ ] IPMI/iLO configured with dedicated IP addresses
- [ ] Network switch configured with VLANs (production, heartbeat, storage)
- [ ] Firewall rules created for cluster communication
- [ ] NAS storage provisioned with NFS export or iSCSI LUN
- [ ] DNS records created for both nodes and VIP
- [ ] NTP servers configured and reachable
- [ ] HAProxy servers deployed and tested (see separate guide)
- [ ] Quorum device prepared (optional but recommended for 2-node clusters)
- [ ] IPMI credentials documented and tested

---

## Initial Appliance Setup

### 3.1 IPMI/iLO Configuration (Out-of-Band Management)

**Purpose**: Required for STONITH fencing to prevent split-brain scenarios.

#### Node 1 IPMI Setup

```bash
# Connect to appliance via serial console or KVM

# Configure IPMI network (hardware-specific, example for Dell iDRAC)
ipmitool lan set 1 ipsrc static
ipmitool lan set 1 ipaddr 10.10.1.111
ipmitool lan set 1 netmask 255.255.255.0
ipmitool lan set 1 defgw ipaddr 10.10.1.1

# Set IPMI admin credentials
ipmitool user set name 2 ipmi_admin
ipmitool user set password 2 <STRONG_PASSWORD>
ipmitool user enable 2

# Enable IPMI over LAN
ipmitool lan set 1 access on
```

#### Node 2 IPMI Setup

```bash
# Repeat for Node 2 with IP 10.10.1.112
ipmitool lan set 1 ipaddr 10.10.1.112
# ... (same commands as Node 1)
```

#### Test IPMI Access

```bash
# From admin workstation, test IPMI reachability
ipmitool -I lanplus -H 10.10.1.111 -U ipmi_admin -P <PASSWORD> power status
# Expected: Chassis Power is on

ipmitool -I lanplus -H 10.10.1.112 -U ipmi_admin -P <PASSWORD> power status
# Expected: Chassis Power is on
```

### 3.2 Base OS Configuration

#### Set Hostname and Timezone

**Node 1:**
```bash
# Set hostname
hostnamectl set-hostname bastion1-site1.wallix.company.local

# Set timezone to UTC
timedatectl set-timezone UTC

# Verify
hostnamectl status
timedatectl status
```

**Node 2:**
```bash
hostnamectl set-hostname bastion2-site1.wallix.company.local
timedatectl set-timezone UTC
```

#### Update /etc/hosts

**Both nodes:**
```bash
cat >> /etc/hosts <<'EOF'
# WALLIX Bastion Cluster
10.10.1.11    bastion1-site1.wallix.company.local bastion1
10.10.1.12    bastion2-site1.wallix.company.local bastion2
10.10.1.100   bastion-site1.wallix.company.local bastion-vip

# IPMI/iLO
10.10.1.111   bastion1-ipmi
10.10.1.112   bastion2-ipmi

# HAProxy
10.10.1.5     haproxy1-site1
10.10.1.6     haproxy2-site1
10.10.1.100   haproxy-vip

# NAS Storage
10.10.1.200   nas-site1
EOF
```

### 3.3 Storage Configuration

#### Configure Shared NFS Storage

**On both nodes:**

```bash
# Install NFS client
apt-get update
apt-get install -y nfs-common

# Create mount point for recordings
mkdir -p /var/wab/recorded

# Add to /etc/fstab
cat >> /etc/fstab <<'EOF'
nas-site1:/wallix/recordings  /var/wab/recorded  nfs4  rw,hard,intr,rsize=32768,wsize=32768  0  0
EOF

# Mount NFS share
mount -a

# Verify mount
df -h | grep recorded
# Expected: nas-site1:/wallix/recordings mounted on /var/wab/recorded

# Set permissions (WALLIX user)
chown -R wab:wab /var/wab/recorded
chmod 750 /var/wab/recorded

# Test write access
su - wab -c "touch /var/wab/recorded/test.txt && rm /var/wab/recorded/test.txt"
# Expected: No errors
```

**NFS Server Configuration** (on NAS):

```bash
# Create export directory
mkdir -p /wallix/recordings
chown -R 1000:1000 /wallix/recordings  # UID/GID for wab user

# Add to /etc/exports
cat >> /etc/exports <<'EOF'
/wallix/recordings  10.10.1.11(rw,sync,no_subtree_check,no_root_squash)
/wallix/recordings  10.10.1.12(rw,sync,no_subtree_check,no_root_squash)
EOF

# Apply exports
exportfs -ra

# Verify
showmount -e localhost
```

---

## Network Configuration

### 4.1 Interface Bonding (Recommended)

**Purpose**: Combine multiple NICs for redundancy and increased bandwidth.

**On both nodes:**

```bash
# Install bonding module
modprobe bonding

# Create bonding configuration
cat > /etc/network/interfaces.d/bond0 <<'EOF'
# Bond0 - Primary production traffic
auto bond0
iface bond0 inet static
    address 10.10.1.11  # Change to .12 for Node 2
    netmask 255.255.255.0
    gateway 10.10.1.1
    bond-mode 802.3ad        # LACP (requires switch support)
    bond-miimon 100
    bond-downdelay 200
    bond-updelay 200
    bond-lacp-rate 1
    bond-slaves eth0 eth1
EOF

# Bring up bond
ifup bond0

# Verify bonding status
cat /proc/net/bonding/bond0
# Expected: Mode: IEEE 802.3ad, Status: up
```

### 4.2 Dedicated Heartbeat Network (Highly Recommended)

**Purpose**: Separate cluster heartbeat traffic from production to prevent false failovers.

```bash
# Create VLAN interface for heartbeat (VLAN 100)
cat > /etc/network/interfaces.d/vlan100 <<'EOF'
auto bond0.100
iface bond0.100 inet static
    address 192.168.100.11  # Change to .12 for Node 2
    netmask 255.255.255.0
    vlan-raw-device bond0
EOF

# Install VLAN support
apt-get install -y vlan

# Bring up VLAN
ifup bond0.100

# Verify
ip addr show bond0.100
ping -c 2 192.168.100.12  # From Node 1 to Node 2
```

### 4.3 Network Validation

```bash
# Test connectivity between nodes
ping -c 5 bastion2  # From Node 1
ping -c 5 bastion1  # From Node 2

# Test heartbeat network
ping -c 5 192.168.100.12  # From Node 1
ping -c 5 192.168.100.11  # From Node 2

# Test NAS storage
ping -c 5 nas-site1

# Test gateway
ping -c 5 10.10.1.1

# Test HAProxy
ping -c 5 haproxy-vip
```

---

## MariaDB Galera Cluster Configuration

### 5.1 Galera Architecture Overview

```
+===============================================================================+
|  MARIADB GALERA MULTI-MASTER REPLICATION                                     |
+===============================================================================+
|                                                                               |
|  Node 1 (10.10.1.11)                    Node 2 (10.10.1.12)                  |
|  +---------------------------+          +---------------------------+         |
|  | MariaDB Galera            |          | MariaDB Galera            |         |
|  | wsrep_cluster_address:    |<-------->| wsrep_cluster_address:    |         |
|  | gcomm://10.10.1.11,       |   3306   | gcomm://10.10.1.11,       |         |
|  |        10.10.1.12         |   4567   |        10.10.1.12         |         |
|  |                           |   4568   |                           |         |
|  | Primary Component         |          | Primary Component         |         |
|  | Cluster Size: 2           |          | Cluster Size: 2           |         |
|  +---------------------------+          +---------------------------+         |
|                                                                               |
|  KEY FEATURES                                                                 |
|  ============                                                                 |
|  - Synchronous replication (certification-based)                              |
|  - Both nodes can read and write                                              |
|  - Automatic conflict detection and resolution                                |
|  - Quorum required: 2/2 nodes (or 2/3 with quorum device)                    |
|  - No data loss on node failure                                               |
|                                                                               |
|  PORTS USED                                                                   |
|  ==========                                                                   |
|  - 3306: MariaDB client connections                                           |
|  - 4567: Galera cluster replication (TCP)                                     |
|  - 4568: Incremental State Transfer (IST)                                     |
|  - 4444: State Snapshot Transfer (SST) - full data copy                       |
|                                                                               |
+===============================================================================+
```

### 5.2 Install Galera Cluster

**On both nodes:**

```bash
# Stop WALLIX services temporarily
systemctl stop wallix-bastion

# Backup existing database
wabadmin backup database /var/backups/pre-galera-db-backup.sql.gz

# Install Galera packages
apt-get update
apt-get install -y mariadb-server-10.11 galera-4 \
                   mariadb-plugin-provider-bzip2 \
                   mariadb-plugin-provider-lz4 \
                   mariadb-plugin-provider-lzma

# Stop MariaDB (will reconfigure)
systemctl stop mariadb
```

### 5.3 Configure Galera on Node 1 (Bootstrap Node)

**Create Galera configuration:**

```bash
cat > /etc/mysql/mariadb.conf.d/60-galera.cnf <<'EOF'
[mysqld]
# Galera Cluster Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Cluster connection
wsrep_cluster_name="wallix_bastion_cluster"
wsrep_cluster_address="gcomm://10.10.1.11,10.10.1.12"

# Node configuration
wsrep_node_name="bastion1"
wsrep_node_address="10.10.1.11"

# Replication settings
wsrep_slave_threads=4
wsrep_certify_nonPK=1
wsrep_max_ws_rows=0
wsrep_max_ws_size=2147483647
wsrep_debug=0
wsrep_convert_LOCK_to_trx=0
wsrep_retry_autocommit=1
wsrep_auto_increment_control=1

# SST (State Snapshot Transfer) method
wsrep_sst_method=rsync
# Alternative: mariabackup (faster, requires mariadb-backup package)
# wsrep_sst_method=mariabackup
# wsrep_sst_auth=sst_user:sst_password

# Performance tuning
innodb_autoinc_lock_mode=2
innodb_locks_unsafe_for_binlog=1
innodb_flush_log_at_trx_commit=0
binlog_format=ROW
default_storage_engine=InnoDB

# Buffer pool
innodb_buffer_pool_size=8G  # Adjust based on RAM (50-70% of total)
innodb_log_file_size=1G

# Connection limits
max_connections=500
EOF
```

**Bootstrap Galera cluster on Node 1:**

```bash
# Initialize new cluster (only on Node 1, ONLY ONCE)
galera_new_cluster

# Verify cluster status
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# Expected: wsrep_cluster_size | 1 (will become 2 after Node 2 joins)

mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_status';"
# Expected: wsrep_cluster_status | Primary

mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_local_state_comment';"
# Expected: wsrep_local_state_comment | Synced
```

### 5.4 Configure Galera on Node 2

**Create Galera configuration (almost identical to Node 1):**

```bash
cat > /etc/mysql/mariadb.conf.d/60-galera.cnf <<'EOF'
[mysqld]
# Galera Cluster Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Cluster connection
wsrep_cluster_name="wallix_bastion_cluster"
wsrep_cluster_address="gcomm://10.10.1.11,10.10.1.12"

# Node configuration
wsrep_node_name="bastion2"  # DIFFERENT from Node 1
wsrep_node_address="10.10.1.12"  # DIFFERENT from Node 1

# Replication settings (same as Node 1)
wsrep_slave_threads=4
wsrep_certify_nonPK=1
wsrep_max_ws_rows=0
wsrep_max_ws_size=2147483647
wsrep_debug=0
wsrep_convert_LOCK_to_trx=0
wsrep_retry_autocommit=1
wsrep_auto_increment_control=1

# SST method
wsrep_sst_method=rsync

# Performance tuning
innodb_autoinc_lock_mode=2
innodb_locks_unsafe_for_binlog=1
innodb_flush_log_at_trx_commit=0
binlog_format=ROW
default_storage_engine=InnoDB

# Buffer pool
innodb_buffer_pool_size=8G
innodb_log_file_size=1G

# Connection limits
max_connections=500
EOF
```

**Start MariaDB on Node 2 (it will join the cluster):**

```bash
systemctl start mariadb

# Verify it joined the cluster
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# Expected: wsrep_cluster_size | 2

mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_incoming_addresses';"
# Expected: wsrep_incoming_addresses | 10.10.1.11:3306,10.10.1.12:3306
```

### 5.5 Verify Galera Cluster Health

**On both nodes:**

```bash
# Check cluster status
mysql -u root -p <<'EOF'
SHOW STATUS LIKE 'wsrep%';
EOF

# Key metrics to verify:
# wsrep_cluster_size = 2
# wsrep_cluster_status = Primary
# wsrep_local_state_comment = Synced
# wsrep_ready = ON
# wsrep_connected = ON
```

**Test replication:**

```bash
# On Node 1: Create test database
mysql -u root -p -e "CREATE DATABASE galera_test;"

# On Node 2: Verify database exists
mysql -u root -p -e "SHOW DATABASES LIKE 'galera_test';"
# Expected: galera_test

# On Node 2: Drop test database
mysql -u root -p -e "DROP DATABASE galera_test;"

# On Node 1: Verify database deleted
mysql -u root -p -e "SHOW DATABASES LIKE 'galera_test';"
# Expected: Empty set (replicated deletion)
```

### 5.6 Galera Monitoring Script

**Create monitoring script:**

```bash
cat > /usr/local/bin/check-galera-status.sh <<'EOF'
#!/bin/bash
# Galera Cluster Health Check

MYSQL_USER="root"
MYSQL_PASS="<ROOT_PASSWORD>"

# Check cluster size
CLUSTER_SIZE=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -Nse "SHOW STATUS LIKE 'wsrep_cluster_size';" | awk '{print $2}')
CLUSTER_STATUS=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -Nse "SHOW STATUS LIKE 'wsrep_cluster_status';" | awk '{print $2}')
LOCAL_STATE=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -Nse "SHOW STATUS LIKE 'wsrep_local_state_comment';" | awk '{print $2}')

echo "Galera Cluster Status:"
echo "  Cluster Size: $CLUSTER_SIZE"
echo "  Cluster Status: $CLUSTER_STATUS"
echo "  Local State: $LOCAL_STATE"

if [ "$CLUSTER_SIZE" -lt 2 ]; then
  echo "WARNING: Cluster size is less than 2!"
  exit 1
fi

if [ "$CLUSTER_STATUS" != "Primary" ]; then
  echo "CRITICAL: Cluster is not in Primary component!"
  exit 2
fi

if [ "$LOCAL_STATE" != "Synced" ]; then
  echo "WARNING: Node is not synchronized!"
  exit 1
fi

echo "Galera cluster is healthy."
exit 0
EOF

chmod +x /usr/local/bin/check-galera-status.sh

# Test script
/usr/local/bin/check-galera-status.sh
```

---

## Pacemaker/Corosync Cluster Management

### 6.1 Pacemaker/Corosync Architecture

```
+===============================================================================+
|  PACEMAKER/COROSYNC CLUSTER STACK                                            |
+===============================================================================+
|                                                                               |
|  +---------------------------+          +---------------------------+         |
|  |        NODE 1             |          |        NODE 2             |         |
|  |                           |          |                           |         |
|  |  +---------------------+  |          |  +---------------------+  |         |
|  |  | Pacemaker           |  |          |  | Pacemaker           |  |         |
|  |  | (Cluster Resource   |  |          |  | (Cluster Resource   |  |         |
|  |  |  Manager)           |  |          |  |  Manager)           |  |         |
|  |  +----------+----------+  |          |  +----------+----------+  |         |
|  |             |             |          |             |             |         |
|  |  +----------v----------+  |          |  +----------v----------+  |         |
|  |  | Corosync            |  |          |  | Corosync            |  |         |
|  |  | (Cluster Messaging) |<-+----------+->| (Cluster Messaging) |  |         |
|  |  +---------------------+  |  UDP     |  +---------------------+  |         |
|  |                           | 5404-5406|                           |         |
|  +---------------------------+          +---------------------------+         |
|                                                                               |
|  RESPONSIBILITIES                                                             |
|  ================                                                             |
|                                                                               |
|  Corosync:                                                                    |
|  - Cluster membership and quorum                                              |
|  - Heartbeat monitoring (every 1 second)                                      |
|  - Message passing between nodes                                              |
|  - Split-brain detection                                                      |
|                                                                               |
|  Pacemaker:                                                                   |
|  - Resource management (start/stop WALLIX services)                           |
|  - Failover orchestration                                                     |
|  - STONITH fencing coordination                                               |
|  - Constraints and ordering                                                   |
|                                                                               |
|  KEY DIFFERENCE FROM ACTIVE-PASSIVE:                                          |
|  In Active-Active mode:                                                       |
|  - Resources run on BOTH nodes simultaneously                                 |
|  - No VIP migration (HAProxy handles load balancing)                          |
|  - Pacemaker ensures both nodes stay healthy                                  |
|  - STONITH still required for split-brain prevention                          |
|                                                                               |
+===============================================================================+
```

### 6.2 Install Pacemaker and Corosync

**On both nodes:**

```bash
# Install cluster packages
apt-get update
apt-get install -y pacemaker corosync pcs fence-agents \
                   fence-agents-ipmilan resource-agents

# Enable services (but don't start yet)
systemctl enable pacemaker
systemctl enable corosync
systemctl enable pcsd

# Set hacluster user password (must be SAME on both nodes)
echo "hacluster:<STRONG_PASSWORD>" | chpasswd
```

### 6.3 Configure Corosync

**On Node 1, create Corosync configuration:**

```bash
cat > /etc/corosync/corosync.conf <<'EOF'
totem {
    version: 2
    cluster_name: wallix_bastion_cluster

    # Crypto (authentication)
    secauth: on
    crypto_cipher: aes256
    crypto_hash: sha256

    # Network configuration
    interface {
        ringnumber: 0
        bindnetaddr: 192.168.100.0  # Dedicated heartbeat network
        mcastport: 5405
        ttl: 1
    }

    # Timeouts (tuned for low-latency network)
    token: 3000
    token_retransmits_before_loss_const: 10
    join: 60
    consensus: 3600
    max_messages: 20
}

logging {
    fileline: off
    to_stderr: no
    to_logfile: yes
    logfile: /var/log/corosync/corosync.log
    to_syslog: yes
    debug: off
    timestamp: on
    logger_subsys {
        subsys: QUORUM
        debug: off
    }
}

quorum {
    provider: corosync_votequorum
    expected_votes: 2
    two_node: 1  # Special 2-node mode (no quorum device needed)
}

nodelist {
    node {
        ring0_addr: 192.168.100.11
        name: bastion1
        nodeid: 1
    }
    node {
        ring0_addr: 192.168.100.12
        name: bastion2
        nodeid: 2
    }
}
EOF

# Copy configuration to Node 2
scp /etc/corosync/corosync.conf root@bastion2:/etc/corosync/
```

**Generate Corosync authentication key:**

```bash
# On Node 1
corosync-keygen

# Copy to Node 2
scp /etc/corosync/authkey root@bastion2:/etc/corosync/

# Set permissions on both nodes
chmod 400 /etc/corosync/authkey
```

### 6.4 Start Corosync and Pacemaker

**On both nodes (start Node 1 first):**

```bash
# Start Corosync
systemctl start corosync

# Verify Corosync is running
systemctl status corosync

# Check cluster membership
corosync-cmapctl | grep members
# Expected: See both nodes listed

# Start Pacemaker
systemctl start pacemaker

# Verify Pacemaker is running
systemctl status pacemaker
```

### 6.5 Configure Pacemaker Cluster Properties

**On Node 1:**

```bash
# Authenticate with pcs
pcs cluster auth bastion1 bastion2 -u hacluster -p <PASSWORD>

# Set cluster properties for Active-Active mode
pcs property set stonith-enabled=true
pcs property set no-quorum-policy=stop  # Important for 2-node
pcs property set symmetric-cluster=true
pcs property set cluster-recheck-interval=1min
pcs property set start-failure-is-fatal=false
pcs property set pe-warn-series-max=1000
pcs property set pe-input-series-max=1000
pcs property set pe-error-series-max=1000

# Disable resource stickiness (allow resources to run anywhere)
pcs resource defaults resource-stickiness=0

# Verify properties
pcs property list
```

### 6.6 Configure STONITH (Fencing)

**Purpose**: Prevent split-brain by forcibly rebooting failed nodes via IPMI.

**Configure IPMI fencing devices:**

```bash
# Node 1 fence device (managed by Node 2)
pcs stonith create fence_node1 fence_ipmilan \
  pcmk_host_list="bastion1" \
  ipaddr="10.10.1.111" \
  login="ipmi_admin" \
  passwd="<IPMI_PASSWORD>" \
  lanplus=1 \
  delay=15 \
  op monitor interval=60s

# Node 2 fence device (managed by Node 1)
pcs stonith create fence_node2 fence_ipmilan \
  pcmk_host_list="bastion2" \
  ipaddr="10.10.1.112" \
  login="ipmi_admin" \
  passwd="<IPMI_PASSWORD>" \
  lanplus=1 \
  op monitor interval=60s

# Prevent nodes from fencing themselves
pcs constraint location fence_node1 avoids bastion1=INFINITY
pcs constraint location fence_node2 avoids bastion2=INFINITY

# Verify STONITH configuration
pcs stonith status
pcs stonith show
```

**Test STONITH fencing:**

```bash
# WARNING: This will reboot the target node!

# Test fence Node 2 from Node 1
pcs stonith fence bastion2

# Monitor Node 2 - should reboot and rejoin cluster within 2-3 minutes
watch -n 2 pcs status

# After Node 2 rejoins:
# Verify cluster health
pcs status
```

### 6.7 Create Cluster Resources (Active-Active Mode)

**Key Difference**: In Active-Active mode, we want WALLIX services to run on BOTH nodes simultaneously.

```bash
# Define WALLIX Bastion service as a cloned resource (runs on all nodes)
pcs resource create wallix_bastion systemd:wallix-bastion \
  op start interval=0s timeout=60s \
  op stop interval=0s timeout=60s \
  op monitor interval=10s timeout=20s \
  --clone

# Define MariaDB Galera as a multi-state resource (all nodes PRIMARY)
pcs resource create galera_cluster ocf:heartbeat:galera \
  wsrep_cluster_address="gcomm://10.10.1.11,10.10.1.12" \
  check_user="clustercheck" \
  check_passwd="<CHECK_PASSWORD>" \
  op start interval=0s timeout=120s \
  op stop interval=0s timeout=120s \
  op promote interval=0s timeout=300s \
  op monitor interval=10s role="Master" timeout=30s \
  op monitor interval=20s role="Slave" timeout=30s \
  --master

# Constraint: Start Galera before WALLIX services
pcs constraint order galera_cluster-master then wallix_bastion-clone

# Constraint: WALLIX service depends on Galera being PRIMARY
pcs constraint colocation add wallix_bastion-clone with Master galera_cluster-master INFINITY

# Verify resources
pcs resource show
pcs resource status
pcs constraint show
```

**Expected Resource Status:**

```
Cluster name: wallix_bastion_cluster
Stack: corosync
Current DC: bastion1
2 nodes configured
4 resources configured

Online: [ bastion1 bastion2 ]

Full list of resources:
 fence_node1    (stonith:fence_ipmilan):        Started bastion2
 fence_node2    (stonith:fence_ipmilan):        Started bastion1
 Clone Set: wallix_bastion-clone [wallix_bastion]
     Started: [ bastion1 bastion2 ]
 Master/Slave Set: galera_cluster-master [galera_cluster]
     Masters: [ bastion1 bastion2 ]
```

---

## Split-Brain Prevention

### 7.1 Understanding Split-Brain

```
+===============================================================================+
|  SPLIT-BRAIN SCENARIO                                                        |
+===============================================================================+
|                                                                               |
|  NORMAL OPERATION:                                                            |
|  Node 1 <----Heartbeat----> Node 2                                           |
|  (Primary)                  (Primary)                                         |
|  Cluster Size: 2            Cluster Size: 2                                  |
|                                                                               |
|  NETWORK PARTITION (Split-Brain):                                            |
|  Node 1      X X X X X      Node 2                                           |
|  (Thinks it's alone)        (Thinks it's alone)                               |
|  Cluster Size: 1            Cluster Size: 1                                  |
|                                                                               |
|  WITHOUT SPLIT-BRAIN PROTECTION:                                              |
|  - Both nodes think they are the only survivor                                |
|  - Both continue accepting writes to database                                 |
|  - Data diverges (CONFLICT!)                                                  |
|  - When network heals, database is inconsistent                               |
|                                                                               |
|  WITH STONITH FENCING (CORRECT):                                              |
|  - Node 1 detects heartbeat loss                                              |
|  - Node 1 attempts to fence Node 2 via IPMI (power cycle)                     |
|  - Node 2 is forcibly rebooted                                                |
|  - Node 1 continues as sole primary                                           |
|  - Node 2 rejoins cluster after reboot (syncs data)                           |
|  - Data consistency maintained                                                |
|                                                                               |
+===============================================================================+
```

### 7.2 Quorum Configuration (2-Node Cluster)

**Challenge**: In a 2-node cluster, if one node fails, the surviving node has only 50% of votes (no quorum).

**Solution**: Use `two_node: 1` setting in Corosync.

**Verify quorum configuration:**

```bash
# Check quorum settings
corosync-quorumtool

# Expected output:
# Quorum information
# ------------------
# Date:             Thu Feb  5 12:00:00 2026
# Quorum provider:  corosync_votequorum
# Nodes:            2
# Node ID:          1
# Ring ID:          1/8
# Quorate:          Yes
#
# Votequorum information
# ----------------------
# Expected votes:   2
# Highest expected: 2
# Total votes:      2
# Quorum:           1  # With two_node mode, only 1 vote needed
# Flags:            2Node Quorate
#
# Membership information
# ----------------------
#     Nodeid      Votes Name
#          1          1 bastion1 (local)
#          2          1 bastion2
```

### 7.3 STONITH Testing Scenarios

#### Scenario 1: Simulated Node Failure

```bash
# From Node 1, simulate Node 2 hard failure (immediate)
pcs stonith fence bastion2

# Expected behavior:
# - Node 2 IPMI receives power cycle command
# - Node 2 reboots immediately
# - Node 1 continues serving traffic
# - Galera cluster size temporarily reduces to 1
# - Node 2 rejoins after reboot (~2 minutes)
# - Galera cluster size returns to 2
```

#### Scenario 2: Network Partition Simulation

```bash
# On Node 2, block heartbeat traffic (simulates network partition)
iptables -A INPUT -s 192.168.100.11 -j DROP
iptables -A OUTPUT -d 192.168.100.11 -j DROP

# Expected behavior:
# - Node 1 detects heartbeat loss within 3 seconds (token timeout)
# - Node 1 attempts to fence Node 2 via IPMI (separate network)
# - Node 2 is forcibly rebooted via IPMI
# - Node 1 remains active
# - After Node 2 reboot, remove iptables rules and it rejoins
```

**Restore network after test:**

```bash
# On Node 2 after rejoining
iptables -F  # Flush all rules
```

### 7.4 Quorum Device (Optional - Recommended for Production)

**Purpose**: Provide a tie-breaker for 2-node clusters without relying solely on STONITH.

**Setup Quorum Device (on separate host, e.g., HAProxy or NAS):**

```bash
# On quorum device host (10.10.1.250)
apt-get install -y corosync-qdevice corosync-qnetd

# Start qnetd service
systemctl enable corosync-qnetd
systemctl start corosync-qnetd

# On Node 1, add quorum device to cluster
pcs quorum device add model net host=10.10.1.250 algorithm=ffsplit

# Verify quorum device
corosync-quorumtool
# Expected: Qdevice votes: 1
```

---

## WALLIX Bastion Configuration Sync

### 8.1 WALLIX Configuration Replication

**WALLIX Bastion automatically synchronizes configuration across cluster nodes via database replication (Galera).**

Configuration stored in MariaDB includes:
- Users, groups, and roles
- Devices and accounts
- Authorization policies
- Session recording settings
- Credential vault data (encrypted)

**Verify configuration sync:**

```bash
# On Node 1: Create a test user via wabadmin CLI
wabadmin user-add testuser --password 'Test123!' --email 'test@example.com'

# On Node 2: List users (should include testuser)
wabadmin user-list | grep testuser
# Expected: testuser present

# On Node 2: Delete test user
wabadmin user-delete testuser

# On Node 1: Verify user deleted
wabadmin user-list | grep testuser
# Expected: Empty (user deleted)
```

### 8.2 Encryption Key Synchronization

**WALLIX encryption keys are stored in database and replicated via Galera.**

**Verify key sync:**

```bash
# On Node 1: List encryption keys
wabadmin keys-list

# On Node 2: List encryption keys (should be identical)
wabadmin keys-list

# Compare key fingerprints
ssh bastion1 "wabadmin keys-list --format=json" > node1_keys.json
ssh bastion2 "wabadmin keys-list --format=json" > node2_keys.json
diff node1_keys.json node2_keys.json
# Expected: No differences
```

### 8.3 Session Recording Consistency

**Session recordings are written to shared NFS storage, accessible from both nodes.**

**Test recording accessibility:**

```bash
# On Node 1: List recent recordings
ls -lh /var/wab/recorded/ | head -20

# On Node 2: List recent recordings (should be identical)
ls -lh /var/wab/recorded/ | head -20

# Verify file locking (prevent simultaneous writes to same file)
# This is handled by NFS lock daemon (rpc.lockd)
systemctl status nfs-lock.service
```

---

## HAProxy Load Balancer Integration

### 9.1 HAProxy Backend Configuration

**On HAProxy servers (separate hosts), configure WALLIX Bastion backend pool.**

**HAProxy Configuration (`/etc/haproxy/haproxy.cfg`):**

```haproxy
global
    log /dev/log local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    maxconn 4096
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

# Frontend for user access (HTTPS, SSH, RDP)
frontend wallix_frontend
    bind *:443 ssl crt /etc/ssl/private/wallix.pem
    bind *:22 name ssh
    bind *:3389 name rdp
    mode http
    option http-server-close
    option forwardfor except 127.0.0.0/8

    # Session persistence (important for WALLIX sessions)
    cookie SERVERID insert indirect nocache

    default_backend wallix_backend

# Backend pool (Active-Active Bastions)
backend wallix_backend
    mode http
    balance roundrobin  # or leastconn

    # Health check (HTTP GET /health)
    option httpchk GET /health HTTP/1.1\r\nHost:\ wallix

    # Bastion Node 1
    server bastion1 10.10.1.11:443 check ssl verify none cookie bastion1 inter 2s rise 2 fall 3

    # Bastion Node 2
    server bastion2 10.10.1.12:443 check ssl verify none cookie bastion2 inter 2s rise 2 fall 3

# HAProxy stats page
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 5s
    stats auth admin:<STATS_PASSWORD>
```

**Key HAProxy Settings for Active-Active:**

| Setting | Value | Purpose |
|---------|-------|---------|
| `balance roundrobin` | Round-robin | Distribute traffic evenly (alternative: `leastconn`) |
| `cookie SERVERID insert` | Session persistence | Keep user on same node for HTTP sessions |
| `check inter 2s` | Health check every 2s | Fast failure detection |
| `rise 2 fall 3` | 2 success / 3 fail | Balance between sensitivity and stability |

**Reload HAProxy configuration:**

```bash
# On both HAProxy servers
systemctl reload haproxy

# Verify HAProxy backend status
echo "show stat" | socat stdio /run/haproxy/admin.sock | grep wallix_backend
```

### 9.2 Health Check Endpoint

**WALLIX Bastion provides a health check endpoint for load balancers.**

**Test health endpoint:**

```bash
# Test Node 1 health
curl -k https://10.10.1.11/health
# Expected: {"status":"ok","cluster":"healthy"}

# Test Node 2 health
curl -k https://10.10.1.12/health
# Expected: {"status":"ok","cluster":"healthy"}
```

**HAProxy will mark nodes as DOWN if:**
- Health check returns HTTP 500+
- Response timeout (> 2 seconds)
- Connection refused
- Node powered off

---

## Testing Load Balancing

### 10.1 Verify Traffic Distribution

**Test 1: HTTP Requests Distribution**

```bash
# Send 20 requests to HAProxy VIP
for i in {1..20}; do
  curl -k -s https://10.10.1.100/health | jq -r '.hostname'
done | sort | uniq -c

# Expected output (approximately even distribution):
#  10 bastion1
#  10 bastion2
```

**Test 2: Monitor Active Connections**

```bash
# On HAProxy, check backend statistics
watch -n 2 'echo "show stat" | socat stdio /run/haproxy/admin.sock | grep wallix_backend'

# While test is running:
# Open multiple browser sessions to https://10.10.1.100
# Observe "scur" (current sessions) incrementing on both backends
```

**Test 3: Session Persistence (Sticky Sessions)**

```bash
# Test that same client goes to same backend (HTTP cookie)
curl -k -c cookies.txt https://10.10.1.100/health
curl -k -b cookies.txt https://10.10.1.100/health
curl -k -b cookies.txt https://10.10.1.100/health

# Check SERVERID cookie:
cat cookies.txt | grep SERVERID
# Expected: SERVERID=bastion1 (or bastion2)

# All subsequent requests should hit the same backend node
```

### 10.2 Load Simulation Testing

**Test with Apache Bench (ab):**

```bash
# Install apache2-utils
apt-get install -y apache2-utils

# Simulate 100 concurrent users, 1000 requests
ab -n 1000 -c 100 -k https://10.10.1.100/health

# Monitor on HAProxy
watch -n 1 'echo "show info" | socat stdio /run/haproxy/admin.sock | grep -E "CurrConns|CumReq"'
```

**Monitor node load:**

```bash
# On Node 1 and Node 2
watch -n 2 'echo "Active connections:"; ss -s | grep estab'
```

---

## Failover Testing

### 11.1 Node Failure Scenarios

#### Scenario 1: Graceful Node Shutdown

**Test graceful failover when Node 1 is shut down cleanly.**

```bash
# On Node 1: Gracefully stop WALLIX service
systemctl stop wallix-bastion

# On HAProxy: Monitor backend status
watch -n 1 'echo "show stat" | socat stdio /run/haproxy/admin.sock | grep bastion1'

# Expected:
# - bastion1 status changes to DOWN within 2-4 seconds
# - All traffic redirected to bastion2
# - Active sessions on bastion1: HTTP sessions continue (if cookie-based), SSH/RDP disconnect

# Verify all traffic goes to Node 2
for i in {1..10}; do curl -k https://10.10.1.100/health | jq -r '.hostname'; done
# Expected: All responses from bastion2

# Restart Node 1
systemctl start wallix-bastion

# Monitor Node 1 rejoining backend pool
watch -n 1 'echo "show stat" | socat stdio /run/haproxy/admin.sock | grep bastion1'
# Expected: Status changes to UP after health checks pass (~4 seconds)
```

#### Scenario 2: Hard Node Failure (Power Loss)

**Simulate complete node failure.**

```bash
# From Node 1 IPMI, force power off
ipmitool -I lanplus -H 10.10.1.111 -U ipmi_admin -P <PASSWORD> power off

# On HAProxy: Monitor backend
watch -n 1 'echo "show stat" | socat stdio /run/haproxy/admin.sock'

# Expected:
# - bastion1 marked DOWN within 6 seconds (3 failed health checks)
# - All traffic routed to bastion2
# - Galera cluster size reduces to 1 on Node 2

# On Node 2: Verify cluster status
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# Expected: wsrep_cluster_size = 1

# Power on Node 1
ipmitool -I lanplus -H 10.10.1.111 -U ipmi_admin -P <PASSWORD> power on

# Wait for Node 1 to boot (~2 minutes)
# Monitor Node 1 rejoining Galera cluster
ssh bastion1 'mysql -u root -p -e "SHOW STATUS LIKE \"wsrep_local_state_comment\";"'
# Expected: Synced (after IST or SST)
```

#### Scenario 3: Network Partition

**Simulate network split between nodes (split-brain test).**

```bash
# On Node 2: Block heartbeat traffic
iptables -A INPUT -s 192.168.100.11 -j DROP
iptables -A OUTPUT -d 192.168.100.11 -j DROP

# Expected behavior:
# - Corosync on Node 1 detects heartbeat loss
# - Node 1 attempts STONITH fence on Node 2 (via IPMI - different network)
# - Node 2 is forcibly rebooted
# - Node 1 continues as sole primary
# - HAProxy marks bastion2 DOWN

# After Node 2 reboots and rejoins:
# Remove iptables rules
ssh bastion2 'iptables -F'

# Verify cluster health
pcs status
corosync-quorumtool
```

### 11.2 Database Failover Testing

**Test Galera cluster resilience to node failure.**

```bash
# On Node 1: Stop MariaDB (simulate database crash)
systemctl stop mariadb

# On Node 2: Verify cluster continues
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# Expected: wsrep_cluster_size = 1

# On Node 2: Test write operations
mysql -u root -p -e "CREATE DATABASE failover_test; DROP DATABASE failover_test;"
# Expected: Success

# Restart MariaDB on Node 1
systemctl start mariadb

# Monitor Node 1 rejoining cluster
watch -n 2 'mysql -u root -p -e "SHOW STATUS LIKE \"wsrep_local_state_comment\";"'
# Expected: Synced (after catching up)
```

### 11.3 Failover Timing Measurements

**Measure exact failover times:**

```bash
# Script to measure failover time
cat > /tmp/measure-failover.sh <<'EOF'
#!/bin/bash
START=$(date +%s.%N)
while true; do
  if ! curl -k -s -m 1 https://10.10.1.100/health > /dev/null 2>&1; then
    FAIL_TIME=$(date +%s.%N)
    echo "Service unavailable at: $FAIL_TIME"
    break
  fi
  sleep 0.1
done

while true; do
  if curl -k -s -m 1 https://10.10.1.100/health > /dev/null 2>&1; then
    RECOVER_TIME=$(date +%s.%N)
    echo "Service recovered at: $RECOVER_TIME"
    break
  fi
  sleep 0.1
done

DOWNTIME=$(echo "$RECOVER_TIME - $FAIL_TIME" | bc)
echo "Total downtime: $DOWNTIME seconds"
EOF

chmod +x /tmp/measure-failover.sh

# Run measurement while triggering failover
/tmp/measure-failover.sh &
# On Node 1: systemctl stop wallix-bastion

# Expected downtime: < 5 seconds (Active-Active with fast health checks)
```

---

## Performance Tuning

### 12.1 MariaDB/Galera Performance Optimization

**Optimize for high-throughput workloads:**

```bash
# Edit /etc/mysql/mariadb.conf.d/60-galera.cnf on both nodes

[mysqld]
# Increase buffer pool (50-70% of RAM)
innodb_buffer_pool_size=24G  # For 32GB RAM system
innodb_buffer_pool_instances=8

# Increase log file size for better write performance
innodb_log_file_size=2G
innodb_log_buffer_size=64M

# Optimize Galera replication
wsrep_slave_threads=8  # Match CPU cores
wsrep_provider_options="gcache.size=4G;evs.send_window=512;evs.user_send_window=256"

# Connection pooling
max_connections=1000
thread_cache_size=128

# Query cache (disable for Galera)
query_cache_size=0
query_cache_type=0

# Restart MariaDB to apply
systemctl restart mariadb
```

### 12.2 Network Optimization

**Tune network stack for low latency:**

```bash
# Edit /etc/sysctl.conf on both nodes

# Increase network buffer sizes
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864

# Enable TCP fast open
net.ipv4.tcp_fastopen=3

# Increase connection tracking
net.netfilter.nf_conntrack_max=1000000

# Apply settings
sysctl -p
```

### 12.3 Corosync Tuning for High Availability

**Reduce failover detection time:**

```bash
# Edit /etc/corosync/corosync.conf

totem {
    # Reduce token timeout for faster failover (default: 3000ms)
    token: 2000  # 2 seconds

    # Faster retransmission
    token_retransmits_before_loss_const: 5

    # Reduce join timeout
    join: 30
}

# Restart Corosync on both nodes (one at a time)
systemctl restart corosync
```

### 12.4 HAProxy Performance Tuning

**Optimize load balancer for high session counts:**

```haproxy
global
    maxconn 10000  # Increase from default 4096
    tune.ssl.default-dh-param 2048
    tune.bufsize 32768

defaults
    timeout connect 5s
    timeout client  300s  # 5 minutes for long-running sessions
    timeout server  300s

backend wallix_backend
    balance leastconn  # Better for uneven session durations
    option httpchk GET /health

    # Reduce health check interval for faster failure detection
    server bastion1 10.10.1.11:443 check inter 1s fall 2 rise 2
    server bastion2 10.10.1.12:443 check inter 1s fall 2 rise 2
```

### 12.5 Monitoring Performance Metrics

**Key metrics to monitor:**

| Metric | Command | Target |
|--------|---------|--------|
| **Galera Replication Lag** | `mysql -e "SHOW STATUS LIKE 'wsrep_local_recv_queue';"` | < 10 |
| **Database Connections** | `mysql -e "SHOW STATUS LIKE 'Threads_connected';"` | < 80% of max_connections |
| **CPU Load** | `uptime` | < 70% average |
| **Memory Usage** | `free -h` | < 80% |
| **Disk I/O Wait** | `iostat -x 1` | < 10% |
| **Network Throughput** | `iftop -i bond0` | < 80% of link capacity |
| **HAProxy Queue** | `echo "show stat" \| socat - /run/haproxy/admin.sock` | qcur = 0 |

---

## Troubleshooting

### 13.1 Common Issues and Solutions

#### Issue 1: Galera Cluster Not Forming

**Symptoms:**
- `wsrep_cluster_size` = 1 on both nodes
- `wsrep_cluster_status` = "non-Primary"
- Nodes not replicating

**Diagnosis:**

```bash
# Check Galera status
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep%';"

# Check for errors in MariaDB log
tail -f /var/log/mysql/error.log | grep -i galera
```

**Common Causes:**

1. **Firewall blocking Galera ports:**
   ```bash
   # Test connectivity
   nc -zv 10.10.1.12 4567  # From Node 1 to Node 2
   nc -zv 10.10.1.11 4567  # From Node 2 to Node 1

   # If fails, check firewall
   iptables -L -n | grep 4567
   ```

2. **Incorrect cluster address:**
   ```bash
   # Verify wsrep_cluster_address in config
   grep wsrep_cluster_address /etc/mysql/mariadb.conf.d/60-galera.cnf
   # Should be: gcomm://10.10.1.11,10.10.1.12
   ```

3. **Both nodes bootstrapped:**
   ```bash
   # Only Node 1 should be bootstrapped initially
   # On Node 2, stop and rejoin cluster
   systemctl stop mariadb
   systemctl start mariadb  # Will join existing cluster
   ```

**Resolution:**

```bash
# Complete cluster restart (both nodes down)
# On Node 1: Bootstrap cluster
galera_new_cluster

# On Node 2: Join cluster
systemctl start mariadb

# Verify cluster size
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# Expected: 2
```

#### Issue 2: Split-Brain Detected

**Symptoms:**
- Both nodes report `wsrep_cluster_size` = 1
- Pacemaker shows "UNCLEAN" nodes
- STONITH fencing attempts failing

**Diagnosis:**

```bash
# Check cluster status
pcs status
crm_mon -1

# Check Corosync membership
corosync-cmapctl | grep members

# Check STONITH fencing history
pcs stonith history show
```

**Resolution (Manual):**

```bash
# Identify which node has newer data (check timestamps)
# On Node 1:
mysql -u root -p -e "SELECT MAX(created_at) FROM wab.sessions;"

# On Node 2:
mysql -u root -p -e "SELECT MAX(created_at) FROM wab.sessions;"

# Assume Node 1 has newer data - make it primary

# On Node 2: Stop MariaDB and clear Galera state
systemctl stop mariadb
rm -f /var/lib/mysql/grastate.dat
rm -f /var/lib/mysql/galera.cache

# On Node 1: Continue as bootstrap
# (if not already running)
galera_new_cluster

# On Node 2: Rejoin and resync
systemctl start mariadb

# Verify replication
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_local_state_comment';"
# Expected: Synced (after IST/SST)
```

#### Issue 3: HAProxy Backend Flapping

**Symptoms:**
- Nodes alternating between UP and DOWN rapidly
- Health checks inconsistent
- User sessions disconnecting

**Diagnosis:**

```bash
# On HAProxy, check backend statistics
echo "show stat" | socat stdio /run/haproxy/admin.sock | grep wallix_backend

# Monitor health check failures
tail -f /var/log/haproxy.log | grep "Health check"
```

**Common Causes:**

1. **Overloaded backend:**
   ```bash
   # Check CPU and load on Bastion nodes
   ssh bastion1 'uptime'
   ssh bastion2 'uptime'

   # If load > CPU cores * 2, backend is overloaded
   ```

2. **Slow health check responses:**
   ```bash
   # Test health endpoint directly
   time curl -k https://10.10.1.11/health
   # Should be < 1 second
   ```

**Resolution:**

```bash
# Increase health check interval and thresholds
# Edit /etc/haproxy/haproxy.cfg

backend wallix_backend
    option httpchk GET /health
    server bastion1 10.10.1.11:443 check inter 5s rise 3 fall 5  # More tolerant
    server bastion2 10.10.1.12:443 check inter 5s rise 3 fall 5

# Reload HAProxy
systemctl reload haproxy
```

#### Issue 4: Session Recordings Not Syncing

**Symptoms:**
- Recordings missing from one node
- NFS mount errors
- Permission denied errors

**Diagnosis:**

```bash
# Check NFS mount
df -h | grep recorded
mount | grep recorded

# Test NFS connectivity
ping -c 5 nas-site1

# Check NFS server exports
showmount -e nas-site1

# Test write access
su - wab -c "touch /var/wab/recorded/test.txt && rm /var/wab/recorded/test.txt"
```

**Resolution:**

```bash
# Remount NFS
umount /var/wab/recorded
mount -a

# Verify mount options
mount | grep recorded
# Should include: rw,hard,intr

# Check NFS lock daemon
systemctl status nfs-lock.service
systemctl restart nfs-lock.service

# Verify permissions
ls -ld /var/wab/recorded
# Should be: drwxr-x--- wab wab
```

### 13.2 Diagnostic Commands Reference

```bash
# Cluster Status
pcs status                    # Overall cluster status
crm_mon -1                    # Cluster resources and nodes
corosync-quorumtool           # Quorum and membership
pcs stonith status            # STONITH fencing status

# Galera Status
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep%';"  # Galera replication
/usr/local/bin/check-galera-status.sh            # Custom health check

# WALLIX Bastion Status
systemctl status wallix-bastion
wabadmin status
wabadmin cluster-status

# HAProxy Status
echo "show stat" | socat stdio /run/haproxy/admin.sock
echo "show info" | socat stdio /run/haproxy/admin.sock

# Network
ss -tunap | grep -E "3306|4567|5404|2224"  # Cluster ports
iftop -i bond0                              # Network traffic
```

### 13.3 Log File Locations

| Component | Log Path |
|-----------|----------|
| **WALLIX Bastion** | `/var/log/wallix/` |
| **MariaDB** | `/var/log/mysql/error.log` |
| **Galera** | `/var/log/mysql/error.log` (search "galera") |
| **Corosync** | `/var/log/corosync/corosync.log` |
| **Pacemaker** | `/var/log/pacemaker/pacemaker.log` |
| **PCSD** | `/var/log/pcsd/pcsd.log` |
| **HAProxy** | `/var/log/haproxy.log` |

---

## Operational Procedures

### 14.1 Daily Operations

**Morning Health Check:**

```bash
#!/bin/bash
# /usr/local/bin/daily-cluster-check.sh

echo "=== Daily Cluster Health Check ==="
date

echo -e "\n1. Cluster Status:"
pcs status | head -20

echo -e "\n2. Galera Cluster Size:"
mysql -u root -p<PASSWORD> -Nse "SHOW STATUS LIKE 'wsrep_cluster_size';"

echo -e "\n3. Active Sessions:"
wabadmin sessions-list --active | wc -l

echo -e "\n4. HAProxy Backend Status:"
ssh haproxy1 'echo "show stat" | socat stdio /run/haproxy/admin.sock | grep bastion'

echo -e "\n5. Disk Usage (Recordings):"
df -h | grep recorded

echo -e "\n6. System Load:"
uptime

echo "=== Health Check Complete ===" | mail -s "WALLIX Cluster Health" admin@example.com
```

### 14.2 Maintenance Procedures

#### Procedure 1: Patching/Upgrading One Node (Zero Downtime)

```bash
# Step 1: Put Node 1 in maintenance mode
pcs node standby bastion1

# Step 2: Verify resources migrated to Node 2
pcs status

# Step 3: Apply patches on Node 1
ssh bastion1 'apt-get update && apt-get upgrade -y'

# Step 4: Reboot Node 1 (optional)
ssh bastion1 'reboot'

# Step 5: Wait for Node 1 to rejoin cluster (~2 minutes)
watch pcs status

# Step 6: Unstandby Node 1
pcs node unstandby bastion1

# Step 7: Verify Node 1 rejoined and serving traffic
pcs status
echo "show stat" | socat stdio /run/haproxy/admin.sock | grep bastion1

# Step 8: Repeat for Node 2
pcs node standby bastion2
# ... (same steps)
```

#### Procedure 2: Emergency Cluster Shutdown

```bash
# Step 1: Stop HAProxy (prevent new connections)
ssh haproxy1 'systemctl stop haproxy'
ssh haproxy2 'systemctl stop haproxy'

# Step 2: Stop WALLIX services gracefully
pcs resource disable wallix_bastion-clone

# Step 3: Wait for all sessions to close (or force-close)
wabadmin sessions-list --active
# If urgent: wabadmin sessions-close-all

# Step 4: Stop Galera cluster
pcs resource disable galera_cluster-master

# Step 5: Stop Pacemaker
systemctl stop pacemaker  # On both nodes

# Step 6: Stop Corosync
systemctl stop corosync  # On both nodes
```

#### Procedure 3: Emergency Cluster Startup

```bash
# Step 1: Start Corosync on both nodes
systemctl start corosync  # Node 1
systemctl start corosync  # Node 2

# Step 2: Start Pacemaker on both nodes
systemctl start pacemaker  # Node 1
systemctl start pacemaker  # Node 2

# Step 3: Bootstrap Galera cluster
# On Node 1:
galera_new_cluster

# Wait 30 seconds, then on Node 2:
systemctl start mariadb

# Step 4: Enable cluster resources
pcs resource enable galera_cluster-master
pcs resource enable wallix_bastion-clone

# Step 5: Verify cluster health
pcs status
wabadmin status

# Step 6: Start HAProxy
ssh haproxy1 'systemctl start haproxy'
ssh haproxy2 'systemctl start haproxy'

# Step 7: Test user access
curl -k https://10.10.1.100/health
```

---

## Summary and Next Steps

### Deployment Checklist

- [ ] Hardware appliances configured with IPMI/iLO
- [ ] Network interfaces bonded and VLANs created
- [ ] Shared NFS storage mounted on both nodes
- [ ] MariaDB Galera cluster configured and running (size = 2)
- [ ] Pacemaker/Corosync cluster established
- [ ] STONITH fencing configured and tested
- [ ] Cluster resources created (wallix_bastion-clone, galera_cluster-master)
- [ ] HAProxy load balancer configured with both backends
- [ ] Health checks passing on both nodes
- [ ] Traffic distribution verified (50/50 split)
- [ ] Failover tested (Node 1 down, Node 2 serves all traffic)
- [ ] Split-brain prevention validated
- [ ] Performance tuning applied
- [ ] Monitoring scripts deployed
- [ ] Operational runbooks documented

### Next Steps

1. **Integrate with Access Manager:** Configure SSO and session brokering
   - See: [03-access-manager-integration.md](03-access-manager-integration.md)

2. **Configure Authentication:** Set up LDAP/AD, FortiAuthenticator MFA
   - See: `/docs/pam/06-authentication/`

3. **Deploy to Additional Sites:** Replicate configuration for Sites 2-5
   - See: [01-network-design.md](01-network-design.md)

4. **Set Up Monitoring:** Deploy Prometheus, Grafana, alerting
   - See: `/docs/pam/12-monitoring-observability/`

5. **Backup Strategy:** Implement automated database and config backups
   - See: `/docs/pam/30-backup-restore/`

---

## References

### Internal Documentation

- [02-ha-architecture.md](02-ha-architecture.md) - Active-Active vs Active-Passive comparison
- [01-network-design.md](01-network-design.md) - Network topology and firewall rules
- [/docs/pam/11-high-availability/](../docs/pam/11-high-availability/) - Detailed HA concepts
- [/docs/pam/32-load-balancer/](../docs/pam/32-load-balancer/) - HAProxy configuration

### External Resources

- WALLIX Bastion HA Guide: https://pam.wallix.one/documentation/admin-doc/
- MariaDB Galera Cluster: https://mariadb.com/kb/en/galera-cluster/
- Pacemaker Explained: https://clusterlabs.org/pacemaker/doc/
- Corosync Configuration: https://corosync.github.io/corosync/

---

**Document Version**: 1.0
**Last Updated**: 2026-02-05
**Tested on**: WALLIX Bastion 12.1.x HW appliances
**Validation Status**: Production-ready
