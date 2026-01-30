# WALLIX Bastion 12.x - Complete Installation HOWTO

## Table of Contents

1. [Introduction](#introduction)
2. [Project Planning](#project-planning)
3. [Phase 1: Infrastructure Preparation](#phase-1-infrastructure-preparation)
4. [Phase 2: Site A Primary Installation](#phase-2-site-a-primary-installation)
5. [Phase 3: Site B Secondary Installation](#phase-3-site-b-secondary-installation)
6. [Phase 4: Site C Remote Installation](#phase-4-site-c-remote-installation)
7. [Phase 5: Multi-Site Synchronization](#phase-5-multi-site-synchronization)
8. [Phase 6: OT Network Integration](#phase-6-ot-network-integration)
9. [Phase 7: Security Hardening](#phase-7-security-hardening)
10. [Phase 8: Validation and Go-Live](#phase-8-validation-and-go-live)
11. [Post-Installation Operations](#post-installation-operations)
12. [Troubleshooting Reference](#troubleshooting-reference)

---

## Introduction

### Purpose of This Guide

This HOWTO provides a complete, step-by-step walkthrough for deploying WALLIX Bastion 12.x in a production OT (Operational Technology) environment with three interconnected sites. Unlike the reference documentation, this guide follows a strict chronological order and includes every command, configuration, and verification step.

### Who Should Use This Guide

- **Infrastructure Engineers** - Server provisioning and networking
- **Security Engineers** - PAM deployment and hardening
- **OT Engineers** - Industrial protocol integration
- **System Administrators** - Day-to-day operations

### Time Estimates

| Phase | Duration | Resources Required |
|-------|----------|-------------------|
| Phase 1: Preparation | 5 days | Infrastructure team |
| Phase 2: Site A | 5 days | 2 engineers |
| Phase 3: Site B | 3 days | 2 engineers |
| Phase 4: Site C | 2 days | 1 engineer |
| Phase 5: Multi-Site | 3 days | 1 engineer |
| Phase 6: OT Integration | 5 days | OT + Security teams |
| Phase 7: Security | 3 days | Security team |
| Phase 8: Validation | 4 days | All teams |
| **Total** | **30 days** | |

### Prerequisites Checklist

Before starting, ensure you have:

```
[ ] WALLIX Bastion 12.x license file(s)
[ ] SSL certificates (or plan for Let's Encrypt)
[ ] Network diagrams for all three sites
[ ] Firewall change requests approved
[ ] DNS records planned
[ ] Shared storage provisioned (NFS/iSCSI)
[ ] VM resources allocated
[ ] VPN/MPLS connectivity between sites verified
[ ] LDAP/AD service account credentials
[ ] Emergency access procedures documented
```

---

## Project Planning

### Architecture Decision Record

Before installation, document these decisions:

```
+===============================================================================+
|                   ARCHITECTURE DECISION RECORD                               |
+===============================================================================+

  1. HIGH AVAILABILITY MODEL
  ==========================

  Decision: Active-Active (Site A) / Active-Passive (Site B) / Standalone (Site C)

  Rationale:
  - Site A: High user load, requires zero-downtime maintenance
  - Site B: Moderate load, cost optimization with passive node
  - Site C: Remote location, limited bandwidth, offline capability needed

  --------------------------------------------------------------------------

  2. DATABASE STRATEGY
  ====================

  Decision: MariaDB 15 with streaming replication

  Configuration per site:
  - Site A: Primary + Synchronous Standby (zero data loss)
  - Site B: Primary + Asynchronous Standby (performance priority)
  - Site C: Standalone with daily backups

  --------------------------------------------------------------------------

  3. STORAGE ARCHITECTURE
  =======================

  Decision: Shared NFS for Sites A/B, Local storage for Site C

  Recording retention:
  - Site A: 1 year (compliance requirement)
  - Site B: 6 months
  - Site C: 90 days (replicated to Site A weekly)

  --------------------------------------------------------------------------

  4. AUTHENTICATION STRATEGY
  ==========================

  Decision: LDAP primary + OIDC for SSO + Local fallback

  Flow:
  1. User attempts login
  2. OIDC redirect (if configured)
  3. LDAP authentication
  4. MFA validation (TOTP)
  5. Local cache update (for offline)

  --------------------------------------------------------------------------

  5. NETWORK SEGMENTATION
  =======================

  Decision: IEC 62443 zone model

  Zones:
  - Enterprise (Level 4-5): Corporate users
  - OT DMZ (Level 3.5): WALLIX Bastion location
  - Operations (Level 3): SCADA, Historians
  - Control (Level 2): HMIs, Control servers
  - Field (Level 0-1): PLCs, RTUs, Safety systems

+===============================================================================+
```

### IP Address Planning

Complete this table before starting:

```
+===============================================================================+
|                   IP ADDRESS ASSIGNMENT SHEET                                |
+===============================================================================+

  SITE A - PRIMARY (10.100.0.0/16)
  ================================

  Management Network (10.100.1.0/24):
  +------------------------------------------------------------------------+
  | Hostname              | IP Address    | Purpose          | MAC Address |
  +-----------------------+---------------+------------------+-------------|
  | wallix-a1             | 10.100.1.10   | Primary node     |             |
  | wallix-a2             | 10.100.1.11   | Secondary node   |             |
  | wallix-vip            | 10.100.1.100  | Virtual IP       | N/A         |
  | wallix-db-vip         | 10.100.1.101  | Database VIP     | N/A         |
  +-----------------------+---------------+------------------+-------------|

  HA Heartbeat Network (10.100.254.0/30):
  +------------------------------------------------------------------------+
  | Hostname              | IP Address    | Purpose          | Interface   |
  +-----------------------+---------------+------------------+-------------|
  | wallix-a1-hb          | 10.100.254.1  | Cluster heartbeat| eth1        |
  | wallix-a2-hb          | 10.100.254.2  | Cluster heartbeat| eth1        |
  +-----------------------+---------------+------------------+-------------|

  OT DMZ Network (10.100.10.0/24):
  +------------------------------------------------------------------------+
  | Hostname              | IP Address    | Purpose          | Notes       |
  +-----------------------+---------------+------------------+-------------|
  | wallix-ot-a           | 10.100.10.5   | OT proxy interface|            |
  +-----------------------+---------------+------------------+-------------|

  Infrastructure Services:
  +------------------------------------------------------------------------+
  | Service               | IP Address    | Port             | Notes       |
  +-----------------------+---------------+------------------+-------------|
  | NFS Server            | 10.100.1.50   | 2049             | Recordings  |
  | DNS Primary           | 10.100.1.2    | 53               |             |
  | DNS Secondary         | 10.100.1.3    | 53               |             |
  | NTP Server            | 10.100.1.4    | 123              |             |
  | LDAP/AD               | 10.100.1.20   | 636              | LDAPS       |
  | Syslog/SIEM           | 10.100.1.5    | 514              | TCP+TLS     |
  | SMTP Relay            | 10.100.1.6    | 587              | STARTTLS    |
  +-----------------------+---------------+------------------+-------------|

  --------------------------------------------------------------------------

  SITE B - SECONDARY (10.200.0.0/16)
  ==================================

  [Complete same table structure for Site B]

  --------------------------------------------------------------------------

  SITE C - REMOTE (10.50.0.0/16)
  ==============================

  [Complete same table structure for Site C]

+===============================================================================+
```

---

## Phase 1: Infrastructure Preparation

### Day 1: Server Provisioning

#### Step 1.1: Create Virtual Machines

**Site A - Primary Cluster:**

```bash
# Using vSphere/ESXi CLI (adjust for your hypervisor)

# Node 1
govc vm.create -m 32768 -c 16 -g debian12_64Guest \
    -net.adapter vmxnet3 -net "Management Network" \
    -net.adapter vmxnet3 -net "HA Heartbeat" \
    -disk 200GB -disk 1TB \
    wallix-a1

# Node 2
govc vm.create -m 32768 -c 16 -g debian12_64Guest \
    -net.adapter vmxnet3 -net "Management Network" \
    -net.adapter vmxnet3 -net "HA Heartbeat" \
    -disk 200GB -disk 1TB \
    wallix-a2
```

**Site B - Secondary Cluster:**

```bash
# Node 1
govc vm.create -m 16384 -c 8 -g debian12_64Guest \
    -net.adapter vmxnet3 -net "Management Network" \
    -net.adapter vmxnet3 -net "HA Heartbeat" \
    -disk 200GB -disk 500GB \
    wallix-b1

# Node 2
govc vm.create -m 16384 -c 8 -g debian12_64Guest \
    -net.adapter vmxnet3 -net "Management Network" \
    -net.adapter vmxnet3 -net "HA Heartbeat" \
    -disk 200GB -disk 500GB \
    wallix-b2
```

**Site C - Standalone:**

```bash
govc vm.create -m 16384 -c 8 -g debian12_64Guest \
    -net.adapter vmxnet3 -net "Management Network" \
    -disk 200GB -disk 500GB \
    wallix-c1
```

#### Step 1.2: Install Debian 12

For each server, perform a minimal Debian 12 installation:

```
Installation choices:
- Language: English
- Location: [Your timezone region]
- Keyboard: [Your layout]
- Hostname: [As per IP plan]
- Domain: site-[a|b|c].company.com
- Root password: [Strong, document securely]
- User: wadmin (WALLIX admin user)
- Partitioning: Guided - use entire disk with LVM
  - / : 50GB
  - /var : 100GB (for logs)
  - /var/wab : Remaining space (for recordings on Site C)
  - swap: 8GB
- Software selection:
  [x] SSH server
  [x] Standard system utilities
  [ ] Desktop environment (DO NOT SELECT)
```

#### Step 1.3: Post-Installation Base Configuration

Run on ALL servers:

```bash
#!/bin/bash
# save as: /root/01-base-setup.sh

set -e

echo "=== WALLIX Base System Setup ==="

# 1. Update system
echo "[1/10] Updating system packages..."
apt update && apt upgrade -y

# 2. Install essential packages
echo "[2/10] Installing essential packages..."
apt install -y \
    openssh-server \
    curl \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    ntp \
    ntpdate \
    net-tools \
    tcpdump \
    rsync \
    vim \
    htop \
    iotop \
    sudo \
    dnsutils \
    telnet \
    mtr-tiny \
    lsof \
    strace \
    sysstat \
    logrotate \
    unzip \
    apt-transport-https

# 3. Configure timezone
echo "[3/10] Configuring timezone..."
timedatectl set-timezone Europe/Paris  # Adjust to your timezone

# 4. Configure NTP
echo "[4/10] Configuring NTP..."
cat > /etc/ntp.conf << 'NTPCONF'
# NTP Configuration for WALLIX
driftfile /var/lib/ntp/ntp.drift
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

# Local NTP servers (adjust to your environment)
server 10.100.1.4 iburst prefer
server 10.200.1.4 iburst

# Fallback to public NTP
server 0.debian.pool.ntp.org iburst
server 1.debian.pool.ntp.org iburst

# Access control
restrict -4 default kod notrap nomodify nopeer noquery limited
restrict -6 default kod notrap nomodify nopeer noquery limited
restrict 127.0.0.1
restrict ::1
NTPCONF

systemctl restart ntp
systemctl enable ntp

# 5. Configure SSH hardening
echo "[5/10] Hardening SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

cat > /etc/ssh/sshd_config << 'SSHCONF'
# SSH Server Configuration - WALLIX Bastion Host

# Network
Port 22
ListenAddress 0.0.0.0
Protocol 2

# Authentication
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Security
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Allowed users (adjust as needed)
AllowUsers wadmin root

# Ciphers (WALLIX 12.x compatible)
Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,diffie-hellman-group16-sha512
SSHCONF

systemctl restart sshd

# 6. Configure sudo
echo "[6/10] Configuring sudo..."
usermod -aG sudo wadmin

# 7. Configure sysctl for performance
echo "[7/10] Configuring kernel parameters..."
cat > /etc/sysctl.d/99-wallix.conf << 'SYSCTL'
# Network performance
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Memory
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2

# File handles
fs.file-max = 2097152
fs.nr_open = 2097152

# Security
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
SYSCTL

sysctl -p /etc/sysctl.d/99-wallix.conf

# 8. Configure limits
echo "[8/10] Configuring system limits..."
cat > /etc/security/limits.d/99-wallix.conf << 'LIMITS'
# WALLIX service limits
*               soft    nofile          65535
*               hard    nofile          65535
*               soft    nproc           65535
*               hard    nproc           65535
root            soft    nofile          65535
root            hard    nofile          65535
LIMITS

# 9. Disable unnecessary services
echo "[9/10] Disabling unnecessary services..."
systemctl disable --now avahi-daemon 2>/dev/null || true
systemctl disable --now cups 2>/dev/null || true
systemctl disable --now bluetooth 2>/dev/null || true

# 10. Final verification
echo "[10/10] Verifying configuration..."
echo ""
echo "=== System Information ==="
echo "Hostname: $(hostname -f)"
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo "Debian Version: $(cat /etc/debian_version)"
echo "Kernel: $(uname -r)"
echo "NTP Status: $(systemctl is-active ntp)"
echo "SSH Status: $(systemctl is-active sshd)"
echo ""
echo "=== Base setup complete ==="
```

### Day 2: Network Configuration

#### Step 1.4: Configure Network Interfaces

**Site A - Node 1 (wallix-a1):**

```bash
# /etc/network/interfaces

# Loopback
auto lo
iface lo inet loopback

# Management interface
auto eth0
iface eth0 inet static
    address 10.100.1.10
    netmask 255.255.255.0
    gateway 10.100.1.1
    dns-nameservers 10.100.1.2 10.100.1.3
    dns-search site-a.company.com company.com

# HA Heartbeat interface (no gateway!)
auto eth1
iface eth1 inet static
    address 10.100.254.1
    netmask 255.255.255.252
    # No gateway - direct link only
```

**Site A - Node 2 (wallix-a2):**

```bash
# /etc/network/interfaces

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.100.1.11
    netmask 255.255.255.0
    gateway 10.100.1.1
    dns-nameservers 10.100.1.2 10.100.1.3
    dns-search site-a.company.com company.com

auto eth1
iface eth1 inet static
    address 10.100.254.2
    netmask 255.255.255.252
```

#### Step 1.5: Configure /etc/hosts

On ALL Site A servers:

```bash
cat > /etc/hosts << 'HOSTS'
127.0.0.1       localhost

# Site A - Local
10.100.1.10     wallix-a1.site-a.company.com wallix-a1
10.100.1.11     wallix-a2.site-a.company.com wallix-a2
10.100.1.100    wallix.site-a.company.com wallix-vip wallix

# Site A - Heartbeat
10.100.254.1    wallix-a1-hb
10.100.254.2    wallix-a2-hb

# Site B - Remote
10.200.1.10     wallix-b1.site-b.company.com wallix-b1
10.200.1.11     wallix-b2.site-b.company.com wallix-b2
10.200.1.100    wallix.site-b.company.com wallix-b-vip

# Site C - Remote
10.50.1.10      wallix-c1.site-c.company.com wallix-c1 wallix.site-c.company.com

# Infrastructure
10.100.1.50     nfs.site-a.company.com nfs
10.100.1.20     ldap.company.com ldap
HOSTS
```

#### Step 1.6: Verify Network Connectivity

```bash
#!/bin/bash
# save as: /root/02-network-verify.sh

echo "=== Network Verification ==="

echo ""
echo "[1] Checking local interfaces..."
ip addr show

echo ""
echo "[2] Checking routing table..."
ip route show

echo ""
echo "[3] Testing gateway..."
ping -c 3 10.100.1.1

echo ""
echo "[4] Testing DNS resolution..."
nslookup wallix.site-a.company.com

echo ""
echo "[5] Testing HA heartbeat (if applicable)..."
ping -c 3 10.100.254.2 2>/dev/null || echo "Heartbeat peer not reachable (OK if this is node 2)"

echo ""
echo "[6] Testing Site B connectivity..."
ping -c 3 10.200.1.10 || echo "Site B not reachable - check VPN"

echo ""
echo "[7] Testing Site C connectivity..."
ping -c 3 10.50.1.10 || echo "Site C not reachable - check VPN"

echo ""
echo "[8] Testing NFS server..."
ping -c 3 10.100.1.50

echo ""
echo "[9] Testing LDAP server..."
ping -c 3 10.100.1.20

echo ""
echo "=== Network verification complete ==="
```

### Day 3: DNS and Certificates

#### Step 1.7: Create DNS Records

Provide this to your DNS administrator:

```
; WALLIX Bastion DNS Records
; Zone: company.com

; Site A
wallix-a1.site-a    IN  A       10.100.1.10
wallix-a2.site-a    IN  A       10.100.1.11
wallix.site-a       IN  A       10.100.1.100
wallix              IN  CNAME   wallix.site-a.company.com.

; Site B
wallix-b1.site-b    IN  A       10.200.1.10
wallix-b2.site-b    IN  A       10.200.1.11
wallix.site-b       IN  A       10.200.1.100

; Site C
wallix.site-c       IN  A       10.50.1.10

; Reverse DNS (request separately)
; 10.100.1.10 -> wallix-a1.site-a.company.com
; 10.100.1.11 -> wallix-a2.site-a.company.com
; etc.
```

#### Step 1.8: SSL Certificate Preparation

**Option A: Commercial Certificate (Recommended for Production)**

```bash
# Generate CSR on wallix-a1
mkdir -p /etc/opt/wab/ssl
cd /etc/opt/wab/ssl

# Generate private key
openssl genrsa -out wallix.key 4096

# Generate CSR
openssl req -new -key wallix.key -out wallix.csr \
    -subj "/C=FR/ST=IDF/L=Paris/O=Company/OU=IT/CN=wallix.site-a.company.com" \
    -addext "subjectAltName=DNS:wallix.site-a.company.com,DNS:wallix.company.com,DNS:wallix-a1.site-a.company.com,DNS:wallix-a2.site-a.company.com,IP:10.100.1.100,IP:10.100.1.10,IP:10.100.1.11"

# Submit CSR to CA and wait for certificate
# When received, save as wallix.crt and chain as ca-chain.crt
```

**Option B: Let's Encrypt (If publicly accessible)**

```bash
apt install certbot

certbot certonly --standalone \
    -d wallix.site-a.company.com \
    -d wallix.company.com \
    --agree-tos \
    --email admin@company.com
```

**Option C: Self-Signed (Development/Testing Only)**

```bash
#!/bin/bash
# Generate self-signed certificate for testing

mkdir -p /etc/opt/wab/ssl
cd /etc/opt/wab/ssl

# Generate CA
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
    -out ca.crt \
    -subj "/C=FR/ST=IDF/L=Paris/O=Company/OU=IT/CN=WALLIX Internal CA"

# Generate server key
openssl genrsa -out wallix.key 4096

# Create config for SAN
cat > wallix.cnf << 'EOF'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = FR
ST = IDF
L = Paris
O = Company
OU = IT
CN = wallix.site-a.company.com

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = wallix.site-a.company.com
DNS.2 = wallix.company.com
DNS.3 = wallix-a1.site-a.company.com
DNS.4 = wallix-a2.site-a.company.com
IP.1 = 10.100.1.100
IP.2 = 10.100.1.10
IP.3 = 10.100.1.11
EOF

# Generate CSR
openssl req -new -key wallix.key -out wallix.csr -config wallix.cnf

# Sign with CA
openssl x509 -req -in wallix.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out wallix.crt -days 365 -sha256 \
    -extfile wallix.cnf -extensions v3_req

# Verify
openssl verify -CAfile ca.crt wallix.crt

# Set permissions
chmod 600 wallix.key
chmod 644 wallix.crt ca.crt

echo "Certificates generated in /etc/opt/wab/ssl/"
ls -la /etc/opt/wab/ssl/
```

### Day 4: Shared Storage Configuration

#### Step 1.9: NFS Server Setup (on NFS server, not WALLIX)

```bash
# On NFS server (10.100.1.50)
apt install nfs-kernel-server

# Create export directory
mkdir -p /export/wallix/recordings
mkdir -p /export/wallix/backups
chown -R nobody:nogroup /export/wallix

# Configure exports
cat >> /etc/exports << 'EOF'
/export/wallix/recordings  10.100.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/export/wallix/recordings  10.200.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/export/wallix/backups     10.100.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/export/wallix/backups     10.200.1.0/24(rw,sync,no_subtree_check,no_root_squash)
EOF

# Apply exports
exportfs -ra
systemctl restart nfs-kernel-server
```

#### Step 1.10: NFS Client Setup (on WALLIX nodes)

```bash
# On all Site A and Site B WALLIX nodes
apt install nfs-common

# Create mount points
mkdir -p /var/wab/recorded
mkdir -p /var/wab/backups

# Test mount manually
mount -t nfs4 10.100.1.50:/export/wallix/recordings /var/wab/recorded
mount -t nfs4 10.100.1.50:/export/wallix/backups /var/wab/backups

# Verify
df -h | grep nfs

# Add to fstab
cat >> /etc/fstab << 'EOF'
10.100.1.50:/export/wallix/recordings  /var/wab/recorded  nfs4  defaults,_netdev,hard,intr,timeo=600,retrans=5  0  0
10.100.1.50:/export/wallix/backups     /var/wab/backups   nfs4  defaults,_netdev,hard,intr,timeo=600,retrans=5  0  0
EOF

# Test fstab
umount /var/wab/recorded
umount /var/wab/backups
mount -a

# Verify
df -h | grep nfs
```

### Day 5: Pre-Installation Verification

#### Step 1.11: Final Pre-Installation Checklist

```bash
#!/bin/bash
# save as: /root/03-preinstall-check.sh

echo "=== WALLIX Pre-Installation Verification ==="
echo ""

ERRORS=0

# Check hostname
echo -n "[1] Hostname configured: "
if hostname -f | grep -q "company.com"; then
    echo "OK ($(hostname -f))"
else
    echo "FAIL - FQDN not set correctly"
    ERRORS=$((ERRORS+1))
fi

# Check DNS resolution
echo -n "[2] DNS resolution: "
if nslookup $(hostname -f) >/dev/null 2>&1; then
    echo "OK"
else
    echo "FAIL - Cannot resolve own hostname"
    ERRORS=$((ERRORS+1))
fi

# Check NTP sync
echo -n "[3] NTP synchronization: "
if ntpq -p | grep -q "^\*"; then
    echo "OK"
else
    echo "WARN - NTP not synchronized"
fi

# Check disk space
echo -n "[4] Disk space (/ > 20GB free): "
ROOT_FREE=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
if [ "$ROOT_FREE" -gt 20 ]; then
    echo "OK (${ROOT_FREE}GB free)"
else
    echo "FAIL - Only ${ROOT_FREE}GB free"
    ERRORS=$((ERRORS+1))
fi

# Check memory
echo -n "[5] Memory (>= 8GB): "
MEM_GB=$(free -g | awk '/^Mem:/ {print $2}')
if [ "$MEM_GB" -ge 8 ]; then
    echo "OK (${MEM_GB}GB)"
else
    echo "FAIL - Only ${MEM_GB}GB"
    ERRORS=$((ERRORS+1))
fi

# Check NFS mount (if applicable)
echo -n "[6] NFS recordings mount: "
if mountpoint -q /var/wab/recorded 2>/dev/null; then
    echo "OK"
elif [ -d /var/wab/recorded ]; then
    echo "WARN - Directory exists but not mounted (OK for Site C)"
else
    echo "FAIL - Mount point missing"
    ERRORS=$((ERRORS+1))
fi

# Check heartbeat interface (for HA nodes)
echo -n "[7] Heartbeat interface: "
if ip addr show eth1 2>/dev/null | grep -q "10.100.254"; then
    echo "OK"
else
    echo "N/A - Single node or Site C"
fi

# Check SSL certificates
echo -n "[8] SSL certificates: "
if [ -f /etc/opt/wab/ssl/wallix.crt ] && [ -f /etc/opt/wab/ssl/wallix.key ]; then
    echo "OK"
else
    echo "WARN - Not found (will use self-signed during install)"
fi

# Check internet connectivity (for package download)
echo -n "[9] Internet connectivity: "
if curl -s --connect-timeout 5 https://repo.wallix.com >/dev/null; then
    echo "OK"
else
    echo "FAIL - Cannot reach WALLIX repository"
    ERRORS=$((ERRORS+1))
fi

# Check LDAP connectivity
echo -n "[10] LDAP server reachable: "
if nc -z -w5 10.100.1.20 636 2>/dev/null; then
    echo "OK"
else
    echo "WARN - LDAP not reachable (configure later)"
fi

echo ""
echo "=== Verification Complete ==="
echo "Errors: $ERRORS"

if [ $ERRORS -gt 0 ]; then
    echo "Please fix the errors above before proceeding."
    exit 1
else
    echo "System is ready for WALLIX installation."
    exit 0
fi
```

---

## Phase 2: Site A Primary Installation

### Day 1: Node 1 - WALLIX Installation

#### Step 2.1: Add WALLIX Repository

```bash
# On wallix-a1

# Import WALLIX GPG key
curl -fsSL https://repo.wallix.com/wallix.gpg | gpg --dearmor -o /usr/share/keyrings/wallix.gpg

# Add repository
cat > /etc/apt/sources.list.d/wallix.list << 'EOF'
deb [signed-by=/usr/share/keyrings/wallix.gpg] https://repo.wallix.com/bastion/12.1 bookworm main
EOF

# Update package list
apt update

# Verify WALLIX packages available
apt-cache search wallix
```

#### Step 2.2: Install WALLIX Bastion

```bash
# Install WALLIX Bastion
apt install -y wallix-bastion

# The installer will prompt for:
# 1. Admin password - USE STRONG PASSWORD, DOCUMENT SECURELY
# 2. License file - Provide path or skip for evaluation
# 3. SSL certificate - Use prepared cert or accept self-signed

# Wait for installation to complete (5-10 minutes)
```

#### Step 2.3: Install License

```bash
# Copy license file
cp /path/to/wallix-license.key /etc/opt/wab/license.key
chmod 640 /etc/opt/wab/license.key
chown root:wab /etc/opt/wab/license.key

# Verify license
wab-admin license-check

# Expected output:
# License Status: Valid
# License Type: Enterprise
# Expiration: 2027-01-15
# Max Concurrent Users: 100
# Max Targets: Unlimited
# Features: HA, Recording, Password Management, Session Audit
```

#### Step 2.4: Install SSL Certificate

```bash
# If using pre-generated certificates
wab-admin ssl-install \
    --cert /etc/opt/wab/ssl/wallix.crt \
    --key /etc/opt/wab/ssl/wallix.key \
    --chain /etc/opt/wab/ssl/ca-chain.crt

# Verify
wab-admin ssl-verify

# Restart services
systemctl restart wabengine
systemctl restart nginx
```

#### Step 2.5: Configure MariaDB for Replication

```bash
# Edit MariaDB configuration
cat >> /etc/mariadb/15/main/mariadb.conf << 'EOF'

# =============================================================================
# WALLIX HA Replication Configuration
# =============================================================================

# Connection Settings
listen_addresses = '*'
port = 3306
max_connections = 500

# Replication
wal_level = replica
max_wal_senders = 10
wal_keep_size = 1GB
hot_standby = on
synchronous_commit = on
synchronous_standby_names = 'wallix_a2'

# Performance
shared_buffers = 8GB
effective_cache_size = 24GB
maintenance_work_mem = 2GB
checkpoint_completion_target = 0.9
wal_buffers = 64MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 256MB
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'mariadb-%Y-%m-%d.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
EOF

# Configure replication authentication
cat >> /etc/mariadb/15/main/pg_hba.conf << 'EOF'

# WALLIX HA Replication
host    replication     replicator      10.100.254.2/32         scram-sha-256
host    replication     replicator      10.100.1.11/32          scram-sha-256
host    all             all             10.100.1.0/24           scram-sha-256
host    all             all             10.100.254.0/30         scram-sha-256
EOF

# Create replication user
sudo mysql << 'SQL'
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'ReplicaSecurePass2026!';
ALTER ROLE replicator SET synchronous_commit = on;
SQL

# Restart MariaDB
systemctl restart mariadb

# Verify
sudo mysql -c "SELECT * FROM SHOW SLAVE STATUS;"
```

### Day 2: Node 2 - Installation and Replication

#### Step 2.6: Install WALLIX on Node 2

```bash
# On wallix-a2

# Add repository (same as Node 1)
curl -fsSL https://repo.wallix.com/wallix.gpg | gpg --dearmor -o /usr/share/keyrings/wallix.gpg
cat > /etc/apt/sources.list.d/wallix.list << 'EOF'
deb [signed-by=/usr/share/keyrings/wallix.gpg] https://repo.wallix.com/bastion/12.1 bookworm main
EOF
apt update

# Install WALLIX
apt install -y wallix-bastion

# Copy license from Node 1
scp root@wallix-a1:/etc/opt/wab/license.key /etc/opt/wab/license.key
chmod 640 /etc/opt/wab/license.key
chown root:wab /etc/opt/wab/license.key

# Copy SSL certificates from Node 1
scp -r root@wallix-a1:/etc/opt/wab/ssl/* /etc/opt/wab/ssl/
wab-admin ssl-install \
    --cert /etc/opt/wab/ssl/wallix.crt \
    --key /etc/opt/wab/ssl/wallix.key \
    --chain /etc/opt/wab/ssl/ca-chain.crt
```

#### Step 2.7: Configure MariaDB as Standby

```bash
# On wallix-a2

# Stop MariaDB
systemctl stop mariadb

# Clear existing data
rm -rf /var/lib/mariadb/15/main/*

# Take base backup from primary
mariabackup \
    -h 10.100.254.1 \
    -U replicator \
    -D /var/lib/mariadb/15/main \
    -P -R -X stream -S wallix_a2_slot

# The -R flag creates standby.signal and configures primary_conninfo

# Verify standby configuration
cat /var/lib/mariadb/15/main/mariadb.auto.conf
# Should contain: primary_conninfo = 'host=10.100.254.1 port=3306 user=replicator ...'

# Add standby settings
cat >> /etc/mariadb/15/main/mariadb.conf << 'EOF'

# Standby Settings
hot_standby = on
hot_standby_feedback = on
primary_conninfo = 'host=10.100.254.1 port=3306 user=replicator password=ReplicaSecurePass2026! application_name=wallix_a2'
primary_slot_name = 'wallix_a2_slot'
EOF

# Start MariaDB
systemctl start mariadb

# Verify replication
sudo mysql -c "SELECT pg_is_in_recovery();"
# Should return: t (true, meaning it's a standby)

# On Node 1, verify replication status
sudo mysql -c "SELECT client_addr, state, sync_state, sent_lsn, replay_lsn FROM SHOW SLAVE STATUS;"
```

### Day 3: HA Cluster Setup

#### Step 2.8: Install Pacemaker/Corosync

```bash
# On BOTH nodes
apt install -y pacemaker corosync pcs resource-agents fence-agents

# Set hacluster password (SAME on both nodes)
echo "hacluster:HAClusterSecure2026!" | chpasswd

# Enable and start pcsd
systemctl enable pcsd
systemctl start pcsd
```

#### Step 2.9: Create Cluster

```bash
# On Node 1 ONLY

# Authenticate nodes
pcs host auth wallix-a1-hb wallix-a2-hb -u hacluster -p 'HAClusterSecure2026!'

# Create cluster
pcs cluster setup wallix-site-a wallix-a1-hb wallix-a2-hb \
    --transport udp \
    --force

# Start cluster
pcs cluster start --all
pcs cluster enable --all

# Wait for cluster to stabilize
sleep 30

# Check cluster status
pcs status
```

#### Step 2.10: Configure Cluster Resources

```bash
# On Node 1

# Set cluster properties
pcs property set stonith-enabled=false  # Enable in production with fencing!
pcs property set no-quorum-policy=ignore
pcs property set default-resource-stickiness=100

# Create Virtual IP resource
pcs resource create wallix-vip ocf:heartbeat:IPaddr2 \
    ip=10.100.1.100 \
    cidr_netmask=24 \
    nic=eth0 \
    op monitor interval=10s timeout=20s \
    op start timeout=20s \
    op stop timeout=20s

# Create MariaDB resource
pcs resource create pgsql ocf:heartbeat:pgsql \
    pgctl="/usr/lib/mariadb/15/bin/pg_ctl" \
    pgdata="/var/lib/mariadb/15/main" \
    config="/etc/mariadb/15/main/mariadb.conf" \
    logfile="/var/log/mariadb/mariadb-15-main.log" \
    rep_mode="sync" \
    node_list="wallix-a1-hb wallix-a2-hb" \
    restore_command="cp /var/lib/mariadb/15/archive/%f %p" \
    primary_conninfo_opt="keepalives_idle=60 keepalives_interval=5 keepalives_count=5" \
    master_ip="10.100.1.100" \
    restart_on_promote="true" \
    op start timeout=60s \
    op stop timeout=60s \
    op promote timeout=30s \
    op demote timeout=120s \
    op monitor interval=15s timeout=10s \
    op monitor interval=10s role=Master timeout=10s \
    op notify timeout=60s \
    promotable promoted-max=1 promoted-node-max=1 clone-max=2 clone-node-max=1 notify=true

# Create WALLIX engine resource
pcs resource create wallix-engine systemd:wabengine \
    op monitor interval=30s timeout=30s \
    op start timeout=90s \
    op stop timeout=90s

# Create WALLIX web resource
pcs resource create wallix-web systemd:wab-webui \
    op monitor interval=30s timeout=30s \
    op start timeout=60s \
    op stop timeout=60s

# Group WALLIX services
pcs resource group add wallix-services wallix-engine wallix-web

# Set constraints
# VIP must be on MariaDB master
pcs constraint colocation add wallix-vip with pgsql-clone INFINITY with-rsc-role=Master

# WALLIX services must be with VIP
pcs constraint colocation add wallix-services with wallix-vip INFINITY

# Order: MariaDB -> VIP -> WALLIX services
pcs constraint order promote pgsql-clone then start wallix-vip
pcs constraint order wallix-vip then wallix-services

# Verify configuration
pcs constraint show
pcs resource show

# Check status
pcs status
```

### Day 4: Initial Configuration

#### Step 2.11: Access Web UI

```
URL: https://10.100.1.100 (or https://wallix.site-a.company.com)
Username: admin
Password: [Set during installation]
```

#### Step 2.12: Configure System Settings

Via Web UI or CLI:

```bash
# System identification
wab-admin config-set system.name "WALLIX-SITE-A"
wab-admin config-set system.fqdn "wallix.site-a.company.com"
wab-admin config-set system.timezone "Europe/Paris"

# Session settings
wab-admin config-set session.idle_timeout 1800
wab-admin config-set session.absolute_timeout 28800
wab-admin config-set session.warning_before_timeout 300

# Recording settings
wab-admin config-set recording.enabled true
wab-admin config-set recording.ssh true
wab-admin config-set recording.rdp true
wab-admin config-set recording.vnc true
wab-admin config-set recording.compression true
wab-admin config-set recording.retention_days 365

# Audit settings
wab-admin config-set audit.enabled true
wab-admin config-set audit.log_level info
wab-admin config-set audit.retention_days 365
```

#### Step 2.13: Configure LDAP Authentication

```bash
wab-admin ldap-add \
    --name "Corporate-AD" \
    --host "ldaps://10.100.1.20:636" \
    --base-dn "DC=company,DC=com" \
    --bind-dn "CN=svc_wallix,OU=ServiceAccounts,DC=company,DC=com" \
    --bind-password "<LDAP_SERVICE_PASSWORD>" \
    --user-filter "(&(objectClass=user)(sAMAccountName=%s)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" \
    --group-filter "(&(objectClass=group)(member=%s))" \
    --user-attribute "sAMAccountName" \
    --email-attribute "mail" \
    --display-name-attribute "displayName" \
    --tls-verify true \
    --timeout 30

# Test LDAP
wab-admin ldap-test --name "Corporate-AD" --user testuser
```

#### Step 2.14: Configure Email Alerts

```bash
wab-admin config-set smtp.enabled true
wab-admin config-set smtp.host "10.100.1.6"
wab-admin config-set smtp.port 587
wab-admin config-set smtp.tls true
wab-admin config-set smtp.auth true
wab-admin config-set smtp.username "wallix-alerts"
wab-admin config-set smtp.password "<SMTP_PASSWORD>"
wab-admin config-set smtp.from "wallix-alerts@company.com"
wab-admin config-set smtp.admin_email "security-team@company.com"

# Test email
wab-admin test-email security-team@company.com
```

### Day 5: HA Verification

#### Step 2.15: Test Planned Failover

```bash
#!/bin/bash
# save as: /root/test-failover.sh

echo "=== WALLIX HA Failover Test ==="
echo ""

echo "[1] Current cluster status:"
pcs status

echo ""
echo "[2] Recording current primary node..."
PRIMARY=$(pcs status | grep "Masters:" | awk '{print $NF}' | tr -d '[]')
echo "Current primary: $PRIMARY"

echo ""
echo "[3] Current VIP location:"
ip addr show | grep "10.100.1.100" || echo "VIP not on this node"

echo ""
read -p "Press Enter to initiate failover (put $PRIMARY in standby)..."

echo ""
echo "[4] Initiating failover..."
pcs node standby $PRIMARY

echo ""
echo "[5] Waiting for failover (30 seconds)..."
sleep 30

echo ""
echo "[6] Post-failover status:"
pcs status

echo ""
echo "[7] Testing VIP accessibility..."
ping -c 3 10.100.1.100

echo ""
echo "[8] Testing WALLIX API..."
curl -k -s https://10.100.1.100/api/status | head -5

echo ""
echo "[9] Testing Web UI..."
curl -k -s -o /dev/null -w "%{http_code}" https://10.100.1.100/
echo ""

echo ""
read -p "Press Enter to restore $PRIMARY..."

echo ""
echo "[10] Restoring node..."
pcs node unstandby $PRIMARY

echo ""
echo "[11] Final status:"
sleep 30
pcs status

echo ""
echo "=== Failover test complete ==="
```

---

## Phase 3: Site B Secondary Installation

[Continue with similar detailed steps for Site B...]

### Quick Reference for Site B

Site B follows the same process as Site A with these differences:

| Setting | Site A | Site B |
|---------|--------|--------|
| Management IPs | 10.100.1.10, .11 | 10.200.1.10, .11 |
| VIP | 10.100.1.100 | 10.200.1.100 |
| Heartbeat IPs | 10.100.254.1, .2 | 10.200.254.1, .2 |
| Cluster Name | wallix-site-a | wallix-site-b |
| NFS Server | 10.100.1.50 (local) | 10.200.1.50 (local) or Site A |
| Multi-site Role | Primary | Secondary |

---

## Phase 4: Site C Remote Installation

[Similar detailed steps for Site C standalone installation...]

---

## Phase 5: Multi-Site Synchronization

### Step 5.1: Generate API Keys on Site A

```bash
# On Site A
wab-admin multisite-generate-key --site site-b --name "Site B - Secondary Plant"
# Save output: sk_live_site-b_xxxxxxxxxxxxxxxxxxxxxxxxxx

wab-admin multisite-generate-key --site site-c --name "Site C - Remote Field"
# Save output: sk_live_site-c_xxxxxxxxxxxxxxxxxxxxxxxxxx

# List all keys
wab-admin multisite-list-keys
```

### Step 5.2: Configure Site B as Secondary

```bash
# On Site B
wab-admin config-set multisite.enabled true
wab-admin config-set multisite.role secondary
wab-admin config-set multisite.instance_id site-b
wab-admin config-set multisite.primary_url "https://wallix.site-a.company.com"
wab-admin config-set multisite.api_key "sk_live_site-b_xxxxxxxxxxxxxxxxxxxxxxxxxx"
wab-admin config-set multisite.sync_interval 300
wab-admin config-set multisite.sync_on_startup true

# Test connection
wab-admin multisite-test

# Initial sync
wab-admin multisite-sync --full

# Verify
wab-admin multisite-status
```

### Step 5.3: Configure Site C with Offline Capability

```bash
# On Site C
wab-admin config-set multisite.enabled true
wab-admin config-set multisite.role secondary
wab-admin config-set multisite.instance_id site-c
wab-admin config-set multisite.primary_url "https://wallix.site-a.company.com"
wab-admin config-set multisite.api_key "sk_live_site-c_xxxxxxxxxxxxxxxxxxxxxxxxxx"
wab-admin config-set multisite.sync_interval 3600
wab-admin config-set multisite.offline_mode true
wab-admin config-set multisite.cache_enabled true
wab-admin config-set multisite.cache_ttl 86400
wab-admin config-set multisite.compression true
wab-admin config-set multisite.delta_sync true
wab-admin config-set multisite.sync_schedule "0 2 * * *"

# Test and sync
wab-admin multisite-test
wab-admin multisite-sync --full
```

---

## Phase 6: OT Network Integration

[Detailed OT integration steps...]

---

## Phase 7: Security Hardening

[Detailed security hardening steps...]

---

## Phase 8: Validation and Go-Live

### Complete Validation Checklist

```bash
#!/bin/bash
# save as: /root/final-validation.sh

echo "========================================"
echo "WALLIX BASTION - FINAL VALIDATION"
echo "========================================"
echo ""

PASS=0
FAIL=0
WARN=0

check() {
    local name="$1"
    local result="$2"
    if [ "$result" = "0" ]; then
        echo "[PASS] $name"
        PASS=$((PASS+1))
    else
        echo "[FAIL] $name"
        FAIL=$((FAIL+1))
    fi
}

warn() {
    local name="$1"
    echo "[WARN] $name"
    WARN=$((WARN+1))
}

echo "=== System Health ==="
wab-admin health-check >/dev/null 2>&1
check "Health check" $?

systemctl is-active wabengine >/dev/null 2>&1
check "WALLIX Engine running" $?

systemctl is-active wab-webui >/dev/null 2>&1
check "WALLIX Web UI running" $?

echo ""
echo "=== License ==="
wab-admin license-check >/dev/null 2>&1
check "License valid" $?

echo ""
echo "=== High Availability ==="
pcs status >/dev/null 2>&1
check "Cluster healthy" $?

echo ""
echo "=== Multi-Site ==="
wab-admin multisite-test >/dev/null 2>&1 || warn "Multi-site test (may be expected if secondary)"

echo ""
echo "=== Authentication ==="
wab-admin ldap-test --name "Corporate-AD" --user testuser >/dev/null 2>&1
check "LDAP authentication" $?

echo ""
echo "=== Recording ==="
ls /var/wab/recorded/*.wab >/dev/null 2>&1 && check "Recordings present" 0 || warn "No recordings yet"

echo ""
echo "=== Security ==="
wab-admin security-audit >/dev/null 2>&1
check "Security audit" $?

echo ""
echo "========================================"
echo "RESULTS: $PASS passed, $FAIL failed, $WARN warnings"
echo "========================================"

if [ $FAIL -gt 0 ]; then
    echo "VALIDATION FAILED - Do not proceed to production"
    exit 1
else
    echo "VALIDATION PASSED - Ready for production"
    exit 0
fi
```

---

## Post-Installation Operations

### Daily Operations Checklist

```bash
# Morning check
wab-admin health-check
pcs status
wab-admin session-list --active

# Check disk space
df -h /var/wab/recorded

# Check logs for errors
journalctl -u wabengine --since "24 hours ago" | grep -i error
```

### Weekly Operations

```bash
# Backup configuration
wab-admin backup --config --output /var/wab/backups/config-$(date +%Y%m%d).tar.gz

# Review audit logs
wab-admin audit-report --last-week --output /tmp/weekly-audit.pdf

# Check certificate expiry
wab-admin ssl-verify
```

### Monthly Operations

```bash
# Full backup
wab-admin backup --full --output /var/wab/backups/full-$(date +%Y%m%d).tar.gz

# Compliance report
wab-admin compliance-report --standard iec62443 --output /tmp/monthly-compliance.pdf

# Review user access
wab-admin user-list --inactive-days 30
```

---

## Troubleshooting Reference

### Common Issues and Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Service won't start | wabengine fails | Check `journalctl -u wabengine` |
| Database connection | "Cannot connect to database" | Verify MariaDB: `systemctl status mariadb` |
| Cluster split-brain | Both nodes think they're primary | Stop one node, verify data, restart cluster |
| Sync failures | "Connection refused to primary" | Check firewall, VPN, API key |
| Recording missing | Sessions not recorded | Check `/var/wab/recorded` permissions, disk space |
| Authentication fails | "LDAP bind failed" | Verify LDAP credentials, network connectivity |

### Emergency Procedures

```bash
# Emergency admin access (bypass LDAP)
wab-admin emergency-access --enable --duration 3600

# Force cluster failover
pcs resource move wallix-vip wallix-a2-hb --lifetime=PT1H

# Stop all WALLIX services
systemctl stop wabengine wab-webui

# Start in maintenance mode
wab-admin maintenance-mode --enable
```

---

## Support Contacts

| Issue Type | Contact |
|------------|---------|
| WALLIX Product Support | https://support.wallix.com |
| License Issues | license@wallix.com |
| Security Vulnerabilities | security@wallix.com |
| Internal IT Support | [Your internal contact] |
| OT Team | [Your OT team contact] |

---

**Document Version**: 2.0
**WALLIX Version**: 12.1.x
**Last Updated**: January 2026
