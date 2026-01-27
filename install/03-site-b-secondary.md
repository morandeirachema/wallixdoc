# 03 - Site B Secondary Installation

## Table of Contents

1. [Overview](#overview)
2. [Node Installation](#node-installation)
3. [HA Cluster Configuration](#ha-cluster-configuration)
4. [Site Synchronization](#site-synchronization)
5. [Verification](#verification)

---

## Overview

Site B is the secondary plant installation running a High Availability cluster in Active-Passive mode.

```
+==============================================================================+
|                   SITE B ARCHITECTURE                                        |
+==============================================================================+

     +--------+--------+           +--------+--------+
     |  WALLIX-B1      |           |  WALLIX-B2      |
     |  (Primary)      |           |  (Secondary)    |
     |                 |           |                 |
     | 10.200.1.10     |           | 10.200.1.11     |
     +--------+--------+           +--------+--------+
              |      Heartbeat Network      |
              +----------10.200.254.0/30----+
              |                             |
     +--------+--------+           +--------+--------+
     |   PostgreSQL    |<--------->|   PostgreSQL    |
     |   (Primary)     | Streaming |   (Standby)     |
     +-----------------+ Replication+-----------------+

  Virtual IP: 10.200.1.100 (wallix.site-b.company.com)

  Site-to-Site Connection:
  Site B <------ VPN/MPLS ------> Site A (10.100.1.100)

+==============================================================================+
```

---

## Node Installation

### Node 1 (wallix-b1)

```bash
# Connect to Node 1
ssh root@10.200.1.10

# Set hostname
hostnamectl set-hostname wallix-b1.site-b.company.com

# Update /etc/hosts
cat >> /etc/hosts << 'EOF'
# Local Site B
10.200.1.10     wallix-b1.site-b.company.com wallix-b1
10.200.1.11     wallix-b2.site-b.company.com wallix-b2
10.200.1.100    wallix.site-b.company.com wallix-b-vip
10.200.254.1    wallix-b1-hb
10.200.254.2    wallix-b2-hb

# Remote Site A (for sync)
10.100.1.100    wallix.site-a.company.com wallix-a-vip
EOF

# Configure network interfaces
cat > /etc/network/interfaces.d/wallix << 'EOF'
# Management interface
auto eth0
iface eth0 inet static
    address 10.200.1.10
    netmask 255.255.255.0
    gateway 10.200.1.1
    dns-nameservers 10.200.1.2 10.200.1.3

# HA Heartbeat interface
auto eth1
iface eth1 inet static
    address 10.200.254.1
    netmask 255.255.255.252
EOF

systemctl restart networking

# Add WALLIX repository
curl -fsSL https://repo.wallix.com/wallix.gpg | gpg --dearmor -o /usr/share/keyrings/wallix.gpg

cat > /etc/apt/sources.list.d/wallix.list << 'EOF'
deb [signed-by=/usr/share/keyrings/wallix.gpg] https://repo.wallix.com/bastion/12.1 bookworm main
EOF

# Install WALLIX Bastion
apt update
apt install -y wallix-bastion

# Configure PostgreSQL for replication (primary)
cat >> /etc/postgresql/16/main/postgresql.conf << 'EOF'

# Replication settings (Primary)
wal_level = replica
max_wal_senders = 5
wal_keep_size = 1GB
hot_standby = on
synchronous_commit = on
EOF

cat >> /etc/postgresql/16/main/pg_hba.conf << 'EOF'

# Replication
host    replication     replicator      10.200.254.2/32         scram-sha-256
host    replication     replicator      10.200.1.11/32          scram-sha-256
EOF

sudo -u postgres psql << 'EOF'
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'ReplicaSecurePass2026!';
EOF

systemctl restart postgresql

# Configure shared storage (local NFS for Site B)
apt install -y nfs-common
mkdir -p /var/wab/recorded

cat >> /etc/fstab << 'EOF'
10.200.1.50:/wallix/recordings  /var/wab/recorded  nfs4  defaults,_netdev,hard,intr  0  0
EOF

mount -a
chown -R wab:wab /var/wab/recorded

# Install license
cp /path/to/license.key /etc/opt/wab/license.key
chmod 640 /etc/opt/wab/license.key
chown root:wab /etc/opt/wab/license.key
```

### Node 2 (wallix-b2)

```bash
# Connect to Node 2
ssh root@10.200.1.11

# Set hostname
hostnamectl set-hostname wallix-b2.site-b.company.com

# Update /etc/hosts (same as Node 1)
cat >> /etc/hosts << 'EOF'
10.200.1.10     wallix-b1.site-b.company.com wallix-b1
10.200.1.11     wallix-b2.site-b.company.com wallix-b2
10.200.1.100    wallix.site-b.company.com wallix-b-vip
10.200.254.1    wallix-b1-hb
10.200.254.2    wallix-b2-hb
10.100.1.100    wallix.site-a.company.com wallix-a-vip
EOF

# Configure network
cat > /etc/network/interfaces.d/wallix << 'EOF'
auto eth0
iface eth0 inet static
    address 10.200.1.11
    netmask 255.255.255.0
    gateway 10.200.1.1
    dns-nameservers 10.200.1.2 10.200.1.3

auto eth1
iface eth1 inet static
    address 10.200.254.2
    netmask 255.255.255.252
EOF

systemctl restart networking

# Install WALLIX
curl -fsSL https://repo.wallix.com/wallix.gpg | gpg --dearmor -o /usr/share/keyrings/wallix.gpg
cat > /etc/apt/sources.list.d/wallix.list << 'EOF'
deb [signed-by=/usr/share/keyrings/wallix.gpg] https://repo.wallix.com/bastion/12.1 bookworm main
EOF

apt update
apt install -y wallix-bastion

# Configure PostgreSQL as standby
systemctl stop postgresql
rm -rf /var/lib/postgresql/16/main/*

sudo -u postgres pg_basebackup -h 10.200.254.1 -U replicator -D /var/lib/postgresql/16/main -P -R

cat >> /etc/postgresql/16/main/postgresql.conf << 'EOF'

# Standby settings
hot_standby = on
primary_conninfo = 'host=10.200.254.1 port=5432 user=replicator password=ReplicaSecurePass2026!'
EOF

systemctl start postgresql

# Configure shared storage
apt install -y nfs-common
mkdir -p /var/wab/recorded
cat >> /etc/fstab << 'EOF'
10.200.1.50:/wallix/recordings  /var/wab/recorded  nfs4  defaults,_netdev,hard,intr  0  0
EOF
mount -a
chown -R wab:wab /var/wab/recorded

# Install license
cp /path/to/license.key /etc/opt/wab/license.key
chmod 640 /etc/opt/wab/license.key
chown root:wab /etc/opt/wab/license.key
```

---

## HA Cluster Configuration

### Configure Pacemaker Cluster

```bash
# On both nodes
apt install -y pacemaker corosync pcs
echo "hacluster:ClusterSecurePass2026!" | chpasswd
systemctl enable pcsd
systemctl start pcsd

# From Node 1 - Create cluster
pcs host auth wallix-b1-hb wallix-b2-hb -u hacluster -p 'ClusterSecurePass2026!'
pcs cluster setup wallix-site-b wallix-b1-hb wallix-b2-hb
pcs cluster start --all
pcs cluster enable --all

# Configure cluster resources
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore

# Virtual IP
pcs resource create wallix-vip ocf:heartbeat:IPaddr2 \
    ip=10.200.1.100 \
    cidr_netmask=24 \
    nic=eth0 \
    op monitor interval=10s

# WALLIX service
pcs resource create wallix-service systemd:wabengine \
    op monitor interval=30s \
    op start timeout=60s \
    op stop timeout=60s

# Constraints
pcs constraint colocation add wallix-service with wallix-vip INFINITY
pcs constraint order wallix-vip then wallix-service

# Verify
pcs status
```

---

## Site Synchronization

### Configure Site B as Replica of Site A

```bash
# On Site B primary node (wallix-b1)

# Configure multi-site sync
wab-admin config-set multisite.enabled true
wab-admin config-set multisite.role secondary
wab-admin config-set multisite.primary_url https://wallix.site-a.company.com
wab-admin config-set multisite.sync_interval 300

# Generate sync API key on Site A first, then configure here
wab-admin config-set multisite.api_key '<API_KEY_FROM_SITE_A>'

# Configure what to sync
wab-admin config-set multisite.sync_users true
wab-admin config-set multisite.sync_groups true
wab-admin config-set multisite.sync_devices true
wab-admin config-set multisite.sync_authorizations true
wab-admin config-set multisite.sync_policies false  # Keep local policies

# Test connection to primary
wab-admin multisite-test

# Start initial sync
wab-admin multisite-sync --full
```

### Configure Local Overrides

```
+==============================================================================+
|                   SITE B LOCAL CONFIGURATION                                 |
+==============================================================================+

  LOCAL SETTINGS (not synced from Site A)
  =======================================

  Navigate to: Configuration > Multi-Site > Local Settings

  +------------------------------------------------------------------------+
  | Setting                    | Value                                     |
  +----------------------------+-------------------------------------------+
  | Instance Name              | WALLIX-SITE-B                             |
  | Local Admin Group          | site-b-admins                             |
  | Local Notification Email   | ot-team-b@company.com                     |
  | Local Syslog Server        | 10.200.1.5                                |
  +----------------------------+-------------------------------------------+

  --------------------------------------------------------------------------

  LOCAL TARGET DEVICES
  ====================

  Site B OT devices are defined locally (not synced):

  Navigate to: Resources > Devices > Add Local Device

  +------------------------------------------------------------------------+
  | Device Name        | IP Address      | Protocol | Zone                 |
  +--------------------+-----------------+----------+----------------------+
  | PLC-B-Line1        | 10.200.10.10    | Modbus   | OT-Zone-B            |
  | PLC-B-Line2        | 10.200.10.11    | Modbus   | OT-Zone-B            |
  | SCADA-B-Primary    | 10.200.10.50    | RDP      | OT-Zone-B            |
  | HMI-B-Station1     | 10.200.10.100   | VNC      | OT-Zone-B            |
  +--------------------+-----------------+----------+----------------------+

+==============================================================================+
```

---

## Verification

### Cluster Health

```bash
# Check cluster status
pcs status

# Expected:
# Cluster name: wallix-site-b
# Node List:
#   * Online: [ wallix-b1-hb wallix-b2-hb ]
# Resources:
#   * wallix-vip: Started wallix-b1-hb
#   * wallix-service: Started wallix-b1-hb
```

### Multi-Site Sync Status

```bash
# Check sync status
wab-admin multisite-status

# Expected output:
# Multi-Site Configuration:
#   Role: Secondary
#   Primary: https://wallix.site-a.company.com
#   Connection: OK
#   Last Sync: 2026-01-27 14:30:00
#   Sync Status: Up to date
#   Objects Synced:
#     Users: 150
#     Groups: 25
#     Devices: 500
#     Authorizations: 200

# Check sync logs
wab-admin multisite-logs --last 20
```

### Connectivity Tests

```bash
# Test connection to Site A
curl -k https://wallix.site-a.company.com/api/status

# Test local OT device connectivity
wab-admin device-check PLC-B-Line1
wab-admin device-check SCADA-B-Primary

# Test session proxy
ssh -o ProxyCommand="ssh -W %h:%p admin@10.200.1.100" testuser@10.200.10.50
```

---

**Next Step**: [04-site-c-remote.md](./04-site-c-remote.md) - Remote Site Installation
