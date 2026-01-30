# 04 - Site C Remote Installation

## Table of Contents

1. [Overview](#overview)
2. [Standalone Installation](#standalone-installation)
3. [Site Synchronization](#site-synchronization)
4. [Offline Operation Mode](#offline-operation-mode)
5. [Verification](#verification)

---

## Overview

Site C is a remote/field site running a standalone WALLIX Bastion installation optimized for limited connectivity environments.

```
+===============================================================================+
|                   SITE C ARCHITECTURE                                        |
+===============================================================================+

                        WAN / VPN
                           |
                     (Limited Bandwidth)
                           |
              +------------+------------+
              |                         |
     +--------+--------+       +--------+--------+
     |  SITE A         |       |  SITE C         |
     |  (Primary)      |       |  (Remote)       |
     |  10.100.1.100   |<----->|  10.50.1.10     |
     +-----------------+ Sync  +-----------------+
                       (Scheduled)      |
                                        |
                               +--------+--------+
                               |   LOCAL OT      |
                               |   NETWORK       |
                               |   10.50.10.0/24 |
                               +-----------------+
                                        |
                               +--------+--------+
                               |  [PLCs] [RTUs]  |
                               |  [SCADA] [HMIs] |
                               +-----------------+

  Features:
  - Standalone operation (no HA dependency)
  - Local authentication cache
  - Scheduled sync (off-peak hours)
  - Air-gap capable mode

+===============================================================================+
```

---

## Standalone Installation

### Step 1: Base System Setup

```bash
# Connect to Site C server
ssh root@10.50.1.10

# Set hostname
hostnamectl set-hostname wallix-c1.site-c.company.com

# Update /etc/hosts
cat >> /etc/hosts << 'EOF'
# Local
10.50.1.10      wallix-c1.site-c.company.com wallix-c1 wallix.site-c.company.com

# Remote Site A (for sync when available)
10.100.1.100    wallix.site-a.company.com wallix-a-vip
EOF

# Configure network
cat > /etc/network/interfaces.d/wallix << 'EOF'
auto eth0
iface eth0 inet static
    address 10.50.1.10
    netmask 255.255.255.0
    gateway 10.50.1.1
    dns-nameservers 10.50.1.2
EOF

systemctl restart networking

# Verify connectivity to Site A (may be intermittent)
ping -c 3 10.100.1.100 || echo "Site A not reachable - will configure offline mode"
```

### Step 2: Install WALLIX Bastion

```bash
# For online installation:
curl -fsSL https://repo.wallix.com/wallix.gpg | gpg --dearmor -o /usr/share/keyrings/wallix.gpg

cat > /etc/apt/sources.list.d/wallix.list << 'EOF'
deb [signed-by=/usr/share/keyrings/wallix.gpg] https://repo.wallix.com/bastion/12.1 bookworm main
EOF

apt update
apt install -y wallix-bastion

# For offline/air-gapped installation:
# Transfer packages manually and install:
# dpkg -i /path/to/wallix-bastion-12.1.1.deb
# apt -f install
```

### Step 3: Configure Local Database

```bash
# Standalone mode uses local MariaDB
# Optimize for smaller deployment

cat >> /etc/mariadb/16/main/mariadb.conf << 'EOF'

# Standalone optimization
shared_buffers = 2GB
effective_cache_size = 6GB
maintenance_work_mem = 512MB
max_connections = 100
checkpoint_completion_target = 0.9
wal_buffers = 16MB
random_page_cost = 1.1
EOF

systemctl restart mariadb
```

### Step 4: Configure Local Storage

```bash
# Create local recording storage
mkdir -p /var/wab/recorded
chown -R wab:wab /var/wab/recorded

# Configure log rotation for limited storage
cat > /etc/logrotate.d/wallix << 'EOF'
/var/log/wab/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 wab wab
}

/var/wab/recorded/*.wab {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    maxsize 100M
}
EOF

# Configure recording cleanup (keep 90 days)
cat > /etc/cron.daily/wallix-cleanup << 'EOF'
#!/bin/bash
find /var/wab/recorded -name "*.wab" -mtime +90 -delete
find /var/log/wab -name "*.log.*.gz" -mtime +30 -delete
EOF
chmod +x /etc/cron.daily/wallix-cleanup
```

### Step 5: Install License

```bash
cp /path/to/license.key /etc/opt/wab/license.key
chmod 640 /etc/opt/wab/license.key
chown root:wab /etc/opt/wab/license.key

wab-admin license-check
```

---

## Site Synchronization

### Configure Scheduled Sync

```bash
# Configure multi-site with offline-capable settings
wab-admin config-set multisite.enabled true
wab-admin config-set multisite.role secondary
wab-admin config-set multisite.primary_url https://wallix.site-a.company.com
wab-admin config-set multisite.api_key '<API_KEY_FROM_SITE_A>'

# Configure for limited bandwidth
wab-admin config-set multisite.sync_interval 3600          # Hourly when online
wab-admin config-set multisite.offline_mode true           # Enable offline operation
wab-admin config-set multisite.cache_credentials true      # Cache for offline auth
wab-admin config-set multisite.cache_ttl 86400             # 24-hour cache validity

# Configure sync schedule (off-peak hours)
wab-admin config-set multisite.sync_schedule "0 2 * * *"   # 2 AM daily

# Configure bandwidth limits
wab-admin config-set multisite.bandwidth_limit 1024        # 1 Mbps max
wab-admin config-set multisite.compression true
```

### Configure Local Authentication Cache

```bash
# Enable local credential caching for offline operation
wab-admin config-set auth.local_cache.enabled true
wab-admin config-set auth.local_cache.ttl 86400            # 24 hours
wab-admin config-set auth.local_cache.max_entries 500
wab-admin config-set auth.local_cache.encryption true

# Configure fallback authentication
wab-admin config-set auth.fallback.enabled true
wab-admin config-set auth.fallback.local_admins true       # Always allow local admins
```

### Recording Replication

```bash
# Configure recording sync to Site A (during maintenance windows)
cat > /etc/cron.d/wallix-recording-sync << 'EOF'
# Sync recordings to Site A every Sunday at 3 AM
0 3 * * 0 root /opt/wab/scripts/sync-recordings.sh >> /var/log/wab/recording-sync.log 2>&1
EOF

# Create sync script
cat > /opt/wab/scripts/sync-recordings.sh << 'EOF'
#!/bin/bash
# Sync recordings to Site A

SITE_A="wallix.site-a.company.com"
REMOTE_PATH="/var/wab/recorded/site-c"
LOCAL_PATH="/var/wab/recorded"

# Check connectivity
if ping -c 1 $SITE_A > /dev/null 2>&1; then
    echo "$(date): Starting recording sync to Site A"

    rsync -avz --progress --bwlimit=512 \
        --include='*.wab' \
        --exclude='*' \
        $LOCAL_PATH/ \
        wab-sync@$SITE_A:$REMOTE_PATH/

    if [ $? -eq 0 ]; then
        echo "$(date): Recording sync completed successfully"
    else
        echo "$(date): Recording sync failed"
        exit 1
    fi
else
    echo "$(date): Site A not reachable, skipping sync"
    exit 0
fi
EOF
chmod +x /opt/wab/scripts/sync-recordings.sh
```

---

## Offline Operation Mode

### Air-Gap Configuration

```
+===============================================================================+
|                   AIR-GAP / OFFLINE CONFIGURATION                            |
+===============================================================================+

  ENABLE AIR-GAP MODE
  ===================

  For sites with no external connectivity:

  wab-admin config-set airgap.enabled true
  wab-admin config-set airgap.local_auth_only true
  wab-admin config-set airgap.disable_external_checks true

  --------------------------------------------------------------------------

  LOCAL USER MANAGEMENT
  =====================

  Create local users when LDAP is unavailable:

  wab-admin user-create \
      --username "ot-operator1" \
      --display-name "OT Operator 1" \
      --email "operator1@site-c.local" \
      --password-prompt \
      --groups "ot-operators" \
      --mfa-type "totp"

  --------------------------------------------------------------------------

  LOCAL DEVICE DEFINITIONS
  ========================

  Define all OT devices locally:

  wab-admin device-create \
      --name "PLC-C-Line1" \
      --host "10.50.10.10" \
      --protocol "modbus" \
      --port 502 \
      --zone "OT-Zone-C"

  wab-admin device-create \
      --name "SCADA-C-Primary" \
      --host "10.50.10.50" \
      --protocol "rdp" \
      --port 3389 \
      --zone "OT-Zone-C"

  --------------------------------------------------------------------------

  MANUAL CONFIGURATION IMPORT
  ===========================

  For air-gapped sites, export config from Site A and import manually:

  # On Site A:
  wab-admin export-config --output /tmp/site-a-config.wab.enc --encrypt

  # Transfer file via secure media to Site C

  # On Site C:
  wab-admin import-config --input /media/usb/site-a-config.wab.enc --decrypt

+===============================================================================+
```

### Offline Authentication Flow

```
+===============================================================================+
|                   OFFLINE AUTHENTICATION FLOW                                |
+===============================================================================+

  When Site C cannot reach Site A or LDAP:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   USER LOGIN                                                           |
  |       |                                                                |
  |       v                                                                |
  |   +-------------------+                                                |
  |   | Check Local Cache |                                                |
  |   +-------------------+                                                |
  |       |                                                                |
  |       +-- Cache Hit --> Validate cached credentials --> GRANT ACCESS  |
  |       |                                                                |
  |       +-- Cache Miss                                                   |
  |             |                                                          |
  |             v                                                          |
  |       +-------------------+                                            |
  |       | Try Remote Auth   |                                            |
  |       | (Site A / LDAP)   |                                            |
  |       +-------------------+                                            |
  |             |                                                          |
  |             +-- Success --> Update cache --> GRANT ACCESS              |
  |             |                                                          |
  |             +-- Timeout/Fail                                           |
  |                   |                                                    |
  |                   v                                                    |
  |             +-------------------+                                      |
  |             | Check Local Users |                                      |
  |             +-------------------+                                      |
  |                   |                                                    |
  |                   +-- Found --> GRANT ACCESS                           |
  |                   |                                                    |
  |                   +-- Not Found --> DENY ACCESS                        |
  |                                                                        |
  +------------------------------------------------------------------------+

  Cached Credentials:
  - Username/password hash (Argon2ID)
  - Group memberships
  - Authorization rules
  - MFA seed (encrypted)
  - TTL: 24 hours (configurable)

+===============================================================================+
```

---

## Verification

### System Health

```bash
# Check WALLIX services
systemctl status wabengine
systemctl status wab-webui

# Check license
wab-admin license-check

# Check health
wab-admin health-check

# Expected output:
# [OK] Database connection
# [OK] License valid
# [OK] SSL certificate valid
# [OK] Disk space sufficient
# [OK] Recording storage accessible
# [WARN] Multi-site primary unreachable (offline mode active)
```

### Offline Mode Verification

```bash
# Check offline mode status
wab-admin multisite-status

# Expected output (when offline):
# Multi-Site Configuration:
#   Role: Secondary
#   Primary: https://wallix.site-a.company.com
#   Connection: OFFLINE
#   Offline Mode: Active
#   Last Sync: 2026-01-26 02:00:00
#   Cache Status: Valid (expires in 22 hours)
#   Cached Objects:
#     Users: 50
#     Groups: 10
#     Devices: 200
#     Authorizations: 100

# Verify cached authentication works
wab-admin auth-test --user ot-operator1 --cached
```

### OT Device Connectivity

```bash
# Test OT device connectivity
wab-admin device-check PLC-C-Line1
wab-admin device-check SCADA-C-Primary

# Expected output:
# Device: PLC-C-Line1
#   Host: 10.50.10.10
#   Protocol: Modbus TCP
#   Port: 502
#   Status: Reachable
#   Response Time: 5ms

# Test session proxy
ssh -o ProxyCommand="ssh -W %h:%p admin@10.50.1.10" operator@10.50.10.50
```

---

**Next Step**: [05-multi-site-sync.md](./05-multi-site-sync.md) - Multi-Site Synchronization
