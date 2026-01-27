# WALLIX Bastion 12.x - Quick Installation HOWTO

## Overview

This guide provides a step-by-step installation order for a 3-site OT environment.

```
INSTALLATION ORDER
==================

Phase 1: Preparation (All Sites)
  |
  v
Phase 2: Site A Primary Installation
  |
  v
Phase 3: Site B Secondary Installation
  |
  v
Phase 4: Site C Remote Installation
  |
  v
Phase 5: Multi-Site Configuration
  |
  v
Phase 6: OT Integration
  |
  v
Phase 7: Security Hardening
  |
  v
Phase 8: Validation & Go-Live
```

---

## Phase 1: Preparation (Week 1)

### Day 1-2: Infrastructure Setup

```bash
# 1. Provision all servers
#    - Site A: 2 VMs (wallix-a1, wallix-a2)
#    - Site B: 2 VMs (wallix-b1, wallix-b2)
#    - Site C: 1 VM (wallix-c1)

# 2. Install Debian 12 on all servers
#    Download: https://www.debian.org/distrib/

# 3. Configure basic networking
#    See: 01-prerequisites.md -> Network Requirements

# 4. Verify connectivity between sites
ping 10.100.1.10    # Site A
ping 10.200.1.10    # Site B
ping 10.50.1.10     # Site C
```

### Day 3: DNS and Certificates

```bash
# 1. Create DNS records
#    See: 01-prerequisites.md -> DNS Requirements

# 2. Obtain SSL certificates
#    Option A: Purchase from CA
#    Option B: Generate with Let's Encrypt
#    Option C: Use self-signed (dev only)

# 3. Configure NTP on all servers
apt install ntp
systemctl enable ntp
```

### Day 4-5: Storage and Prerequisites

```bash
# 1. Configure shared storage (Site A and B)
#    NFS or iSCSI for recordings

# 2. Install required packages on ALL servers
apt update && apt install -y \
    openssh-server curl gnupg lsb-release \
    ca-certificates ntp net-tools rsync

# 3. Add WALLIX repository on ALL servers
curl -fsSL https://repo.wallix.com/wallix.gpg | \
    gpg --dearmor -o /usr/share/keyrings/wallix.gpg

cat > /etc/apt/sources.list.d/wallix.list << 'EOF'
deb [signed-by=/usr/share/keyrings/wallix.gpg] \
    https://repo.wallix.com/bastion/12.1 bookworm main
EOF

apt update
```

---

## Phase 2: Site A Primary Installation (Week 2)

### Day 1: Node 1 Installation

```bash
# On wallix-a1 (10.100.1.10)

# 1. Set hostname
hostnamectl set-hostname wallix-a1.site-a.company.com

# 2. Install WALLIX Bastion
apt install -y wallix-bastion

# 3. Configure PostgreSQL for replication
# See: 02-site-a-primary.md -> Step 3

# 4. Mount shared storage
mkdir -p /var/wab/recorded
mount -t nfs4 10.100.1.50:/wallix/recordings /var/wab/recorded

# 5. Install license
cp license.key /etc/opt/wab/license.key
wab-admin license-check
```

### Day 2: Node 2 Installation

```bash
# On wallix-a2 (10.100.1.11)

# 1. Set hostname
hostnamectl set-hostname wallix-a2.site-a.company.com

# 2. Install WALLIX Bastion
apt install -y wallix-bastion

# 3. Configure PostgreSQL as standby
# See: 02-site-a-primary.md -> Node 2 Installation

# 4. Mount shared storage (same as Node 1)
# 5. Install license (same as Node 1)
```

### Day 3: HA Cluster Setup

```bash
# On both nodes

# 1. Install cluster software
apt install -y pacemaker corosync pcs

# 2. Configure cluster password
echo "hacluster:ClusterSecurePass2026!" | chpasswd
systemctl enable --now pcsd

# 3. Create cluster (from Node 1)
pcs host auth wallix-a1-hb wallix-a2-hb -u hacluster -p 'ClusterSecurePass2026!'
pcs cluster setup wallix-site-a wallix-a1-hb wallix-a2-hb
pcs cluster start --all
pcs cluster enable --all

# 4. Configure resources
# See: 02-site-a-primary.md -> HA Cluster Configuration

# 5. Verify cluster
pcs status
```

### Day 4-5: Initial Configuration

```bash
# 1. Access Web UI
#    URL: https://10.100.1.100
#    User: admin

# 2. Configure global settings
#    - System name: WALLIX-SITE-A
#    - Timezone
#    - Email alerts

# 3. Configure authentication
#    - LDAP/Active Directory
#    - OIDC (optional)
#    - MFA for administrators

# 4. Create initial user groups
#    - ot-admins
#    - ot-operators
#    - ot-engineers

# 5. Test HA failover
pcs node standby wallix-a1-hb
# Verify VIP moved
pcs node unstandby wallix-a1-hb
```

---

## Phase 3: Site B Secondary Installation (Week 3)

### Day 1-2: Node Installation

```bash
# Same process as Site A
# On wallix-b1 and wallix-b2

# See: 03-site-b-secondary.md

# Key differences:
# - IP addresses: 10.200.1.x
# - Hostname: wallix-b*.site-b.company.com
# - VIP: 10.200.1.100
```

### Day 3: HA Cluster Setup

```bash
# Same cluster setup as Site A
# Cluster name: wallix-site-b
```

### Day 4-5: Multi-Site Sync Configuration

```bash
# On Site A (Primary)
wab-admin multisite-generate-key --site site-b --name "Site B Secondary"
# Note the API key

# On Site B (Secondary)
wab-admin config-set multisite.enabled true
wab-admin config-set multisite.role secondary
wab-admin config-set multisite.primary_url https://wallix.site-a.company.com
wab-admin config-set multisite.api_key '<API_KEY_FROM_SITE_A>'

# Test sync
wab-admin multisite-test
wab-admin multisite-sync --full

# Verify
wab-admin multisite-status
```

---

## Phase 4: Site C Remote Installation (Week 4)

### Day 1-2: Standalone Installation

```bash
# On wallix-c1 (10.50.1.10)

# 1. Set hostname
hostnamectl set-hostname wallix-c1.site-c.company.com

# 2. Install WALLIX
apt install -y wallix-bastion

# 3. Configure local storage
mkdir -p /var/wab/recorded
chown -R wab:wab /var/wab/recorded

# 4. Install license
# 5. Basic configuration via Web UI
```

### Day 3: Offline Capability Setup

```bash
# Configure for limited connectivity
wab-admin config-set multisite.enabled true
wab-admin config-set multisite.role secondary
wab-admin config-set multisite.offline_mode true
wab-admin config-set multisite.cache_enabled true
wab-admin config-set multisite.cache_ttl 86400

# Configure scheduled sync
wab-admin config-set multisite.sync_schedule "0 2 * * *"

# Enable local authentication cache
wab-admin config-set auth.local_cache.enabled true
```

### Day 4-5: Test Offline Operation

```bash
# 1. Perform full sync
wab-admin multisite-sync --full

# 2. Test offline authentication
# Block Site A connectivity
iptables -A OUTPUT -d 10.100.1.100 -j DROP

# 3. Verify cached auth works
wab-admin auth-test --user operator1 --cached

# 4. Restore connectivity
iptables -D OUTPUT -d 10.100.1.100 -j DROP
```

---

## Phase 5: Multi-Site Configuration (Week 5)

### Day 1-2: Verify All Sites Syncing

```bash
# From Site A
wab-admin multisite-status

# Expected output:
# Site B: ONLINE, Last sync: X min ago
# Site C: ONLINE, Last sync: X hour ago

# Force sync to all sites
wab-admin multisite-sync --all --force
```

### Day 3: Configure Sync Policies

```bash
# Define what syncs where
# See: 05-multi-site-sync.md -> Sync Policies

# Site B: Full sync
wab-admin config-set multisite.sync.users true
wab-admin config-set multisite.sync.groups true
wab-admin config-set multisite.sync.authorizations true

# Site C: Cached sync with local overrides
wab-admin config-set multisite.sync.devices_local false
```

### Day 4-5: Test Multi-Site Scenarios

```bash
# Test 1: Create user on Site A, verify appears on B and C
# Test 2: Site B failover - verify still syncs
# Test 3: Site C offline - verify cached operations
```

---

## Phase 6: OT Integration (Week 6)

### Day 1-2: Configure OT Network Access

```bash
# See: 06-ot-network-config.md

# 1. Define OT zones
wab-admin zone-create --name "operations" --security-level 3
wab-admin zone-create --name "control" --security-level 2
wab-admin zone-create --name "field" --security-level 1

# 2. Add OT devices
wab-admin device-create --name "SCADA-Primary" --host "10.100.20.10" \
    --protocols "rdp:3389,ssh:22" --zone "operations"

wab-admin device-create --name "PLC-Line1" --host "10.100.40.10" \
    --protocols "modbus:502" --zone "field"
```

### Day 3: Configure Universal Tunneling

```bash
# Enable industrial protocol tunneling
wab-admin config-set tunneling.enabled true
wab-admin config-set tunneling.protocols "modbus,s7comm,ethernetip,opcua"

# Create tunnel definitions
# See: 06-ot-network-config.md -> Universal Tunneling
```

### Day 4-5: Configure Device Accounts

```bash
# Create accounts for OT devices
wab-admin account-create --name "Administrator" --device "SCADA-Primary" \
    --protocol "rdp" --domain "OT-DOMAIN" --auto-rotate true

wab-admin account-create --name "plc-admin" --device "PLC-Line1" \
    --protocol "modbus" --checkout-required true
```

---

## Phase 7: Security Hardening (Week 7)

### Day 1-2: Apply Security Settings

```bash
# See: 07-security-hardening.md

# Verify 12.x security defaults
wab-admin security-audit

# Configure SSL/TLS
wab-admin ssl-install --cert /path/to/cert.pem \
    --key /path/to/key.pem --chain /path/to/chain.pem

# Enable HSTS
wab-admin config-set web.hsts.enabled true
```

### Day 3: Configure MFA

```bash
# Enforce MFA for administrators
wab-admin config-set auth.mfa.required_for_admins true
wab-admin config-set auth.mfa.required_for_ot true

# Test MFA enrollment
```

### Day 4: Configure Audit Logging

```bash
# Enable comprehensive logging
wab-admin config-set audit.enabled true
wab-admin config-set audit.log_level info

# Configure SIEM integration
wab-admin config-set syslog.enabled true
wab-admin config-set syslog.server "10.100.1.5"
wab-admin config-set syslog.format "cef"
```

### Day 5: IEC 62443 Compliance Check

```bash
# Generate compliance report
wab-admin compliance-report --standard iec62443

# Review and remediate any gaps
```

---

## Phase 8: Validation & Go-Live (Week 8)

### Day 1-2: Functional Testing

```bash
# See: 08-validation-testing.md

# Test authentication
wab-admin auth-test --user admin --method local
wab-admin auth-test --user ldapuser --method ldap

# Test session proxy
ssh -o ProxyCommand="ssh -W %h:%p admin@wallix.site-a.company.com" \
    root@target-server

# Test recording
wab-admin session-list --last 5
```

### Day 3: HA and Failover Testing

```bash
# Test Site A failover
pcs node standby wallix-a1-hb
# Verify services continue
pcs node unstandby wallix-a1-hb

# Test Site B failover
# Same process
```

### Day 4: Security Validation

```bash
# Run security scan
wab-admin security-scan --type full

# Verify all checks pass
```

### Day 5: Go-Live

```bash
# Final validation
wab-admin validate-all --verbose

# Enable production monitoring
wab-admin monitor-start

# Document and handover
# - Generate runbook
# - Train operators
# - Schedule first maintenance window
```

---

## Quick Reference Commands

```bash
# Health check
wab-admin health-check

# Cluster status
pcs status

# Multi-site status
wab-admin multisite-status

# License status
wab-admin license-check

# Active sessions
wab-admin session-list --active

# Sync status
wab-admin multisite-sync --status

# Security audit
wab-admin security-audit
```

---

## Troubleshooting Quick Fixes

```bash
# Service not starting
systemctl status wabengine
journalctl -u wabengine -f

# Database issues
sudo -u postgres pg_isready
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"

# Cluster issues
pcs status
pcs cluster status

# Sync issues
wab-admin multisite-test
wab-admin multisite-logs --last 50

# Certificate issues
wab-admin ssl-verify
openssl s_client -connect localhost:443 </dev/null
```

---

## Support Contacts

| Issue | Contact |
|-------|---------|
| WALLIX Support | https://support.wallix.com |
| Documentation | https://pam.wallix.one/documentation |
| Emergency | Your internal OT security team |

---

**Document Version**: 1.0
**Last Updated**: January 2026
**WALLIX Version**: 12.1.x
