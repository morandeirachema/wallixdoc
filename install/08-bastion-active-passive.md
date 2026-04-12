# Active-Passive WALLIX Bastion Hardware Appliance Cluster

> Step-by-step deployment guide for Master/Slave high availability configuration using `bastion-replication` on WALLIX Bastion 12.3.2

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Master/Slave cluster deployment for WALLIX Bastion HW appliances |
| **Configuration** | 2 appliances per site: 1 Master + 1 Slave |
| **Failover Method** | Manual promotion via `bastion-replication --elevate-master` |
| **Complexity** | Medium (simpler than Active-Active) |
| **Best For** | Sites with < 100 concurrent sessions, simplicity priority |
| **Version** | WALLIX Bastion 12.1.x |
| **Prerequisites** | [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md), [04-ad-per-site.md](04-ad-per-site.md) |
| **Last Updated** | April 2026 |

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Initial Appliance Setup](#initial-appliance-setup)
4. [Network Configuration](#network-configuration)
5. [Bastion-Replication Setup](#bastion-replication-setup)
6. [WALLIX Bastion Configuration](#wallix-bastion-configuration)
7. [Slave Node Synchronization](#slave-node-synchronization)
8. [Failover Testing](#failover-testing)
9. [Failback Procedures](#failback-procedures)
10. [Slave Management](#slave-management)
11. [Upgrade Procedure](#upgrade-procedure)
12. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### 1.1 Master/Slave Cluster Design

```
+===============================================================================+
|  MASTER/SLAVE WALLIX BASTION CLUSTER ARCHITECTURE                             |
+===============================================================================+
|                                                                               |
|                         +--------------------------+                          |
|                         |  Virtual IP (Floating)   |                          |
|                         |  Managed by Keepalived   |                          |
|                         |  (external to Bastion)   |                          |
|                         |  VIP: 10.10.X.10         |                          |
|                         +-----------+--------------+                          |
|                                     |                                         |
|                    +----------------+                                         |
|                    |                                                          |
|                    v                                                          |
|  +--------------------------------+                                           |
|  |  WALLIX BASTION NODE 1         |                                           |
|  |  (MASTER)                      |                                           |
|  |                                |                                           |
|  |  IP: 10.10.X.11                |          +-------------------------------+|
|  |  Load: 100% traffic            |          |  WALLIX BASTION NODE 2        ||
|  |                                |          |  (SLAVE)                      ||
|  |  +---------------------------+ |          |                               ||
|  |  | WALLIX Bastion            | |          |  IP: 10.10.X.12               ||
|  |  | Services (Running)        | |          |  Load: 0% (idle)              ||
|  |  |                           | |          |                               ||
|  |  | - Session Manager         | |          |  +---------------------------+||
|  |  | - Password Manager        | |          |  | WALLIX Bastion            |||
|  |  | - Web UI                  | |          |  | Services (Read-only)      |||
|  |  | - API Server              | |          |  |                           |||
|  |  +---------------------------+ |          |  | - Web UI (read-only)      |||
|  |                                |          |  | - API (read-only)         |||
|  |  +---------------------------+ |          |  +---------------------------+||
|  |  | MariaDB (Master)          | |          |                               ||
|  |  |                           | |          |  +---------------------------+||
|  |  | Replication via SSH ------+-+--------->|  | MariaDB (Slave)           |||
|  |  | tunnel (autossh)          | |          |  | Read-only replica         |||
|  |  | Port 2242 (SSH)           | |          |  |                           |||
|  |  | Port 3306 (MariaDB dest)  | |          |  | Outbound 3307 -> 3306     |||
|  |  +---------------------------+ |          |  | via SSH tunnel on 2242    |||
|  |                                |          |  +---------------------------+||
|  +--------------------------------+          |                               ||
|                    |                         +-------------------------------+|
|                    |                                         |                |
|                    +----------------+------------------------+                |
|                                     |                                         |
|                         +-----------+--------------+                          |
|                         |  Shared Storage (NAS)    |                          |
|                         |  Session Recordings      |                          |
|                         |  /var/wab/recorded       |                          |
|                         |  NFS/iSCSI Mount         |                          |
|                         +--------------------------+                          |
|                                                                               |
|  REPLICATION (Managed by bastion-replication + autossh)                       |
|  =============================================================               |
|  Slave initiates SSH tunnel: outbound 3307 -> Master 3306 via SSH 2242       |
|  All configuration changes replicated from Master to Slave automatically     |
|  Managed entirely by bastion-replication tool (no manual MariaDB config)     |
|                                                                               |
|  FAILOVER PROCESS (Manual promotion)                                         |
|  ====================================                                        |
|    1. Detect Master failure (monitoring / manual check)                      |
|    2. Run: bastion-replication --elevate-master (on Slave)                   |
|    3. Slave promoted to new Master                                           |
|    4. Update HAProxy/Keepalived to point to new Master                       |
|    5. New Master ready to accept connections                                 |
|                                                                               |
+===============================================================================+
```

### 1.2 Key Characteristics

| Aspect | Details |
|--------|---------|
| **Master Node** | Handles 100% of traffic, all services running, all changes made here |
| **Slave Node** | Read-only replica, configuration replicated from Master |
| **Replication** | `bastion-replication` tool with autossh tunnel (SSH 2242, MariaDB 3306/3307) |
| **Failover Trigger** | Manual: `bastion-replication --elevate-master` on Slave node |
| **Session Impact** | Active sessions disconnected, users must reconnect |
| **Data Loss Risk** | Minimal (async replication with low lag) |

### 1.3 Official Limitations (WALLIX Bastion 12.3.2)

**CRITICAL**: These limitations apply to Master/Slave mode:

| Limitation | Details |
|------------|---------|
| **Audit tables** | NOT replicated between nodes |
| **SMTP configuration** | Must be configured individually on each node |
| **Password changes** | Must be performed ONLY on Master; rotation crons not replicated |
| **Password at check-in** | "Change password at check-in" NOT supported in Master/Slave mode |
| **Approvals** | Must be requested AND validated only on Master |
| **VM cloning** | NOT supported; never clone a Bastion node |
| **Changes on Slave** | All changes MUST be made on Master; changes on Slave WILL break replication |

### 1.4 Replication Exclusions

The following items are **NOT replicated** and must be configured individually on each node:

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

### 1.5 When to Use Master/Slave

**Recommended for:**
- Sites with < 100 concurrent sessions
- Single-node capacity sufficient for peak load
- Simplicity and ease of management priority
- 30-60 second failover window acceptable (manual promotion)

**Not recommended for:**
- Sites with > 100 concurrent sessions (use Active-Active)
- Requirement for automatic sub-second failover
- Zero-downtime maintenance windows

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
| Node 1 Primary IP | 10.10.X.11/24 | Production interface (Master) |
| Node 2 Primary IP | 10.10.X.12/24 | Production interface (Slave) |
| Virtual IP (VIP) | 10.10.X.10/24 | User-facing floating IP (managed by HAProxy/Keepalived) |
| Default Gateway | 10.10.X.1 | Fortigate firewall |

### 2.3 Official Prerequisites (WALLIX Bastion 12.3.2)

The following requirements MUST be met before configuring `bastion-replication`:

- [ ] All nodes on the same subnet (or maximum 1 router between them)
- [ ] Same WALLIX Bastion version installed on all nodes
- [ ] Encryption initialized on all nodes
- [ ] Same NTP source and timezone configured on all nodes
- [ ] IPv4 only (no FQDN or IPv6 in HA configuration)
- [ ] Dedicated admin interface recommended per node

### 2.4 Software Requirements

#### Operating System (Pre-installed on Appliances)

WALLIX Bastion appliances come with Debian 12 (Bookworm) pre-installed and hardened.

**NOTE**: Most configuration is done via `wabadmin` CLI and Web UI, not direct OS access.

### 2.5 Access Requirements

| Service | Credentials | Purpose |
|---------|-------------|---------|
| **WALLIX admin account** | admin / PASSWORD_REDACTED | Web UI and CLI access |
| **NFS/iSCSI** | mount credentials | Shared storage access |
| **Firewall rules** | Pre-configured | See [01-network-design.md](01-network-design.md) |

### 2.6 Prerequisites Checklist

- [ ] 2x WALLIX Bastion HW appliances racked and powered on
- [ ] Same WALLIX Bastion 12.3.2 version on both nodes
- [ ] Encryption initialized on both nodes
- [ ] Production network configured (VLAN X, IPs .11, .12, .10 reserved)
- [ ] All nodes on same subnet (or max 1 router hop)
- [ ] Shared NFS/iSCSI storage mounted on both nodes at `/var/wab/recorded`
- [ ] DNS A records created: bastion-node1, bastion-node2, bastion-vip
- [ ] Firewall rules configured (see [01-network-design.md](01-network-design.md))
- [ ] NTP servers reachable from both nodes (same source, same timezone)
- [ ] IPv4 addresses only (no FQDN/IPv6 in HA config)
- [ ] FortiAuthenticator RADIUS VIP accessible (10.10.X.52, Cyber VLAN, inter-VLAN via Fortigate)
- [ ] Active Directory LDAPS accessible (10.10.X.60:636, Cyber VLAN, inter-VLAN via Fortigate)
- [ ] HAProxy load balancer configured to point to VIP (10.10.X.10)

---

## Initial Appliance Setup

### 3.1 Node 1 (Master) Initial Configuration

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

# Set hostname
wabadmin hostname-set bastion-node1.company.com

# Configure DNS servers (use per-site AD DC in Cyber VLAN)
wabadmin dns-set --primary 10.10.X.60 --secondary 8.8.8.8

# Verify configuration
wabadmin network-status
```

Expected output:
```
Interface: bond0
  IP: 10.10.X.11/24
  Gateway: 10.10.X.1
  Status: UP

Hostname: bastion-node1.company.com
DNS: 10.10.X.60
```

#### 3.1.3 Configure NTP

```bash
# Configure NTP servers (use organizational NTP or public pool)
wabadmin ntp-set --servers ntp1.company.com,ntp2.company.com

# Force time sync
wabadmin ntp-sync

# Verify NTP status
wabadmin ntp-status
```

Expected output:
```
NTP Status: Synchronized
Reference ID: ntp1.company.com
Stratum: 3
Offset: -0.003 seconds
```

#### 3.1.4 Initialize Encryption

```bash
# Encryption MUST be initialized before configuring replication
wabadmin encryption-init

# Verify encryption status
wabadmin encryption-status
# Expected: Encryption initialized
```

#### 3.1.5 Mount Shared Storage

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

### 3.2 Node 2 (Slave) Initial Configuration

Repeat the same steps as Node 1 with the following changes:

```bash
# Network configuration
wabadmin network-config --interface bond0 --ip 10.10.X.12/24 --gateway 10.10.X.1

# Hostname
wabadmin hostname-set bastion-node2.company.com

# Initialize encryption (MUST be done on each node)
wabadmin encryption-init

# NTP, DNS, and storage configuration identical to Node 1
```

### 3.3 Verify Connectivity Between Nodes

```bash
# From Node 1 (10.10.X.11)
ping -c 4 10.10.X.12
# Expected: 4 packets transmitted, 4 received, 0% packet loss

# From Node 2 (10.10.X.12)
ping -c 4 10.10.X.11
# Expected: 4 packets transmitted, 4 received, 0% packet loss
```

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

| Parameter | bond0 (Production) |
|-----------|-------------------|
| **Mode** | active-backup (1) |
| **Primary Slave** | eth0 |
| **MII Monitoring** | 100ms |
| **Fail Over MAC** | active |

### 4.2 Firewall Rules (Bastion-Replication Communication)

Ensure the following ports are open between Node 1 (Master) and Node 2 (Slave):

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Node 2 (10.10.X.12) | Node 1 (10.10.X.11) | 2242 | TCP | SSH tunnel (autossh) |
| Node 2 (10.10.X.12) | Node 1 (10.10.X.11) | 3306 | TCP | MariaDB inbound (destination through tunnel) |
| Node 2 (10.10.X.12) | Local | 3307 | TCP | MariaDB outbound (source port on Slave) |

**NOTE**: The Slave initiates an SSH tunnel on port 2242 to the Master. MariaDB replication traffic flows through this tunnel: Slave outbound port 3307 maps to Master inbound port 3306.

```bash
# Verify firewall allows replication traffic (from Node 2 / Slave)
nc -zv 10.10.X.11 2242
nc -zv 10.10.X.11 3306
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

## Bastion-Replication Setup

### 5.1 Architecture: Master/Slave Replication via SSH Tunnel

```
+===============================================================================+
|  BASTION-REPLICATION TOPOLOGY                                                 |
+===============================================================================+
|                                                                               |
|  Node 1 (Master)                       Node 2 (Slave)                         |
|  +---------------------------+          +---------------------------+          |
|  | WALLIX Bastion 12.3.2     |          | WALLIX Bastion 12.3.2     |          |
|  |                           |          |                           |          |
|  | MariaDB (Read-Write)      |          | MariaDB (Read-Only)       |          |
|  | Port 3306 (listens)       |          | Port 3307 (outbound src)  |          |
|  | SSH on port 2242          |          | autossh tunnel to Master  |          |
|  |                           |  SSH     |                           |          |
|  |                           | <--------|  Slave connects via       |          |
|  |                           |  2242    |  autossh to Master:2242   |          |
|  |                           |          |  tunnel: 3307 -> 3306     |          |
|  +---------------------------+          +---------------------------+          |
|                                                                               |
|  REPLICATION FLOW (managed by bastion-replication)                            |
|  ==================================================                           |
|  1. bastion-replication --create-conf-file (select Master/Slave roles)        |
|  2. bastion-replication --install (initializes replication)                   |
|  3. Slave opens SSH tunnel (autossh) to Master on port 2242                  |
|  4. MariaDB replication flows through tunnel (3307 -> 3306)                  |
|  5. Configuration changes on Master replicated to Slave automatically        |
|                                                                               |
+===============================================================================+
```

### 5.2 Generate Replication Configuration

Run on **both** nodes:

```bash
# SSH to each node and generate the replication configuration file
ssh admin@10.10.X.11

# On Node 1 (Master):
bastion-replication --create-conf-file
# Select role: Master
# Enter the local IP address: 10.10.X.11
# Enter peer IP address: 10.10.X.12
```

```bash
# On Node 2 (Slave):
ssh admin@10.10.X.12

bastion-replication --create-conf-file
# Select role: Slave
# Enter the local IP address: 10.10.X.12
# Enter Master IP address: 10.10.X.11
```

### 5.3 Install Replication

Run on **both** nodes (Master first, then Slave):

```bash
# On Node 1 (Master) first:
bastion-replication --install
```

```bash
# Then on Node 2 (Slave):
bastion-replication --install
```

**NOTE**: The `--install` command handles all MariaDB configuration internally. Do NOT manually edit MariaDB configuration files or run manual replication SQL commands.

### 5.4 Verify Replication Status

```bash
# On either node, check replication monitoring
bastion-replication --monitoring
```

Expected output should show:
- Master node identified and reachable
- Slave node connected and replicating
- No replication errors
- Low replication lag

### 5.5 Install Monitoring and Notifications

```bash
# Install monitoring checks for replication health
bastion-replication --install-monitoring

# Install notification alerts for replication failures
bastion-replication --install-notification
```

---

## WALLIX Bastion Configuration

### 6.1 Configure Node 1 (Master) as Active

#### 6.1.1 Initial WALLIX Bastion Setup

```bash
# Access Web UI on the Master node
https://10.10.X.11

# Initial wizard (first-time setup):
# - Set admin password
# - Upload license file
# - Configure hostname: bastion-node1.company.com
# - Configure email/SMTP for alerts
```

**IMPORTANT**: SMTP must be configured individually on each node (not replicated).

#### 6.1.2 Verify Replication Status

```bash
# Via CLI on Master
bastion-replication --monitoring

# Expected: Master active, Slave connected, replication healthy
```

### 6.2 Configure Authentication (FortiAuthenticator + AD)

**IMPORTANT**: Configure authentication on the Master node only. Settings will replicate to Slave automatically.

#### 6.2.1 RADIUS Configuration (MFA)

```bash
# Web UI: Configuration > Authentication > RADIUS

# Add FortiAuthenticator primary (Cyber VLAN)
RADIUS Server 1:
  IP: 10.10.X.50  # FortiAuth-1 (site-specific, replace X with site number)
  Port: 1812
  Shared Secret: RADIUS_SECRET_REDACTED
  Timeout: 5 seconds

# Add FortiAuthenticator secondary (Cyber VLAN)
RADIUS Server 2:
  IP: 10.10.X.51  # FortiAuth-2 (site-specific, replace X with site number)
  Port: 1812
  Shared Secret: RADIUS_SECRET_REDACTED
  Timeout: 5 seconds
```

#### 6.2.2 LDAP Configuration (User Directory)

```bash
# Web UI: Configuration > Authentication > LDAP

# Add Active Directory (Cyber VLAN)
LDAP Server:
  Hostname: 10.10.X.60  # AD DC (site-specific, replace X with site number)
  Port: 636 (LDAPS)
  Base DN: dc=company,dc=local
  Bind DN: cn=wallixsvc,ou=Service Accounts,dc=company,dc=local
  Bind Password: LDAP_BIND_PASSWORD_REDACTED
  User Filter: (&(objectClass=user)(sAMAccountName={0}))
  Group Filter: (member={0})
```

### 6.3 Configure Session Recording Storage

```bash
# Verify shared NFS mount
df -h | grep recorded

# Configure recording storage in Web UI (on Master)
# Configuration > Recordings > Storage
Recording Path: /var/wab/recorded
Format: MP4 (H.264)
Encryption: AES-256-GCM
Retention: 90 days
```

### 6.4 Configure Non-Replicated Items on Each Node

The following must be configured **individually on each node** (Master AND Slave):

```bash
# On EACH node, configure:
# - SMTP Server (Configuration > SMTP)
# - SNMP settings
# - SIEM Integration
# - Network settings
# - Time Service
# - Service Control
# - Connection Messages
# - Recording Options
# - Configuration Options
```

---

## Slave Node Synchronization

### 7.1 Verify Configuration Sync

After `bastion-replication --install` completes, the Slave should have replicated configuration from the Master.

```bash
# On Slave (Node 2), verify replication is active
bastion-replication --monitoring
```

### 7.2 Encryption Key Synchronization

CRITICAL: Encryption keys must be identical on both nodes. This should be handled during the `bastion-replication --install` process, but verify:

```bash
# On Node 1 (Master), export encryption keys
wabadmin keys-export --output /tmp/wallix-keys.tar.gz.enc

# Copy to Node 2
scp /tmp/wallix-keys.tar.gz.enc admin@10.10.X.12:/tmp/

# On Node 2, import encryption keys
wabadmin keys-import --input /tmp/wallix-keys.tar.gz.enc

# Verify keys match
wabadmin keys-verify --peer 10.10.X.11
# Expected: Keys verified, checksum match
```

### 7.3 License Synchronization

```bash
# License is stored in database and replicated automatically
# Verify on Node 2
wabadmin license-info

# Expected: Same license details as Node 1
```

---

## Failover Testing

### 8.1 Pre-Failover Baseline

#### 8.1.1 Verify Cluster Healthy

```bash
# On Master (Node 1), check replication status
bastion-replication --monitoring

# Expected: Master active, Slave connected, replication healthy, low lag
```

### 8.2 Simulate Master Failure and Promote Slave

#### 8.2.1 Simulate Master Failure

```bash
# On Node 1 (Master), simulate failure by stopping services
# WARNING: This will disconnect active sessions!

# Option 1: Shut down the Master node
sudo shutdown -h now

# Option 2: Bring down production interface (simulates network failure)
sudo ip link set bond0 down
```

#### 8.2.2 Promote Slave to Master

```bash
# On Node 2 (Slave), elevate to Master
bastion-replication --elevate-master

# This command:
# 1. Stops replication from old Master
# 2. Promotes Slave MariaDB to read-write
# 3. Reconfigures Node 2 as the new Master
```

#### 8.2.3 Update External Load Balancer

After promoting the Slave, update HAProxy/Keepalived to direct traffic to the new Master (Node 2):

```bash
# Update HAProxy backend to point to Node 2 (10.10.X.12)
# Or trigger Keepalived failover if configured for health-check-based switching
```

#### 8.2.4 Verify Failover Success

```bash
# From external machine, test VIP connectivity
ping -c 4 10.10.X.10
# Expected: Replies (VIP now directed to Node 2)

# Test Web UI
curl -k https://10.10.X.10/health
# Expected: HTTP 200 OK

# On Node 2, verify it is now Master
bastion-replication --monitoring
# Expected: Node 2 is Master
```

### 8.3 Manual Failover Test (Controlled)

```bash
# For a controlled failover without simulating failure:

# 1. On Node 2 (Slave), promote to Master
bastion-replication --elevate-master

# 2. Update HAProxy/Keepalived to point to Node 2

# 3. Verify Node 2 is accepting connections
curl -k https://10.10.X.12/health
```

---

## Failback Procedures

### 9.1 When to Failback

Failback is the process of returning to the original Master node (Node 1) after a failure event.

**Recommended approach**: Manual failback during maintenance window.

**Reasons**:
- Verify Node 1 is fully recovered
- Minimize risk of repeated failovers
- Controlled timing (low-traffic period)

### 9.2 Reconfigure Node 1 as Slave

After the original Master (Node 1) is recovered:

```bash
# On Node 1, reconfigure as Slave
bastion-replication --create-conf-file
# Select role: Slave
# Enter Master IP: 10.10.X.12 (current Master = Node 2)

bastion-replication --install
```

### 9.3 Resync Node 1

```bash
# If replication is broken or data is out of sync, resync from current Master:

# Option 1: Full dump and resync (recommended after extended outage)
bastion-replication --dump-resync

# Option 2: Resync without full dump (if replication just needs restart)
bastion-replication --resync
```

### 9.4 Promote Node 1 Back to Master

Once Node 1 is fully synchronized as a Slave:

#### 9.4.1 Announce Maintenance Window

```
Maintenance Window: 30 minutes
Expected Outage: 1-5 minutes (during promotion and VIP migration)
Impacted Services: Active WALLIX sessions (users must reconnect)
```

#### 9.4.2 Execute Failback

```bash
# On Node 1, promote back to Master
bastion-replication --elevate-master

# Update HAProxy/Keepalived to point back to Node 1 (10.10.X.11)
```

#### 9.4.3 Reconfigure Node 2 as Slave

```bash
# On Node 2, reconfigure as Slave
bastion-replication --create-conf-file
# Select role: Slave
# Enter Master IP: 10.10.X.11

bastion-replication --install
```

#### 9.4.4 Verify Services

```bash
# Test VIP connectivity
ping -c 4 10.10.X.10

# Test Web UI
curl -k https://10.10.X.10/health

# Test SSH session
ssh user@10.10.X.10

# Verify replication
bastion-replication --monitoring
# Expected: Node 1 is Master, Node 2 is Slave, replication healthy
```

---

## Slave Management

### 10.1 Add a New Slave

```bash
# On the new Slave node, generate configuration
bastion-replication --create-conf-file
# Select role: Slave
# Enter Master IP

# Install replication
bastion-replication --install

# On the Master, add the new Slave
bastion-replication --add-slave
# Enter new Slave IP address
```

### 10.2 Elevate Slave to Master

```bash
# On the Slave node to be promoted
bastion-replication --elevate-master

# Update HAProxy/Keepalived to point to new Master
```

### 10.3 Resync a Slave

```bash
# Full dump and resync (use after extended outage or data divergence)
bastion-replication --dump-resync

# Quick resync (use when replication just stopped temporarily)
bastion-replication --resync
```

### 10.4 Monitor Replication

```bash
# Check replication status
bastion-replication --monitoring

# Install automated monitoring
bastion-replication --install-monitoring

# Install automated notifications
bastion-replication --install-notification
```

---

## Upgrade Procedure

### 11.1 HA Upgrade Process (WALLIX Bastion)

**CRITICAL**: Follow this order strictly to avoid breaking replication.

#### 11.1.1 Preparation

```bash
# 1. Download the ISO, SHA256 checksum, and signature files
# 2. Transfer files to all nodes

# Verify ISO integrity on each node
sha256sum -c wallix-bastion-12.x.x.sha256sum
```

#### 11.1.2 Stop Replication

```bash
# On the Master node, stop replication before upgrading
# Verify replication is fully caught up first
bastion-replication --monitoring
```

#### 11.1.3 Upgrade Slaves First

```bash
# On each Slave node (Node 2 first):
BastionSecureUpgrade -i /path/to/wallix-bastion.iso -c /path/to/sha256sum -s /path/to/sha256sum.sig

# Reboot after upgrade
sudo reboot
```

#### 11.1.4 Upgrade Master

```bash
# On the Master node (Node 1):
BastionSecureUpgrade -i /path/to/wallix-bastion.iso -c /path/to/sha256sum -s /path/to/sha256sum.sig

# Reboot after upgrade
sudo reboot
```

#### 11.1.5 Resync and Restart Replication

```bash
# After all nodes are upgraded and rebooted, resync
bastion-replication --dump-resync

# Start replication
bastion-replication --install

# Verify replication is healthy
bastion-replication --monitoring
```

---

## Troubleshooting

### 12.1 Common Issues and Solutions

#### Issue 1: Replication Stopped

**Symptoms:**
```bash
bastion-replication --monitoring
# Shows replication not running or errors
```

**Diagnosis:**
```bash
# Check network connectivity to Master
ping -c 4 10.10.X.11
nc -zv 10.10.X.11 2242
nc -zv 10.10.X.11 3306

# Check autossh tunnel status
ps aux | grep autossh
```

**Resolution:**
```bash
# Option 1: Resync replication (quick)
bastion-replication --resync

# Option 2: Full dump and resync (after extended outage)
bastion-replication --dump-resync
```

#### Issue 2: SSH Tunnel Not Establishing

**Symptoms:**
- Replication not working
- autossh process not running or restarting repeatedly

**Diagnosis:**
```bash
# On the Slave, check SSH connectivity to Master on port 2242
ssh -p 2242 admin@10.10.X.11

# Check autossh process
ps aux | grep autossh

# Check firewall allows port 2242
nc -zv 10.10.X.11 2242
```

**Resolution:**
```bash
# Verify firewall rules allow TCP 2242 between nodes
# Restart replication
bastion-replication --resync
```

#### Issue 3: Changes Made on Slave (Replication Broken)

**Symptoms:**
- Replication errors after making configuration changes on Slave
- Data divergence between Master and Slave

**Resolution:**
```bash
# CRITICAL: All changes must be made on Master ONLY
# To recover, perform a full resync from Master

# On the Slave:
bastion-replication --dump-resync

# This will overwrite Slave data with Master data
```

**Prevention:**
- NEVER make configuration changes on a Slave node
- All changes MUST be performed on the Master

#### Issue 4: VIP Not Responding (ARP Cache Issue)

**Symptoms:**
- HAProxy/Keepalived shows VIP assigned, but ping fails
- Node is reachable on its own IP but not on VIP

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
```

### 12.2 Diagnostic Commands

#### Replication Health

```bash
# Overall replication status
bastion-replication --monitoring

# Check autossh tunnel
ps aux | grep autossh

# Check SSH connectivity on replication port
nc -zv 10.10.X.11 2242
nc -zv 10.10.X.11 3306
```

#### Network Connectivity

```bash
# Test replication SSH tunnel port
nc -zv 10.10.X.11 2242

# Test MariaDB port (through tunnel)
nc -zv 10.10.X.11 3306
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
```

---

## Backup and Recovery

### 12.3 Backup Procedures

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
- [07-bastion-active-active.md](07-bastion-active-active.md) - Active-Active cluster setup (alternative)
- [01-network-design.md](01-network-design.md) - Network topology and port requirements
- [11-high-availability](../docs/pam/11-high-availability/README.md) - Detailed HA concepts

---

## References

### Official Documentation

- WALLIX Bastion 12.x Admin Guide: https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf

---

**Document Version**: 2.0
**Last Updated**: April 2026
**Deployment Model**: Master/Slave (2-node cluster via bastion-replication)
**Tested On**: WALLIX Bastion 12.1.x with Debian 12

---

**Next Steps:**

1. **Integrate with Access Manager:** Configure SSO and session brokering (Bastion-side only)
   - See: [15-access-manager-integration.md](15-access-manager-integration.md)

2. **Configure RADIUS MFA (FortiAuthenticator):** Use per-site FortiAuth HA pair (Cyber VLAN)
   - Primary RADIUS server: 10.10.X.50 (FortiAuth-1)
   - Secondary RADIUS server: 10.10.X.51 (FortiAuth-2)
   - See: [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md)

3. **Configure LDAP/AD:** Connect to per-site Active Directory (Cyber VLAN)
   - AD DC: 10.10.X.60
   - See: [04-ad-per-site.md](04-ad-per-site.md)

4. **Deploy to Additional Sites:** Replicate configuration for Sites 2-5
   - See: [01-network-design.md](01-network-design.md)

5. **Proceed to testing**: [11-testing-validation.md](11-testing-validation.md)

6. **Configure HAProxy**: [06-haproxy-setup.md](06-haproxy-setup.md)

7. **Set up monitoring**: [/docs/pam/12-monitoring-observability/](../docs/pam/12-monitoring-observability/README.md)
