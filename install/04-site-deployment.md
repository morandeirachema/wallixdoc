# Site Deployment Template

> Per-site deployment guide for replicating WALLIX Bastion infrastructure across 5 datacenter site sites

---

## Table of Contents

1. [Overview](#overview)
2. [Site Deployment Phases](#site-deployment-phases)
3. [Phase 1: Infrastructure Preparation](#phase-1-infrastructure-preparation)
4. [Phase 2: HAProxy Load Balancer Deployment](#phase-2-haproxy-load-balancer-deployment)
5. [Phase 3: Bastion Cluster Deployment](#phase-3-bastion-cluster-deployment)
6. [Phase 4: WALLIX RDS Jump Host](#phase-4-wallix-rds-jump-host)
7. [Phase 5: Access Manager Integration](#phase-5-access-manager-integration)
8. [Phase 6: Site Testing](#phase-6-site-testing)
9. [Site Replication Checklist](#site-replication-checklist)
10. [Deployment Timeline](#deployment-timeline)

---

## Overview

This document provides a comprehensive, repeatable template for deploying WALLIX Bastion infrastructure at each of the 5 datacenter site sites. Each site contains identical components configured for local operation while integrating with centralized Access Managers.

### Per-Site Architecture

```
+===============================================================================+
|  PER-SITE DEPLOYMENT ARCHITECTURE                                             |
+===============================================================================+
|                                                                               |
|                            External Users / Operators                         |
|                                       |                                       |
|                                       v                                       |
|                          MPLS Network (from Access Managers)                  |
|                                       |                                       |
|                                       v                                       |
|                           +----------------------+                            |
|                           |  Fortigate Firewall  |                            |
|                           |  - SSL VPN           |                            |
|                           |  - RADIUS Proxy      |                            |
|                           +----------+-----------+                            |
|                                      |                                        |
|                                      v                                        |
|                          HAProxy VIP: 10.10.X.100                             |
|                                      |                                        |
|                      +---------------+---------------+                        |
|                      |                               |                        |
|              +-------v------+                +-------v------+                 |
|              |  HAProxy-1   |   Keepalived   |  HAProxy-2   |                 |
|              |  10.10.X.5   |<-------------->|  10.10.X.6   |                 |
|              |  (MASTER)    |     VRRP       |  (BACKUP)    |                 |
|              +--------------+                +--------------+                 |
|                      |                               |                        |
|                      +---------------+---------------+                        |
|                                      |                                        |
|                      +---------------+---------------+                        |
|                      |                               |                        |
|              +-------v------+                +-------v------+                 |
|              | WALLIX       |  Replication   | WALLIX       |                 |
|              | Bastion-1    |<-------------->| Bastion-2    |                 |
|              | 10.10.X.11   |  MariaDB HA    | 10.10.X.12   |                 |
|              | (Active)     |                | (Active)     |                 |
|              +--------------+                +--------------+                 |
|                      |                               |                        |
|                      +---------------+---------------+                        |
|                                      |                                        |
|                                      v                                        |
|                           +----------------------+                            |
|                           |  WALLIX RDS          |                            |
|                           |  10.10.X.30          |                            |
|                           |  (OT Jump Host)      |                            |
|                           +----------+-----------+                            |
|                                      |                                        |
|                                      v                                        |
|                           Target Systems (Windows/Linux)                      |
|                                                                               |
+===============================================================================+
```

### Site-Specific Components

Each site contains:

| Component | Quantity | Configuration | Purpose |
|-----------|----------|---------------|---------|
| **HAProxy** | 2 | Active-Passive with Keepalived VRRP | Load balancing with HA |
| **WALLIX Bastion** | 2 | Active-Active OR Active-Passive | PAM enforcement and session recording |
| **WALLIX RDS** | 1 | Standalone | Jump host for OT RemoteApp access |

### Site Locations

| Site | Datacenter | Subnet | HAProxy VIP | Notes |
|------|------------|--------|-------------|-------|
| **Site 1** | Site 1 DC (Building A) | 10.10.1.0/24 | 10.10.1.100 | Deploy first (reference) |
| **Site 2** | Site 2 DC (Building B) | 10.10.2.0/24 | 10.10.2.100 | Replicate from Site 1 |
| **Site 3** | Site 3 DC (Building C) | 10.10.3.0/24 | 10.10.3.100 | Replicate from Site 1 |
| **Site 4** | Site 4 DC (Building D) | 10.10.4.0/24 | 10.10.4.100 | Replicate from Site 1 |
| **Site 5** | Site 5 DC (Building E) | 10.10.5.0/24 | 10.10.5.100 | Replicate from Site 1 |

---

## Site Deployment Phases

### Deployment Strategy

**Site 1 (Reference Site)**: Deploy fully with detailed configuration and testing (3-4 weeks)

**Sites 2-5 (Replicated Sites)**: Use Site 1 as template, adjust site-specific parameters (1 week each)

### Phase Overview

```
+===============================================================================+
|  DEPLOYMENT PHASES (PER SITE)                                                 |
+===============================================================================+
|                                                                               |
|  Phase 1: Infrastructure Preparation                                          |
|  - Network configuration                                                      |
|  - IP addressing                                                              |
|  - DNS records                                                                |
|  - Firewall rules                                                             |
|  Duration: 1-2 days                                                           |
|                                                                               |
|  Phase 2: HAProxy Load Balancer Deployment                                    |
|  - Install and configure HAProxy-1 and HAProxy-2                              |
|  - Configure Keepalived VRRP                                                  |
|  - Test VIP failover                                                          |
|  Duration: 1-2 days                                                           |
|                                                                               |
|  Phase 3: Bastion Cluster Deployment                                          |
|  - Deploy WALLIX Bastion appliances                                           |
|  - Configure HA (Active-Active OR Active-Passive)                             |
|  - Configure MariaDB replication                                              |
|  - Test cluster failover                                                      |
|  Duration: 1-2 weeks (Site 1), 2-3 days (Sites 2-5)                          |
|                                                                               |
|  Phase 4: WALLIX RDS Jump Host                                                |
|  - Deploy Windows Server 2022                                                 |
|  - Install WALLIX RDS software                                                |
|  - Integrate with Bastion cluster                                             |
|  Duration: 2-3 days                                                           |
|                                                                               |
|  Phase 5: Access Manager Integration                                          |
|  - Configure SSO (SAML/OIDC)                                                  |
|  - Configure MFA (FortiAuthenticator)                                         |
|  - Configure session brokering                                                |
|  - Register site with Access Managers                                         |
|  Duration: 2-3 days                                                           |
|                                                                               |
|  Phase 6: Site Testing                                                        |
|  - End-to-end authentication testing                                          |
|  - Session recording validation                                               |
|  - HA failover testing                                                        |
|  - Performance benchmarking                                                   |
|  Duration: 3-5 days                                                           |
|                                                                               |
+===============================================================================+
```

---

## Phase 1: Infrastructure Preparation

### Step 1.1: Network Planning

Prepare site-specific network parameters:

**Site 1 Example (adjust for Sites 2-5):**

| Component | IP Address | Hostname | FQDN |
|-----------|------------|----------|------|
| HAProxy-1 | 10.10.1.5 | haproxy1-1 | haproxy1-1.company.com |
| HAProxy-2 | 10.10.1.6 | haproxy1-2 | haproxy1-2.company.com |
| HAProxy VIP | 10.10.1.100 | bastion-site1 | bastion-site1.company.com |
| Bastion-1 | 10.10.1.11 | bastion1-node1 | bastion1-node1.company.com |
| Bastion-2 | 10.10.1.12 | bastion1-node2 | bastion1-node2.company.com |
| WALLIX RDS | 10.10.1.30 | rds1 | rds1.company.com |
| Gateway | 10.10.1.1 | - | - |
| DNS Server | 10.10.0.10 | - | - |
| NTP Server | 10.10.0.11 | - | - |

**Template for Sites 2-5:**

Replace the third octet with site number:
- Site 2: `10.10.2.x`
- Site 3: `10.10.3.x`
- Site 4: `10.10.4.x`
- Site 5: `10.10.5.x`

### Step 1.2: DNS Records

Create DNS records for all site components:

```bash
# Site 1 DNS Records (adjust for Sites 2-5)

# HAProxy A Records
bastion-site1.company.com       A    10.10.1.100
haproxy1-1.company.com          A    10.10.1.5
haproxy1-2.company.com          A    10.10.1.6

# Bastion A Records
bastion1-node1.company.com      A    10.10.1.11
bastion1-node2.company.com      A    10.10.1.12

# RDS A Record
rds1.company.com                A    10.10.1.30

# PTR Records (Reverse DNS)
5.1.10.10.in-addr.arpa          PTR  haproxy1-1.company.com
6.1.10.10.in-addr.arpa          PTR  haproxy1-2.company.com
11.1.10.10.in-addr.arpa         PTR  bastion1-node1.company.com
12.1.10.10.in-addr.arpa         PTR  bastion1-node2.company.com
30.1.10.10.in-addr.arpa         PTR  rds1.company.com
100.1.10.10.in-addr.arpa        PTR  bastion-site1.company.com
```

**Verify DNS:**

```bash
# Forward lookup
nslookup bastion-site1.company.com
nslookup bastion1-node1.company.com

# Reverse lookup
nslookup 10.10.1.100
nslookup 10.10.1.11

# Expected: Correct IP addresses and hostnames
```

### Step 1.3: Firewall Rules Configuration

Configure firewall rules for site-internal and external connectivity:

**Inbound to Site (from Access Managers):**

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Access Manager 1 | HAProxy VIP | 443 | TCP | HTTPS API, session brokering |
| Access Manager 2 | HAProxy VIP | 443 | TCP | HTTPS API, session brokering |
| Users (via VPN) | HAProxy VIP | 443 | TCP | HTTPS Web UI |
| Users (via VPN) | HAProxy VIP | 22 | TCP | SSH proxy |
| Users (via VPN) | HAProxy VIP | 3389 | TCP | RDP proxy |

**Within Site (Internal):**

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| HAProxy-1 | Bastion-1, Bastion-2 | 443 | TCP | Load balancing |
| HAProxy-1 | Bastion-1, Bastion-2 | 22 | TCP | SSH proxy |
| HAProxy-1 | Bastion-1, Bastion-2 | 3389 | TCP | RDP proxy |
| HAProxy-2 | Bastion-1, Bastion-2 | 443 | TCP | Load balancing |
| HAProxy-2 | Bastion-1, Bastion-2 | 22 | TCP | SSH proxy |
| HAProxy-2 | Bastion-1, Bastion-2 | 3389 | TCP | RDP proxy |
| Bastion-1 | Bastion-2 | 3306 | TCP | MariaDB replication |
| Bastion-2 | Bastion-1 | 3306 | TCP | MariaDB replication |
| Bastion-1 | Bastion-2 | 5404-5406 | UDP | Corosync (if Active-Active) |
| Bastion-1 | Bastion-2 | 2224 | TCP | Pacemaker (if Active-Active) |
| Bastion-1, Bastion-2 | WALLIX RDS | 3389 | TCP | RDP to jump host |

**Outbound from Site:**

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion-1, Bastion-2 | Access Manager | 443 | TCP | SSO callbacks, health checks |
| Bastion-1, Bastion-2 | FortiAuthenticator | 1812 | UDP | RADIUS authentication |
| Bastion-1, Bastion-2 | FortiAuthenticator | 1813 | UDP | RADIUS accounting |
| Bastion-1, Bastion-2 | Active Directory | 389 | TCP | LDAP authentication |
| Bastion-1, Bastion-2 | Active Directory | 636 | TCP | LDAPS (secure) |
| Bastion-1, Bastion-2 | Active Directory | 88 | TCP/UDP | Kerberos |
| Bastion-1, Bastion-2 | NTP Server | 123 | UDP | Time sync |
| Bastion-1, Bastion-2 | DNS Server | 53 | UDP/TCP | Name resolution |
| Bastion-1, Bastion-2 | Target Systems | 22 | TCP | SSH to Linux targets |
| Bastion-1, Bastion-2 | Target Systems | 3389 | TCP | RDP to Windows targets |
| WALLIX RDS | Target Systems | 3389 | TCP | RDP to OT targets |

**Test Connectivity:**

```bash
# From Bastion-1, test key connections
ssh admin@bastion1-node1.company.com

# Test Access Manager connectivity
curl -v https://accessmanager.company.com/health

# Test FortiAuthenticator RADIUS
nc -zvu fortiauth.company.com 1812

# Test Active Directory LDAP
nc -zv dc01.company.com 636

# Test NTP
ntpdate -q ntp.company.com

# Test DNS
nslookup company.com
```

### Step 1.4: SSL/TLS Certificates

Obtain SSL certificates for site components:

**Certificate Requirements:**

| Component | Certificate Type | Subject/SAN |
|-----------|------------------|-------------|
| HAProxy VIP | Wildcard or site-specific | bastion-site1.company.com |
| Bastion-1 | Internal CA or self-signed | bastion1-node1.company.com |
| Bastion-2 | Internal CA or self-signed | bastion1-node2.company.com |

**Generate CSR (Certificate Signing Request):**

```bash
# Generate CSR for HAProxy VIP certificate
openssl req -new -newkey rsa:2048 -nodes \
  -keyout bastion-site1.key \
  -out bastion-site1.csr \
  -subj "/C=FR/ST=Ile-de-France/L=CityName/O=Company/CN=bastion-site1.company.com"

# Submit CSR to internal CA or public CA
# Receive certificate: bastion-site1.crt
# Receive CA chain: ca-chain.crt

# Create combined PEM for HAProxy
cat bastion-site1.crt bastion-site1.key ca-chain.crt > bastion-site1.pem
```

---

## Phase 2: HAProxy Load Balancer Deployment

Deploy and configure 2 HAProxy servers in Active-Passive HA configuration.

**Reference**: See [05-haproxy-setup.md](05-haproxy-setup.md) for complete HAProxy installation and configuration.

### Step 2.1: HAProxy Server Preparation

**Both HAProxy-1 and HAProxy-2:**

```bash
# Install Debian 12 or RHEL 9
# Configure static IP addresses

# HAProxy-1
hostnamectl set-hostname haproxy1-1.company.com
nmcli con mod eth0 ipv4.addresses 10.10.1.5/24
nmcli con mod eth0 ipv4.gateway 10.10.1.1
nmcli con mod eth0 ipv4.dns 10.10.0.10
nmcli con up eth0

# HAProxy-2
hostnamectl set-hostname haproxy1-2.company.com
nmcli con mod eth0 ipv4.addresses 10.10.1.6/24
nmcli con mod eth0 ipv4.gateway 10.10.1.1
nmcli con mod eth0 ipv4.dns 10.10.0.10
nmcli con up eth0

# Update /etc/hosts
cat >> /etc/hosts << 'EOF'
10.10.1.5   haproxy1-1.company.com haproxy1-1
10.10.1.6   haproxy1-2.company.com haproxy1-2
10.10.1.11  bastion1-node1.company.com bastion1-node1
10.10.1.12  bastion1-node2.company.com bastion1-node2
10.10.1.100 bastion-site1.company.com bastion-site1
EOF
```

### Step 2.2: Install HAProxy and Keepalived

```bash
# On both HAProxy-1 and HAProxy-2

# Debian 12
apt update && apt install -y haproxy keepalived

# RHEL 9
dnf install -y haproxy keepalived

# Enable services
systemctl enable haproxy keepalived
```

### Step 2.3: Configure HAProxy

Create HAProxy configuration (same on both nodes):

```bash
# Backup default config
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig

# Create new configuration
cat > /etc/haproxy/haproxy.cfg << 'EOF'
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # SSL/TLS settings
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

#---------------------------------------------------------------------
# Default settings
#---------------------------------------------------------------------
defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    option  redispatch
    timeout connect 10s
    timeout client  1h
    timeout server  1h
    timeout tunnel  1h
    timeout client-fin 30s
    timeout server-fin 30s

#---------------------------------------------------------------------
# Stats page
#---------------------------------------------------------------------
listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if LOCALHOST

#---------------------------------------------------------------------
# WALLIX Bastion HTTPS Frontend (Web UI)
#---------------------------------------------------------------------
frontend wallix_https
    bind 10.10.1.100:443
    mode tcp
    option tcplog
    default_backend wallix_https_backend
    maxconn 2000

backend wallix_https_backend
    mode tcp
    balance roundrobin
    option tcp-check
    option log-health-checks

    # Active-Active: both nodes serve traffic
    server bastion1-node1 10.10.1.11:443 check inter 5s rise 2 fall 3 maxconn 1000
    server bastion1-node2 10.10.1.12:443 check inter 5s rise 2 fall 3 maxconn 1000

#---------------------------------------------------------------------
# WALLIX Bastion SSH Proxy Frontend
#---------------------------------------------------------------------
frontend wallix_ssh
    bind 10.10.1.100:22
    mode tcp
    option tcplog
    default_backend wallix_ssh_backend
    maxconn 500

backend wallix_ssh_backend
    mode tcp
    balance leastconn
    option tcp-check
    option log-health-checks

    server bastion1-node1 10.10.1.11:22 check inter 5s rise 2 fall 3
    server bastion1-node2 10.10.1.12:22 check inter 5s rise 2 fall 3

#---------------------------------------------------------------------
# WALLIX Bastion RDP Proxy Frontend
#---------------------------------------------------------------------
frontend wallix_rdp
    bind 10.10.1.100:3389
    mode tcp
    option tcplog
    default_backend wallix_rdp_backend
    maxconn 500

backend wallix_rdp_backend
    mode tcp
    balance leastconn
    option tcp-check
    option log-health-checks

    server bastion1-node1 10.10.1.11:3389 check inter 5s rise 2 fall 3
    server bastion1-node2 10.10.1.12:3389 check inter 5s rise 2 fall 3

EOF

# Validate configuration
haproxy -c -f /etc/haproxy/haproxy.cfg

# Start HAProxy (don't start yet - wait for Keepalived)
```

### Step 2.4: Configure Keepalived VRRP

**On HAProxy-1 (MASTER):**

```bash
cat > /etc/keepalived/keepalived.conf << 'EOF'
global_defs {
    router_id HAPROXY_SITE1
    enable_script_security
}

vrrp_script check_haproxy {
    script "/usr/bin/systemctl is-active haproxy"
    interval 2
    weight -20
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass SecurePassword123!
    }

    virtual_ipaddress {
        10.10.1.100/24 dev eth0
    }

    track_script {
        check_haproxy
    }
}
EOF

# Start services
systemctl restart keepalived
systemctl restart haproxy

# Verify VIP is assigned
ip addr show eth0 | grep 10.10.1.100
```

**On HAProxy-2 (BACKUP):**

```bash
cat > /etc/keepalived/keepalived.conf << 'EOF'
global_defs {
    router_id HAPROXY_SITE1
    enable_script_security
}

vrrp_script check_haproxy {
    script "/usr/bin/systemctl is-active haproxy"
    interval 2
    weight -20
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 90
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass SecurePassword123!
    }

    virtual_ipaddress {
        10.10.1.100/24 dev eth0
    }

    track_script {
        check_haproxy
    }
}
EOF

# Start services
systemctl restart keepalived
systemctl restart haproxy

# Verify VIP is NOT assigned (BACKUP state)
ip addr show eth0 | grep 10.10.1.100
# Expected: No VIP (it's on MASTER)
```

### Step 2.5: Test HAProxy HA

```bash
# Test VIP connectivity
ping -c 5 10.10.1.100

# Test VIP failover
# On HAProxy-1 (MASTER):
systemctl stop haproxy

# Wait 5 seconds, then check VIP on HAProxy-2 (BACKUP):
ip addr show eth0 | grep 10.10.1.100
# Expected: VIP should now be on HAProxy-2

# Restore HAProxy-1
systemctl start haproxy
# VIP should fail back to HAProxy-1 after 5 seconds
```

---

## Phase 3: Bastion Cluster Deployment

Deploy 2 WALLIX Bastion HW appliances in HA configuration.

**Choose HA Model:**
- **Active-Active**: See [06-bastion-active-active.md](06-bastion-active-active.md)
- **Active-Passive**: See [07-bastion-active-passive.md](07-bastion-active-passive.md)

### Step 3.1: Initial Appliance Setup

**Bastion-1 (Primary Node):**

```bash
# Console access to appliance
# Initial setup wizard will prompt for:

# 1. Network Configuration
IP Address:      10.10.1.11
Netmask:         255.255.255.0
Gateway:         10.10.1.1
DNS:             10.10.0.10
Hostname:        bastion1-node1

# 2. Admin Account
Admin User:      admin
Admin Password:  [Strong password - store in vault]

# 3. License Activation
License File:    [Upload bastion-license.lic]

# After initial setup, SSH to appliance
ssh admin@10.10.1.11

# Complete basic configuration
wabadmin system-config \
  --hostname bastion1-node1.company.com \
  --timezone "Europe/Paris" \
  --ntp-server ntp.company.com

# Set management VLAN (if applicable)
wabadmin network-config \
  --interface eth0 \
  --ip 10.10.1.11/24 \
  --gateway 10.10.1.1

# Enable HTTPS access
wabadmin web-config --enable --port 443

# Reboot to apply changes
wabadmin reboot
```

**Bastion-2 (Secondary Node):**

```bash
# Repeat same process with site-specific parameters

IP Address:      10.10.1.12
Hostname:        bastion1-node2

# SSH to appliance
ssh admin@10.10.1.12

# Configure basic settings
wabadmin system-config \
  --hostname bastion1-node2.company.com \
  --timezone "Europe/Paris" \
  --ntp-server ntp.company.com

wabadmin network-config \
  --interface eth0 \
  --ip 10.10.1.12/24 \
  --gateway 10.10.1.1

wabadmin web-config --enable --port 443
wabadmin reboot
```

### Step 3.2: Configure High Availability

**Option A: Active-Active Configuration**

See [06-bastion-active-active.md](06-bastion-active-active.md) for complete instructions.

**Quick Overview:**

1. Configure MariaDB multi-master replication (Galera or MaxScale)
2. Configure Pacemaker/Corosync cluster
3. Enable session state synchronization
4. Test cluster split-brain protection
5. Verify load balancing through HAProxy

**Option B: Active-Passive Configuration**

See [07-bastion-active-passive.md](07-bastion-active-passive.md) for complete instructions.

**Quick Overview:**

1. Configure MariaDB primary-replica replication
2. Configure automated failover (Pacemaker or manual)
3. Test failover procedure
4. Verify passive node readiness
5. Document manual failover steps

### Step 3.3: Essential Bastion Configuration

**On Primary Node (Bastion-1):**

```bash
# Configure authentication domains
wabadmin domain create \
  --name "company.com" \
  --type "Active Directory" \
  --ldap-url "ldaps://dc01.company.com:636" \
  --bind-dn "CN=WALLIX-SVC,OU=Service Accounts,DC=company,DC=com" \
  --bind-password "ServiceAccountPassword" \
  --base-dn "DC=company,DC=com"

# Configure RADIUS (FortiAuthenticator MFA)
wabadmin radius-config \
  --server fortiauth.company.com \
  --port 1812 \
  --secret "RadiusSharedSecret" \
  --timeout 30

# Enable audit logging
wabadmin audit-config \
  --enable \
  --syslog-server syslog.company.com \
  --syslog-port 514 \
  --retention-days 90

# Configure session recording
wabadmin recording-config \
  --enable \
  --storage-path /var/wab/recorded_sessions \
  --retention-days 90 \
  --compression gzip

# Configure backup
wabadmin backup-config \
  --enable \
  --schedule "0 2 * * *" \
  --destination nfs://backup.company.com/wallix/site1 \
  --retention-days 30

# Verify configuration
wabadmin config-show
```

### Step 3.4: Test Bastion Cluster

```bash
# Test cluster status
wabadmin cluster-status

# Expected output (Active-Active):
# Cluster Status: ONLINE
# Node 1: bastion1-node1 - ACTIVE
# Node 2: bastion1-node2 - ACTIVE
# MariaDB Replication: OK
# Configuration Sync: OK

# Test web UI access via HAProxy VIP
curl -k https://10.10.1.100/health

# Expected: HTTP 200 OK

# Test database replication
wabadmin db-replication-status

# Expected: Replication delay < 1 second
```

---

## Phase 4: WALLIX RDS Jump Host

Deploy Windows Server 2022 with WALLIX RDS software for OT RemoteApp access.

**Reference**: See [08-rds-jump-host.md](08-rds-jump-host.md) for complete RDS installation and configuration.

### Step 4.1: Deploy Windows Server VM

**VM Specifications:**

```
Hostname:    rds1.company.com
OS:          Windows Server 2022 Standard
vCPU:        4
RAM:         8 GB
Disk:        100 GB
IP:          10.10.1.30/24
Gateway:     10.10.1.1
DNS:         10.10.0.10
```

**Initial Configuration:**

```powershell
# Set computer name
Rename-Computer -NewName "rds1" -Restart

# After reboot, configure network
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.10.1.30 `
    -PrefixLength 24 -DefaultGateway 10.10.1.1

Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
    -ServerAddresses 10.10.0.10,8.8.8.8

# Set timezone
Set-TimeZone -Name "Romance Standard Time"  # time

# Enable RDP (for management)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
    -Name "fDenyTSConnections" -Value 0

Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

### Step 4.2: Join Active Directory

```powershell
# Join AD domain
$domain = "company.com"
$credential = Get-Credential -Message "Enter domain admin credentials"

Add-Computer -DomainName $domain -Credential $credential -Restart
```

### Step 4.3: Install WALLIX RDS Software

```powershell
# Download WALLIX RDS installer from WALLIX Support Portal
# https://support.wallix.com/downloads/

# Install prerequisites
Install-WindowsFeature -Name NET-Framework-45-Features -IncludeAllSubFeature
Install-WindowsFeature -Name NET-Framework-Core

# Install Visual C++ Redistributables
$vcredist = "C:\Temp\vc_redist.x64.exe"
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile $vcredist
Start-Process -FilePath $vcredist -Args "/install /quiet /norestart" -Wait

# Run WALLIX RDS installer
# C:\Temp\WALLIX_Session_Manager_12.x_x64.exe
# Follow installation wizard

# Configure connection to Bastion cluster
# Bastion Cluster VIP: https://10.10.1.100
# API Key: [Generated from Bastion]
```

### Step 4.4: Register RDS with Bastion

**On Bastion-1:**

```bash
# Generate API key for RDS
wabadmin api-key create \
  --name "RDS-Site1" \
  --permissions "session.create,session.proxy,recording.upload" \
  --validity 365

# Output: API Key: RDS_abc123def456...

# Register RDS jump host
wabadmin rds-register \
  --name "RDS-Site1" \
  --host rds1.company.com \
  --ip 10.10.1.30 \
  --port 3389 \
  --api-key "RDS_abc123def456..."

# Verify registration
wabadmin rds-list
```

### Step 4.5: Test RDS Connectivity

```powershell
# On RDS server, test connection to Bastion
Test-NetConnection -ComputerName 10.10.1.11 -Port 443

# Test RDP to target system via Bastion
# Use WALLIX RDS client to initiate session
```

---

## Phase 5: Access Manager Integration

Integrate site with centralized Access Managers for SSO, MFA, and session brokering.

**Reference**: See [03-access-manager-integration.md](03-access-manager-integration.md) for complete integration steps.

### Step 5.1: Export Bastion SAML Metadata

**On Bastion-1:**

```bash
# Export SAML SP metadata
wabadmin saml-export-metadata --output /tmp/bastion-site1-sp-metadata.xml

# Download metadata file
scp admin@bastion1-node1.company.com:/tmp/bastion-site1-sp-metadata.xml .
```

### Step 5.2: Register Site with Access Manager

**Coordinate with Access Manager team:**

Send the following information:
- **Site Name**: Site 1 - Site 1 DC
- **Site ID**: site1
- **Entity ID**: https://bastion-site1.company.com
- **SP Metadata**: bastion-site1-sp-metadata.xml
- **API Endpoint**: https://bastion-site1.company.com/api/v1
- **Health Check**: https://bastion-site1.company.com/health

**Access Manager team will provide:**
- IdP metadata XML file
- Session brokering API key
- RADIUS configuration (if not already configured)

### Step 5.3: Configure SSO on Bastion

**On Bastion-1:**

```bash
# Import IdP metadata from Access Manager
wabadmin saml-import-idp \
  --metadata /tmp/access-manager-idp-metadata.xml \
  --name "AccessManager-IdP" \
  --default-domain "company.com"

# Enable SAML authentication
wabadmin auth-config --enable-saml --idp "AccessManager-IdP"

# Configure SSO settings
wabadmin saml-config \
  --auto-create-users \
  --update-attributes \
  --enforce-sso

# Test SSO configuration
wabadmin test sso --user testuser
```

### Step 5.4: Configure Session Brokering

**On Bastion-1:**

```bash
# Generate API key for Access Manager to call Bastion
wabadmin api-key create \
  --name "AccessManager-SessionBroker" \
  --permissions "session.create,session.query,health.read" \
  --validity 365

# Output: API Key: AM_broker_xyz789...
# Share this key with Access Manager team

# Configure Bastion to register with Access Manager
wabadmin session-broker enable \
  --broker-url "https://accessmanager.company.com/api/v1" \
  --site-id "site1" \
  --api-key "YOUR_BASTION_API_KEY" \
  --health-check-port 443

# Configure health check endpoint
wabadmin health-check configure \
  --enable \
  --path "/health" \
  --checks "database,cluster,sessions,disk"

# Register with broker
wabadmin session-broker register

# Verify registration
wabadmin session-broker status
```

### Step 5.5: Test End-to-End Integration

```bash
# Test SSO flow
# 1. Open browser: https://bastion-site1.company.com
# 2. Verify redirect to Access Manager
# 3. Login with AD credentials + MFA
# 4. Verify redirect back to Bastion

# Test session brokering
wabadmin test session-broker --user testuser

# Verify site is visible to Access Manager
# (Check with Access Manager team)
```

---

## Phase 6: Site Testing

Comprehensive testing to validate site deployment.

### Step 6.1: Authentication Testing

```bash
# Test 1: Local authentication (for testing)
ssh testuser@bastion-site1.company.com

# Test 2: SSO authentication via Access Manager
# Open browser: https://bastion-site1.company.com
# Verify SSO redirect and login

# Test 3: MFA challenge
# Login and verify FortiToken push notification

# Test 4: LDAP/AD authentication
wabadmin test auth --user testuser --method ldap

# Test 5: RADIUS MFA
wabadmin test auth --user testuser --method radius
```

### Step 6.2: Session Recording Testing

```bash
# Test 1: SSH session recording
ssh -o ProxyCommand='ssh -W %h:%p bastion-site1.company.com' testuser@linux-target.company.com

# Perform some commands, then disconnect

# Verify recording
wabadmin recordings list --last 10

# Test 2: RDP session recording
# Connect via RDP to bastion-site1.company.com
# Select Windows target
# Verify session is recorded

# Test 3: RDS jump host session
# Connect to OT target via RDS
# Verify recording includes OCR data
```

### Step 6.3: High Availability Testing

```bash
# Test 1: HAProxy failover
# On HAProxy-1 (MASTER):
systemctl stop haproxy

# Verify VIP migrates to HAProxy-2
ping -c 5 10.10.1.100

# Verify sessions continue without interruption

# Restore HAProxy-1
systemctl start haproxy

# Test 2: Bastion node failover (Active-Active)
# On Bastion-1:
wabadmin cluster-failover-test --node bastion1-node1

# Verify sessions are redistributed to Bastion-2
# Verify no session loss

# Test 3: Bastion node failover (Active-Passive)
# Stop Bastion-1
systemctl stop wallix-bastion

# Verify failover to Bastion-2 (30-60 seconds)
# Verify services restored on passive node

# Test 4: Database replication
wabadmin db-replication-test

# Verify replication lag < 1 second
```

### Step 6.4: Performance Benchmarking

```bash
# Test 1: Concurrent session capacity
# Use load testing tool to simulate concurrent users

# Target: 90-100 concurrent sessions per site

# Test 2: Session establishment latency
wabadmin performance-test --sessions 50 --duration 300

# Target: < 2 seconds session establishment time

# Test 3: Recording storage performance
# Simulate heavy recording load
# Verify disk I/O sufficient for recordings

# Test 4: Network throughput
# Test RDP session quality
# Target: < 100ms latency, no packet loss
```

### Step 6.5: Backup and Restore Testing

```bash
# Test 1: Configuration backup
wabadmin backup create --type config --output /tmp/config-backup.tar.gz

# Test 2: Database backup
wabadmin backup create --type database --output /tmp/db-backup.sql.gz

# Test 3: Restore test (on Bastion-2 for testing)
wabadmin backup restore --file /tmp/config-backup.tar.gz --dry-run

# Verify no errors

# Test 4: Automated backup schedule
wabadmin backup-schedule verify

# Verify backups running as scheduled
```

---

## Site Replication Checklist

Use this checklist when replicating Site 1 configuration to Sites 2-5.

### Site-Specific Parameters

| Parameter | Site 1 | Site 2 | Site 3 | Site 4 | Site 5 |
|-----------|--------|--------|--------|--------|--------|
| **Subnet** | 10.10.1.0/24 | 10.10.2.0/24 | 10.10.3.0/24 | 10.10.4.0/24 | 10.10.5.0/24 |
| **HAProxy-1 IP** | 10.10.1.5 | 10.10.2.5 | 10.10.3.5 | 10.10.4.5 | 10.10.5.5 |
| **HAProxy-2 IP** | 10.10.1.6 | 10.10.2.6 | 10.10.3.6 | 10.10.4.6 | 10.10.5.6 |
| **HAProxy VIP** | 10.10.1.100 | 10.10.2.100 | 10.10.3.100 | 10.10.4.100 | 10.10.5.100 |
| **Bastion-1 IP** | 10.10.1.11 | 10.10.2.11 | 10.10.3.11 | 10.10.4.11 | 10.10.5.11 |
| **Bastion-2 IP** | 10.10.1.12 | 10.10.2.12 | 10.10.3.12 | 10.10.4.12 | 10.10.5.12 |
| **RDS IP** | 10.10.1.30 | 10.10.2.30 | 10.10.3.30 | 10.10.4.30 | 10.10.5.30 |
| **Site ID** | site1 | site2 | site3 | site4 | site5 |
| **FQDN** | bastion-site1.company.com | bastion-site2.company.com | bastion-site3.company.com | bastion-site4.company.com | bastion-site5.company.com |

### Replication Steps

```
+===============================================================================+
|  SITE REPLICATION CHECKLIST (Sites 2-5)                                      |
+===============================================================================+

Phase 1: Infrastructure Preparation
[ ] DNS records created for site components
[ ] Firewall rules configured (same as Site 1)
[ ] SSL certificates obtained for site FQDN
[ ] Network connectivity tested (MPLS, DNS, NTP)
[ ] Site-specific IP addresses allocated

Phase 2: HAProxy Deployment
[ ] HAProxy-1 and HAProxy-2 VMs deployed
[ ] Static IPs configured (10.10.X.5, 10.10.X.6)
[ ] HAProxy and Keepalived installed
[ ] HAProxy configuration copied from Site 1 (adjust IPs)
[ ] Keepalived configuration copied from Site 1 (adjust IPs)
[ ] VIP failover tested (10.10.X.100)
[ ] HAProxy stats page accessible (http://10.10.X.5:8404/stats)

Phase 3: Bastion Cluster Deployment
[ ] Bastion-1 and Bastion-2 HW appliances racked and powered
[ ] Initial appliance configuration completed (IPs, hostnames)
[ ] License file installed (shared pool across all sites)
[ ] HA configuration completed (Active-Active OR Active-Passive)
[ ] MariaDB replication configured
[ ] Cluster status verified (wabadmin cluster-status)
[ ] Authentication domains configured (copied from Site 1)
[ ] RADIUS MFA configured (FortiAuthenticator)
[ ] Audit logging configured (syslog to SIEM)
[ ] Session recording configured
[ ] Backup schedule configured

Phase 4: WALLIX RDS Deployment
[ ] Windows Server 2022 VM deployed
[ ] Static IP configured (10.10.X.30)
[ ] Joined to Active Directory
[ ] WALLIX RDS software installed
[ ] Registered with Bastion cluster
[ ] Connectivity to OT targets tested

Phase 5: Access Manager Integration
[ ] SAML SP metadata exported from Bastion
[ ] Site registered with Access Manager (via AM team)
[ ] IdP metadata imported to Bastion
[ ] SSO authentication configured and tested
[ ] Session brokering configured
[ ] API keys exchanged (Bastion <-> Access Manager)
[ ] Health check endpoint tested
[ ] Site visible in Access Manager dashboard

Phase 6: Site Testing
[ ] Authentication tested (SSO, LDAP, RADIUS)
[ ] MFA flow tested (FortiToken push)
[ ] SSH session recording tested
[ ] RDP session recording tested
[ ] RDS jump host session tested
[ ] HAProxy failover tested
[ ] Bastion HA failover tested
[ ] Performance benchmark completed (90-100 concurrent sessions)
[ ] Backup and restore tested

Documentation:
[ ] Site-specific network diagram updated
[ ] Configuration exported and documented
[ ] Passwords and API keys stored in vault
[ ] Handoff to operations team completed

+===============================================================================+
```

---

## Deployment Timeline

### Site 1 (Reference Site) - 3-4 Weeks

| Week | Phase | Activities | Duration |
|------|-------|------------|----------|
| **Week 1** | Infrastructure + HAProxy | Network prep, DNS, firewall, HAProxy deployment, VIP testing | 5 days |
| **Week 2-3** | Bastion Cluster | Appliance deployment, HA configuration, authentication, testing | 10 days |
| **Week 3-4** | RDS + Integration | RDS deployment, Access Manager integration, SSO, MFA | 5 days |
| **Week 4** | Testing + Documentation | End-to-end testing, performance benchmarking, documentation | 5 days |

**Total Site 1**: 25 days (3-4 weeks with buffer)

### Sites 2-5 (Replicated Sites) - 1 Week Each

| Day | Phase | Activities |
|-----|-------|------------|
| **Day 1** | Infrastructure + HAProxy | Network prep, HAProxy deployment (copy Site 1 config), VIP testing |
| **Day 2-3** | Bastion Cluster | Appliance deployment, HA configuration (copy Site 1 config) |
| **Day 4** | RDS | RDS deployment (copy Site 1 config) |
| **Day 5** | Integration | Access Manager integration (register site, test SSO) |
| **Day 6-7** | Testing | End-to-end testing, performance validation |

**Total per Site**: 7 days (1 week)

### Overall Deployment Timeline

```
+===============================================================================+
|  OVERALL DEPLOYMENT TIMELINE (All 5 Sites)                                    |
+===============================================================================+
|                                                                               |
|  Week 1-4:   Site 1 Deployment (Reference Site)                               |
|  Week 5:     Site 2 Deployment (Replicate from Site 1)                        |
|  Week 6:     Site 3 Deployment (Replicate from Site 1)                        |
|  Week 7:     Site 4 Deployment (Replicate from Site 1)                        |
|  Week 8:     Site 5 Deployment (Replicate from Site 1)                        |
|  Week 9:     Final Integration and Testing (All Sites)                        |
|  Week 10:    Go-Live and Handoff                                              |
|                                                                               |
|  Total Duration: 10 weeks (2.5 months)                                        |
|                                                                               |
+===============================================================================+
```

### Critical Path

1. **Week 1**: Infrastructure readiness (network, DNS, firewall)
2. **Week 2-3**: Site 1 Bastion cluster (first deployment, thorough testing)
3. **Week 4**: Site 1 validation (reference for replication)
4. **Week 5-8**: Parallel site deployments (Sites 2-5)
5. **Week 9**: Cross-site integration testing
6. **Week 10**: Production go-live

### Parallel Deployment Option (Faster)

If resources permit, Sites 2-5 can be deployed in parallel:

```
Week 1-4:  Site 1 (Reference)
Week 5-6:  Sites 2 and 3 (Parallel)
Week 7-8:  Sites 4 and 5 (Parallel)
Week 9:    Integration Testing (All Sites)
Week 10:   Go-Live

Total Duration: 10 weeks (same, but more resource-intensive)
```

---

## Best Practices for Site Replication

### Configuration Management

1. **Version Control**: Store all configuration files in Git repository
2. **Templates**: Create templates for site-specific parameters
3. **Automation**: Use Ansible or Terraform for repeatable deployments
4. **Documentation**: Maintain per-site documentation with actual values

### Testing Strategy

1. **Site 1 Thorough Testing**: Validate all functionality before replication
2. **Incremental Replication**: Deploy one site at a time, validate before next
3. **Automated Testing**: Use scripts to verify configurations
4. **Performance Baselines**: Compare each site against Site 1 benchmarks

### Team Coordination

1. **Daily Standups**: Brief status meetings during deployment
2. **Issue Tracking**: Use ticketing system for issues and blockers
3. **Runbook Updates**: Document lessons learned from Site 1
4. **Access Manager Team**: Maintain regular communication for integration

### Risk Mitigation

1. **Rollback Plans**: Document rollback procedures for each phase
2. **Maintenance Windows**: Schedule deployments during approved windows
3. **Backup Everything**: Take backups before each major change
4. **Parallel Testing**: Keep Site 1 running while deploying Sites 2-5

---

## Related Documentation

| Document | Description |
|----------|-------------|
| [00-prerequisites.md](00-prerequisites.md) | Hardware, network, licensing requirements |
| [01-network-design.md](01-network-design.md) | MPLS topology, firewall rules, port matrix |
| [02-ha-architecture.md](02-ha-architecture.md) | Active-Active vs Active-Passive comparison |
| [03-access-manager-integration.md](03-access-manager-integration.md) | SSO, MFA, session brokering |
| [05-haproxy-setup.md](05-haproxy-setup.md) | HAProxy load balancer configuration |
| [06-bastion-active-active.md](06-bastion-active-active.md) | Active-Active cluster setup |
| [07-bastion-active-passive.md](07-bastion-active-passive.md) | Active-Passive cluster setup |
| [08-rds-jump-host.md](08-rds-jump-host.md) | WALLIX RDS deployment |
| [09-licensing.md](09-licensing.md) | License pool management |
| [10-testing-validation.md](10-testing-validation.md) | End-to-end testing procedures |

---

## Version Information

| Item | Value |
|------|-------|
| Documentation Version | 1.0 |
| WALLIX Bastion Version | 12.1.x |
| Last Updated | February 2026 |

---

**Next Steps:**
1. Complete Phase 1 infrastructure preparation for Site 1
2. Begin HAProxy deployment following [05-haproxy-setup.md](05-haproxy-setup.md)
3. Choose HA architecture from [02-ha-architecture.md](02-ha-architecture.md)
4. Follow Bastion deployment guide ([06-bastion-active-active.md](06-bastion-active-active.md) or [07-bastion-active-passive.md](07-bastion-active-passive.md))
5. Deploy RDS following [08-rds-jump-host.md](08-rds-jump-host.md)
6. Complete Access Manager integration per [03-access-manager-integration.md](03-access-manager-integration.md)
7. Replicate to Sites 2-5 using this guide as template
