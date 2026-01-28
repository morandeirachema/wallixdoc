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
