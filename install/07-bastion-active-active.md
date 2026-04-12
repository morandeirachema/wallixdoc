# 07 - Active-Active WALLIX Bastion HW Appliance Cluster Setup

> Comprehensive guide for deploying Active-Active High Availability clusters using WALLIX Bastion hardware appliances with `bastion-replication` Master/Master mode

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Active-Active HA cluster configuration for WALLIX Bastion HW appliances |
| **Deployment Model** | 2 hardware appliances per site in Active-Active (Master/Master) mode; DMZ VLAN |
| **Version** | WALLIX Bastion 12.1.x |
| **Prerequisites** | [02-ha-architecture.md](02-ha-architecture.md), [01-network-design.md](01-network-design.md), [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md) |
| **Last Updated** | April 2026 |

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites & Planning](#prerequisites--planning)
3. [Initial Appliance Setup](#initial-appliance-setup)
4. [Network Configuration](#network-configuration)
5. [bastion-replication Master/Master Configuration](#bastion-replication-mastermaster-configuration)
6. [Replication Limitations & Exclusions](#replication-limitations--exclusions)
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
|  ACTIVE-ACTIVE WALLIX BASTION CLUSTER (Master/Master)                        |
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
| |  (MASTER - HW Appliance)       | |  (MASTER - HW Appliance)       |         |
| |                                | |                                |         |
| |  IP: 10.10.X.11                | |  IP: 10.10.X.12                |         |
| |  Load: 50% traffic             | |  Load: 50% traffic             |         |
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
| |  | bastion-replication       | | |  | bastion-replication       | |         |
| |  | (MASTER/MASTER)           |<+-+->| (MASTER/MASTER)           | |         |
| |  |                           | | |  |                           | |         |
| |  | SSH tunnel via autossh    | | |  | SSH tunnel via autossh    | |         |
| |  | Port 2242 (SSH tunnel)    | | |  | Port 2242 (SSH tunnel)    | |         |
| |  | Port 3306 (MariaDB in)    | | |  | Port 3306 (MariaDB in)    | |         |
| |  | Port 3307 (MariaDB out)   | | |  | Port 3307 (MariaDB out)   | |         |
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
|  - Replication managed by bastion-replication (Master/Master)                 |
|  - SSH tunnel (autossh) on port 2242 between nodes                           |
|  - MariaDB replication tunneled: outbound 3307 -> inbound 3306               |
|  - Shared NAS for session recordings                                          |
|  - HAProxy + Keepalived for load balancing and VIP                           |
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
|  1. User -> HAProxy VIP (10.10.X.100:443)                                     |
|     - HTTPS connection established                                            |
|     - SSL termination at HAProxy (optional) or passthrough                    |
|                                                                               |
|  2. HAProxy -> Backend Selection                                               |
|     - Algorithm: roundrobin or leastconn                                      |
|     - Health check: GET /health (every 2s)                                    |
|     - Session persistence: cookie insertion (SERVERID)                        |
|                                                                               |
|  3. Request Distribution:                                                     |
|     - User A -> Node 1 (10.10.X.11)                                           |
|     - User B -> Node 2 (10.10.X.12)                                           |
|     - User C -> Node 1 (10.10.X.11)                                           |
|     - User D -> Node 2 (10.10.X.12)                                           |
|                                                                               |
|  4. Database Sync:                                                            |
|     - User A creates session on Node 1                                        |
|     - Database write replicated to Node 2 via bastion-replication             |
|     - Both nodes have consistent view (except excluded tables)                |
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
|  - HAProxy detects health check failure (< 6 seconds)                        |
|  - Node 1 removed from backend pool immediately                               |
|  - All new traffic directed to Node 2                                         |
|  - Existing sessions on Node 1: HTTP sessions continue (cookie-based)         |
|  - SSH/RDP sessions: may disconnect (protocol limitation)                     |
|                                                                               |
|  Database Impact:                                                             |
|  - bastion-replication detects peer down                                      |
|  - Node 2 continues serving independently                                     |
|  - Replication resumes automatically when Node 1 recovers                     |
|  - dump-resync may be needed if data diverged significantly                   |
|                                                                               |
+===============================================================================+
```

### 1.3 Comparison to Active-Passive

| Aspect | Active-Active (M/M) | Active-Passive (M/S) |
|--------|----------------------|----------------------|
| **Node Utilization** | 100% (both serving) | 50% (standby idle) |
| **Failover Time** | < 6 seconds (HAProxy detection) | 30-60 seconds |
| **Session Continuity** | Full (HTTP), Partial (SSH/RDP) | None (all disconnect) |
| **Configuration Complexity** | Medium (bastion-replication) | Low |
| **Database** | Master/Master (bastion-replication) | Master/Slave (bastion-replication) |
| **Approvals** | Replicated between both nodes | Replicated |
| **Password Changes** | Only on primary Master node | Only on Master |
| **Recommended Load** | > 100 concurrent sessions | < 100 concurrent sessions |

---

## Prerequisites & Planning

### 2.1 Hardware Requirements

#### WALLIX Bastion Hardware Appliances

| Specification | Requirement | Notes |
|---------------|-------------|-------|
| **Model** | WALLIX Bastion HW 1U/2U appliance | Vendor-supplied hardware |
| **CPU** | 8+ cores (16+ recommended) | Higher core count for 100+ sessions |
| **RAM** | 32 GB minimum (64 GB recommended) | Database + session handling |
| **Storage** | 500 GB SSD (RAID 1) | OS + database + local cache |
| **Network** | 2x 10GbE (bonded) | Primary + dedicated admin interface recommended |
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
| **WALLIX Bastion** | 12.1.x | PAM application (same version on both nodes) |
| **MariaDB** | Bundled with Bastion | Database (managed by bastion-replication) |
| **bastion-replication** | Bundled with Bastion | Master/Master replication tool |
| **autossh** | Bundled with Bastion | Persistent SSH tunnel for replication |
| **HAProxy** | 2.8+ | Load balancer (separate hosts) |
| **Keepalived** | 2.2+ | VIP management for HAProxy (separate hosts) |

**Installation Note**: WALLIX hardware appliances come with pre-installed OS and software. Verify versions:

```bash
# Check WALLIX Bastion version (must be identical on both nodes)
wabadmin version
systemctl status wallix-bastion
mariadb --version
```

### 2.3 Official Prerequisites for bastion-replication

The following requirements must be met before configuring Master/Master replication:

- [ ] Both nodes must be on the same subnet (or at most 1 router hop between them)
- [ ] Same WALLIX Bastion version installed on both nodes
- [ ] Encryption must be initialized on both nodes before setting up replication
- [ ] Same NTP source and timezone configured on both nodes
- [ ] IPv4 addresses only in HA configuration (no FQDN, no IPv6)
- [ ] Dedicated admin interface recommended per node
- [ ] No VM cloning to create the second node (install each node independently)

### 2.4 Network Requirements

#### IP Addressing (Per Site)

| Component | IP Address | Purpose |
|-----------|------------|---------|
| **HAProxy VIP** | 10.10.X.100 | User entry point |
| **HAProxy-1** | 10.10.X.5 | Load balancer primary |
| **HAProxy-2** | 10.10.X.6 | Load balancer backup |
| **Bastion Node 1** | 10.10.X.11 | Master node 1 |
| **Bastion Node 2** | 10.10.X.12 | Master node 2 |
| **NAS Storage** | 10.10.X.200 | Shared recordings |

#### Firewall Rules

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| HAProxy-1/2 | Bastion-1/2 | 443 | TCP | HTTPS backend health checks |
| HAProxy-1/2 | Bastion-1/2 | 22 | TCP | SSH proxy (if configured) |
| Bastion-1 | Bastion-2 | 2242 | TCP | SSH tunnel for replication (autossh) |
| Bastion-2 | Bastion-1 | 2242 | TCP | SSH tunnel for replication (autossh) |
| Bastion-1 | Bastion-2 | 3306 | TCP | MariaDB inbound via SSH tunnel |
| Bastion-2 | Bastion-1 | 3306 | TCP | MariaDB inbound via SSH tunnel |
| Bastion-1/2 | NAS Storage | 2049 | TCP | NFS |
| Bastion-1/2 | NAS Storage | 111 | TCP/UDP | RPC portmapper |

**Note on replication ports**: Each node opens an SSH tunnel on port 2242 to its peer. MariaDB replication flows through this tunnel: outbound source port 3307 on the initiating node is forwarded to inbound port 3306 on the destination node.

**CRITICAL**: Ensure port 2242/TCP is open bidirectionally between both Bastion nodes.

### 2.5 Pre-Deployment Checklist

- [ ] Hardware appliances racked, powered, and connected to network
- [ ] Network switch configured with VLANs (production, storage)
- [ ] Firewall rules created for replication communication (port 2242, 3306)
- [ ] NAS storage provisioned with NFS export or iSCSI LUN
- [ ] DNS records created for both nodes and VIP
- [ ] NTP servers configured and reachable (same source on both nodes)
- [ ] Same timezone set on both nodes
- [ ] HAProxy servers deployed and tested (see separate guide)
- [ ] Encryption initialized on both Bastion nodes
- [ ] Same WALLIX Bastion version on both nodes (12.1.x)
- [ ] Each node installed independently (no VM cloning)
- [ ] IPv4 addresses only (no FQDN/IPv6 in HA configuration)

---

## Initial Appliance Setup

### 3.1 Base OS Configuration

#### Set Hostname and Timezone

**Node 1:**
```bash
# Set hostname
hostnamectl set-hostname bastion1-site1.company.com

# Set timezone to UTC (must be identical on both nodes)
timedatectl set-timezone UTC

# Verify
hostnamectl status
timedatectl status
```

**Node 2:**
```bash
hostnamectl set-hostname bastion2-site1.company.com
timedatectl set-timezone UTC
```

#### Update /etc/hosts

**Both nodes:**
```bash
cat >> /etc/hosts <<'EOF'
# WALLIX Bastion Cluster
10.10.1.11    bastion1-site1.company.com bastion1
10.10.1.12    bastion2-site1.company.com bastion2
10.10.1.100   bastion-site1.company.com bastion-vip

# HAProxy
10.10.1.5     haproxy1-site1
10.10.1.6     haproxy2-site1
10.10.1.100   haproxy-vip

# NAS Storage
10.10.1.200   nas-site1
EOF
```

### 3.2 NTP Configuration

**CRITICAL**: Both nodes must use the same NTP source for replication to work correctly.

**On both nodes:**
```bash
# Verify NTP is synchronized
timedatectl status
# Expected: NTP synchronized: yes

# Check NTP source
chronyc sources -v
# or
ntpq -p

# If not configured, set NTP server
cat > /etc/chrony/chrony.conf <<'EOF'
server ntp.company.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
EOF

systemctl restart chronyd
```

### 3.3 Encryption Initialization

**CRITICAL**: Encryption must be initialized on BOTH nodes BEFORE setting up bastion-replication.

**On both nodes:**
```bash
# Initialize encryption (follow the WALLIX setup wizard)
# This is typically done during initial Bastion setup
# Verify encryption is initialized:
WABSecurityLevel
```

### 3.4 Storage Configuration

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

### 4.2 Network Validation

```bash
# Test connectivity between nodes
ping -c 5 10.10.1.12  # From Node 1
ping -c 5 10.10.1.11  # From Node 2

# Test SSH tunnel port (2242) between nodes
nc -zv 10.10.1.12 2242  # From Node 1
nc -zv 10.10.1.11 2242  # From Node 2

# Test NAS storage
ping -c 5 nas-site1

# Test gateway
ping -c 5 10.10.1.1

# Test HAProxy
ping -c 5 haproxy-vip
```

---

## bastion-replication Master/Master Configuration

### 5.1 Replication Architecture Overview

```
+===============================================================================+
|  bastion-replication MASTER/MASTER REPLICATION                               |
+===============================================================================+
|                                                                               |
|  Node 1 (10.10.1.11)                    Node 2 (10.10.1.12)                  |
|  +---------------------------+          +---------------------------+         |
|  | WALLIX Bastion            |          | WALLIX Bastion            |         |
|  | (Master)                  |          | (Master)                  |         |
|  |                           |          |                           |         |
|  | MariaDB :3306 <-----------+-- SSH ---+-- autossh :3307 (out)    |         |
|  |                           |  tunnel  |                           |         |
|  | autossh :3307 (out) ------+-- SSH ---+---------> MariaDB :3306  |         |
|  |                           |  tunnel  |                           |         |
|  | SSH tunnel on port 2242   |<-------->| SSH tunnel on port 2242   |         |
|  +---------------------------+          +---------------------------+         |
|                                                                               |
|  REPLICATION FLOW                                                             |
|  ================                                                             |
|  - Each node runs autossh to maintain a persistent SSH tunnel to peer        |
|  - SSH tunnel on port 2242 (WALLIX admin SSH port)                           |
|  - MariaDB outbound port 3307 tunneled to peer inbound port 3306            |
|  - Both nodes can accept reads and writes                                    |
|  - Approvals are replicated between nodes in M/M mode                        |
|                                                                               |
|  PORTS USED                                                                   |
|  ==========                                                                   |
|  - 2242: SSH tunnel for replication (autossh, bidirectional)                 |
|  - 3306: MariaDB local + inbound replication via tunnel                      |
|  - 3307: MariaDB outbound replication source port                            |
|                                                                               |
+===============================================================================+
```

### 5.2 Create Replication Configuration

**On Node 1 (first Master):**

```bash
# Generate the replication configuration file
# Select "Master/Master" when prompted for replication mode
bastion-replication --create-conf-file

# The wizard will ask for:
# - Replication mode: Master/Master
# - Peer IP address: 10.10.1.12
# - SSH port: 2242
#
# Configuration is saved to /var/wab/etc/ha.conf
```

**On Node 2 (second Master):**

```bash
# Generate the replication configuration file
# Select "Master/Master" when prompted for replication mode
bastion-replication --create-conf-file

# The wizard will ask for:
# - Replication mode: Master/Master
# - Peer IP address: 10.10.1.11
# - SSH port: 2242
#
# Configuration is saved to /var/wab/etc/ha.conf
```

### 5.3 Install Replication

**On Node 1 (first):**

```bash
# Install and start replication
bastion-replication --install

# This will:
# - Configure MariaDB for replication
# - Set up autossh tunnel to peer on port 2242
# - Configure outbound port 3307 -> peer inbound port 3306
# - Start the replication process
```

**On Node 2 (after Node 1 is complete):**

```bash
# Install and start replication
bastion-replication --install
```

### 5.4 Verify Replication Health

**On both nodes:**

```bash
# Check replication status using the official monitoring command
bastion-replication --monitoring

# Expected output should show:
# - Replication mode: Master/Master
# - Both nodes connected
# - Replication running: Yes
# - No errors
```

**Test replication:**

```bash
# On Node 1: Create a test user via wabadmin CLI
wabadmin user-add testuser --password 'Test_REDACTED' --email 'test@company.com'

# On Node 2: List users (should include testuser)
wabadmin user-list | grep testuser
# Expected: testuser present

# On Node 2: Delete test user
wabadmin user-delete testuser

# On Node 1: Verify user deleted
wabadmin user-list | grep testuser
# Expected: Empty (user deleted via replication)
```

### 5.5 Replication Monitoring Script

**Create monitoring script (for cron/alerting):**

```bash
cat > /usr/local/bin/check-replication-status.sh <<'EOF'
#!/bin/bash
# bastion-replication Health Check

echo "=== bastion-replication Status ==="
bastion-replication --monitoring

RETVAL=$?
if [ $RETVAL -ne 0 ]; then
  echo "WARNING: Replication is not healthy!"
  exit 1
fi

echo "Replication is healthy."
exit 0
EOF

chmod +x /usr/local/bin/check-replication-status.sh

# Test script
/usr/local/bin/check-replication-status.sh
```

---

## Replication Limitations & Exclusions

### 6.1 Official Limitations (bastion-replication Master/Master)

The following limitations apply to WALLIX Bastion 12.1.x Master/Master replication:

| Limitation | Details |
|------------|---------|
| **Audit tables** | NOT replicated between nodes |
| **SMTP configuration** | Must be configured individually on each node |
| **API provisioning** | Cannot run simultaneously on both nodes |
| **VM cloning** | Do NOT clone VMs to create HA nodes; install each independently |
| **Password changes** | Must be performed on the primary Master node only |
| **Password rotation crons** | NOT replicated; configure on primary Master only |
| **Approvals** | Replicated between both nodes in M/M mode |

### 6.2 Configuration Items NOT Replicated

The following configuration areas are excluded from replication and must be configured individually on each node:

- Audit
- Recording Options
- Configuration Options
- Connection Messages
- Audit Logs
- Network
- Time Service
- SNMP
- SMTP Server
- Service Control
- SIEM Integration
- GPG fingerprint
- Device certificates

**IMPORTANT**: After initial setup, configure these items individually on each node. Changes to these settings on one node will NOT propagate to the other.

### 6.3 Password Change Policy

```
+===============================================================================+
|  PASSWORD CHANGE WORKFLOW IN MASTER/MASTER MODE                              |
+===============================================================================+
|                                                                               |
|  CORRECT:                                                                     |
|  - Perform password changes on the primary Master node                       |
|  - Password rotation crons must be configured on primary Master only         |
|  - Changes replicate to the secondary Master node                            |
|                                                                               |
|  INCORRECT:                                                                   |
|  - Running password rotation crons on both nodes simultaneously              |
|  - Changing passwords on the secondary Master while primary is active        |
|                                                                               |
|  API PROVISIONING:                                                            |
|  - Do NOT run API provisioning on both nodes at the same time                |
|  - Designate one node as the API provisioning target                         |
|                                                                               |
+===============================================================================+
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
|  Node 1 <---SSH tunnel (2242)---> Node 2                                     |
|  (Master)                         (Master)                                    |
|  Replication: Running             Replication: Running                        |
|                                                                               |
|  NETWORK PARTITION (Split-Brain):                                            |
|  Node 1      X X X X X      Node 2                                           |
|  (No tunnel)                 (No tunnel)                                      |
|  Replication: Stopped        Replication: Stopped                             |
|                                                                               |
|  IMPACT:                                                                      |
|  - Both nodes continue accepting writes independently                        |
|  - Data diverges until connectivity is restored                              |
|  - When network heals, bastion-replication resumes                           |
|  - A dump-resync may be needed if data diverged significantly                |
|                                                                               |
|  MITIGATION:                                                                  |
|  - HAProxy health checks detect unresponsive nodes                           |
|  - Monitor replication status with bastion-replication --monitoring          |
|  - Alert on replication failure and investigate immediately                  |
|  - Perform dump-resync to restore consistency if needed                      |
|                                                                               |
+===============================================================================+
```

### 7.2 Monitoring for Split-Brain

```bash
# Regular monitoring (add to cron, run every minute)
cat > /usr/local/bin/check-split-brain.sh <<'EOF'
#!/bin/bash
# Check replication health and alert on potential split-brain

bastion-replication --monitoring > /tmp/replication-status.txt 2>&1
RETVAL=$?

if [ $RETVAL -ne 0 ]; then
  echo "ALERT: Replication may be broken - potential split-brain risk!"
  echo "Check output:"
  cat /tmp/replication-status.txt
  # Send alert (configure SMTP individually on each node)
  exit 1
fi

exit 0
EOF

chmod +x /usr/local/bin/check-split-brain.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/check-split-brain.sh") | crontab -
```

### 7.3 Recovery from Split-Brain (dump-resync)

If both nodes diverged during a network partition:

```bash
# Step 1: Identify which node has the most current/authoritative data
# Check last session timestamps, user modifications, etc.
bastion-replication --monitoring  # Run on both nodes

# Step 2: Stop replication on both nodes
bastion-replication --stop  # On Node 1
bastion-replication --stop  # On Node 2

# Step 3: Perform dump-resync from authoritative node to secondary
# On the authoritative (source) node:
bastion-replication --dump-resync

# Step 4: Restart replication
bastion-replication --start  # On both nodes

# Step 5: Verify replication is healthy
bastion-replication --monitoring
```

---

## WALLIX Bastion Configuration Sync

### 8.1 WALLIX Configuration Replication

**WALLIX Bastion automatically synchronizes configuration across cluster nodes via bastion-replication.**

Configuration replicated via database includes:
- Users, groups, and roles
- Devices and accounts
- Authorization policies
- Session recording settings
- Credential vault data (encrypted)
- Approvals (in M/M mode)

**Verify configuration sync:**

```bash
# On Node 1: Create a test user via wabadmin CLI
wabadmin user-add testuser --password 'Test_REDACTED' --email 'test@company.com'

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

**Encryption must be initialized on both nodes BEFORE setting up replication.**

**Verify encryption:**

```bash
# On both nodes: Check encryption/security level
WABSecurityLevel
```

### 8.3 Non-Replicated Configuration

**Remember to configure these items individually on EACH node** (see Section 6.2):

```bash
# On EACH node independently, configure:
# - SMTP server settings
# - SNMP configuration
# - SIEM integration
# - Network settings
# - Time service
# - Service control
# - Device certificates
# - GPG fingerprint
```

### 8.4 Session Recording Consistency

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
    stats auth admin:STATS_PASSWORD_REDACTED
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
# - bastion1 status changes to DOWN within 2-6 seconds
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

# Verify replication resumed
bastion-replication --monitoring
```

#### Scenario 2: Hard Node Failure (Power Loss)

**Simulate complete node failure.**

```bash
# Power off Node 1 (via management interface or physical)

# On HAProxy: Monitor backend
watch -n 1 'echo "show stat" | socat stdio /run/haproxy/admin.sock'

# Expected:
# - bastion1 marked DOWN within 6 seconds (3 failed health checks)
# - All traffic routed to bastion2

# On Node 2: Verify replication status
bastion-replication --monitoring
# Expected: Replication to peer stopped (peer unreachable)

# Power on Node 1 and wait for boot (~2 minutes)

# After Node 1 boots: Verify replication resumes
bastion-replication --monitoring  # On both nodes
# If data diverged, perform dump-resync (see Section 7.3)
```

#### Scenario 3: Network Partition

**Simulate network split between nodes.**

```bash
# On Node 2: Block replication traffic
iptables -A INPUT -s 10.10.1.11 -p tcp --dport 2242 -j DROP
iptables -A OUTPUT -d 10.10.1.11 -p tcp --dport 2242 -j DROP

# Expected behavior:
# - autossh tunnel breaks
# - bastion-replication detects peer unreachable
# - Both nodes continue serving traffic independently
# - HAProxy continues distributing to both (both still respond to health checks)
# - Data may diverge during partition

# Restore connectivity:
iptables -F

# Verify replication resumes:
bastion-replication --monitoring

# If needed, perform dump-resync:
# bastion-replication --dump-resync  (on authoritative node)
```

### 11.2 Failover Timing Measurements

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

# Expected downtime: < 6 seconds (Active-Active with fast health checks)
```

---

## Performance Tuning

### 12.1 Network Optimization

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

### 12.2 HAProxy Performance Tuning

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

### 12.3 Monitoring Performance Metrics

**Key metrics to monitor:**

| Metric | Command | Target |
|--------|---------|--------|
| **Replication Status** | `bastion-replication --monitoring` | Running, no errors |
| **Database Connections** | `mysql -e "SHOW STATUS LIKE 'Threads_connected';"` | < 80% of max_connections |
| **CPU Load** | `uptime` | < 70% average |
| **Memory Usage** | `free -h` | < 80% |
| **Disk I/O Wait** | `iostat -x 1` | < 10% |
| **Network Throughput** | `iftop -i bond0` | < 80% of link capacity |
| **HAProxy Queue** | `echo "show stat" \| socat - /run/haproxy/admin.sock` | qcur = 0 |

---

## Troubleshooting

### 13.1 Common Issues and Solutions

#### Issue 1: Replication Not Starting

**Symptoms:**
- `bastion-replication --monitoring` shows errors
- Nodes not synchronizing data

**Diagnosis:**

```bash
# Check replication status
bastion-replication --monitoring

# Check SSH tunnel connectivity
ss -tunap | grep 2242
ss -tunap | grep 3307
```

**Common Causes:**

1. **Firewall blocking replication port:**
   ```bash
   # Test connectivity
   nc -zv 10.10.1.12 2242  # From Node 1 to Node 2
   nc -zv 10.10.1.11 2242  # From Node 2 to Node 1

   # If fails, check firewall
   iptables -L -n | grep 2242
   ```

2. **Different WALLIX Bastion versions:**
   ```bash
   # Verify version on both nodes (must be identical)
   wabadmin version  # On Node 1
   wabadmin version  # On Node 2
   ```

3. **Encryption not initialized:**
   ```bash
   # Check encryption on both nodes
   WABSecurityLevel
   ```

4. **FQDN or IPv6 used in HA config:**
   ```bash
   # Verify ha.conf uses IPv4 only
   cat /var/wab/etc/ha.conf
   # Peer address must be an IPv4 address, NOT a hostname or IPv6
   ```

**Resolution:**

```bash
# Recreate configuration if needed
bastion-replication --create-conf-file

# Reinstall replication
bastion-replication --install

# Verify
bastion-replication --monitoring
```

#### Issue 2: Data Divergence After Network Partition

**Symptoms:**
- Different data on Node 1 and Node 2
- Users/devices present on one node but not the other

**Diagnosis:**

```bash
# Check replication status on both nodes
bastion-replication --monitoring
```

**Resolution (dump-resync):**

```bash
# Step 1: Determine which node has authoritative data
# (typically the node that was serving most traffic)

# Step 2: Stop replication on both nodes
bastion-replication --stop

# Step 3: From the authoritative node, resync
bastion-replication --dump-resync

# Step 4: Restart replication
bastion-replication --start

# Step 5: Verify
bastion-replication --monitoring
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
# Replication Status
bastion-replication --monitoring           # Official replication health check
bastion-replication --status               # Quick status

# WALLIX Bastion Status
systemctl status wallix-bastion
wabadmin status
wabadmin version

# SSH Tunnel Status
ss -tunap | grep 2242                      # SSH tunnel ports
ss -tunap | grep 3306                      # MariaDB ports
ss -tunap | grep 3307                      # Replication outbound ports

# Security
WABSecurityLevel                           # Check encryption/security level

# HAProxy Status
echo "show stat" | socat stdio /run/haproxy/admin.sock
echo "show info" | socat stdio /run/haproxy/admin.sock

# Network
ss -tunap | grep -E "2242|3306|3307"       # Replication ports
iftop -i bond0                             # Network traffic
```

### 13.3 Log File Locations

| Component | Log Path |
|-----------|----------|
| **WALLIX Bastion** | `/var/log/wallix/` |
| **MariaDB** | `/var/log/mysql/error.log` |
| **bastion-replication** | `/var/log/wallix/` (replication logs) |
| **autossh** | `/var/log/syslog` |
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

echo -e "\n1. Replication Status:"
bastion-replication --monitoring

echo -e "\n2. Active Sessions:"
wabadmin sessions-list --active | wc -l

echo -e "\n3. HAProxy Backend Status:"
ssh haproxy1 'echo "show stat" | socat stdio /run/haproxy/admin.sock | grep bastion'

echo -e "\n4. Disk Usage (Recordings):"
df -h | grep recorded

echo -e "\n5. System Load:"
uptime

echo -e "\n6. Security Level:"
WABSecurityLevel

echo "=== Health Check Complete ==="
```

### 14.2 Maintenance Procedures

#### Procedure 1: Upgrading WALLIX Bastion (Official Method)

**Upload ISO via SCP:**

```bash
# Upload the upgrade ISO to each node via SCP on port 2242
# Use the wabupgrade account
scp -P 2242 wallix-bastion-12.x.x.iso wabupgrade@10.10.1.11:/home/wabupgrade/
scp -P 2242 wallix-bastion-12.x.x.iso wabupgrade@10.10.1.12:/home/wabupgrade/
scp -P 2242 wallix-bastion-12.x.x.sha256sum wabupgrade@10.10.1.11:/home/wabupgrade/
scp -P 2242 wallix-bastion-12.x.x.sha256sum wabupgrade@10.10.1.12:/home/wabupgrade/
scp -P 2242 wallix-bastion-12.x.x.sha256sum.sig wabupgrade@10.10.1.11:/home/wabupgrade/
scp -P 2242 wallix-bastion-12.x.x.sha256sum.sig wabupgrade@10.10.1.12:/home/wabupgrade/
```

**HA Upgrade Procedure:**

```bash
# Step 1: Stop replication on BOTH nodes
bastion-replication --stop  # On Node 1
bastion-replication --stop  # On Node 2

# Step 2: Upgrade all nodes (can be done in parallel)
# On Node 1:
BastionSecureUpgrade -i /home/wabupgrade/wallix-bastion-12.x.x.iso \
  -c /home/wabupgrade/wallix-bastion-12.x.x.sha256sum \
  -s /home/wabupgrade/wallix-bastion-12.x.x.sha256sum.sig

# On Node 2 (can run simultaneously):
BastionSecureUpgrade -i /home/wabupgrade/wallix-bastion-12.x.x.iso \
  -c /home/wabupgrade/wallix-bastion-12.x.x.sha256sum \
  -s /home/wabupgrade/wallix-bastion-12.x.x.sha256sum.sig

# Step 3: Reboot both nodes
reboot  # On Node 1
reboot  # On Node 2

# Step 4: After reboot, perform dump-resync from primary node
bastion-replication --dump-resync  # On the authoritative node

# Step 5: Start replication on both nodes
bastion-replication --start  # On Node 1
bastion-replication --start  # On Node 2

# Step 6: Verify replication is healthy
bastion-replication --monitoring  # On both nodes

# Step 7: Post-upgrade security check
WABSecurityLevel  # On both nodes
```

#### Procedure 2: Emergency Cluster Shutdown

```bash
# Step 1: Stop HAProxy (prevent new connections)
ssh haproxy1 'systemctl stop haproxy'
ssh haproxy2 'systemctl stop haproxy'

# Step 2: Wait for active sessions to close (or force-close)
wabadmin sessions-list --active
# If urgent: wabadmin sessions-close-all

# Step 3: Stop replication
bastion-replication --stop  # On both nodes

# Step 4: Stop WALLIX services
systemctl stop wallix-bastion  # On both nodes
```

#### Procedure 3: Emergency Cluster Startup

```bash
# Step 1: Start WALLIX services on both nodes
systemctl start wallix-bastion  # Node 1
systemctl start wallix-bastion  # Node 2

# Step 2: Start replication
bastion-replication --start  # Node 1
bastion-replication --start  # Node 2

# Step 3: Verify replication health
bastion-replication --monitoring

# Step 4: Start HAProxy
ssh haproxy1 'systemctl start haproxy'
ssh haproxy2 'systemctl start haproxy'

# Step 5: Test user access
curl -k https://10.10.1.100/health
```

---

## Summary and Next Steps

### Deployment Checklist

- [ ] Hardware appliances configured and connected to network
- [ ] Network interfaces bonded (optional but recommended)
- [ ] Same WALLIX Bastion version on both nodes (12.1.x)
- [ ] Encryption initialized on both nodes
- [ ] Same NTP source and timezone on both nodes
- [ ] IPv4 only in HA configuration (no FQDN/IPv6)
- [ ] Shared NFS storage mounted on both nodes
- [ ] bastion-replication configured in Master/Master mode
- [ ] bastion-replication installed and running on both nodes
- [ ] Replication verified with `bastion-replication --monitoring`
- [ ] Non-replicated settings configured individually on each node (SMTP, SNMP, SIEM, etc.)
- [ ] Password rotation crons configured on primary Master only
- [ ] HAProxy load balancer configured with both backends
- [ ] Keepalived VIP configured on HAProxy pair
- [ ] Health checks passing on both nodes
- [ ] Traffic distribution verified (50/50 split)
- [ ] Failover tested (Node 1 down, Node 2 serves all traffic)
- [ ] dump-resync procedure tested
- [ ] Monitoring scripts deployed
- [ ] Operational runbooks documented

### Next Steps

1. **Integrate with Access Manager:** Configure SSO and session brokering
   - See: [15-access-manager-integration.md](15-access-manager-integration.md)

2. **Configure RADIUS MFA (FortiAuthenticator):** Use per-site FortiAuth HA pair (Cyber VLAN)
   - Primary RADIUS server: 10.10.X.50 (FortiAuth-1)
   - Secondary RADIUS server: 10.10.X.51 (FortiAuth-2)
   - See: [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md)

3. **Configure LDAP/AD:** Connect to per-site Active Directory (Cyber VLAN)
   - AD DC: 10.10.X.60
   - See: [04-ad-per-site.md](04-ad-per-site.md)

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
- WALLIX Bastion Deployment Guide: https://pam.wallix.one/documentation/deployment-guide/

---

**Document Version**: 2.0
**Last Updated**: 2026-03-23
**Tested on**: WALLIX Bastion 12.1.x HW appliances
**Validation Status**: Production-ready
