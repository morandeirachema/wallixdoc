# 02 - Site A Primary Installation

## Table of Contents

1. [Overview](#overview)
2. [Node 1 Installation](#node-1-installation)
3. [Node 2 Installation](#node-2-installation)
4. [HA Cluster Configuration](#ha-cluster-configuration)
5. [Initial Configuration](#initial-configuration)
6. [Verification](#verification)

---

## Overview

Site A is the primary headquarters installation running a full High Availability cluster.

```
+===============================================================================+
|                   SITE A ARCHITECTURE                                        |
+===============================================================================+

                    +------------------+
                    |   LOAD BALANCER  |
                    |   (Optional)     |
                    +--------+---------+
                             |
              +--------------+--------------+
              |                             |
     +--------+--------+           +--------+--------+
     |  WALLIX-A1      |           |  WALLIX-A2      |
     |  (Primary)      |           |  (Secondary)    |
     |                 |           |                 |
     | 10.100.1.10     |           | 10.100.1.11     |
     +--------+--------+           +--------+--------+
              |      Heartbeat Network      |
              +----------10.100.254.0/30----+
              |                             |
     +--------+--------+           +--------+--------+
     |   PostgreSQL    |<--------->|   PostgreSQL    |
     |   (Primary)     | Streaming |   (Standby)     |
     +-----------------+ Replication+-----------------+
              |                             |
              +-------------+---------------+
                            |
                   +--------+--------+
                   |  SHARED STORAGE |
                   |  (Recordings)   |
                   |  NFS: 10.100.1.50:/wallix |
                   +-----------------+

  Virtual IP: 10.100.1.100 (wallix.site-a.company.com)

+===============================================================================+
```

---

## Node 1 Installation

### Step 1: Base System Preparation

```bash
# Connect to Node 1
ssh root@10.100.1.10

# Set hostname
hostnamectl set-hostname wallix-a1.site-a.company.com

# Update /etc/hosts
cat >> /etc/hosts << 'EOF'
10.100.1.10     wallix-a1.site-a.company.com wallix-a1
10.100.1.11     wallix-a2.site-a.company.com wallix-a2
10.100.1.100    wallix.site-a.company.com wallix-vip
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

# Apply network configuration
systemctl restart networking
```

### Step 2: Install WALLIX Bastion

```bash
# Add WALLIX repository
curl -fsSL https://repo.wallix.com/wallix.gpg | gpg --dearmor -o /usr/share/keyrings/wallix.gpg

cat > /etc/apt/sources.list.d/wallix.list << 'EOF'
deb [signed-by=/usr/share/keyrings/wallix.gpg] https://repo.wallix.com/bastion/12.1 bookworm main
EOF

# Update and install
apt update
apt install -y wallix-bastion

# The installer will prompt for:
# - Admin password (set strong password, document securely)
# - License file path
# - SSL certificate (use self-signed for now, replace later)
```

### Step 3: Configure PostgreSQL for Replication

```bash
# Edit PostgreSQL configuration for primary role
cat >> /etc/postgresql/16/main/postgresql.conf << 'EOF'

# Replication settings (Primary)
wal_level = replica
max_wal_senders = 5
wal_keep_size = 1GB
hot_standby = on
synchronous_commit = on
EOF

# Configure replication access
cat >> /etc/postgresql/16/main/pg_hba.conf << 'EOF'

# Replication
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

### Step 4: Configure Shared Storage

```bash
# Install NFS client
apt install -y nfs-common

# Create mount point
mkdir -p /var/wab/recorded

# Add NFS mount to fstab
cat >> /etc/fstab << 'EOF'
10.100.1.50:/wallix/recordings  /var/wab/recorded  nfs4  defaults,_netdev,hard,intr  0  0
EOF

# Mount the share
mount -a

# Verify mount
df -h /var/wab/recorded

# Set permissions
chown -R wab:wab /var/wab/recorded
```

### Step 5: Install License

```bash
# Copy license file
cp /path/to/license.key /etc/opt/wab/license.key
chmod 640 /etc/opt/wab/license.key
chown root:wab /etc/opt/wab/license.key

# Verify license
wab-admin license-check
```

---

## Node 2 Installation

### Step 1: Base System Preparation

```bash
# Connect to Node 2
ssh root@10.100.1.11

# Set hostname
hostnamectl set-hostname wallix-a2.site-a.company.com

# Update /etc/hosts (same as Node 1)
cat >> /etc/hosts << 'EOF'
10.100.1.10     wallix-a1.site-a.company.com wallix-a1
10.100.1.11     wallix-a2.site-a.company.com wallix-a2
10.100.1.100    wallix.site-a.company.com wallix-vip
10.100.254.1    wallix-a1-hb
10.100.254.2    wallix-a2-hb
EOF

# Configure network interfaces
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

### Step 2: Install WALLIX Bastion

```bash
# Add WALLIX repository (same as Node 1)
curl -fsSL https://repo.wallix.com/wallix.gpg | gpg --dearmor -o /usr/share/keyrings/wallix.gpg

cat > /etc/apt/sources.list.d/wallix.list << 'EOF'
deb [signed-by=/usr/share/keyrings/wallix.gpg] https://repo.wallix.com/bastion/12.1 bookworm main
EOF

apt update
apt install -y wallix-bastion
```

### Step 3: Configure PostgreSQL as Standby

```bash
# Stop PostgreSQL
systemctl stop postgresql

# Remove existing data
rm -rf /var/lib/postgresql/16/main/*

# Perform base backup from primary
sudo -u postgres pg_basebackup -h 10.100.254.1 -U replicator -D /var/lib/postgresql/16/main -P -R

# Configure standby
cat >> /etc/postgresql/16/main/postgresql.conf << 'EOF'

# Standby settings
hot_standby = on
primary_conninfo = 'host=10.100.254.1 port=5432 user=replicator password=ReplicaSecurePass2026!'
EOF

# Start PostgreSQL in standby mode
systemctl start postgresql

# Verify replication status
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"
```

### Step 4: Configure Shared Storage

```bash
# Same NFS configuration as Node 1
apt install -y nfs-common
mkdir -p /var/wab/recorded

cat >> /etc/fstab << 'EOF'
10.100.1.50:/wallix/recordings  /var/wab/recorded  nfs4  defaults,_netdev,hard,intr  0  0
EOF

mount -a
chown -R wab:wab /var/wab/recorded
```

### Step 5: Install License

```bash
# Copy same license file as Node 1
cp /path/to/license.key /etc/opt/wab/license.key
chmod 640 /etc/opt/wab/license.key
chown root:wab /etc/opt/wab/license.key
```

---

## HA Cluster Configuration

### Step 1: Install Cluster Software (Both Nodes)

```bash
# On both nodes
apt install -y pacemaker corosync pcs

# Set cluster password
echo "hacluster:ClusterSecurePass2026!" | chpasswd

# Enable and start pcsd
systemctl enable pcsd
systemctl start pcsd
```

### Step 2: Create Cluster (Node 1)

```bash
# Authenticate nodes (from Node 1)
pcs host auth wallix-a1-hb wallix-a2-hb -u hacluster -p 'ClusterSecurePass2026!'

# Create cluster
pcs cluster setup wallix-site-a wallix-a1-hb wallix-a2-hb

# Start cluster
pcs cluster start --all
pcs cluster enable --all

# Verify cluster status
pcs status
```

### Step 3: Configure Cluster Resources

```bash
# Configure cluster properties
pcs property set stonith-enabled=false  # Enable STONITH in production with proper fencing
pcs property set no-quorum-policy=ignore

# Create Virtual IP resource
pcs resource create wallix-vip ocf:heartbeat:IPaddr2 \
    ip=10.100.1.100 \
    cidr_netmask=24 \
    nic=eth0 \
    op monitor interval=10s

# Create WALLIX service resource
pcs resource create wallix-service systemd:wabengine \
    op monitor interval=30s \
    op start timeout=60s \
    op stop timeout=60s

# Create PostgreSQL promotion resource
pcs resource create pgsql-primary ocf:heartbeat:pgsql \
    pgctl="/usr/lib/postgresql/16/bin/pg_ctl" \
    pgdata="/var/lib/postgresql/16/main" \
    config="/etc/postgresql/16/main/postgresql.conf" \
    rep_mode="sync" \
    node_list="wallix-a1-hb wallix-a2-hb" \
    primary_conninfo_opt="keepalives_idle=60 keepalives_interval=5 keepalives_count=5" \
    master_ip="10.100.1.100" \
    op start timeout=60s \
    op stop timeout=60s \
    op promote timeout=60s \
    op demote timeout=60s \
    op monitor interval=10s role=Master \
    op monitor interval=30s role=Slave

# Configure resource colocation and ordering
pcs constraint colocation add wallix-service with wallix-vip INFINITY
pcs constraint colocation add wallix-vip with pgsql-primary INFINITY with-rsc-role=Master
pcs constraint order wallix-vip then wallix-service

# Verify configuration
pcs status
pcs constraint show
```

### Step 4: Test Failover

```bash
# Check current node status
pcs status

# Simulate failover (from active node)
pcs node standby wallix-a1-hb

# Verify VIP moved to Node 2
ping -c 3 10.100.1.100

# Bring Node 1 back online
pcs node unstandby wallix-a1-hb

# Verify cluster recovered
pcs status
```

---

## Initial Configuration

### Step 1: Access Web UI

```
URL: https://10.100.1.100
Username: admin
Password: (set during installation)
```

### Step 2: Configure Global Settings

```
+===============================================================================+
|                   INITIAL CONFIGURATION STEPS                                |
+===============================================================================+

  SYSTEM SETTINGS
  ===============

  1. Navigate to: Configuration > System > General

  +------------------------------------------------------------------------+
  | Setting              | Value                                           |
  +----------------------+-------------------------------------------------+
  | Instance Name        | WALLIX-SITE-A                                   |
  | FQDN                 | wallix.site-a.company.com                       |
  | Timezone             | Europe/Paris (or local)                         |
  | Session Timeout      | 30 minutes                                      |
  +----------------------+-------------------------------------------------+

  --------------------------------------------------------------------------

  SECURITY SETTINGS (12.x defaults to HIGH)
  =========================================

  2. Navigate to: Configuration > System > Security

  +------------------------------------------------------------------------+
  | Setting              | Value                                           |
  +----------------------+-------------------------------------------------+
  | Security Level       | High (default in 12.x)                          |
  | Password Min Length  | 16 (default in 12.x)                            |
  | MFA Enforcement      | Required for admins                             |
  | Session Recording    | Enabled (all protocols)                         |
  | Encryption           | AES-256-GCM                                     |
  +----------------------+-------------------------------------------------+

  --------------------------------------------------------------------------

  SSH CIPHER CONFIGURATION (12.x restricted set)
  ==============================================

  3. Navigate to: Configuration > Proxies > SSH

  Allowed Ciphers (12.x default):
  - aes256-gcm@openssh.com
  - aes128-gcm@openssh.com
  - aes256-ctr
  - aes192-ctr
  - aes128-ctr

  Key Exchange:
  - curve25519-sha256
  - curve25519-sha256@libssh.org
  - ecdh-sha2-nistp256
  - ecdh-sha2-nistp384
  - ecdh-sha2-nistp521

+===============================================================================+
```

### Step 3: Configure Authentication

```
+===============================================================================+
|                   AUTHENTICATION CONFIGURATION                               |
+===============================================================================+

  LDAP/ACTIVE DIRECTORY
  =====================

  Navigate to: Configuration > Authentication > LDAP

  +------------------------------------------------------------------------+
  | Setting              | Value                                           |
  +----------------------+-------------------------------------------------+
  | Name                 | Corporate-AD                                    |
  | Server               | ldaps://dc.company.com:636                      |
  | Base DN              | DC=company,DC=com                               |
  | Bind DN              | CN=wallix-svc,OU=Service,DC=company,DC=com      |
  | Bind Password        | <SECURE_PASSWORD>                               |
  | User Filter          | (&(objectClass=user)(sAMAccountName=%s))        |
  | Group Filter         | (&(objectClass=group)(member=%s))               |
  +----------------------+-------------------------------------------------+

  --------------------------------------------------------------------------

  OPENID CONNECT (New in 12.x)
  ============================

  Navigate to: Configuration > Authentication > OIDC

  +------------------------------------------------------------------------+
  | Setting              | Value                                           |
  +----------------------+-------------------------------------------------+
  | Enabled              | Yes                                             |
  | Provider URL         | https://login.company.com/oauth2/v2.0           |
  | Client ID            | <CLIENT_ID>                                     |
  | Client Secret        | <CLIENT_SECRET>                                 |
  | Redirect URI         | https://wallix.site-a.company.com/auth/callback |
  +----------------------+-------------------------------------------------+

  --------------------------------------------------------------------------

  MFA CONFIGURATION
  =================

  Navigate to: Configuration > Authentication > MFA

  +------------------------------------------------------------------------+
  | Setting              | Value                                           |
  +----------------------+-------------------------------------------------+
  | TOTP Enabled         | Yes                                             |
  | TOTP Required        | Administrators, OT Operators                    |
  | TOTP Issuer          | WALLIX-SITE-A                                   |
  | Recovery Codes       | Enabled (10 codes)                              |
  +----------------------+-------------------------------------------------+

+===============================================================================+
```

### Step 4: Configure Email Alerts

```bash
# Via CLI
wab-admin config-set smtp.host smtp.company.com
wab-admin config-set smtp.port 587
wab-admin config-set smtp.tls true
wab-admin config-set smtp.from wallix-alerts@company.com
wab-admin config-set smtp.auth true
wab-admin config-set smtp.username wallix-smtp
wab-admin config-set smtp.password '<SMTP_PASSWORD>'

# Test email
wab-admin test-email admin@company.com
```

---

## Verification

### Cluster Health Checks

```bash
# Check cluster status
pcs status

# Expected output:
# Cluster name: wallix-site-a
# Status of pacemakerd: active
#
# Node List:
#   * Online: [ wallix-a1-hb wallix-a2-hb ]
#
# Full List of Resources:
#   * wallix-vip    (ocf:heartbeat:IPaddr2):     Started wallix-a1-hb
#   * wallix-service (systemd:wabengine):        Started wallix-a1-hb
#   * pgsql-primary (ocf:heartbeat:pgsql):       Master wallix-a1-hb

# Check PostgreSQL replication
sudo -u postgres psql -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"

# Expected output:
#  client_addr   |   state   | sync_state
# ---------------+-----------+------------
#  10.100.254.2  | streaming | sync
```

### Service Health Checks

```bash
# Check WALLIX services
systemctl status wabengine
systemctl status wab-webui

# Check license status
wab-admin license-check

# Check system health
wab-admin health-check

# Expected output:
# [OK] Database connection
# [OK] License valid (expires: 2027-01-15)
# [OK] SSL certificate valid
# [OK] Disk space sufficient
# [OK] Recording storage accessible
# [OK] HA cluster healthy
```

### Functional Tests

```bash
# Test Web UI access
curl -k -I https://10.100.1.100/

# Test SSH proxy
ssh -o ProxyCommand="ssh -W %h:%p admin@10.100.1.100" testuser@target-server

# Test RDP proxy (from Windows)
# Connect to: wallix.site-a.company.com
# Username: domain\user@target-server

# Verify session recording
wab-admin session-list --last 10
```

---

**Next Step**: [03-site-b-secondary.md](./03-site-b-secondary.md) - Secondary Site Installation
