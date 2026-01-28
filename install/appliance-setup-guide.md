# WALLIX Bastion Appliance Setup Guide

> **Purpose**: Step-by-step guide for setting up WALLIX Bastion appliances, covering standalone and High Availability configurations.

## Table of Contents

1. [Quick Start Overview](#quick-start-overview)
2. [Hardware Requirements](#hardware-requirements)
3. [Standalone Appliance Setup](#standalone-appliance-setup)
4. [HA Cluster Setup](#ha-cluster-setup)
5. [Initial Configuration](#initial-configuration)
6. [Post-Installation Tasks](#post-installation-tasks)
7. [Verification Commands](#verification-commands)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start Overview

```
+============================================================================+
|                         APPLIANCE SETUP OVERVIEW                           |
+============================================================================+
|                                                                            |
|  DEPLOYMENT OPTIONS                                                        |
|  ==================                                                        |
|                                                                            |
|  Option 1: STANDALONE                    Option 2: HA CLUSTER              |
|  ====================                    ===================               |
|                                                                            |
|       +-------------+                  +-------------+  +-------------+    |
|       |   WALLIX    |                  |   Node 1    |  |   Node 2    |    |
|       |  Bastion    |                  |  (Primary)  |  | (Secondary) |    |
|       |             |                  +------+------+  +------+------+    |
|       | Single node |                         |    Heartbeat    |          |
|       +-------------+                         +--------+--------+          |
|                                                        |                   |
|       Best for:                                  [Virtual IP]              |
|       * Small deployments                              |                   |
|       * Remote sites                           +-------+-------+           |
|       * Air-gapped locations                   | Shared Storage|           |
|       * Testing/POC                            +---------------+           |
|                                                                            |
|                                               Best for:                    |
|                                               * Production deployments     |
|                                               * High availability needs    |
|                                               * Zero-downtime maintenance  |
|                                                                            |
+============================================================================+
```

### Setup Timeline

| Deployment Type | Duration | Complexity |
|-----------------|----------|------------|
| Standalone | 2-4 hours | Low |
| HA Cluster (2 nodes) | 1-2 days | Medium |
| Multi-site (3+ sites) | 2-4 weeks | High |

---

## Hardware Requirements

### Standalone Appliance

```
+============================================================================+
|                      STANDALONE REQUIREMENTS                               |
+============================================================================+
|                                                                            |
|  +-------------------------+-------------------+------------------------+  |
|  | Component               | Minimum           | Recommended            |  |
|  +-------------------------+-------------------+------------------------+  |
|  | CPU                     | 4 vCPU            | 8 vCPU                 |  |
|  | RAM                     | 8 GB              | 16 GB                  |  |
|  | OS Disk                 | 100 GB SSD        | 200 GB NVMe            |  |
|  | Data/Recording Storage  | 250 GB SSD        | 500 GB+ NVMe           |  |
|  | Network                 | 1x 1 Gbps         | 2x 1 Gbps (bonded)     |  |
|  +-------------------------+-------------------+------------------------+  |
|                                                                            |
|  Sizing by user count:                                                     |
|  * Up to 50 concurrent users: Minimum specs                                |
|  * 50-200 concurrent users: Recommended specs                              |
|  * 200+ concurrent users: Consider HA cluster                              |
|                                                                            |
+============================================================================+
```

### HA Cluster (per node)

```
+============================================================================+
|                       HA CLUSTER REQUIREMENTS                              |
+============================================================================+
|                                                                            |
|  PER NODE:                                                                 |
|  +-------------------------+-------------------+------------------------+  |
|  | Component               | Minimum           | Recommended            |  |
|  +-------------------------+-------------------+------------------------+  |
|  | CPU                     | 8 vCPU            | 16 vCPU                |  |
|  | RAM                     | 16 GB             | 32 GB                  |  |
|  | OS Disk                 | 100 GB SSD        | 200 GB NVMe            |  |
|  | Data Disk               | 500 GB SSD        | 1 TB NVMe              |  |
|  | Network                 | 2x 1 Gbps         | 2x 10 Gbps             |  |
|  +-------------------------+-------------------+------------------------+  |
|                                                                            |
|  SHARED STORAGE:                                                           |
|  +-------------------------+-------------------+------------------------+  |
|  | Component               | Minimum           | Recommended            |  |
|  +-------------------------+-------------------+------------------------+  |
|  | NFS/iSCSI Storage       | 2 TB              | 10 TB                  |  |
|  | IOPS                    | 1,000             | 5,000+                 |  |
|  +-------------------------+-------------------+------------------------+  |
|                                                                            |
|  ADDITIONAL:                                                               |
|  * Dedicated heartbeat network (separate NIC)                              |
|  * 3 IP addresses: Node 1, Node 2, Virtual IP                              |
|                                                                            |
+============================================================================+
```

---

## Standalone Appliance Setup

### Step 1: Install Debian 12

```
+============================================================================+
|                       DEBIAN 12 INSTALLATION                               |
+============================================================================+
|                                                                            |
|  INSTALLATION OPTIONS                                                      |
|  ====================                                                      |
|                                                                            |
|  1. Download Debian 12 (Bookworm) netinst ISO                              |
|     https://www.debian.org/download                                        |
|                                                                            |
|  2. Boot from ISO and select "Install"                                     |
|                                                                            |
|  3. Configure:                                                             |
|     - Language: English                                                    |
|     - Hostname: wallix-bastion (or your naming convention)                 |
|     - Domain: company.com                                                  |
|     - Root password: [Strong password - document securely]                 |
|     - User account: wadmin (for administration)                            |
|                                                                            |
|  4. Partitioning (Guided LVM):                                             |
|     +-------------------+------------------+----------------------------+  |
|     | Mount Point       | Size             | Purpose                    |  |
|     +-------------------+------------------+----------------------------+  |
|     | /boot             | 1 GB             | Boot partition             |  |
|     | /                 | 50 GB            | System root                |  |
|     | /var              | 50 GB            | Logs                       |  |
|     | /var/wab          | Remaining        | WALLIX data & recordings   |  |
|     | swap              | 8 GB             | Swap space                 |  |
|     +-------------------+------------------+----------------------------+  |
|                                                                            |
|  5. Software selection:                                                    |
|     [x] SSH server                                                         |
|     [x] Standard system utilities                                          |
|     [ ] Desktop environment (DO NOT select)                                |
|                                                                            |
+============================================================================+
```

### Step 2: Base System Configuration

```bash
#!/bin/bash
# Run as root after Debian installation

# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y \
    curl \
    wget \
    gnupg \
    apt-transport-https \
    ca-certificates \
    ntp \
    chrony \
    rsync \
    net-tools \
    vim \
    htop

# Configure timezone
timedatectl set-timezone Europe/Paris  # Adjust to your timezone

# Configure NTP
systemctl enable chrony
systemctl start chrony

# Verify time sync
chronyc tracking
```

### Step 3: Configure Network

```bash
# Edit network configuration
cat > /etc/network/interfaces.d/wallix << 'EOF'
# Primary network interface
auto eth0
iface eth0 inet static
    address 10.100.1.10
    netmask 255.255.255.0
    gateway 10.100.1.1
    dns-nameservers 10.100.1.2 10.100.1.3
EOF

# Update /etc/hosts
cat >> /etc/hosts << 'EOF'
10.100.1.10     wallix-bastion.company.com wallix-bastion
EOF

# Apply network configuration
systemctl restart networking

# Verify connectivity
ping -c 3 10.100.1.1
```

### Step 4: Install WALLIX Bastion

```bash
# Add WALLIX repository GPG key
curl -fsSL https://repo.wallix.com/wallix.gpg | gpg --dearmor -o /usr/share/keyrings/wallix.gpg

# Add WALLIX repository
cat > /etc/apt/sources.list.d/wallix.list << 'EOF'
deb [signed-by=/usr/share/keyrings/wallix.gpg] https://repo.wallix.com/bastion/12.1 bookworm main
EOF

# Update package list
apt update

# Install WALLIX Bastion
apt install -y wallix-bastion

# The installer will prompt for:
# - Administrator password (set strong password)
# - License file path (can be done later)
# - SSL certificate configuration
```

### Step 5: Install License

```bash
# Copy license file to the server
scp license.key root@10.100.1.10:/tmp/

# On the WALLIX server
cp /tmp/license.key /etc/opt/wab/license.key
chmod 640 /etc/opt/wab/license.key
chown root:wab /etc/opt/wab/license.key

# Verify license
wabadmin license-info
```

### Step 6: Configure SSL Certificate

```bash
# Option A: Self-signed certificate (for testing)
wabadmin cert-generate --cn wallix-bastion.company.com

# Option B: Install purchased certificate
cp server.crt /etc/opt/wab/ssl/server.crt
cp server.key /etc/opt/wab/ssl/server.key
chmod 640 /etc/opt/wab/ssl/server.key
chown root:wab /etc/opt/wab/ssl/server.key

# Restart WALLIX services
systemctl restart wallix-bastion
```

### Step 7: Verify Installation

```bash
# Check service status
systemctl status wallix-bastion

# Check all WALLIX services
wabadmin status

# Test web interface
curl -k https://localhost/api/health

# Access web UI
echo "Access: https://10.100.1.10"
echo "Username: admin"
echo "Password: [configured during installation]"
```

---

## HA Cluster Setup

### Architecture Overview

```
+============================================================================+
|                         HA CLUSTER ARCHITECTURE                            |
+============================================================================+
|                                                                            |
|                           [Virtual IP]                                     |
|                          10.100.1.100                                      |
|                               |                                            |
|              +----------------+----------------+                           |
|              |                                 |                           |
|     +--------+--------+               +--------+--------+                  |
|     |     NODE 1      |               |     NODE 2      |                  |
|     |    (Primary)    |               |   (Secondary)   |                  |
|     |                 |               |                 |                  |
|     | 10.100.1.10     |               | 10.100.1.11     |                  |
|     +--------+--------+               +--------+--------+                  |
|              |     Heartbeat Network          |                            |
|              |     10.100.254.0/30            |                            |
|              +--------+-------+---------------+                            |
|                       |       |                                            |
|              10.100.254.1   10.100.254.2                                   |
|                       |       |                                            |
|     +-----------------+-------+-----------------+                          |
|     |                                           |                          |
|     |           SHARED STORAGE (NFS)            |                          |
|     |           10.100.1.50:/wallix             |                          |
|     |                                           |                          |
|     +-------------------------------------------+                          |
|                                                                            |
|  Components:                                                               |
|  * Pacemaker/Corosync: Cluster management                                  |
|  * PostgreSQL: Streaming replication                                       |
|  * Shared Storage: Session recordings                                      |
|                                                                            |
+============================================================================+
```

### Node 1 Setup

#### Step 1: Base Configuration

```bash
# SSH to Node 1
ssh root@10.100.1.10

# Set hostname
hostnamectl set-hostname wallix-a1.company.com

# Configure /etc/hosts
cat >> /etc/hosts << 'EOF'
# WALLIX HA Cluster
10.100.1.10     wallix-a1.company.com wallix-a1
10.100.1.11     wallix-a2.company.com wallix-a2
10.100.1.100    wallix-vip.company.com wallix-vip

# Heartbeat network
10.100.254.1    wallix-a1-hb
10.100.254.2    wallix-a2-hb
EOF

# Configure network interfaces
cat > /etc/network/interfaces.d/wallix << 'EOF'
# Management interface
auto eth0
iface eth0 inet static
    address 10.100.1.10
    netmask 255.255.255.0
    gateway 10.100.1.1
    dns-nameservers 10.100.1.2 10.100.1.3

# HA Heartbeat interface
auto eth1
iface eth1 inet static
    address 10.100.254.1
    netmask 255.255.255.252
EOF

# Apply network
systemctl restart networking
```

#### Step 2: Install WALLIX Bastion

```bash
# Add repository and install (same as standalone)
curl -fsSL https://repo.wallix.com/wallix.gpg | gpg --dearmor -o /usr/share/keyrings/wallix.gpg

cat > /etc/apt/sources.list.d/wallix.list << 'EOF'
deb [signed-by=/usr/share/keyrings/wallix.gpg] https://repo.wallix.com/bastion/12.1 bookworm main
EOF

apt update
apt install -y wallix-bastion
```

#### Step 3: Configure PostgreSQL for Replication (Primary)

```bash
# Edit PostgreSQL configuration
cat >> /etc/postgresql/16/main/postgresql.conf << 'EOF'

# Replication settings (Primary)
wal_level = replica
max_wal_senders = 5
wal_keep_size = 1GB
hot_standby = on
synchronous_commit = on
synchronous_standby_names = 'wallix_standby'
EOF

# Configure replication access
cat >> /etc/postgresql/16/main/pg_hba.conf << 'EOF'

# Replication from Node 2
host    replication     replicator      10.100.254.2/32         scram-sha-256
host    replication     replicator      10.100.1.11/32          scram-sha-256
EOF

# Create replication user
sudo -u postgres psql << 'EOF'
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'ReplicaSecurePass2026!';
EOF

# Restart PostgreSQL
systemctl restart postgresql
```

#### Step 4: Configure Shared Storage

```bash
# Install NFS client
apt install -y nfs-common

# Create mount point
mkdir -p /var/wab/recorded

# Add NFS mount
cat >> /etc/fstab << 'EOF'
10.100.1.50:/wallix/recordings  /var/wab/recorded  nfs4  defaults,_netdev,hard,intr  0  0
EOF

# Mount and verify
mount -a
df -h /var/wab/recorded

# Set permissions
chown -R wab:wab /var/wab/recorded
```

### Node 2 Setup

#### Step 1: Base Configuration

```bash
# SSH to Node 2
ssh root@10.100.1.11

# Set hostname
hostnamectl set-hostname wallix-a2.company.com

# Configure /etc/hosts (same as Node 1)
cat >> /etc/hosts << 'EOF'
# WALLIX HA Cluster
10.100.1.10     wallix-a1.company.com wallix-a1
10.100.1.11     wallix-a2.company.com wallix-a2
10.100.1.100    wallix-vip.company.com wallix-vip

# Heartbeat network
10.100.254.1    wallix-a1-hb
10.100.254.2    wallix-a2-hb
EOF

# Configure network
cat > /etc/network/interfaces.d/wallix << 'EOF'
# Management interface
auto eth0
iface eth0 inet static
    address 10.100.1.11
    netmask 255.255.255.0
    gateway 10.100.1.1
    dns-nameservers 10.100.1.2 10.100.1.3

# HA Heartbeat interface
auto eth1
iface eth1 inet static
    address 10.100.254.2
    netmask 255.255.255.252
EOF

systemctl restart networking
```

#### Step 2: Install WALLIX and Configure PostgreSQL Standby

```bash
# Install WALLIX Bastion
apt update
apt install -y wallix-bastion

# Stop PostgreSQL to configure as standby
systemctl stop postgresql

# Remove existing data directory
rm -rf /var/lib/postgresql/16/main/*

# Create base backup from primary
sudo -u postgres pg_basebackup -h 10.100.254.1 -U replicator -D /var/lib/postgresql/16/main -Fp -Xs -P -R

# The -R flag creates standby.signal and configures replication

# Configure standby settings
cat >> /etc/postgresql/16/main/postgresql.conf << 'EOF'

# Standby configuration
hot_standby = on
primary_conninfo = 'host=10.100.254.1 port=5432 user=replicator password=ReplicaSecurePass2026! application_name=wallix_standby'
EOF

# Start PostgreSQL
systemctl start postgresql

# Verify replication status (on Node 1)
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"
```

### Cluster Configuration (Both Nodes)

#### Step 1: Install Cluster Software

```bash
# Run on BOTH nodes
apt install -y pacemaker corosync pcs

# Set cluster password
echo "hacluster:ClusterSecurePass2026!" | chpasswd

# Enable and start pcsd
systemctl enable pcsd
systemctl start pcsd
```

#### Step 2: Configure Corosync (Node 1 only)

```bash
# Authenticate nodes (run on Node 1)
pcs host auth wallix-a1-hb wallix-a2-hb -u hacluster -p ClusterSecurePass2026!

# Create cluster
pcs cluster setup wallix-cluster wallix-a1-hb wallix-a2-hb

# Start cluster
pcs cluster start --all
pcs cluster enable --all
```

#### Step 3: Configure Cluster Resources

```bash
# Disable STONITH for initial setup (configure properly for production)
pcs property set stonith-enabled=false

# Set no-quorum policy
pcs property set no-quorum-policy=ignore

# Create Virtual IP resource
pcs resource create wallix-vip ocf:heartbeat:IPaddr2 \
    ip=10.100.1.100 \
    cidr_netmask=24 \
    op monitor interval=10s

# Create WALLIX service resource
pcs resource create wallix-bastion systemd:wallix-bastion \
    op monitor interval=30s \
    op start timeout=120s \
    op stop timeout=120s

# Create resource group
pcs resource group add wallix-group wallix-vip wallix-bastion

# Set colocation (VIP and service on same node)
pcs constraint colocation add wallix-bastion with wallix-vip INFINITY

# Set order (VIP starts before service)
pcs constraint order wallix-vip then wallix-bastion

# Verify cluster status
pcs status
```

---

## Initial Configuration

### First Login

```
+============================================================================+
|                         INITIAL CONFIGURATION                              |
+============================================================================+
|                                                                            |
|  1. ACCESS WEB INTERFACE                                                   |
|     =======================                                                |
|                                                                            |
|     URL: https://<IP_ADDRESS>                                              |
|     Username: admin                                                        |
|     Password: [Set during installation]                                    |
|                                                                            |
|  2. INITIAL SETUP WIZARD                                                   |
|     ======================                                                 |
|                                                                            |
|     Step 1: License                                                        |
|             - Upload license file if not done                              |
|             - Verify features enabled                                      |
|                                                                            |
|     Step 2: Network Settings                                               |
|             - Verify hostname                                              |
|             - Configure DNS                                                |
|             - Configure NTP                                                |
|                                                                            |
|     Step 3: SSL Certificate                                                |
|             - Replace self-signed with proper certificate                  |
|                                                                            |
|     Step 4: Authentication                                                 |
|             - Configure LDAP/AD (recommended)                              |
|             - Configure MFA (TOTP)                                         |
|                                                                            |
|     Step 5: Create First Domain                                            |
|             - Domain = logical grouping of targets                         |
|             - Example: "Production-Linux"                                  |
|                                                                            |
|     Step 6: Add First Device                                               |
|             - Create device (target server)                                |
|             - Add service (SSH, RDP, etc.)                                 |
|             - Add account (credentials)                                    |
|                                                                            |
|     Step 7: Create User Group                                              |
|             - Map to LDAP group or create local                            |
|                                                                            |
|     Step 8: Create Target Group                                            |
|             - Group related devices/accounts                               |
|                                                                            |
|     Step 9: Create Authorization                                           |
|             - Link user group to target group                              |
|             - Define access permissions                                    |
|                                                                            |
+============================================================================+
```

### Configure LDAP/AD Authentication

```bash
# Via Web UI: Configuration > Authentication > LDAP

# Or via API:
curl -k -X POST https://localhost/api/ldapdomains \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $API_TOKEN" \
  -d '{
    "domain_name": "company.com",
    "ldap_server": "ldaps://dc01.company.com:636",
    "ldap_base_dn": "DC=company,DC=com",
    "ldap_user_dn": "CN=wallix-svc,OU=Service Accounts,DC=company,DC=com",
    "ldap_password": "ServiceAccountPassword",
    "ldap_user_filter": "(sAMAccountName=%s)",
    "ldap_group_filter": "(member=%s)",
    "default_profile": "user"
  }'
```

### Configure MFA (TOTP)

```bash
# Enable TOTP for all users
# Via Web UI: Configuration > Authentication > MFA

# Settings:
# - MFA Type: TOTP
# - Issuer Name: WALLIX Bastion
# - Require MFA: Yes (for all users or specific groups)
```

---

## Post-Installation Tasks

### Security Hardening Checklist

```
+============================================================================+
|                      POST-INSTALLATION CHECKLIST                           |
+============================================================================+
|                                                                            |
|  SECURITY                                                                  |
|  ========                                                                  |
|  [ ] Change default admin password                                         |
|  [ ] Install production SSL certificate                                    |
|  [ ] Configure LDAP/AD authentication                                      |
|  [ ] Enable MFA for all users                                              |
|  [ ] Configure session timeout                                             |
|  [ ] Enable audit logging                                                  |
|  [ ] Configure SIEM integration                                            |
|  [ ] Restrict SSH access (key-based only)                                  |
|  [ ] Configure firewall rules                                              |
|  [ ] Enable automatic updates (or schedule)                                |
|                                                                            |
|  BACKUP                                                                    |
|  ======                                                                    |
|  [ ] Configure database backup schedule                                    |
|  [ ] Configure configuration backup                                        |
|  [ ] Test restore procedure                                                |
|  [ ] Document backup locations                                             |
|                                                                            |
|  MONITORING                                                                |
|  ==========                                                                |
|  [ ] Configure SNMP monitoring                                             |
|  [ ] Configure email alerts                                                |
|  [ ] Set up health check monitoring                                        |
|  [ ] Configure disk space alerts                                           |
|                                                                            |
|  DOCUMENTATION                                                             |
|  =============                                                             |
|  [ ] Document all IP addresses                                             |
|  [ ] Document all credentials (secure storage)                             |
|  [ ] Document recovery procedures                                          |
|  [ ] Create runbook for common tasks                                       |
|                                                                            |
+============================================================================+
```

### Configure Backup

```bash
# Database backup script
cat > /root/backup-wallix.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/wallix"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup PostgreSQL
sudo -u postgres pg_dump wab > $BACKUP_DIR/wab_db_$DATE.sql

# Backup configuration
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /etc/opt/wab/

# Cleanup old backups (keep 30 days)
find $BACKUP_DIR -type f -mtime +30 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /root/backup-wallix.sh

# Add to crontab (daily at 2 AM)
echo "0 2 * * * /root/backup-wallix.sh >> /var/log/wallix-backup.log 2>&1" | crontab -
```

---

## Verification Commands

### Service Status

```bash
# Check WALLIX service status
systemctl status wallix-bastion

# Check all WALLIX components
wabadmin status

# Check license information
wabadmin license-info

# Check database status
sudo -u postgres psql -c "SELECT version();"
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
```

### HA Cluster Status

```bash
# Check cluster status
pcs status

# Check cluster resources
pcs resource status

# Check corosync status
corosync-cfgtool -s

# Check quorum
corosync-quorumtool

# Check PostgreSQL replication (on primary)
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"

# Check PostgreSQL standby status (on standby)
sudo -u postgres psql -c "SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();"
```

### Connectivity Tests

```bash
# Test web interface
curl -k -o /dev/null -s -w "%{http_code}\n" https://localhost/

# Test API health
curl -k https://localhost/api/health

# Test SSH proxy port
nc -zv localhost 22

# Test RDP proxy port
nc -zv localhost 3389
```

---

## Troubleshooting

### Common Issues

```
+============================================================================+
|                         TROUBLESHOOTING GUIDE                              |
+============================================================================+
|                                                                            |
|  ISSUE: Service won't start                                                |
|  ===========================                                               |
|                                                                            |
|  Check logs:                                                               |
|  journalctl -u wallix-bastion -f                                           |
|  cat /var/log/wab/*.log                                                    |
|                                                                            |
|  Common causes:                                                            |
|  * License expired or invalid                                              |
|  * Database not running                                                    |
|  * SSL certificate issues                                                  |
|  * Disk space full                                                         |
|                                                                            |
|  -----------------------------------------------------------------------   |
|                                                                            |
|  ISSUE: Cannot access web interface                                        |
|  ==================================                                        |
|                                                                            |
|  Check:                                                                    |
|  1. Service running: systemctl status wallix-bastion                       |
|  2. Port listening: ss -tlnp | grep 443                                    |
|  3. Firewall: iptables -L -n                                               |
|  4. SSL cert: openssl s_client -connect localhost:443                      |
|                                                                            |
|  -----------------------------------------------------------------------   |
|                                                                            |
|  ISSUE: HA failover not working                                            |
|  ==============================                                            |
|                                                                            |
|  Check:                                                                    |
|  1. Cluster status: pcs status                                             |
|  2. Heartbeat network: ping <other-node-hb-ip>                             |
|  3. Corosync: corosync-cfgtool -s                                          |
|  4. Resource errors: pcs resource cleanup                                  |
|                                                                            |
|  -----------------------------------------------------------------------   |
|                                                                            |
|  ISSUE: Database replication lag                                           |
|  ================================                                          |
|                                                                            |
|  Check replication status:                                                 |
|  sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"             |
|                                                                            |
|  Check standby lag:                                                        |
|  sudo -u postgres psql -c "SELECT now() - pg_last_xact_replay_timestamp()" |
|                                                                            |
|  Common causes:                                                            |
|  * Network latency                                                         |
|  * Disk I/O bottleneck on standby                                          |
|  * High write load on primary                                              |
|                                                                            |
+============================================================================+
```

### Log Locations

| Log | Path | Purpose |
|-----|------|---------|
| WALLIX service | /var/log/wab/*.log | Main application logs |
| PostgreSQL | /var/log/postgresql/*.log | Database logs |
| Cluster | /var/log/cluster/*.log | Pacemaker/Corosync |
| System | /var/log/syslog | System messages |
| Authentication | /var/log/auth.log | Login attempts |

---

## OT Environment Configuration

### OT Zone Placement

```
+============================================================================+
|                       OT ZONE ARCHITECTURE                                 |
+============================================================================+
|                                                                            |
|  IEC 62443 ZONE MODEL - WALLIX PLACEMENT                                   |
|  =======================================                                   |
|                                                                            |
|  ENTERPRISE ZONE (Level 4-5)                                               |
|  +----------------------------------------------------------------------+  |
|  |  [Corporate Network]  [ERP]  [Email]  [Users]                        |  |
|  +----------------------------------+-----------------------------------+  |
|                                     |                                      |
|  ===================================|=== ENTERPRISE DMZ ==============     |
|                                     |                                      |
|  OT DMZ (Level 3.5) <-- WALLIX HERE |                                      |
|  +----------------------------------+-----------------------------------+  |
|  |                                  |                                   |  |
|  |  +=========================+     |     +---------------------+       |  |
|  |  |    WALLIX BASTION       |<----+     | Historian Mirror    |       |  |
|  |  |                         |           | (Read-Only)         |       |  |
|  |  | * Secure gateway        |           +---------------------+       |  |
|  |  | * Session recording     |                                         |  |
|  |  | * Protocol proxy        |           +---------------------+       |  |
|  |  | * Credential vault      |           | Patch Server        |       |  |
|  |  +=========================+           +---------------------+       |  |
|  |              |                                                       |  |
|  +--------------|-------------------------------------------------------+  |
|                 |                                                          |
|  ===============|========= INDUSTRIAL FIREWALL ========================    |
|                 |                                                          |
|  OPERATIONS ZONE (Level 3) - Security Level 3                              |
|  +--------------|-------------------------------------------------------+  |
|  |              v                                                       |  |
|  |  [SCADA Server]    [Historian]    [Engineering WS]                   |  |
|  +----------------------------------+-----------------------------------+  |
|                                     |                                      |
|  ===================================|=== CONTROL FIREWALL =============    |
|                                     |                                      |
|  CONTROL ZONE (Level 2) - Security Level 2                                 |
|  +----------------------------------+-----------------------------------+  |
|  |              v                                                       |  |
|  |  [HMI Stations]    [Control Server]    [Operator WS]                 |  |
|  +----------------------------------+-----------------------------------+  |
|                                     |                                      |
|  ===================================|=== FIELD FIREWALL ===============    |
|                                     |                                      |
|  FIELD ZONE (Level 0-1) - Security Level 1                                 |
|  +----------------------------------------------------------------------+  |
|  |              v                                                       |  |
|  |  [PLCs]    [RTUs]    [DCS]    [Safety Systems]    [Sensors]          |  |
|  +----------------------------------------------------------------------+  |
|                                                                            |
|  KEY: All access to OT zones MUST go through WALLIX Bastion                |
|                                                                            |
+============================================================================+
```

### OT Network Configuration

```bash
# Configure OT DMZ network interface (if separate from management)
cat >> /etc/network/interfaces.d/wallix << 'EOF'

# OT DMZ interface (for OT zone access)
auto eth2
iface eth2 inet static
    address 10.100.10.5
    netmask 255.255.255.0
    # No gateway - OT traffic routed through firewalls
EOF

systemctl restart networking
```

### Enable Industrial Protocol Support

```bash
# Enable Universal Tunneling for industrial protocols
wabadmin config-set tunneling.enabled true
wabadmin config-set tunneling.protocols "modbus,s7comm,ethernetip,opcua,bacnet,dnp3"

# Configure tunnel settings
wabadmin config-set tunneling.timeout 3600          # 1 hour max session
wabadmin config-set tunneling.keepalive 60          # Keepalive interval
wabadmin config-set tunneling.max_tunnels 100       # Max concurrent tunnels

# Restart services
systemctl restart wallix-bastion
```

### Configure Industrial Protocol Tunnels

```bash
# Create tunnel configuration file
cat > /etc/opt/wab/tunnels.json << 'EOF'
{
  "tunnels": [
    {
      "name": "modbus-plc-line1",
      "description": "Modbus access to Production Line 1 PLCs",
      "protocol": "modbus",
      "local_port": 10502,
      "remote_host": "10.100.40.10",
      "remote_port": 502,
      "authorization_required": true,
      "recording": true,
      "allowed_groups": ["ot-engineers", "plc-programmers"]
    },
    {
      "name": "s7-siemens-plc",
      "description": "S7comm access to Siemens S7-1500",
      "protocol": "s7comm",
      "local_port": 10102,
      "remote_host": "10.100.40.20",
      "remote_port": 102,
      "authorization_required": true,
      "recording": true,
      "allowed_groups": ["siemens-engineers"]
    },
    {
      "name": "opcua-historian",
      "description": "OPC UA access to Historian",
      "protocol": "opcua",
      "local_port": 14840,
      "remote_host": "10.100.20.20",
      "remote_port": 4840,
      "authorization_required": true,
      "recording": true,
      "tls_enabled": true,
      "allowed_groups": ["data-engineers"]
    }
  ]
}
EOF

# Apply tunnel configuration
wabadmin tunnel-reload
wabadmin tunnel-status
```

### Add OT Devices

```bash
# Add SCADA server
wabadmin device-create \
    --name "SCADA-Primary" \
    --host "10.100.20.10" \
    --description "Primary SCADA Server" \
    --domain "OT-Operations"

wabadmin service-create \
    --device "SCADA-Primary" \
    --name "RDP" \
    --protocol "RDP" \
    --port 3389

wabadmin service-create \
    --device "SCADA-Primary" \
    --name "SSH" \
    --protocol "SSH" \
    --port 22

# Add HMI stations
wabadmin device-create \
    --name "HMI-Station-01" \
    --host "10.100.30.10" \
    --description "Operator HMI Station 1" \
    --domain "OT-Control"

wabadmin service-create \
    --device "HMI-Station-01" \
    --name "VNC" \
    --protocol "VNC" \
    --port 5900

# Add Engineering Workstation (for PLC programming)
wabadmin device-create \
    --name "ENG-WS-01" \
    --host "10.100.20.30" \
    --description "Engineering WS with TIA Portal/RSLogix" \
    --domain "OT-Operations"

wabadmin service-create \
    --device "ENG-WS-01" \
    --name "RDP" \
    --protocol "RDP" \
    --port 3389
```

### Configure Shared HMI Accounts

```bash
# HMI stations often use shared operator accounts
# WALLIX provides individual accountability through session recording

wabadmin account-create \
    --name "operator" \
    --device "HMI-Station-01" \
    --description "Shared operator account" \
    --checkout-required false \
    --credential-injection true

# Users connect through WALLIX, credentials are injected
# Session is recorded with individual user identity
```

### OT Approval Workflows

```bash
# Require approval for access to critical OT systems
wabadmin approval-create \
    --name "plc-access-approval" \
    --description "Approval required for PLC access" \
    --approvers "ot-supervisors" \
    --timeout 60 \
    --target-groups "field-zone-plcs"

wabadmin approval-create \
    --name "scada-access-approval" \
    --description "Approval required for SCADA changes" \
    --approvers "ot-managers" \
    --dual-approval true \
    --timeout 120 \
    --target-groups "scada-servers"
```

### Offline/Air-Gapped Configuration

```bash
# For air-gapped or intermittently connected sites
# Enable offline credential caching

wabadmin config-set offline.enabled true
wabadmin config-set offline.cache_duration 168    # 7 days cache
wabadmin config-set offline.sync_interval 3600    # Sync hourly when connected
wabadmin config-set offline.local_auth true       # Allow local auth if disconnected

# Configure local credential cache encryption
wabadmin config-set offline.cache_encryption "AES-256-GCM"
wabadmin config-set offline.cache_key_rotation 86400  # Daily key rotation

# Restart services
systemctl restart wallix-bastion
```

### OT Security Hardening

```bash
# OT-specific security settings

# 1. Disable unnecessary protocols
wabadmin config-set protocols.telnet.enabled false  # Unless required for legacy
wabadmin config-set protocols.ftp.enabled false

# 2. Enable enhanced logging for OT
wabadmin config-set logging.ot_verbose true
wabadmin config-set logging.protocol_debug true

# 3. Configure session recording retention (compliance)
wabadmin config-set recording.retention_days 365    # 1 year for IEC 62443
wabadmin config-set recording.compression true
wabadmin config-set recording.encryption true

# 4. Enable industrial protocol alerting
wabadmin config-set alerts.plc_write true           # Alert on PLC writes
wabadmin config-set alerts.scada_config_change true # Alert on SCADA changes
wabadmin config-set alerts.safety_system_access true

# 5. Configure emergency bypass (break-glass)
wabadmin config-set emergency.enabled true
wabadmin config-set emergency.code_rotation 24      # Change code every 24 hours
wabadmin config-set emergency.audit_alert true      # Alert on emergency use
wabadmin config-set emergency.require_justification true
```

### OT Firewall Rules

```bash
# Firewall rules for WALLIX in OT DMZ

# Allow management access from IT (HTTPS only)
iptables -A INPUT -s 10.0.1.0/24 -p tcp --dport 443 -j ACCEPT

# Allow user connections for session proxying
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 22 -j ACCEPT    # SSH
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 3389 -j ACCEPT  # RDP
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 5900 -j ACCEPT  # VNC

# Allow industrial protocol tunnels (from users through WALLIX)
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 10502 -j ACCEPT # Modbus tunnel
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 10102 -j ACCEPT # S7comm tunnel
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 14840 -j ACCEPT # OPC UA tunnel

# Allow WALLIX to access OT zones
iptables -A OUTPUT -d 10.100.20.0/24 -j ACCEPT  # Operations zone
iptables -A OUTPUT -d 10.100.30.0/24 -j ACCEPT  # Control zone
iptables -A OUTPUT -d 10.100.40.0/24 -j ACCEPT  # Field zone

# Save rules
iptables-save > /etc/iptables/rules.v4
```

### Verify OT Configuration

```bash
# Check industrial protocol status
wabadmin protocol-status

# Expected output:
# Protocol     | Status  | Connections
# -------------+---------+-------------
# SSH          | Active  | 12
# RDP          | Active  | 8
# VNC          | Active  | 3
# Modbus       | Active  | 5
# S7comm       | Active  | 2
# OPC UA       | Active  | 1

# Check tunnel status
wabadmin tunnel-status

# Check offline cache status
wabadmin offline-status

# Test connectivity to OT devices
wabadmin device-test "SCADA-Primary"
wabadmin device-test "HMI-Station-01"
```

---

## Related Documentation

- [HOWTO.md](./HOWTO.md) - Complete multi-site installation guide
- [01-prerequisites.md](./01-prerequisites.md) - Detailed requirements
- [02-site-a-primary.md](./02-site-a-primary.md) - Primary site setup
- [07-security-hardening.md](./07-security-hardening.md) - Security configuration
- [08-validation-testing.md](./08-validation-testing.md) - Testing procedures
- [10-postgresql-streaming-replication.md](./10-postgresql-streaming-replication.md) - Database HA

---

## Quick Reference

```bash
# Start/Stop/Restart WALLIX
systemctl start wallix-bastion
systemctl stop wallix-bastion
systemctl restart wallix-bastion

# Check status
wabadmin status
systemctl status wallix-bastion

# License info
wabadmin license-info

# Cluster commands (HA only)
pcs status
pcs resource status
pcs cluster start --all
pcs cluster stop --all

# Database commands
sudo -u postgres psql -c "SELECT version();"
sudo -u postgres pg_dump wab > backup.sql

# View recent audit
wabadmin audit --last 20
```
