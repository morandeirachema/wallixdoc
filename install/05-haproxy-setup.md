# 05 - HAProxy Load Balancer Setup

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [HAProxy Architecture](#haproxy-architecture)
3. [Prerequisites](#prerequisites)
4. [Operating System Installation](#operating-system-installation)
5. [HAProxy Installation](#haproxy-installation)
6. [HAProxy Configuration](#haproxy-configuration)
7. [Keepalived Configuration](#keepalived-configuration)
8. [SSL Certificate Setup](#ssl-certificate-setup)
9. [Health Checks Configuration](#health-checks-configuration)
10. [Logging and Monitoring](#logging-and-monitoring)
11. [Failover Testing](#failover-testing)
12. [Troubleshooting](#troubleshooting)
13. [Operational Procedures](#operational-procedures)

---

## Executive Summary

This document provides comprehensive instructions for deploying and configuring HAProxy load balancers in high availability configuration for WALLIX Bastion sites. Each site requires **2 HAProxy servers** operating in **Active-Passive** mode with Keepalived VRRP for automatic failover.

### Quick Overview

| Component | Details |
|-----------|---------|
| **HAProxy Instances per Site** | 2 (Primary + Backup) |
| **HA Mode** | Active-Passive with Keepalived VRRP |
| **Failover Time** | < 3 seconds |
| **Backend Servers** | 2x WALLIX Bastion appliances per site |
| **Protocols** | HTTPS (443), SSH (22), RDP (3389), HTTP (80 redirect) |
| **SSL Termination** | Optional (pass-through mode recommended) |
| **Load Balancing Algorithm** | Roundrobin (HTTPS), source IP hash (SSH/RDP) |

### Key Features

```
+===============================================================================+
|  HAPROXY LOAD BALANCER FEATURES                                               |
+===============================================================================+
|                                                                               |
|  1. HIGH AVAILABILITY                                                         |
|     - Active-Passive configuration with VRRP                                  |
|     - Automatic failover in under 3 seconds                                   |
|     - Virtual IP migration between nodes                                      |
|                                                                               |
|  2. LOAD BALANCING                                                            |
|     - Distributes connections to 2 Bastion appliances                         |
|     - TCP mode for SSH/RDP (protocol preservation)                            |
|     - HTTP/HTTPS mode for Web UI                                              |
|     - Session persistence (sticky sessions)                                   |
|                                                                               |
|  3. HEALTH MONITORING                                                         |
|     - Active health checks every 5 seconds                                    |
|     - Automatic backend removal on failure                                    |
|     - Graceful connection draining                                            |
|                                                                               |
|  4. SECURITY                                                                  |
|     - TLS 1.2+ enforcement                                                    |
|     - Modern cipher suite configuration                                       |
|     - HTTP → HTTPS redirection                                                |
|     - Connection rate limiting                                                |
|                                                                               |
|  5. OBSERVABILITY                                                             |
|     - Detailed connection logging                                             |
|     - Real-time statistics dashboard                                          |
|     - Prometheus metrics export                                               |
|     - Syslog integration                                                      |
|                                                                               |
+===============================================================================+
```

---

## HAProxy Architecture

### 2.1 High-Level Architecture

```
+===============================================================================+
|  HAPROXY HIGH AVAILABILITY ARCHITECTURE (PER SITE)                            |
+===============================================================================+
|                                                                               |
|                       End Users (SSH, RDP, HTTPS)                             |
|                                    |                                          |
|                                    v                                          |
|                       +-------------------------+                             |
|                       |   Virtual IP (VIP)      |                             |
|                       |   10.10.X.100           |                             |
|                       |   Keepalived VRRP       |                             |
|                       +------------+------------+                             |
|                                    |                                          |
|                    +---------------+---------------+                          |
|                    |                               |                          |
|         +----------v----------+         +----------v----------+               |
|         |  HAProxy-1 PRIMARY  |         |  HAProxy-2 BACKUP   |               |
|         |  10.10.X.5          |  VRRP   |  10.10.X.6          |               |
|         |  (MASTER)           |<------->|  (BACKUP)           |               |
|         |                     | Proto   |                     |               |
|         |  VIP: ACTIVE        |  112    |  VIP: STANDBY       |               |
|         +----------+----------+         +----------+----------+               |
|                    |                               |                          |
|                    | (Only primary forwards)       |                          |
|                    +---------------+---------------+                          |
|                                    |                                          |
|              Load Balancing (Active Primary Only)                             |
|                                    |                                          |
|                    +---------------+---------------+                          |
|                    |                               |                          |
|         +----------v----------+         +----------v----------+               |
|         | WALLIX Bastion-1    |   HA    | WALLIX Bastion-2    |               |
|         | 10.10.X.11          |  Sync   | 10.10.X.12          |               |
|         | Backend Server 1    |<------->| Backend Server 2    |               |
|         +---------------------+         +---------------------+               |
|                                                                               |
|  PROTOCOLS LOAD BALANCED:                                                     |
|  - HTTPS (443): Web UI, API                                                   |
|  - SSH (22): SSH proxy sessions                                               |
|  - RDP (3389): RDP proxy sessions                                             |
|  - HTTP (80): Redirect to HTTPS                                               |
|                                                                               |
+===============================================================================+
```

### 2.2 Traffic Flow

**Normal Operation (HAProxy-1 Primary):**

```
+===============================================================================+
|  NORMAL TRAFFIC FLOW                                                          |
+===============================================================================+
|                                                                               |
|  1. User connects to VIP (10.10.X.100:443)                                    |
|     |                                                                         |
|     v                                                                         |
|  2. VIP owned by HAProxy-1 (primary)                                          |
|     |                                                                         |
|     v                                                                         |
|  3. HAProxy-1 receives connection                                             |
|     |                                                                         |
|     v                                                                         |
|  4. HAProxy health checks both Bastion nodes                                  |
|     - Bastion-1: UP                                                           |
|     - Bastion-2: UP                                                           |
|     |                                                                         |
|     v                                                                         |
|  5. Load balancing algorithm selects backend:                                 |
|     - HTTPS: Roundrobin with session persistence                              |
|     - SSH/RDP: Source IP hash (sticky)                                        |
|     |                                                                         |
|     v                                                                         |
|  6. Connection forwarded to selected Bastion node                             |
|     |                                                                         |
|     v                                                                         |
|  7. User authenticated and session established                                |
|                                                                               |
+===============================================================================+
```

**Failover Scenario (HAProxy-1 Failure):**

```
+===============================================================================+
|  FAILOVER TRAFFIC FLOW                                                        |
+===============================================================================+
|                                                                               |
|  T+0s:  HAProxy-1 fails (network, hardware, service crash)                    |
|         |                                                                     |
|         v                                                                     |
|  T+1s:  Keepalived on HAProxy-2 detects primary down                          |
|         - VRRP advertisements from HAProxy-1 stop                             |
|         |                                                                     |
|         v                                                                     |
|  T+2s:  HAProxy-2 transitions to MASTER state                                 |
|         - VIP (10.10.X.100) migrated to HAProxy-2                             |
|         - Gratuitous ARP sent to update network                               |
|         |                                                                     |
|         v                                                                     |
|  T+3s:  New connections flow to HAProxy-2                                     |
|         - Existing TCP connections broken (users reconnect)                   |
|         - New connections load balanced normally                              |
|         |                                                                     |
|         v                                                                     |
|  T+5s:  All traffic restored via HAProxy-2                                    |
|                                                                               |
|  RECOVERY:                                                                    |
|  When HAProxy-1 returns online:                                               |
|  - If preempt_enabled=no (recommended): HAProxy-2 remains MASTER             |
|  - If preempt_enabled=yes: VIP migrates back to HAProxy-1                    |
|                                                                               |
+===============================================================================+
```

### 2.3 Component IP Addressing

**Example for Site 1 (10.10.1.0/24):**

| Component | IP Address | Role | VRRP State |
|-----------|------------|------|------------|
| HAProxy-1 | 10.10.1.5 | Primary | MASTER (default) |
| HAProxy-2 | 10.10.1.6 | Backup | BACKUP (default) |
| Virtual IP (VIP) | 10.10.1.100 | User entry point | Owned by MASTER |
| WALLIX Bastion-1 | 10.10.1.11 | Backend server | N/A |
| WALLIX Bastion-2 | 10.10.1.12 | Backend server | N/A |
| Default Gateway | 10.10.1.1 | Fortigate firewall | N/A |

**Adjust for each site:**
- Site 2: 10.10.2.0/24
- Site 3: 10.10.3.0/24
- Site 4: 10.10.4.0/24
- Site 5: 10.10.5.0/24

---

## Prerequisites

### 3.1 Hardware Requirements

**Minimum Specifications (per HAProxy server):**

| Component | Specification | Justification |
|-----------|---------------|---------------|
| **CPU** | 4 vCPU (2 GHz) | SSL termination, connection handling |
| **RAM** | 8 GB | Connection buffers, TLS session cache |
| **Disk** | 50 GB SSD | OS, logs, configuration |
| **Network** | 2x 1 GbE NICs | Redundancy, bonding |
| **IPMI/iLO** | Required | Remote management, out-of-band access |

**Recommended Specifications (production):**

| Component | Specification |
|-----------|---------------|
| **CPU** | 8 vCPU (2.5 GHz+) |
| **RAM** | 16 GB |
| **Disk** | 100 GB SSD (enterprise-grade) |
| **Network** | 2x 10 GbE NICs (bonded) |

### 3.2 Network Requirements

**VLANs and Interfaces:**

```
+===============================================================================+
|  NETWORK INTERFACE CONFIGURATION                                              |
+===============================================================================+
|                                                                               |
|  Physical Interfaces:                                                         |
|  - eth0: Primary network (VLAN 11)                                            |
|  - eth1: Secondary network (redundancy)                                       |
|                                                                               |
|  Bonding (Recommended):                                                       |
|  - bond0: Active-Backup mode (eth0 + eth1)                                    |
|  - Primary: eth0                                                              |
|  - Slave: eth1 (automatic failover)                                           |
|                                                                               |
|  IP Configuration (bond0):                                                    |
|  - HAProxy-1: 10.10.X.5/24                                                    |
|  - HAProxy-2: 10.10.X.6/24                                                    |
|  - VIP: 10.10.X.100/24 (managed by Keepalived)                                |
|  - Gateway: 10.10.X.1                                                         |
|                                                                               |
+===============================================================================+
```

**Required Firewall Rules:**

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| End Users | VIP (10.10.X.100) | 443 | TCP | HTTPS (Web UI, API) |
| End Users | VIP (10.10.X.100) | 22 | TCP | SSH proxy |
| End Users | VIP (10.10.X.100) | 3389 | TCP | RDP proxy |
| End Users | VIP (10.10.X.100) | 80 | TCP | HTTP → HTTPS redirect |
| HAProxy-1 | Bastion-1/2 (10.10.X.11-12) | 443 | TCP | Backend health checks |
| HAProxy-1 | Bastion-1/2 (10.10.X.11-12) | 22 | TCP | Backend health checks |
| HAProxy-2 | Bastion-1/2 (10.10.X.11-12) | 443 | TCP | Backend health checks |
| HAProxy-1 | HAProxy-2 | 112 | IP/VRRP | Keepalived heartbeat |
| HAProxy-2 | HAProxy-1 | 112 | IP/VRRP | Keepalived heartbeat |
| Monitoring | HAProxy-1/2 | 8404 | TCP | HAProxy stats dashboard |

**Note:** IP protocol 112 (VRRP) is not TCP/UDP. Ensure firewalls allow this protocol.

### 3.3 Software Requirements

**Operating System:**
- Debian 12 (Bookworm) - Recommended
- RHEL 9 / Rocky Linux 9 - Alternative

**Required Packages:**
- HAProxy 2.8+
- Keepalived 2.2+
- rsyslog (logging)
- chrony (NTP)
- net-tools, iproute2

**Optional but Recommended:**
- haproxy-exporter (Prometheus metrics)
- logrotate (log management)
- fail2ban (DDoS protection)

### 3.4 DNS and SSL Certificates

**DNS Records Required:**

```bash
# Forward DNS (A records)
haproxy1-siteX.wallix.company.local    A    10.10.X.5
haproxy2-siteX.wallix.company.local    A    10.10.X.6
bastion-siteX.wallix.company.local     A    10.10.X.100   # VIP

# Reverse DNS (PTR records)
10.10.X.5    PTR    haproxy1-siteX.wallix.company.local
10.10.X.6    PTR    haproxy2-siteX.wallix.company.local
10.10.X.100  PTR    bastion-siteX.wallix.company.local
```

**SSL Certificates:**
- Certificate CN/SAN must match VIP hostname: `bastion-siteX.wallix.company.local`
- Wildcard certificate: `*.wallix.company.local` (recommended)
- Chain file required: certificate + intermediate CA + root CA
- Private key in PEM format

---

## Operating System Installation

### 4.1 Debian 12 Installation (Recommended)

**Step 1: Boot from Debian 12 ISO**

```bash
# Installation media preparation
# Download Debian 12 netinst ISO from:
# https://www.debian.org/releases/bookworm/

# Create bootable USB (from Linux workstation)
dd if=debian-12.x.x-amd64-netinst.iso of=/dev/sdX bs=4M status=progress && sync
```

**Step 2: Basic System Installation**

```
Installer Options:
  - Language: English
  - Location: Europe/Paris (adjust per site)
  - Keyboard: US (or local)
  - Hostname: haproxy1-site1 (or haproxy2-site1)
  - Domain: wallix.company.local
  - Root password: <strong password>
  - Create user: wallixadmin / <strong password>

Disk Partitioning (50 GB SSD):
  - /boot:     1 GB   (ext4)
  - /        : 30 GB  (ext4)
  - /var     : 15 GB  (ext4, logs)
  - swap     : 4 GB
  - (unallocated): Reserve for growth

Software Selection:
  - [x] SSH server
  - [ ] Desktop environment (uncheck)
  - [x] Standard system utilities
```

**Step 3: Post-Installation Network Configuration**

Edit `/etc/network/interfaces`:

```bash
# Interface bonding configuration (Active-Backup)
auto lo
iface lo inet loopback

# Bond configuration
auto bond0
iface bond0 inet static
    address 10.10.1.5        # Change to .6 for HAProxy-2
    netmask 255.255.255.0
    gateway 10.10.1.1
    dns-nameservers 10.20.0.10 10.20.0.11
    bond-slaves eth0 eth1
    bond-mode active-backup
    bond-miimon 100
    bond-primary eth0

# Slave interfaces
auto eth0
iface eth0 inet manual
    bond-master bond0

auto eth1
iface eth1 inet manual
    bond-master bond0
```

Enable bonding kernel module:

```bash
# Load bonding module
echo "bonding" >> /etc/modules

# Load module immediately
modprobe bonding

# Install ifenslave for bond management
apt update && apt install -y ifenslave

# Restart networking
systemctl restart networking

# Verify bond status
cat /proc/net/bonding/bond0
# Expected: Mode: fault-tolerance (active-backup)
#           Primary Slave: eth0
#           Currently Active Slave: eth0
```

**Step 4: System Hardening**

```bash
# Update system
apt update && apt full-upgrade -y

# Install essential tools
apt install -y \
    vim \
    curl \
    wget \
    net-tools \
    tcpdump \
    htop \
    iotop \
    rsync \
    chrony \
    fail2ban

# Disable unused services
systemctl disable bluetooth.service
systemctl disable avahi-daemon.service
systemctl disable cups.service

# Enable automatic security updates
apt install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

**Step 5: NTP Time Synchronization**

Edit `/etc/chrony/chrony.conf`:

```bash
# Internal NTP servers
server 10.20.0.20 iburst prefer
server 10.20.0.21 iburst

# Fallback public NTP
pool 2.debian.pool.ntp.org iburst

# Allow large time corrections on startup
makestep 1.0 3

# Drift file
driftfile /var/lib/chrony/drift

# Logging
logdir /var/log/chrony
log measurements statistics tracking
```

Start and verify NTP:

```bash
systemctl enable --now chrony

# Verify synchronization
chronyc tracking
# Expected: Leap status: Normal

chronyc sources
# Expected: At least one source with '*' (synchronized)
```

**Step 6: SSH Hardening**

Edit `/etc/ssh/sshd_config`:

```bash
# Security hardening
Port 22
PermitRootLogin no
PasswordAuthentication yes   # Change to 'no' after SSH key setup
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10

# Allowed users
AllowUsers wallixadmin
```

Restart SSH:

```bash
systemctl restart sshd
```

### 4.2 RHEL 9 Installation (Alternative)

**Differences from Debian:**

```bash
# Network configuration uses NetworkManager
nmcli con add type bond con-name bond0 ifname bond0 bond.options "mode=active-backup,miimon=100"
nmcli con add type ethernet slave-type bond con-name bond0-eth0 ifname eth0 master bond0
nmcli con add type ethernet slave-type bond con-name bond0-eth1 ifname eth1 master bond0
nmcli con mod bond0 ipv4.addresses 10.10.1.5/24
nmcli con mod bond0 ipv4.gateway 10.10.1.1
nmcli con mod bond0 ipv4.dns "10.20.0.10 10.20.0.11"
nmcli con mod bond0 ipv4.method manual
nmcli con up bond0

# Package management uses dnf
dnf update -y
dnf install -y haproxy keepalived chrony fail2ban

# Firewall configuration uses firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=3389/tcp
firewall-cmd --permanent --add-rich-rule='rule protocol value="vrrp" accept'
firewall-cmd --reload

# SELinux context for HAProxy
setsebool -P haproxy_connect_any 1
```

---

## HAProxy Installation

### 5.1 Install HAProxy from Official Repository

**Debian 12:**

```bash
# Add HAProxy 2.8 LTS repository
curl -fsSL https://haproxy.debian.net/bernat.debian.org.gpg | \
    gpg --dearmor -o /usr/share/keyrings/haproxy.gpg

echo "deb [signed-by=/usr/share/keyrings/haproxy.gpg] \
    http://haproxy.debian.net bookworm-backports-2.8 main" | \
    tee /etc/apt/sources.list.d/haproxy.list

# Install HAProxy
apt update
apt install -y haproxy=2.8.\*

# Hold package version (prevent accidental upgrades)
apt-mark hold haproxy

# Verify installation
haproxy -v
# Expected: HAProxy version 2.8.x
```

**RHEL 9:**

```bash
# Enable EPEL repository
dnf install -y epel-release

# Install HAProxy
dnf install -y haproxy

# Verify version
haproxy -v

# Enable and start service (will configure first)
systemctl enable haproxy
```

### 5.2 HAProxy System Tuning

**Kernel Parameter Optimization:**

Create `/etc/sysctl.d/99-haproxy.conf`:

```bash
# Network tuning for high connection load
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 8192
net.core.netdev_max_backlog = 5000

# Connection tracking
net.netfilter.nf_conntrack_max = 262144

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# Enable IP forwarding (required for VRRP)
net.ipv4.ip_forward = 1
net.ipv4.ip_nonlocal_bind = 1
```

Apply kernel parameters:

```bash
sysctl -p /etc/sysctl.d/99-haproxy.conf

# Verify
sysctl net.ipv4.ip_nonlocal_bind
# Expected: net.ipv4.ip_nonlocal_bind = 1
```

**System Limits:**

Edit `/etc/security/limits.conf`:

```bash
# HAProxy process limits
haproxy soft nofile 65536
haproxy hard nofile 65536
haproxy soft nproc 8192
haproxy hard nproc 8192
```

**Systemd Service Limits:**

Create `/etc/systemd/system/haproxy.service.d/override.conf`:

```bash
[Service]
LimitNOFILE=65536
LimitNPROC=8192

# Restart policy
Restart=on-failure
RestartSec=5s
```

Reload systemd:

```bash
systemctl daemon-reload
```

---

## HAProxy Configuration

### 6.1 Complete HAProxy Configuration

Create `/etc/haproxy/haproxy.cfg`:

```haproxy
#===============================================================================
# WALLIX BASTION HAPROXY CONFIGURATION
# Version: 2.8 LTS
# Site: Site 1 (Adjust IPs for other sites)
# Updated: February 2026
#===============================================================================

#-------------------------------------------------------------------------------
# GLOBAL SETTINGS
#-------------------------------------------------------------------------------
global
    # Process management
    daemon
    maxconn 10000
    user haproxy
    group haproxy

    # Logging
    log /dev/log local0 info
    log /dev/log local1 notice

    # Performance tuning
    nbproc 1
    nbthread 4
    cpu-map auto:1/1-4 0-3

    # TLS/SSL configuration
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
    ssl-default-server-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    ssl-default-server-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-server-options ssl-min-ver TLSv1.2 no-tls-tickets

    # TLS session cache
    tune.ssl.default-dh-param 2048
    tune.ssl.cachesize 100000
    tune.ssl.lifetime 600

    # Stats socket (for runtime API)
    stats socket /var/run/haproxy.sock mode 660 level admin
    stats timeout 30s

#-------------------------------------------------------------------------------
# DEFAULTS
#-------------------------------------------------------------------------------
defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option  http-server-close
    option  redispatch
    option  log-health-checks

    # Timeouts
    timeout connect 10s
    timeout client  60s
    timeout server  60s
    timeout http-request 10s
    timeout http-keep-alive 10s
    timeout queue 30s
    timeout tunnel 3600s    # Long timeout for SSH/RDP sessions

    # Retries and connection management
    retries 3
    maxconn 3000

    # Error handling
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

#-------------------------------------------------------------------------------
# STATISTICS DASHBOARD
#-------------------------------------------------------------------------------
frontend stats
    bind *:8404
    mode http
    stats enable
    stats uri /stats
    stats realm HAProxy\ Statistics
    stats auth admin:ChangeThisPassword123!
    stats refresh 30s
    stats show-legends
    stats show-node

    # Prometheus metrics endpoint
    http-request use-service prometheus-exporter if { path /metrics }

#-------------------------------------------------------------------------------
# FRONTEND: HTTP (Port 80) - Redirect to HTTPS
#-------------------------------------------------------------------------------
frontend http_frontend
    bind *:80
    mode http

    # Logging
    log global
    option httplog

    # Redirect all HTTP to HTTPS
    redirect scheme https code 301 if !{ ssl_fc }

#-------------------------------------------------------------------------------
# FRONTEND: HTTPS (Port 443) - WALLIX Web UI and API
#-------------------------------------------------------------------------------
frontend https_frontend
    bind *:443 ssl crt /etc/haproxy/certs/wallix-bastion.pem alpn h2,http/1.1
    mode http

    # Logging
    log global
    option httplog
    option forwardfor except 127.0.0.1

    # Security headers
    http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    http-response set-header X-Frame-Options "SAMEORIGIN"
    http-response set-header X-Content-Type-Options "nosniff"
    http-response set-header X-XSS-Protection "1; mode=block"

    # Connection rate limiting (anti-DDoS)
    stick-table type ip size 100k expire 30s store conn_rate(3s),http_req_rate(10s)
    http-request track-sc0 src
    http-request deny deny_status 429 if { sc_conn_rate(0) gt 20 }
    http-request deny deny_status 429 if { sc_http_req_rate(0) gt 100 }

    # Session persistence (cookie-based sticky sessions)
    cookie BASTIONSRV insert indirect nocache httponly secure

    # Use backend
    default_backend wallix_bastion_https

#-------------------------------------------------------------------------------
# BACKEND: HTTPS - WALLIX Bastion Cluster
#-------------------------------------------------------------------------------
backend wallix_bastion_https
    mode http
    balance roundrobin

    # Session persistence
    cookie BASTIONSRV insert indirect nocache httponly secure

    # Health checks
    option httpchk GET /health HTTP/1.1\r\nHost:\ bastion-site1.wallix.company.local
    http-check expect status 200

    # Backend servers
    server bastion1 10.10.1.11:443 check ssl verify none inter 5s rise 2 fall 3 cookie bastion1 maxconn 1500
    server bastion2 10.10.1.12:443 check ssl verify none inter 5s rise 2 fall 3 cookie bastion2 maxconn 1500

#-------------------------------------------------------------------------------
# FRONTEND: SSH (Port 22) - SSH Proxy Sessions
#-------------------------------------------------------------------------------
frontend ssh_frontend
    bind *:22
    mode tcp

    # Logging
    log global
    option tcplog

    # Use backend
    default_backend wallix_bastion_ssh

#-------------------------------------------------------------------------------
# BACKEND: SSH - WALLIX Bastion Cluster
#-------------------------------------------------------------------------------
backend wallix_bastion_ssh
    mode tcp
    balance source
    hash-type consistent

    # Health checks (TCP connect)
    option tcp-check
    tcp-check connect port 22

    # Backend servers
    server bastion1 10.10.1.11:22 check inter 5s rise 2 fall 3 maxconn 500
    server bastion2 10.10.1.12:22 check inter 5s rise 2 fall 3 maxconn 500

#-------------------------------------------------------------------------------
# FRONTEND: RDP (Port 3389) - RDP Proxy Sessions
#-------------------------------------------------------------------------------
frontend rdp_frontend
    bind *:3389
    mode tcp

    # Logging
    log global
    option tcplog

    # Use backend
    default_backend wallix_bastion_rdp

#-------------------------------------------------------------------------------
# BACKEND: RDP - WALLIX Bastion Cluster
#-------------------------------------------------------------------------------
backend wallix_bastion_rdp
    mode tcp
    balance source
    hash-type consistent

    # Health checks (TCP connect)
    option tcp-check
    tcp-check connect port 3389

    # Backend servers
    server bastion1 10.10.1.11:3389 check inter 5s rise 2 fall 3 maxconn 500
    server bastion2 10.10.1.12:3389 check inter 5s rise 2 fall 3 maxconn 500
```

### 6.2 Configuration Validation

**Syntax Check:**

```bash
# Test configuration before applying
haproxy -c -f /etc/haproxy/haproxy.cfg

# Expected output:
# Configuration file is valid
```

**Common Errors and Fixes:**

| Error | Cause | Solution |
|-------|-------|----------|
| `cannot bind socket` | Port already in use | Check with `ss -tulpn | grep :443` |
| `SSL handshake failure` | Missing/invalid certificate | Verify certificate file exists and has correct permissions |
| `'stats' already defined` | Duplicate frontend name | Rename one of the frontends |
| `unknown keyword 'nbthread'` | Old HAProxy version | Upgrade to HAProxy 2.8+ |

### 6.3 Site-Specific Customization

**For Site 2 (10.10.2.0/24):**

```bash
# Update backend server IPs
sed -i 's/10.10.1.11/10.10.2.11/g' /etc/haproxy/haproxy.cfg
sed -i 's/10.10.1.12/10.10.2.12/g' /etc/haproxy/haproxy.cfg
sed -i 's/bastion-site1/bastion-site2/g' /etc/haproxy/haproxy.cfg
```

**For Sites 3, 4, 5:**
- Replace `10.10.1` with `10.10.3`, `10.10.4`, `10.10.5`
- Update hostnames to match site (bastion-site3, etc.)

---

## Keepalived Configuration

### 7.1 Install Keepalived

```bash
# Debian
apt install -y keepalived

# RHEL
dnf install -y keepalived

# Enable service (configure first)
systemctl enable keepalived
```

### 7.2 Keepalived Configuration (HAProxy-1 Primary)

Create `/etc/keepalived/keepalived.conf` on **HAProxy-1**:

```bash
#===============================================================================
# KEEPALIVED CONFIGURATION - HAPROXY-1 (PRIMARY)
# Role: MASTER (default)
# Priority: 100 (higher than backup)
# Site: Site 1
#===============================================================================

global_defs {
    router_id HAPROXY1_SITE1
    enable_script_security
    script_user root
    vrrp_version 3
    vrrp_garp_master_delay 1
    vrrp_garp_master_repeat 3
}

# Health check script for HAProxy service
vrrp_script check_haproxy {
    script "/usr/local/bin/check_haproxy.sh"
    interval 2
    weight -20
    fall 2
    rise 2
}

vrrp_instance WALLIX_VRRP_1 {
    state MASTER
    interface bond0
    virtual_router_id 51
    priority 100
    advert_int 1

    # Authentication (shared secret)
    authentication {
        auth_type PASS
        auth_pass ChangeThisSecretKey123
    }

    # Virtual IP (VIP)
    virtual_ipaddress {
        10.10.1.100/24 dev bond0 label bond0:vip
    }

    # Track script
    track_script {
        check_haproxy
    }

    # Notifications (optional)
    notify_master "/usr/local/bin/keepalived_notify.sh MASTER"
    notify_backup "/usr/local/bin/keepalived_notify.sh BACKUP"
    notify_fault  "/usr/local/bin/keepalived_notify.sh FAULT"

    # Preemption (recommended: no)
    # This prevents VIP from migrating back when primary recovers
    nopreempt
}
```

### 7.3 Keepalived Configuration (HAProxy-2 Backup)

Create `/etc/keepalived/keepalived.conf` on **HAProxy-2**:

```bash
#===============================================================================
# KEEPALIVED CONFIGURATION - HAPROXY-2 (BACKUP)
# Role: BACKUP (default)
# Priority: 90 (lower than master)
# Site: Site 1
#===============================================================================

global_defs {
    router_id HAPROXY2_SITE1
    enable_script_security
    script_user root
    vrrp_version 3
    vrrp_garp_master_delay 1
    vrrp_garp_master_repeat 3
}

# Health check script for HAProxy service
vrrp_script check_haproxy {
    script "/usr/local/bin/check_haproxy.sh"
    interval 2
    weight -20
    fall 2
    rise 2
}

vrrp_instance WALLIX_VRRP_1 {
    state BACKUP
    interface bond0
    virtual_router_id 51
    priority 90
    advert_int 1

    # Authentication (must match master)
    authentication {
        auth_type PASS
        auth_pass ChangeThisSecretKey123
    }

    # Virtual IP (same as master)
    virtual_ipaddress {
        10.10.1.100/24 dev bond0 label bond0:vip
    }

    # Track script
    track_script {
        check_haproxy
    }

    # Notifications (optional)
    notify_master "/usr/local/bin/keepalived_notify.sh MASTER"
    notify_backup "/usr/local/bin/keepalived_notify.sh BACKUP"
    notify_fault  "/usr/local/bin/keepalived_notify.sh FAULT"
}
```

### 7.4 HAProxy Health Check Script

Create `/usr/local/bin/check_haproxy.sh`:

```bash
#!/bin/bash
#===============================================================================
# HAProxy Health Check Script for Keepalived
# Returns: 0 (success) if HAProxy is running and healthy
#          1 (failure) if HAProxy is down or unhealthy
#===============================================================================

# Check if HAProxy service is running
systemctl is-active --quiet haproxy
SERVICE_STATUS=$?

if [ $SERVICE_STATUS -ne 0 ]; then
    logger -t keepalived "HAProxy service is not running"
    exit 1
fi

# Check if HAProxy is responding on stats port
curl -s -f -m 2 http://127.0.0.1:8404/stats > /dev/null 2>&1
STATS_STATUS=$?

if [ $STATS_STATUS -ne 0 ]; then
    logger -t keepalived "HAProxy stats endpoint not responding"
    exit 1
fi

# Additional check: Verify HAProxy socket is responding
echo "show info" | socat stdio /var/run/haproxy.sock > /dev/null 2>&1
SOCKET_STATUS=$?

if [ $SOCKET_STATUS -ne 0 ]; then
    logger -t keepalived "HAProxy admin socket not responding"
    exit 1
fi

# All checks passed
exit 0
```

Make script executable:

```bash
chmod +x /usr/local/bin/check_haproxy.sh

# Test script
/usr/local/bin/check_haproxy.sh
echo $?
# Expected: 0 (success)
```

### 7.5 Keepalived Notification Script (Optional)

Create `/usr/local/bin/keepalived_notify.sh`:

```bash
#!/bin/bash
#===============================================================================
# Keepalived State Change Notification Script
# Sends alerts when VRRP state changes
#===============================================================================

STATE=$1
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
VIP="10.10.1.100"

# Log state change
logger -t keepalived "VRRP state changed to $STATE on $HOSTNAME"

# Send email notification (requires configured mail server)
case $STATE in
    MASTER)
        echo "$TIMESTAMP - $HOSTNAME transitioned to MASTER state. VIP $VIP is now active." | \
            mail -s "WALLIX HAProxy: $HOSTNAME is now MASTER" admin@company.local
        ;;
    BACKUP)
        echo "$TIMESTAMP - $HOSTNAME transitioned to BACKUP state. VIP $VIP released." | \
            mail -s "WALLIX HAProxy: $HOSTNAME is now BACKUP" admin@company.local
        ;;
    FAULT)
        echo "$TIMESTAMP - $HOSTNAME entered FAULT state. Check HAProxy service immediately!" | \
            mail -s "ALERT: WALLIX HAProxy $HOSTNAME FAULT" admin@company.local
        ;;
esac

# Send to syslog
logger -t keepalived "[$STATE] VIP $VIP on $HOSTNAME"

exit 0
```

Make script executable:

```bash
chmod +x /usr/local/bin/keepalived_notify.sh
```

### 7.6 Start and Verify Keepalived

**Start services:**

```bash
# On both HAProxy-1 and HAProxy-2
systemctl start keepalived
systemctl status keepalived

# Check logs
journalctl -u keepalived -f
```

**Verify VIP assignment:**

```bash
# On HAProxy-1 (should show VIP)
ip addr show bond0 | grep 10.10.1.100
# Expected: inet 10.10.1.100/24 scope global secondary bond0:vip

# On HAProxy-2 (should NOT show VIP)
ip addr show bond0 | grep 10.10.1.100
# Expected: (no output)

# Check VRRP state
systemctl status keepalived | grep -i state
# HAProxy-1 Expected: "Entering MASTER STATE"
# HAProxy-2 Expected: "Entering BACKUP STATE"
```

**Test VIP connectivity:**

```bash
# From external host
ping -c 4 10.10.1.100
# Expected: Successful pings

curl -k https://10.10.1.100/health
# Expected: HTTP 200 OK (if WALLIX Bastion is running)
```

---

## SSL Certificate Setup

### 8.1 Certificate Requirements

**Certificate Format:**

HAProxy requires a single PEM file containing:
1. Private key (unencrypted)
2. Certificate
3. Intermediate CA certificate(s)
4. Root CA certificate (optional)

**File Structure:**

```
/etc/haproxy/certs/wallix-bastion.pem:
-----BEGIN PRIVATE KEY-----
<private key>
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
<server certificate>
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
<intermediate CA certificate>
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
<root CA certificate (optional)>
-----END CERTIFICATE-----
```

### 8.2 Create Combined Certificate File

**From separate files:**

```bash
# Create certificate directory
mkdir -p /etc/haproxy/certs
chmod 700 /etc/haproxy/certs

# Combine certificate files
cat /path/to/private.key \
    /path/to/certificate.crt \
    /path/to/intermediate_ca.crt \
    /path/to/root_ca.crt > /etc/haproxy/certs/wallix-bastion.pem

# Secure permissions
chmod 600 /etc/haproxy/certs/wallix-bastion.pem
chown haproxy:haproxy /etc/haproxy/certs/wallix-bastion.pem
```

**Verify certificate:**

```bash
# Check certificate details
openssl x509 -in /etc/haproxy/certs/wallix-bastion.pem -noout -text

# Verify private key matches certificate
openssl x509 -in /etc/haproxy/certs/wallix-bastion.pem -noout -modulus | openssl md5
openssl rsa -in /etc/haproxy/certs/wallix-bastion.pem -noout -modulus | openssl md5
# Both MD5 hashes must match

# Check certificate chain
openssl s_client -connect 127.0.0.1:443 -servername bastion-site1.wallix.company.local < /dev/null
# Expected: "Verify return code: 0 (ok)"
```

### 8.3 Let's Encrypt Certificate (Optional)

**Using Certbot:**

```bash
# Install Certbot
apt install -y certbot

# Obtain certificate (HTTP-01 challenge)
certbot certonly --standalone -d bastion-site1.wallix.company.local

# Combine for HAProxy
cat /etc/letsencrypt/live/bastion-site1.wallix.company.local/privkey.pem \
    /etc/letsencrypt/live/bastion-site1.wallix.company.local/fullchain.pem \
    > /etc/haproxy/certs/wallix-bastion.pem

chmod 600 /etc/haproxy/certs/wallix-bastion.pem
chown haproxy:haproxy /etc/haproxy/certs/wallix-bastion.pem
```

**Automatic renewal:**

Create `/etc/cron.daily/renew-haproxy-cert`:

```bash
#!/bin/bash
certbot renew --quiet --deploy-hook "cat /etc/letsencrypt/live/bastion-site1.wallix.company.local/privkey.pem /etc/letsencrypt/live/bastion-site1.wallix.company.local/fullchain.pem > /etc/haproxy/certs/wallix-bastion.pem && systemctl reload haproxy"
```

Make executable:

```bash
chmod +x /etc/cron.daily/renew-haproxy-cert
```

### 8.4 SSL Termination vs Pass-Through

**Option 1: SSL Termination (Recommended for Web UI)**

HAProxy decrypts HTTPS, forwards HTTP to backend:

```haproxy
frontend https_frontend
    bind *:443 ssl crt /etc/haproxy/certs/wallix-bastion.pem
    # HAProxy terminates SSL, forwards plain HTTP to backend
```

**Pros:**
- HAProxy can inspect HTTP headers
- Load balancing based on HTTP content
- Session persistence with cookies

**Cons:**
- HAProxy must handle SSL/TLS overhead
- End-to-end encryption broken

**Option 2: SSL Pass-Through (Recommended for SSH/RDP)**

HAProxy forwards encrypted traffic to backend:

```haproxy
frontend https_frontend
    bind *:443
    mode tcp
    # HAProxy forwards encrypted traffic as-is
    default_backend wallix_bastion_https_passthrough

backend wallix_bastion_https_passthrough
    mode tcp
    server bastion1 10.10.1.11:443 check
```

**Pros:**
- End-to-end encryption maintained
- Lower CPU overhead on HAProxy
- WALLIX Bastion handles TLS

**Cons:**
- Cannot inspect traffic
- No HTTP-based load balancing

**Recommendation:** Use SSL termination for HTTPS (Web UI), TCP pass-through for SSH/RDP.

---

## Health Checks Configuration

### 9.1 Backend Health Check Strategies

**HTTP Health Checks (HTTPS backend):**

```haproxy
backend wallix_bastion_https
    option httpchk GET /health HTTP/1.1\r\nHost:\ bastion-site1.wallix.company.local
    http-check expect status 200

    server bastion1 10.10.1.11:443 check ssl verify none inter 5s rise 2 fall 3
    server bastion2 10.10.1.12:443 check ssl verify none inter 5s rise 2 fall 3
```

**Parameters:**
- `inter 5s`: Check every 5 seconds
- `rise 2`: Consider UP after 2 consecutive successes
- `fall 3`: Consider DOWN after 3 consecutive failures
- `ssl verify none`: Skip certificate validation (use `verify required` if CA configured)

**TCP Health Checks (SSH/RDP backends):**

```haproxy
backend wallix_bastion_ssh
    option tcp-check
    tcp-check connect port 22

    server bastion1 10.10.1.11:22 check inter 5s rise 2 fall 3
    server bastion2 10.10.1.12:22 check inter 5s rise 2 fall 3
```

### 9.2 Advanced Health Check Script

**Custom health check endpoint on WALLIX Bastion:**

If WALLIX Bastion exposes `/health` endpoint:

```bash
# Check health endpoint manually
curl -k https://10.10.1.11/health

# Expected response:
# {"status":"ok","services":{"database":"up","session_manager":"up"}}
```

**HAProxy configuration:**

```haproxy
backend wallix_bastion_https
    option httpchk GET /health
    http-check expect string "ok"

    server bastion1 10.10.1.11:443 check ssl verify none
```

### 9.3 Health Check Monitoring

**View backend status:**

```bash
# Via stats socket
echo "show stat" | socat stdio /var/run/haproxy.sock | grep wallix_bastion

# Via stats dashboard
# Open browser: http://10.10.1.5:8404/stats
# Username: admin
# Password: <configured in haproxy.cfg>
```

**Backend server states:**

| State | Color | Description |
|-------|-------|-------------|
| UP | Green | Server is healthy and receiving traffic |
| DOWN | Red | Server failed health checks, removed from pool |
| MAINT | Blue | Server in maintenance mode (manual) |
| DRAIN | Orange | Server draining connections, no new traffic |

---

## Logging and Monitoring

### 10.1 Rsyslog Configuration

**Configure rsyslog to receive HAProxy logs:**

Create `/etc/rsyslog.d/49-haproxy.conf`:

```bash
# HAProxy logs
$ModLoad imudp
$UDPServerRun 514

# Log to separate file
if $programname startswith 'haproxy' then /var/log/haproxy.log
& stop
```

Restart rsyslog:

```bash
systemctl restart rsyslog

# Verify HAProxy logging
tail -f /var/log/haproxy.log
```

### 10.2 Log Rotation

Create `/etc/logrotate.d/haproxy`:

```bash
/var/log/haproxy.log {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
```

### 10.3 Monitoring with HAProxy Stats Dashboard

**Access stats dashboard:**

```
URL: http://10.10.1.5:8404/stats
Username: admin
Password: ChangeThisPassword123!
```

**Key metrics to monitor:**

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| **Session rate** | New sessions per second | > 1000/s |
| **Queue length** | Pending connections | > 100 |
| **Backend status** | Number of UP servers | < 1 (critical) |
| **Response time** | Average backend response time | > 5s |
| **Error rate** | HTTP 5xx errors per minute | > 10/min |
| **Connection timeouts** | Failed connections | > 5% |

### 10.4 Prometheus Metrics Export

**HAProxy built-in Prometheus exporter:**

Already configured in `haproxy.cfg`:

```haproxy
frontend stats
    bind *:8404
    http-request use-service prometheus-exporter if { path /metrics }
```

**Test metrics endpoint:**

```bash
curl http://10.10.1.5:8404/metrics

# Sample output:
# haproxy_process_current_connections 142
# haproxy_frontend_http_requests_total{frontend="https_frontend"} 45231
# haproxy_backend_up{backend="wallix_bastion_https",server="bastion1"} 1
```

**Prometheus scrape configuration:**

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'haproxy'
    static_configs:
      - targets:
          - '10.10.1.5:8404'
          - '10.10.1.6:8404'
    metrics_path: /metrics
    scrape_interval: 30s
```

### 10.5 Grafana Dashboard

**Import pre-built HAProxy dashboard:**

1. Open Grafana: http://grafana.company.local
2. Navigate to **Dashboards** → **Import**
3. Enter dashboard ID: **12693** (HAProxy 2 Full)
4. Select Prometheus data source
5. Click **Import**

**Key dashboard panels:**
- Frontend requests per second
- Backend server status
- Response time percentiles (p50, p95, p99)
- Error rates by status code
- Connection queue depth

---

## Failover Testing

### 11.1 Planned Failover Test

**Objective:** Verify automatic failover from HAProxy-1 to HAProxy-2.

**Prerequisites:**
- Both HAProxy servers running
- HAProxy-1 is MASTER (owns VIP)
- Active user sessions (optional, for session continuity testing)

**Test Procedure:**

```bash
# Step 1: Verify initial state
# On HAProxy-1
ip addr show bond0 | grep 10.10.1.100
# Expected: VIP present

systemctl status keepalived | grep STATE
# Expected: MASTER STATE

# Step 2: Initiate graceful failover (stop Keepalived)
systemctl stop keepalived

# Step 3: Verify VIP migration (within 3 seconds)
# On HAProxy-2
ip addr show bond0 | grep 10.10.1.100
# Expected: VIP now present on HAProxy-2

systemctl status keepalived | grep STATE
# Expected: MASTER STATE

# Step 4: Test user connectivity
curl -k https://10.10.1.100/health
# Expected: HTTP 200 OK (via HAProxy-2)

# Step 5: Verify HAProxy stats
curl http://10.10.2.6:8404/stats
# Expected: Dashboard shows HAProxy-2 as active

# Step 6: Restore HAProxy-1
# On HAProxy-1
systemctl start keepalived

# Step 7: Verify HAProxy-2 remains MASTER (nopreempt)
# On HAProxy-2
ip addr show bond0 | grep 10.10.1.100
# Expected: VIP still on HAProxy-2 (due to nopreempt)
```

**Expected Results:**
- Failover completes in < 3 seconds
- No user-visible impact (existing connections may drop for SSH/RDP)
- New connections immediately route to HAProxy-2
- HAProxy-2 remains MASTER after HAProxy-1 returns (nopreempt)

### 11.2 Unplanned Failover Test (Simulated Failure)

**Objective:** Verify failover on total HAProxy-1 failure.

**Test Procedure:**

```bash
# Step 1: Simulate hardware failure (power off or kernel panic)
# DANGER: This will kill the server immediately

# On HAProxy-1 (use IPMI/iLO console)
echo b > /proc/sysrq-trigger   # Immediate reboot (simulate crash)

# Step 2: Verify automatic failover
# On HAProxy-2 (should happen within 3 seconds)
ip addr show bond0 | grep 10.10.1.100
# Expected: VIP migrated to HAProxy-2

journalctl -u keepalived -f
# Expected: "Entering MASTER STATE"

# Step 3: Test connectivity
curl -k https://10.10.1.100/health
# Expected: Still accessible via HAProxy-2
```

### 11.3 Split-Brain Prevention Test

**Objective:** Verify VRRP authentication prevents split-brain.

**Test Procedure:**

```bash
# Step 1: Temporarily break VRRP communication (firewall rule)
# On HAProxy-1
iptables -A INPUT -p vrrp -j DROP

# Step 2: Monitor Keepalived behavior
# On HAProxy-1
journalctl -u keepalived -f
# Expected: "VRRP Advertisement timeout"

# On HAProxy-2
journalctl -u keepalived -f
# Expected: "Entering MASTER STATE" (takes over VIP)

# Step 3: Verify BOTH nodes do NOT claim VIP simultaneously
# On HAProxy-1
ip addr show bond0 | grep 10.10.1.100
# Expected: VIP removed after VRRP timeout

# On HAProxy-2
ip addr show bond0 | grep 10.10.1.100
# Expected: VIP present

# Step 4: Restore VRRP communication
iptables -D INPUT -p vrrp -j DROP

# Step 5: Verify HAProxy-1 returns to BACKUP
systemctl status keepalived | grep STATE
# Expected: BACKUP STATE (due to nopreempt)
```

### 11.4 Backend Server Failure Test

**Objective:** Verify HAProxy automatically removes failed backend servers.

**Test Procedure:**

```bash
# Step 1: Verify both Bastion nodes are UP
echo "show stat" | socat stdio /var/run/haproxy.sock | grep wallix_bastion_https
# Expected: bastion1=UP, bastion2=UP

# Step 2: Stop WALLIX Bastion service on bastion1
# On Bastion-1
systemctl stop wallix-bastion

# Step 3: Monitor HAProxy health checks (wait 15 seconds)
# On HAProxy (primary)
journalctl -u haproxy -f | grep bastion1
# Expected: "Health check failed"

echo "show stat" | socat stdio /var/run/haproxy.sock | grep bastion1
# Expected: bastion1=DOWN

# Step 4: Verify all traffic routes to bastion2
curl -k https://10.10.1.100/health
# Expected: Still responds (via bastion2 only)

# Step 5: Restore bastion1
systemctl start wallix-bastion

# Step 6: Verify automatic re-inclusion (after 2 successful checks)
echo "show stat" | socat stdio /var/run/haproxy.sock | grep bastion1
# Expected: bastion1=UP
```

### 11.5 Session Persistence Test

**Objective:** Verify sticky sessions (cookie-based for HTTPS).

**Test Procedure:**

```bash
# Step 1: Establish session and note backend server
curl -k -c cookies.txt -b cookies.txt https://10.10.1.100/login
# Check response headers for Set-Cookie: BASTIONSRV=bastion1

# Step 2: Make subsequent requests with same cookie
for i in {1..10}; do
  curl -k -b cookies.txt https://10.10.1.100/api/status | grep -o 'bastion[12]'
done
# Expected: All requests go to same backend (bastion1 or bastion2)

# Step 3: Delete cookie and verify round-robin
rm cookies.txt
for i in {1..10}; do
  curl -k https://10.10.1.100/api/status | grep -o 'bastion[12]'
done
# Expected: Requests distributed between bastion1 and bastion2
```

---

## Troubleshooting

### 12.1 Common Issues and Resolution

#### Issue 1: VIP Not Responding

**Symptoms:**
- Cannot connect to VIP (10.10.X.100)
- Ping to VIP fails

**Diagnosis:**

```bash
# Check which server owns VIP
ip addr show bond0 | grep 10.10.X.100

# Check Keepalived status
systemctl status keepalived
journalctl -u keepalived -n 50

# Check VRRP state
grep -i "entering.*state" /var/log/syslog | tail -5
```

**Resolution:**

```bash
# If no server has VIP:
# 1. Restart Keepalived on primary
systemctl restart keepalived

# 2. Check authentication mismatch
grep "authentication" /etc/keepalived/keepalived.conf
# Ensure auth_pass matches on both nodes

# 3. Verify VRRP traffic allowed
tcpdump -i bond0 proto 112
# Expected: VRRP advertisements every 1 second
```

#### Issue 2: HAProxy Not Balancing Traffic

**Symptoms:**
- All traffic goes to one backend server
- One server shows 0% utilization

**Diagnosis:**

```bash
# Check backend status
echo "show stat" | socat stdio /var/run/haproxy.sock | grep wallix_bastion

# Check health check logs
journalctl -u haproxy | grep -i health

# Test backend directly
curl -k https://10.10.1.11/health
curl -k https://10.10.1.12/health
```

**Resolution:**

```bash
# If one backend is DOWN:
# 1. Verify backend service is running
ssh root@10.10.1.11 "systemctl status wallix-bastion"

# 2. Check firewall rules
ssh root@10.10.1.11 "iptables -L -n | grep 443"

# 3. Manually enable backend
echo "enable server wallix_bastion_https/bastion1" | socat stdio /var/run/haproxy.sock
```

#### Issue 3: SSL Certificate Errors

**Symptoms:**
- Browser shows "Certificate not trusted"
- `curl` returns SSL handshake failure

**Diagnosis:**

```bash
# Check certificate validity
openssl x509 -in /etc/haproxy/certs/wallix-bastion.pem -noout -dates

# Verify certificate chain
openssl s_client -connect 10.10.1.100:443 -servername bastion-site1.wallix.company.local

# Check HAProxy logs
journalctl -u haproxy | grep -i ssl
```

**Resolution:**

```bash
# 1. Verify certificate CN/SAN matches hostname
openssl x509 -in /etc/haproxy/certs/wallix-bastion.pem -noout -text | grep -A2 "Subject Alternative Name"

# 2. Check certificate chain order (private key → cert → intermediate → root)
openssl crl2pkcs7 -nocrl -certfile /etc/haproxy/certs/wallix-bastion.pem | openssl pkcs7 -print_certs -noout

# 3. Verify private key matches certificate
diff <(openssl x509 -in /etc/haproxy/certs/wallix-bastion.pem -noout -modulus | openssl md5) \
     <(openssl rsa -in /etc/haproxy/certs/wallix-bastion.pem -noout -modulus | openssl md5)
# Expected: No output (files match)

# 4. Reload HAProxy
systemctl reload haproxy
```

#### Issue 4: High Connection Timeouts

**Symptoms:**
- Users report slow connections
- HAProxy logs show "Connection timeout"

**Diagnosis:**

```bash
# Check connection queue
echo "show stat" | socat stdio /var/run/haproxy.sock | grep qcur

# Monitor real-time connection rate
watch -n 1 'echo "show info" | socat stdio /var/run/haproxy.sock | grep Conn'

# Check backend response times
echo "show stat" | socat stdio /var/run/haproxy.sock | grep rtime
```

**Resolution:**

```bash
# 1. Increase timeout values in haproxy.cfg
timeout connect 15s
timeout client  120s
timeout server  120s

# 2. Increase maxconn per backend
server bastion1 10.10.1.11:443 maxconn 3000

# 3. Check backend server load
ssh root@10.10.1.11 "top -bn1 | head -20"

# 4. Reload HAProxy
systemctl reload haproxy
```

#### Issue 5: Split-Brain (Both Nodes MASTER)

**Symptoms:**
- Both HAProxy servers claim VIP
- Duplicate IP warnings in network

**Diagnosis:**

```bash
# Check VRRP state on both nodes
# On HAProxy-1
systemctl status keepalived | grep STATE

# On HAProxy-2
systemctl status keepalived | grep STATE

# If both show MASTER: SPLIT-BRAIN DETECTED

# Check VRRP traffic
tcpdump -i bond0 proto 112
# Expected: Should see VRRP advertisements from BOTH nodes
```

**Resolution:**

```bash
# IMMEDIATE ACTION (prevents network issues):
# 1. Stop Keepalived on BACKUP node (lower priority)
systemctl stop keepalived   # On HAProxy-2

# 2. Verify VIP on single node
ip addr show bond0 | grep 10.10.X.100

# 3. Diagnose root cause:
# - Check VRRP authentication mismatch
grep auth_pass /etc/keepalived/keepalived.conf  # Must match both nodes

# - Check firewall blocking VRRP (IP proto 112)
iptables -L -n | grep 112

# - Check network connectivity between nodes
ping -c 5 10.10.X.6   # From HAProxy-1 to HAProxy-2

# 4. Fix configuration and restart
systemctl restart keepalived
```

### 12.2 Diagnostic Commands Reference

```bash
# HAProxy status and stats
systemctl status haproxy
echo "show info" | socat stdio /var/run/haproxy.sock
echo "show stat" | socat stdio /var/run/haproxy.sock
echo "show errors" | socat stdio /var/run/haproxy.sock

# Keepalived status
systemctl status keepalived
journalctl -u keepalived -f
ip addr show bond0 | grep vip

# Network connectivity
ping -c 4 10.10.X.11   # Backend server 1
ping -c 4 10.10.X.12   # Backend server 2
tcpdump -i bond0 port 443  # HTTPS traffic
tcpdump -i bond0 proto 112  # VRRP traffic

# SSL/TLS debugging
openssl s_client -connect 10.10.X.100:443 -servername bastion-siteX.wallix.company.local
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt /etc/haproxy/certs/wallix-bastion.pem

# Log analysis
tail -f /var/log/haproxy.log
journalctl -u haproxy -f
journalctl -u keepalived -f
```

### 12.3 Performance Troubleshooting

**High CPU usage:**

```bash
# Check HAProxy process CPU
top -p $(pidof haproxy)

# Check SSL/TLS overhead
echo "show info" | socat stdio /var/run/haproxy.sock | grep SslRate

# Mitigation: Enable TLS session reuse
# Already configured in haproxy.cfg:
tune.ssl.cachesize 100000
tune.ssl.lifetime 600
```

**High memory usage:**

```bash
# Check HAProxy memory
ps aux | grep haproxy

# Check connection buffers
echo "show pools" | socat stdio /var/run/haproxy.sock

# Mitigation: Tune buffer sizes
tune.bufsize 16384
tune.maxrewrite 1024
```

**Network saturation:**

```bash
# Check interface utilization
sar -n DEV 1 10

# Check bandwidth per backend
echo "show stat" | socat stdio /var/run/haproxy.sock | grep bout

# Mitigation: Enable compression (HTTPS only)
compression algo gzip
compression type text/html text/plain text/css application/json
```

---

## Operational Procedures

### 13.1 Daily Health Checks

**Automated monitoring script:**

Create `/usr/local/bin/haproxy-daily-check.sh`:

```bash
#!/bin/bash
#===============================================================================
# Daily HAProxy Health Check
# Runs every day at 08:00 via cron
#===============================================================================

LOGFILE="/var/log/haproxy-health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting daily health check" >> $LOGFILE

# Check 1: HAProxy service status
if ! systemctl is-active --quiet haproxy; then
    echo "[$DATE] CRITICAL: HAProxy service is not running!" >> $LOGFILE
    systemctl start haproxy
fi

# Check 2: Keepalived VRRP state
VRRP_STATE=$(systemctl status keepalived | grep -oP '(?<=Entering )\w+(?= STATE)' | tail -1)
echo "[$DATE] VRRP state: $VRRP_STATE" >> $LOGFILE

# Check 3: Backend server status
BACKEND_STATUS=$(echo "show stat" | socat stdio /var/run/haproxy.sock | grep wallix_bastion | grep -c "UP")
echo "[$DATE] Backend servers UP: $BACKEND_STATUS/2" >> $LOGFILE

if [ "$BACKEND_STATUS" -lt 1 ]; then
    echo "[$DATE] CRITICAL: No backend servers available!" >> $LOGFILE
fi

# Check 4: SSL certificate expiry
CERT_EXPIRY=$(openssl x509 -in /etc/haproxy/certs/wallix-bastion.pem -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$CERT_EXPIRY" +%s)
CURRENT_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))

echo "[$DATE] SSL certificate expires in $DAYS_UNTIL_EXPIRY days" >> $LOGFILE

if [ "$DAYS_UNTIL_EXPIRY" -lt 30 ]; then
    echo "[$DATE] WARNING: SSL certificate expires soon!" >> $LOGFILE
fi

# Check 5: Log rotation
LOG_SIZE=$(du -m /var/log/haproxy.log | cut -f1)
echo "[$DATE] HAProxy log size: ${LOG_SIZE}MB" >> $LOGFILE

if [ "$LOG_SIZE" -gt 1000 ]; then
    echo "[$DATE] WARNING: HAProxy log size exceeds 1GB, consider manual rotation" >> $LOGFILE
fi

echo "[$DATE] Health check completed" >> $LOGFILE
echo "========================================" >> $LOGFILE
```

**Install cron job:**

```bash
chmod +x /usr/local/bin/haproxy-daily-check.sh

# Add to crontab
crontab -e
# Add line:
0 8 * * * /usr/local/bin/haproxy-daily-check.sh
```

### 13.2 Maintenance Procedures

**Graceful HAProxy reload (zero downtime):**

```bash
# After configuration changes
haproxy -c -f /etc/haproxy/haproxy.cfg

# If syntax OK, reload gracefully
systemctl reload haproxy

# Verify reload successful
journalctl -u haproxy -n 20
```

**Drain connections before maintenance:**

```bash
# Put backend server in DRAIN mode (no new connections, existing finish)
echo "set server wallix_bastion_https/bastion1 state drain" | socat stdio /var/run/haproxy.sock

# Wait for active connections to finish
watch -n 5 'echo "show stat" | socat stdio /var/run/haproxy.sock | grep bastion1'

# When scur=0 (no active connections), put in MAINT mode
echo "set server wallix_bastion_https/bastion1 state maint" | socat stdio /var/run/haproxy.sock

# Perform maintenance on Bastion-1...

# Re-enable server
echo "set server wallix_bastion_https/bastion1 state ready" | socat stdio /var/run/haproxy.sock
```

**Planned failover for HAProxy maintenance:**

```bash
# Step 1: Transfer VIP to HAProxy-2
# On HAProxy-1
systemctl stop keepalived

# Step 2: Verify VIP transferred
# On HAProxy-2
ip addr show bond0 | grep 10.10.X.100

# Step 3: Perform maintenance on HAProxy-1
apt update && apt upgrade -y
systemctl restart haproxy

# Step 4: Restore Keepalived
systemctl start keepalived

# Step 5: Verify HAProxy-2 remains MASTER (due to nopreempt)
```

### 13.3 Emergency Procedures

**Emergency backend failover (force traffic to single node):**

```bash
# Scenario: Bastion-1 is malfunctioning but passing health checks

# Option 1: Disable backend server
echo "disable server wallix_bastion_https/bastion1" | socat stdio /var/run/haproxy.sock
echo "disable server wallix_bastion_ssh/bastion1" | socat stdio /var/run/haproxy.sock
echo "disable server wallix_bastion_rdp/bastion1" | socat stdio /var/run/haproxy.sock

# Option 2: Put in maintenance mode (preserves config)
echo "set server wallix_bastion_https/bastion1 state maint" | socat stdio /var/run/haproxy.sock

# Verify all traffic to bastion2
echo "show stat" | socat stdio /var/run/haproxy.sock | grep wallix_bastion
```

**Emergency VIP failover:**

```bash
# Scenario: HAProxy-1 unresponsive, force immediate failover

# On HAProxy-1 (if accessible)
systemctl stop keepalived
systemctl stop haproxy

# On HAProxy-2 (will automatically become MASTER within 3 seconds)
# Verify VIP migration
ip addr show bond0 | grep 10.10.X.100

# If VIP does not migrate automatically:
systemctl restart keepalived
```

**Rollback configuration:**

```bash
# Backup current config before changes
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.$(date +%Y%m%d-%H%M%S)

# If new config causes issues, restore backup
cp /etc/haproxy/haproxy.cfg.20260205-140000 /etc/haproxy/haproxy.cfg
systemctl reload haproxy
```

### 13.4 Backup and Recovery

**Configuration backup:**

```bash
# Backup script: /usr/local/bin/backup-haproxy-config.sh
#!/bin/bash
BACKUP_DIR="/backup/haproxy"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

# Backup configurations
tar -czf $BACKUP_DIR/haproxy-config-$DATE.tar.gz \
    /etc/haproxy/haproxy.cfg \
    /etc/keepalived/keepalived.conf \
    /etc/haproxy/certs/ \
    /usr/local/bin/check_haproxy.sh \
    /usr/local/bin/keepalived_notify.sh

# Keep only last 30 days of backups
find $BACKUP_DIR -name "haproxy-config-*.tar.gz" -mtime +30 -delete

echo "Backup completed: haproxy-config-$DATE.tar.gz"
```

**Disaster recovery:**

```bash
# Restore from backup
tar -xzf /backup/haproxy/haproxy-config-20260205-140000.tar.gz -C /

# Verify configurations
haproxy -c -f /etc/haproxy/haproxy.cfg

# Restart services
systemctl restart haproxy keepalived
```

---

## Appendix A: Configuration Files Reference

### Complete File Listing

```
/etc/haproxy/
├── haproxy.cfg                        # Main HAProxy configuration
├── certs/
│   └── wallix-bastion.pem             # SSL certificate bundle
└── errors/
    ├── 400.http
    ├── 403.http
    ├── 408.http
    ├── 500.http
    ├── 502.http
    ├── 503.http
    └── 504.http

/etc/keepalived/
└── keepalived.conf                    # Keepalived VRRP configuration

/usr/local/bin/
├── check_haproxy.sh                   # Health check script
├── keepalived_notify.sh               # State change notification
├── haproxy-daily-check.sh             # Daily health monitoring
└── backup-haproxy-config.sh           # Configuration backup

/etc/rsyslog.d/
└── 49-haproxy.conf                    # Rsyslog configuration

/etc/logrotate.d/
└── haproxy                            # Log rotation configuration

/var/log/
├── haproxy.log                        # HAProxy access logs
└── haproxy-health.log                 # Health check logs
```

---

## Appendix B: Port Reference

### Ports Used by HAProxy

| Port | Protocol | Purpose | Access |
|------|----------|---------|--------|
| 80 | TCP/HTTP | HTTP → HTTPS redirect | Public |
| 443 | TCP/HTTPS | Web UI, API (SSL termination) | Public |
| 22 | TCP/SSH | SSH proxy sessions | Public |
| 3389 | TCP/RDP | RDP proxy sessions | Public |
| 8404 | TCP/HTTP | Stats dashboard, Prometheus metrics | Management only |
| 112 | IP/VRRP | Keepalived heartbeat | Internal (HAProxy-1 ↔ HAProxy-2) |

### Backend Server Ports

| Backend | Port | Purpose |
|---------|------|---------|
| WALLIX Bastion-1 | 443 | HTTPS (Web UI, API) |
| WALLIX Bastion-1 | 22 | SSH proxy |
| WALLIX Bastion-1 | 3389 | RDP proxy |
| WALLIX Bastion-2 | 443 | HTTPS (Web UI, API) |
| WALLIX Bastion-2 | 22 | SSH proxy |
| WALLIX Bastion-2 | 3389 | RDP proxy |

---

## References

### Internal Documentation

- [00-prerequisites.md](00-prerequisites.md) - Hardware and software requirements
- [01-network-design.md](01-network-design.md) - Network topology and firewall rules
- [02-ha-architecture.md](02-ha-architecture.md) - HA architecture comparison (Active-Active vs Active-Passive)
- [06-bastion-active-active.md](06-bastion-active-active.md) - WALLIX Bastion Active-Active cluster setup
- [07-bastion-active-passive.md](07-bastion-active-passive.md) - WALLIX Bastion Active-Passive cluster setup

### External Resources

- HAProxy Documentation: https://www.haproxy.org/
- HAProxy 2.8 Configuration Manual: https://cbonte.github.io/haproxy-dconv/2.8/configuration.html
- Keepalived Documentation: https://www.keepalived.org/documentation.html
- VRRP Protocol (RFC 5798): https://tools.ietf.org/html/rfc5798
- TLS Best Practices: https://wiki.mozilla.org/Security/Server_Side_TLS

---

**Document Version**: 1.0
**Last Updated**: February 2026
**Validated By**: Network Engineering Team
**Approval Status**: Pending Production Deployment

**Next Steps**: Proceed to [06-bastion-active-active.md](06-bastion-active-active.md) or [07-bastion-active-passive.md](07-bastion-active-passive.md) for WALLIX Bastion cluster configuration.
