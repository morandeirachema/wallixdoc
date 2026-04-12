# WALLIX Bastion - Master Installation Guide

> Step-by-step deployment instructions for 5-site enterprise PAM infrastructure

---

## Table of Contents

1. [Overview](#overview)
2. [Deployment Timeline](#deployment-timeline)
3. [Phase 1: Planning and Prerequisites (Week 1)](#phase-1-planning-and-prerequisites-week-1)
4. [Phase 2: Per-Site FortiAuthenticator HA Setup (Week 2)](#phase-2-per-site-fortiauthenticator-ha-setup-week-2)
5. [Phase 3: Site 1 Deployment (Weeks 3-4)](#phase-3-site-1-deployment-weeks-3-4)
6. [Phase 4-7: Sites 2-5 Deployment (Weeks 5-8)](#phase-4-7-sites-2-5-deployment-weeks-5-8)
7. [Phase 8: Final Integration (Week 9)](#phase-8-final-integration-week-9)
8. [Phase 9: Go-Live (Week 10)](#phase-9-go-live-week-10)
9. [Quick Reference Commands](#quick-reference-commands)
10. [Troubleshooting Quick Links](#troubleshooting-quick-links)

---

## Overview

This guide provides a comprehensive, step-by-step walkthrough for deploying a 5-site WALLIX Bastion infrastructure with per-site FortiAuthenticator HA, per-site Active Directory, and Bastion-side integration with a client-managed Access Manager.

### Architecture Summary

```
+===============================================================================+
|  DEPLOYMENT ARCHITECTURE                                                      |
+===============================================================================+
|                                                                               |
|  Client-Managed (not deployed by us):                                         |
|  +-------------------------+          +-------------------------+             |
|  | Access Manager 1 (DC-A) |  <---->  | Access Manager 2 (DC-B) |             |
|  | - SSO / Session Broker  |          | - SSO / Session Broker  |             |
|  +------------+------------+          +------------+------------+             |
|               |  MPLS                              |                          |
|               +------------------------------------+                          |
|                            MPLS Network                                       |
|       +----------------+--------+--------+--------+----------------+          |
|       |                |        |        |        |                |          |
|  +----v----+      +----v----+  ...  +----v----+  +----v----+  +----v----+     |
|  | Site 1  |      | Site 2  |       | Site 3  |  | Site 4  |  | Site 5  |     |
|  | (DC-1)  |      | (DC-2)  |       | (DC-3)  |  | (DC-4)  |  | (DC-5)  |     |
|  +---------+      +---------+       +---------+  +---------+  +---------+     |
|                                                                               |
|  Each Site (Our Scope):                                                       |
|  - DMZ VLAN (10.10.X.0/25): 2x HAProxy, 2x Bastion, 1x RDS                  |
|  - Cyber VLAN (10.10.X.128/25): FortiAuth HA pair + AD DC                    |
|  - Bastion license: 30 sessions/site, 150 total (5 sites)                    |
|                                                                               |
+===============================================================================+
```

### Key Deployment Facts

| Aspect | Details |
|--------|---------|
| **Total Sites** | 5 (all in datacenter site buildings) |
| **Access Managers** | 2 (client-managed, separate datacenters — not deployed by us) |
| **HA Models** | Active-Active OR Active-Passive (per site choice) |
| **Network** | MPLS connectivity, no direct site-to-site Bastion communication |
| **Total Duration** | 10 weeks (Site 1: 3-4 weeks, Sites 2-5: 1 week each) |
| **Total Appliances** | 10 Bastion HW appliances, 10 HAProxy servers, 5 RDS servers |
| **FortiAuthenticator** | Per site: 1x Primary + 1x Secondary HA pair (10 total) |
| **Active Directory** | Per site: 1x AD DC in Cyber VLAN (5 total) |
| **Licensed Capacity** | 150 concurrent Bastion sessions (30/site; AM licensing is client-managed) |

---

## Deployment Timeline

### Overview Table

| Phase | Duration | Components | Key Deliverables |
|-------|----------|------------|------------------|
| **Phase 1: Planning** | Week 1 | Prerequisites, network design | Network ready, licenses confirmed |
| **Phase 2: FortiAuth HA** | Week 2 | Per-site FortiAuth HA, AD/LDAP, FortiToken | RADIUS and LDAP integration ready |
| **Phase 3: Site 1** | Week 3-4 | HAProxy, Bastion HA, RDS | Fully functional site, template created |
| **Phase 4: Site 2** | Week 5 | Replicate Site 1 | Second site operational |
| **Phase 5: Site 3** | Week 6 | Replicate Site 1 | Third site operational |
| **Phase 6: Site 4** | Week 7 | Replicate Site 1 | Fourth site operational |
| **Phase 7: Site 5** | Week 8 | Replicate Site 1 | All sites deployed |
| **Phase 8: Integration** | Week 9 | Testing, AM coordination | Multi-site validated |
| **Phase 9: Go-Live** | Week 10 | Production cutover | Production operational |

### Critical Path Dependencies

```
Week 1 (Planning) → Week 2 (FortiAuth HA + AD) → Weeks 3-4 (Site 1)
                                                         ↓
                                              Weeks 5-8 (Sites 2-5 in parallel)
                                                         ↓
                                              Week 9 (Final Integration + AM coord)
                                                         ↓
                                              Week 10 (Go-Live)
```

**Key Constraint**: Site 1 must be fully operational and tested before replicating to Sites 2-5.

**Parallelization Opportunity**: Sites 2-5 can be deployed in parallel if resources permit (reduces Weeks 5-8 to 1-2 weeks total instead of 4).

---

## Phase 1: Planning and Prerequisites (Week 1)

### Objectives

- Validate all prerequisites are met
- Design network topology and port matrix
- Choose HA architecture model per site
- Prepare installation environment

### Step 1.1: Review Prerequisites

**Action**: Read and complete checklist in [00-prerequisites.md](00-prerequisites.md)

**Key Items to Verify**:

```bash
# Hardware readiness
- [ ] 10x WALLIX Bastion HW appliances received, racked, powered
- [ ] 10x HAProxy servers (VMs or physical) provisioned
- [ ] 5x Windows Server 2022 (RDS) ready
- [ ] 10x FortiAuthenticator VMs provisioned (2 per site, in Cyber VLAN)
- [ ] 5x Active Directory DCs provisioned (1 per site, in Cyber VLAN)
- [ ] IPMI/iLO access configured for all Bastion appliances

# Network readiness
- [ ] MPLS circuits installed (all sites interconnected + AM reachable)
- [ ] DMZ VLAN (10.10.X.0/25) and Cyber VLAN (10.10.X.128/25) configured per site
- [ ] Fortigate inter-VLAN routing rules configured (DMZ ↔ Cyber)
- [ ] DNS records created (all components, per-site)
- [ ] NTP servers configured and reachable
- [ ] SSL/TLS certificates obtained (wildcard or per-host)
- [ ] Firewall rules pre-approved

# Licensing
- [ ] Bastion license pool purchased (150 concurrent sessions total, 30/site)
- [ ] FortiToken Mobile licenses obtained (150 recommended; FTM-ELIC)
- [ ] License activation keys received
- [ ] Client AM licensing confirmed with client team (not our scope)

# Security
- [ ] Per-site AD/LDAP service accounts created (DC at 10.10.X.60)
- [ ] Per-site FortiAuthenticator RADIUS shared secret defined (one per site)
- [ ] FortiToken Mobile (TOTP) enrollment plan confirmed with security team
- [ ] Backup storage configured (offsite)
- [ ] Encryption keys generated
- [ ] Client AM team contact obtained (for Bastion registration coordination)
```

**Deliverable**: Completed prerequisite checklist with sign-off.

---

### Step 1.2: Design Network Topology

**Action**: Read and document network design in [01-network-design.md](01-network-design.md)

**Key Decisions**:

1. **IP Address Allocation** (per-site VLAN split)

   ```
   Site 1 (DC-1):
   DMZ VLAN (10.10.1.0/25):
   - HAProxy VIP:          10.10.1.100
   - HAProxy-1:            10.10.1.5
   - HAProxy-2:            10.10.1.6
   - Bastion-1:            10.10.1.11
   - Bastion-2:            10.10.1.12
   - WALLIX RDS:           10.10.1.30
   Cyber VLAN (10.10.1.128/25):
   - FortiAuth Primary:    10.10.1.50
   - FortiAuth Secondary:  10.10.1.51
   - FortiAuth VIP:        10.10.1.52
   - Active Directory DC:  10.10.1.60

   Site 2 (DC-2):
   DMZ VLAN (10.10.2.0/25): same pattern with .2. prefix
   Cyber VLAN (10.10.2.128/25): .50/.51/.52/.60

   (Pattern repeats for Sites 3-5)
   ```

2. **DNS Records**

   ```bash
   # Site 1 Example
   bastion-site1.company.com      A    10.10.1.100  (HAProxy VIP)
   bastion1-site1.company.com     A    10.10.1.11
   bastion2-site1.company.com     A    10.10.1.12
   rds-site1.company.com          A    10.10.1.30
   fortiauth1-site1.company.com   A    10.10.1.50
   fortiauth2-site1.company.com   A    10.10.1.51
   dc-site1.company.com           A    10.10.1.60
   ```

3. **Firewall Rules**

   **Reference**: [01-network-design.md](01-network-design.md) for complete port matrix.

   **Critical Ports**:
   - Bastion (DMZ) → FortiAuthenticator (Cyber): UDP 1812/1813 (RADIUS) — inter-VLAN via Fortigate
   - Bastion (DMZ) → Active Directory (Cyber): TCP 389/636 (LDAP/LDAPS) — inter-VLAN via Fortigate
   - HAProxy → Bastion: TCP 443, TCP 3389, TCP 22
   - Users → HAProxy VIP: TCP 443 (Web UI), TCP 22 (SSH), TCP 3389 (RDP)
   - Bastion → AM (MPLS): TCP 443 (HTTPS health check, SAML) — client provides AM URL

**Deliverable**: Network design document with IP allocations, DNS records, and approved firewall rules.

---

### Step 1.3: Choose HA Architecture Model

**Action**: Review [02-ha-architecture.md](02-ha-architecture.md) and decide per site.

**Decision Matrix**:

| Site | Expected Load | HA Model | Rationale |
|------|---------------|----------|-----------|
| Site 1 | 150+ sessions | **Active-Active** | High load, needs full capacity |
| Site 2 | 80 sessions | **Active-Passive** | Lower load, simplicity preferred |
| Site 3 | 120 sessions | **Active-Active** | Moderate load, growth expected |
| Site 4 | 60 sessions | **Active-Passive** | Low load, easier operations |
| Site 5 | 40 sessions | **Active-Passive** | Low load, easier operations |

**Recommendation**: While the decision matrix above suggests Active-Active for Site 1 based on expected load, consider starting with **Active-Passive** during initial deployment for simplicity. Convert to Active-Active later once the site is stabilized and the team is comfortable with operations.

**Configuration References**:
- Active-Active: [07-bastion-active-active.md](07-bastion-active-active.md)
- Active-Passive: [08-bastion-active-passive.md](08-bastion-active-passive.md)

**Deliverable**: HA model selection document with justification per site.

---

### Step 1.4: Prepare Installation Environment

**Actions**:

1. **Download Software**

   ```bash
   # WALLIX Bastion ISO (obtain from WALLIX support portal)
   # https://support.wallix.com — download latest 12.1.x ISO

   # HAProxy packages
   apt-get update && apt-get install -y haproxy keepalived
   ```

2. **Create Installation Media**

   ```bash
   # Burn ISO to USB for appliance installation
   dd if=wallix-bastion-12.1.x.iso of=/dev/sdX bs=4M status=progress
   sync
   ```

3. **Prepare Configuration Templates**

   - HAProxy configuration template
   - Bastion initial configuration
   - RDS installation script

**Deliverable**: Installation media ready, configuration templates prepared.

---

### Week 1 Deliverables Checklist

- [ ] All prerequisites validated and signed off
- [ ] Network design documented (IP, DNS, firewall rules, both VLANs)
- [ ] HA model selected per site with justification
- [ ] Installation environment prepared (software, media, templates)
- [ ] FortiAuthenticator licenses and FortiToken Mobile licenses confirmed
- [ ] Client AM team contact established (for Bastion registration in Week 9)

---

## Phase 2: Per-Site FortiAuthenticator HA Setup (Week 2)

### Objectives

- Deploy and configure FortiAuthenticator HA pair at Site 1 (template for Sites 2-5)
- Configure FortiToken Mobile (TOTP) enrollment
- Configure Active Directory / LDAP integration on FortiAuthenticator
- Validate RADIUS authentication from a test Bastion client
- Document per-site FortiAuth configuration as template for Sites 2-5

**Reference**: [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md) for detailed FortiAuth HA procedures.

---

### Step 2.1: Deploy FortiAuthenticator HA Pair (Site 1)

**Action**: Deploy two FortiAuthenticator VMs in the Site 1 Cyber VLAN.

```
Site 1 Cyber VLAN (10.10.1.128/25):
- FortiAuth Primary (FAC-1):   10.10.1.50
- FortiAuth Secondary (FAC-2): 10.10.1.51
- FortiAuth Cluster VIP:       10.10.1.52
```

**Configuration Summary**:

```bash
# On FAC-1 (Primary):
# 1. Set hostname, IP, and HA role via web console
#    System > Network > Interfaces
#    System > High Availability > HA Configuration
#    Role: Primary
#    Cluster IP: 10.10.1.52

# 2. On FAC-2 (Secondary):
#    System > High Availability > HA Configuration
#    Role: Secondary
#    Primary IP: 10.10.1.50

# 3. Verify HA sync
#    System > High Availability > Status
#    Expected: both nodes "In sync"
```

**Deliverable**: FortiAuthenticator HA pair operational at Site 1.

---

### Step 2.2: Configure Active Directory Integration on FortiAuthenticator

**Action**: Connect FortiAuthenticator to the Site 1 AD DC (10.10.1.60, Cyber VLAN).

```bash
# On FortiAuthenticator web console:
# Authentication > Remote Auth. Servers > LDAP

# LDAP Server Settings:
Name:        COMPANY-DC-SITE1
Server:      10.10.1.60
Port:        636 (LDAPS)
Base DN:     DC=company,DC=local
Bind DN:     CN=svc_wallix,OU=Service Accounts,DC=company,DC=local
Bind Pwd:    [LDAP_PASSWORD]
User Filter: (objectClass=user)

# Test: Authentication > User Management > Import Remote Users
# Verify: privileged users visible from AD
```

**Deliverable**: FortiAuthenticator LDAP connected to Site 1 AD DC.

---

### Step 2.3: Configure FortiToken Mobile (TOTP)

**Action**: Assign FortiToken Mobile licenses and configure TOTP.

```bash
# On FortiAuthenticator:
# System > FortiTokens > FortiToken Mobile
# Import FTM-ELIC license batch

# Token Settings:
Token Type:    FortiToken Mobile (software)
TOTP window:   1 (30-second window, +/-1 window = 90-second tolerance)
Auth Method:   TOTP only (no push notifications)

# Assign tokens to users:
# Authentication > User Management > Local Users → [select user] → Token: FortiToken Mobile
# Send QR code for enrollment to user's authenticator app (Google Authenticator compatible)
```

**Security Note**: TOTP only — push authentication is NOT configured. Users must enter the 6-digit TOTP code from their FortiToken Mobile app.

**Deliverable**: FortiToken Mobile enrolled for test users at Site 1.

---

### Step 2.4: Configure RADIUS Clients on FortiAuthenticator

**Action**: Register both Bastion nodes as RADIUS clients.

```bash
# On FortiAuthenticator:
# Authentication > RADIUS Service > Clients

# Add RADIUS Client (repeat for each Bastion node):
Name:          WALLIX-Bastion1-Site1
Client IP:     10.10.1.11          # Bastion-1, DMZ VLAN
Shared Secret: SITE1_RADIUS_SECRET  # Site-specific secret
NAS ID:        bastion-site1

Name:          WALLIX-Bastion2-Site1
Client IP:     10.10.1.12          # Bastion-2, DMZ VLAN
Shared Secret: SITE1_RADIUS_SECRET
NAS ID:        bastion-site1
```

**Deliverable**: Bastion nodes registered as RADIUS clients on Site 1 FortiAuth.

---

### Step 2.5: Validate RADIUS Authentication

**Action**: Test RADIUS from a test client (pre-prod lab or temporary script).

```bash
# Test RADIUS with radtest (install: apt-get install freeradius-utils)
radtest testuser@company.local TOTP_CODE 10.10.1.52 0 SITE1_RADIUS_SECRET
# Expected: Access-Accept

# Test primary failover: take down FAC-1, verify VIP stays up via FAC-2
nc -zvu 10.10.1.52 1812   # Should still respond
```

**Deliverable**: RADIUS authentication validated, HA failover tested.

---

### Step 2.6: Create Per-Site FortiAuth Configuration Template

**Action**: Export and document Site 1 FortiAuth config as template for Sites 2-5.

```bash
# Export config from FAC-1:
# System > Dashboard > System Information > [Export Configuration]

# Document per-site variables (change for each site):
# SITE_ID:           1 (→ 2, 3, 4, 5)
# FAC_PRIMARY_IP:    10.10.X.50
# FAC_SECONDARY_IP:  10.10.X.51
# FAC_VIP:           10.10.X.52
# AD_DC_IP:          10.10.X.60
# RADIUS_SECRET:     SITEХ_RADIUS_SECRET
# BASTION1_IP:       10.10.X.11
# BASTION2_IP:       10.10.X.12
```

**Deliverable**: FortiAuth configuration template ready for Sites 2-5 replication.

---

### Week 2 Deliverables Checklist

- [ ] FortiAuthenticator HA pair deployed and synced at Site 1
- [ ] FortiAuthenticator connected to Site 1 AD DC (10.10.1.60)
- [ ] FortiToken Mobile (TOTP) licenses assigned and enrolled for test users
- [ ] Bastion nodes registered as RADIUS clients
- [ ] RADIUS authentication validated (Access-Accept with TOTP code)
- [ ] FortiAuth HA failover tested (FAC-1 → FAC-2, VIP stays up)
- [ ] Per-site configuration template documented for Sites 2-5

---

## Phase 3: Site 1 Deployment (Weeks 3-4)

### Objectives

- Deploy Site 1 as reference template for Sites 2-5
- Configure HAProxy load balancer in HA mode
- Deploy Bastion HA cluster (Active-Passive or Active-Active)
- Set up WALLIX RDS jump host for OT access
- Validate end-to-end functionality
- Document deployment process for replication

### Week 3: Infrastructure Setup

#### Step 3.1: Deploy HAProxy Load Balancer Pair

**Action**: Follow [06-haproxy-setup.md](06-haproxy-setup.md)

**Configuration Summary**:

```bash
# HAProxy-1 (10.10.1.5) and HAProxy-2 (10.10.1.6)

# 1. Install HAProxy and Keepalived
apt-get update
apt-get install -y haproxy keepalived

# 2. Configure HAProxy
cat > /etc/haproxy/haproxy.cfg <<'EOF'
global
    log /dev/log local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend bastion-web
    bind 10.10.1.100:443 ssl crt /etc/haproxy/certs/bastion-site1.pem
    mode http
    default_backend bastion-web-backend

backend bastion-web-backend
    mode http
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    server bastion1 10.10.1.11:443 check ssl verify none
    server bastion2 10.10.1.12:443 check ssl verify none

frontend bastion-ssh
    bind *:22
    mode tcp
    default_backend bastion-ssh-backend

backend bastion-ssh-backend
    mode tcp
    balance roundrobin
    option tcp-check
    server bastion1 10.10.1.11:22 check
    server bastion2 10.10.1.12:22 check

frontend bastion-rdp
    bind *:3389
    mode tcp
    default_backend bastion-rdp-backend

backend bastion-rdp-backend
    mode tcp
    balance roundrobin
    option tcp-check
    server bastion1 10.10.1.11:3389 check
    server bastion2 10.10.1.12:3389 check
EOF

# 3. Configure Keepalived (VIP: 10.10.1.100)
cat > /etc/keepalived/keepalived.conf <<'EOF'
vrrp_instance HAPROXY_VIP {
    state MASTER              # BACKUP on HAProxy-2
    interface eth0
    virtual_router_id 51
    priority 100              # 90 on HAProxy-2
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass VRRP_SECRET_REDACTED
    }
    virtual_ipaddress {
        10.10.1.100/24
    }
}
EOF

# 4. Enable and start services
systemctl enable haproxy keepalived
systemctl start haproxy keepalived

# 5. Verify VIP
ip addr show eth0 | grep 10.10.1.100
```

**Validation**:

```bash
# Test HAProxy stats
curl http://10.10.1.100:8404/stats

# Test VIP failover
# On HAProxy-1 (master)
systemctl stop keepalived
# Verify VIP moves to HAProxy-2
ping 10.10.1.100
```

**Deliverable**: HAProxy HA pair operational with VIP failover tested.

---

#### Step 3.2: Deploy Bastion HA Cluster

**Action**: Choose deployment model and follow corresponding guide.

**Option A: Active-Passive (Recommended for Initial Deployment)**

Follow [08-bastion-active-passive.md](08-bastion-active-passive.md)

**Summary**:

```bash
# On Bastion-1 (Primary: 10.10.1.11)

# 1. Initial appliance setup
wabadmin setup --hostname bastion1-site1.company.com \
               --ip 10.10.1.11 \
               --netmask 255.255.255.0 \
               --gateway 10.10.1.1 \
               --dns 10.10.1.60 \
               --ntp ntp.company.com

# 2. Configure as primary
wabadmin ha configure --mode active-passive \
                      --role primary \
                      --partner 10.10.1.12 \
                      --vip 10.10.1.100 \
                      --cluster-password "SecureClusterPassword"

# 3. Apply license
wabadmin license apply --key "LICENSE_KEY_SITE1"

# On Bastion-2 (Secondary: 10.10.1.12)

# 1. Initial appliance setup
wabadmin setup --hostname bastion2-site1.company.com \
               --ip 10.10.1.12 \
               --netmask 255.255.255.0 \
               --gateway 10.10.1.1 \
               --dns 10.10.1.60 \
               --ntp ntp.company.com

# 2. Configure as secondary
wabadmin ha configure --mode active-passive \
                      --role secondary \
                      --partner 10.10.1.11 \
                      --vip 10.10.1.100 \
                      --cluster-password "SecureClusterPassword"

# 3. Verify cluster status
wabadmin ha status
```

**Option B: Active-Active (For High Load Sites)**

Follow [07-bastion-active-active.md](07-bastion-active-active.md)

**Note**: Active-Active requires `bastion-replication` Master/Master configuration. Refer to the official WALLIX Bastion 12.1.x deployment guide.

**Validation**:

```bash
# Check cluster health
wabadmin ha status

# Test failover (Active-Passive)
# On Bastion-1
wabadmin ha failover

# Verify Bastion-2 becomes primary
wabadmin ha status

# Restore Bastion-1 as primary
wabadmin ha failback
```

**Deliverable**: Bastion HA cluster operational with failover tested.

---

#### Step 3.3: Configure Authentication Integration

**Action**: Integrate Bastion with per-site FortiAuthenticator (RADIUS) and Active Directory (LDAP/AD). Configure SAML SSO integration with client-managed AM.

```bash
# On primary Bastion (Bastion-1)

# 1. Configure RADIUS MFA (FortiAuthenticator VIP in Site 1 Cyber VLAN)
wabadmin auth configure --method radius \
  --primary-server 10.10.1.50 \
  --secondary-server 10.10.1.51 \
  --shared-secret "SITE1_RADIUS_SECRET" \
  --timeout 5 \
  --retry 3
# Note: VIP (10.10.1.52) is also an option; using .50/.51 directly ensures
# both nodes are tried explicitly. Confirm preferred approach with FortiAuth docs.

# 2. Configure LDAP/AD user sync (Site 1 AD DC, Cyber VLAN)
wabadmin ldap configure --server 10.10.1.60 \
  --port 636 \
  --use-ssl \
  --base-dn "DC=company,DC=local" \
  --bind-dn "CN=svc_wallix,OU=Service Accounts,DC=company,DC=local" \
  --bind-password "LDAP_PASSWORD_REDACTED" \
  --user-filter "(objectClass=user)" \
  --sync-interval 300

# 3. Configure SSO (SAML) integration with client-managed Access Manager
#    Obtain SAML IdP metadata URL from client AM team
wabadmin sso configure --provider saml \
  --idp-metadata "https://am1.client.com/saml/metadata" \
  --entity-id "https://bastion-site1.company.com" \
  --assertion-consumer-url "https://bastion-site1.company.com/auth/sso"

# 4. Test RADIUS authentication (TOTP — enter 6-digit code from FortiToken Mobile)
wabadmin auth test-radius --user john.doe@company.local --token 123456

# 5. Test LDAP connectivity
wabadmin ldap test --user john.doe@company.local
```

**Validation**:

```bash
# Test direct RADIUS authentication (TOTP)
# Provide AD username + 6-digit TOTP code from FortiToken Mobile app
wabadmin auth test-radius --user john.doe@company.local --token 123456
# Expected: Authentication successful (Access-Accept from FortiAuth)

# Test LDAP user sync
wabadmin ldap sync --dry-run

# Test SSO login via web UI (if AM team has configured Bastion as SAML SP)
# 1. Open browser: https://bastion-site1.company.com
# 2. Click "Login with SSO"
# 3. Redirect to client Access Manager
# 4. Authenticate with AD credentials + FortiToken TOTP
# 5. Return to Bastion dashboard
```

**Deliverable**: RADIUS MFA (TOTP), LDAP/AD sync, and SAML SSO working end-to-end.

---

### Week 4: Services and Integration

#### Step 3.4: Deploy WALLIX RDS Jump Host

**Action**: Follow [09-rds-jump-host.md](09-rds-jump-host.md)

**Configuration Summary**:

```powershell
# On WALLIX RDS (Windows Server 2022: 10.10.1.30)

# 1. Install RDS RemoteApp role
Install-WindowsFeature -Name RDS-RD-Server -IncludeManagementTools

# 2. Configure RemoteApp
New-RDRemoteApp -CollectionName "OT-RemoteApps" `
                -DisplayName "OT Access" `
                -FilePath "C:\Windows\System32\mstsc.exe" `
                -ShowInWebAccess $true

# 3. Configure access via Bastion
# Add WALLIX RDS as target in Bastion
# Protocol: RDP
# Port: 3389
# Authentication: WALLIX credentials (passed through)

# 4. Test OT RemoteApp access
# User connects to Bastion → Bastion proxies to RDS → RDS launches RemoteApp
```

**Validation**:

```bash
# On Bastion, add RDS target
wabadmin target create --name "rds-site1" \
                       --host "10.10.1.30" \
                       --protocol rdp \
                       --port 3389 \
                       --domain "COMPANY"

# Grant access to test user
wabadmin authorization create --user "john.doe@company.com" \
                              --target "rds-site1" \
                              --account "ot-access"

# Test RDP connection via Bastion
rdesktop -u john.doe@bastion-site1.company.com -p - 10.10.1.100:3389
```

**Deliverable**: WALLIX RDS operational with RemoteApp access via Bastion.

---

#### Step 3.5: Coordinate Bastion Registration with Client AM Team

**Action**: Provide the client AM team with Site 1 Bastion details for registration in their Access Manager. The AM is client-managed — we do not have admin access to it.

**Information to Provide to Client AM Team**:

```yaml
# Site 1 Bastion registration parameters
bastion_name:         "bastion-site1"
bastion_url:          "https://bastion-site1.company.com"
health_check_url:     "https://bastion-site1.company.com/health"
health_check_interval: 30   # seconds
session_capacity:     30    # max concurrent sessions for Site 1
location:             "Site 1 DC"

# SAML SP metadata URL (for AM to configure Bastion as SAML SP)
saml_metadata_url:    "https://bastion-site1.company.com/auth/saml/metadata"
```

**Bastion Health Check Endpoint Verification**:

```bash
# Verify Bastion health check endpoint responds (AM uses this)
curl -sk https://bastion-site1.company.com/health
# Expected: HTTP 200 with JSON status

# Verify SAML SP metadata is accessible
curl -sk https://bastion-site1.company.com/auth/saml/metadata
# Expected: XML SAML metadata document
```

**Validation** (after client AM team confirms registration):

```bash
# Verify SSO redirect works (AM configured Bastion as SAML SP)
# 1. Open: https://bastion-site1.company.com
# 2. Click "Login with SSO"
# 3. Should redirect to client AM login page

# Test authenticated session via SSO
# (Use a test account configured in client AM)
```

**Deliverable**: Client AM team has registered Site 1 Bastion, SSO redirect tested.

---

#### Step 3.6: Configure Target Systems

**Action**: Add initial target systems for testing.

```bash
# Add Windows target
wabadmin target create --name "win-server-01" \
                       --host "win-server-01.company.com" \
                       --protocol rdp \
                       --port 3389 \
                       --domain "COMPANY" \
                       --description "Windows Server 2022"

# Add Linux target
wabadmin target create --name "rhel-server-01" \
                       --host "rhel-server-01.company.com" \
                       --protocol ssh \
                       --port 22 \
                       --description "RHEL 10"

# Configure credentials (Password Manager)
wabadmin credential create --target "win-server-01" \
                           --account "Administrator" \
                           --password "TARGET_PASSWORD_REDACTED" \
                           --auto-change \
                           --change-interval 30

wabadmin credential create --target "rhel-server-01" \
                           --account "root" \
                           --password "TARGET_PASSWORD_REDACTED" \
                           --auto-change \
                           --change-interval 30

# Grant access to test users
wabadmin authorization create --user "john.doe@company.com" \
                              --target "win-server-01" \
                              --account "Administrator"

wabadmin authorization create --user "jane.smith@company.com" \
                              --target "rhel-server-01" \
                              --account "root"
```

**Validation**:

```bash
# Test SSH access via Bastion
ssh john.doe@bastion-site1.company.com@rhel-server-01

# Test RDP access via Bastion
rdesktop -u john.doe@bastion-site1.company.com@win-server-01 -p - 10.10.1.100:3389

# Verify session recording
wabadmin session list --recent 10
wabadmin session replay --id <session_id>
```

**Deliverable**: Target systems configured and accessible via Bastion with session recording.

---

#### Step 3.7: Site 1 Validation Testing

**Action**: Comprehensive testing before replication to Sites 2-5.

**Test Checklist**:

```bash
# 1. Authentication
- [ ] SSO login via web UI (redirect to client Access Manager)
- [ ] MFA with FortiToken Mobile (TOTP 6-digit code, 30-second window)
- [ ] LDAP user sync from Site 1 AD DC (10.10.1.60)
- [ ] Service account authentication (no MFA)

# 2. Session Management
- [ ] SSH session to Linux target
- [ ] RDP session to Windows target
- [ ] VNC session (if applicable)
- [ ] Session recording enabled
- [ ] Session playback functional
- [ ] Session termination

# 3. High Availability
- [ ] HAProxy VIP failover (stop HAProxy-1, VIP moves to HAProxy-2)
- [ ] Bastion failover (stop Bastion-1, Bastion-2 takes over)
- [ ] Active sessions preserved during failover
- [ ] No data loss during failover

# 4. Password Management
- [ ] Credential checkout
- [ ] Automatic password rotation (30-day interval)
- [ ] Credential reconciliation after rotation
- [ ] Password complexity enforcement

# 5. OT Access
- [ ] RemoteApp launch via WALLIX RDS
- [ ] Session recording of RemoteApp session
- [ ] OT target access via RDS

# 6. Access Manager Integration (Bastion-side verification only)
- [ ] AM health check endpoint responds (https://bastion-site1.company.com/health)
- [ ] SAML SP metadata accessible (https://bastion-site1.company.com/auth/saml/metadata)
- [ ] SSO redirect works (clicking "Login with SSO" redirects to client AM)

# 7. Audit and Compliance
- [ ] Audit log generation
- [ ] Syslog export to SIEM
- [ ] Compliance report generation (SOC2, ISO27001)
```

**Reference**: [11-testing-validation.md](11-testing-validation.md) for detailed test procedures.

**Deliverable**: Test results documented with all items passing.

---

#### Step 3.8: Document Site 1 Deployment

**Action**: Create deployment template for Sites 2-5 replication.

**Template Structure**:

```markdown
# Site Deployment Template (Based on Site 1)

## 1. IP Address Allocation
- HAProxy VIP: 10.10.X.100
- HAProxy-1: 10.10.X.5
- HAProxy-2: 10.10.X.6
- Bastion-1: 10.10.X.11
- Bastion-2: 10.10.X.12
- WALLIX RDS: 10.10.X.30

## 2. DNS Records
- bastion-siteX.company.com → 10.10.X.100
- bastion1-siteX.company.com → 10.10.X.11
- bastion2-siteX.company.com → 10.10.X.12
- rds-siteX.company.com → 10.10.X.30

## 3. Configuration Files
- HAProxy: /etc/haproxy/haproxy.cfg (attached)
- Keepalived: /etc/keepalived/keepalived.conf (attached)
- Bastion: wabadmin scripts (attached)

## 4. Deployment Steps
1. Deploy HAProxy pair (45 mins)
2. Deploy Bastion HA cluster (2 hours)
3. Configure authentication (1 hour)
4. Deploy WALLIX RDS (1 hour)
5. Register with Access Manager (30 mins)
6. Add target systems (1 hour)
7. Validation testing (2 hours)

Total Time: ~8 hours (1 business day)

## 5. Validation Checklist
[Copy from Site 1 test checklist]
```

**Deliverable**: Site deployment template ready for replication.

---

### Week 3-4 Deliverables Checklist

- [ ] HAProxy HA pair deployed and failover tested
- [ ] Bastion HA cluster deployed (Active-Passive or Active-Active)
- [ ] RADIUS MFA (FortiToken TOTP) and LDAP/AD authentication working
- [ ] SAML SSO integration configured (client AM team to register Bastion in AM)
- [ ] WALLIX RDS operational with RemoteApp
- [ ] Client AM team provided Site 1 Bastion registration parameters
- [ ] Target systems configured and accessible
- [ ] Comprehensive testing completed (100% pass rate)
- [ ] Deployment template created for Sites 2-5 (including per-site FortiAuth config)

---

## Phase 4-7: Sites 2-5 Deployment (Weeks 5-8)

### Objectives

- Replicate Site 1 configuration to Sites 2-5
- Minimize deployment time using template
- Register all sites with Access Manager
- Validate multi-site operation

### Deployment Strategy

**Sequential Deployment** (default):
- Week 5: Site 2
- Week 6: Site 3
- Week 7: Site 4
- Week 8: Site 5

**Parallel Deployment** (if resources permit):
- Week 5-6: Sites 2, 3, 4, 5 in parallel
- Requires 4 deployment teams
- Reduces timeline to 2 weeks instead of 4

---

### Step 4.1: Site 2 Deployment (Week 5)

**Action**: Replicate Site 1 using deployment template.

**IP Allocation**:

```bash
# Site 2 (DC-2)
# DMZ VLAN (10.10.2.0/25)
HAProxy VIP:        10.10.2.100
HAProxy-1:          10.10.2.5
HAProxy-2:          10.10.2.6
Bastion-1:          10.10.2.11
Bastion-2:          10.10.2.12
WALLIX RDS:         10.10.2.30
# Cyber VLAN (10.10.2.128/25)
FortiAuth Primary:  10.10.2.50
FortiAuth Secondary:10.10.2.51
FortiAuth VIP:      10.10.2.52
Active Directory:   10.10.2.60
```

**DNS Records**:

```bash
bastion-site2.company.com      A    10.10.2.100
bastion1-site2.company.com     A    10.10.2.11
bastion2-site2.company.com     A    10.10.2.12
rds-site2.company.com          A    10.10.2.30
fortiauth1-site2.company.com   A    10.10.2.50
fortiauth2-site2.company.com   A    10.10.2.51
dc-site2.company.com           A    10.10.2.60
```

**Deployment Steps** (using template):

```bash
# 1. Deploy HAProxy pair (45 mins)
# - Adapt Site 1 config: update IPs, VIP, hostname
# - Deploy HAProxy-1 and HAProxy-2
# - Test VIP failover

# 2. Deploy Bastion HA cluster (2 hours)
# - Install appliances with Site 2 IPs
# - Configure HA cluster
# - Apply license (from Bastion pool)

# 3. Deploy per-site FortiAuthenticator HA (45 mins)
# - Apply Site 2 values to FortiAuth template from Phase 2
# - FAC Primary: 10.10.2.50, Secondary: 10.10.2.51, VIP: 10.10.2.52
# - Connect to Site 2 AD DC (10.10.2.60, LDAPS 636)
# - Register Bastion nodes (10.10.2.11, .12) as RADIUS clients

# 4. Configure Bastion authentication (30 mins)
# - Import SAML SSO config from Site 1 (update assertion-consumer-url hostname)
# - Configure RADIUS: primary 10.10.2.50, secondary 10.10.2.51
# - Configure LDAP: server 10.10.2.60

# 5. Deploy WALLIX RDS (1 hour)
# - Install Windows Server 2022
# - Configure RemoteApp
# - Add as target in Bastion

# 6. Coordinate with client AM team (30 mins)
# - Provide Bastion Site 2 registration parameters
# - URL: https://bastion-site2.company.com
# - Health check: https://bastion-site2.company.com/health
# - SAML metadata: https://bastion-site2.company.com/auth/saml/metadata
# - Capacity: 30 sessions

# 7. Add target systems (1 hour)
# - Import target list from Site 1 (or create site-specific)
# - Configure credentials
# - Grant user authorizations

# 7. Validation testing (2 hours)
# - Run test checklist from Site 1
# - Verify session brokering from Access Manager
# - Test multi-site failover (AM routes to Site 2 when Site 1 unavailable)
```

**Validation**:

```bash
# Test RADIUS (TOTP) authentication on Site 2 Bastion
wabadmin auth test-radius --user john.doe@company.local --token 123456

# Test LDAP sync from Site 2 AD DC
wabadmin ldap sync --dry-run

# Test FortiAuth HA failover (Site 2)
# Take down FAC-1 (10.10.2.50) — verify RADIUS still works via FAC-2
nc -zvu 10.10.2.52 1812   # VIP should still respond

# Verify Bastion health check (for AM to use)
curl -sk https://bastion-site2.company.com/health

# Confirm with client AM team that Site 2 Bastion is visible in AM dashboard
```

**Deliverable**: Site 2 operational, FortiAuth HA and AD configured, client AM team provided registration parameters.

---

### Step 4.2: Sites 3, 4, 5 Deployment (Weeks 6-8)

**Action**: Repeat Site 2 deployment process for remaining sites.

**IP Allocation Summary**:

| Site | HAProxy VIP | Bastion-1 | Bastion-2 | WALLIX RDS | FortiAuth VIP | AD DC |
|------|-------------|-----------|-----------|------------|---------------|-------|
| Site 3 | 10.10.3.100 | 10.10.3.11 | 10.10.3.12 | 10.10.3.30 | 10.10.3.52 | 10.10.3.60 |
| Site 4 | 10.10.4.100 | 10.10.4.11 | 10.10.4.12 | 10.10.4.30 | 10.10.4.52 | 10.10.4.60 |
| Site 5 | 10.10.5.100 | 10.10.5.11 | 10.10.5.12 | 10.10.5.30 | 10.10.5.52 | 10.10.5.60 |

**Parallel Deployment** (if resources permit):

```bash
# Week 6: Deploy Sites 3 and 4 in parallel (2 teams)
# Week 7: Deploy Site 5 and start integration testing

# Reduces 4 weeks to 2 weeks
```

**Coordination with Client AM Team (Sites 3, 4, 5)**:

```bash
# Provide the following to client AM team for each site:
for site in 3 4 5; do
  echo "--- Site ${site} Bastion registration parameters ---"
  echo "Name:         bastion-site${site}"
  echo "URL:          https://bastion-site${site}.company.com"
  echo "Health check: https://bastion-site${site}.company.com/health"
  echo "SAML meta:    https://bastion-site${site}.company.com/auth/saml/metadata"
  echo "Capacity:     30 sessions"
  echo "Location:     Site ${site} DC"
  echo ""
done

# Verify Bastion health check endpoints respond:
for site in 3 4 5; do
  echo "Site ${site}:"
  curl -sk https://bastion-site${site}.company.com/health && echo "OK" || echo "FAIL"
done

# After client AM team confirms registration, test SSO redirect from each site
for site in 3 4 5; do
  echo "Testing SSO redirect Site ${site}..."
  wabadmin sso status --site bastion-site${site}
done
```

**Deliverable**: Sites 3, 4, 5 operational, per-site FortiAuth HA configured, client AM team provided registration parameters.

---

### Week 5-8 Deliverables Checklist

- [ ] Site 2 deployed and operational (Week 5)
- [ ] Site 3 deployed and operational (Week 6)
- [ ] Site 4 deployed and operational (Week 7)
- [ ] Site 5 deployed and operational (Week 8)
- [ ] Per-site FortiAuthenticator HA configured and validated at all 5 sites
- [ ] Per-site AD/LDAP integration validated at all 5 sites
- [ ] Client AM team provided registration parameters for all 5 sites
- [ ] Deployment metrics collected (actual vs. estimated time)

---

## Phase 8: Final Integration (Week 9)

### Objectives

- Configure license pooling across all 5 sites
- Optimize session brokering rules
- Conduct comprehensive multi-site testing
- Performance tuning and optimization

### Step 8.1: Verify License Configuration Per Site

**Action**: Confirm Bastion license is applied and limits are correct on each site. License management is per-site on each Bastion cluster (not pooled through AM — AM licensing is client-managed).

**Reference**: [10-licensing.md](10-licensing.md)

**Configuration**:

```bash
# Verify license on each Bastion site
for site in 1 2 3 4 5; do
  echo "Site ${site} license status:"
  ssh bastion1-site${site}.company.com "wabadmin license status"
  echo ""
done

# Expected output per site:
# License Status: Active
# Max Concurrent Sessions: 30
# Currently Used: [N]
# Available: [30-N]

# Verify alerting threshold is set at 80% (24 of 30)
# On each Bastion:
wabadmin monitoring configure --license-alert-threshold 80

# Confirm total across all sites: 30 x 5 = 150 max concurrent sessions
```

**Validation**:

```bash
# Test license limit behavior per site
# Simulate sessions at each site and verify new requests are rejected gracefully at 30

# Verify monitoring alert at 80% (24 sessions) triggers correctly
wabadmin monitoring test --alert license-threshold
```

**Deliverable**: Bastion license limits verified (30/site), monitoring thresholds configured.

---

### Step 8.2: Coordinate Session Brokering Rules with Client AM Team

**Action**: Session brokering rules are configured in the client-managed Access Manager. In this step, we provide the client AM team with the recommended routing parameters based on our Bastion deployment, and verify the brokering works correctly from the Bastion side.

**Information to Provide to Client AM Team**:

```yaml
# Recommended routing hints for client AM configuration:

# Route by AD site (users authenticate against their local site AD):
site1_bastion_url: "https://bastion-site1.company.com"
site2_bastion_url: "https://bastion-site2.company.com"
site3_bastion_url: "https://bastion-site3.company.com"
site4_bastion_url: "https://bastion-site4.company.com"
site5_bastion_url: "https://bastion-site5.company.com"

# Health check endpoints (AM uses these for failover routing):
bastion_health_check_path: "/health"
health_check_interval: 30   # seconds

# Session capacity per Bastion site:
session_capacity_per_site: 30
total_capacity: 150   # 30 x 5 sites

# Failover priority: route to closest available site
```

**Validation (Bastion-side)**:

```bash
# Verify health check endpoints respond at all 5 sites
for site in 1 2 3 4 5; do
  echo "Site ${site} health check:"
  curl -sk https://bastion-site${site}.company.com/health && echo "OK" || echo "FAIL"
done

# Verify SSO flow works from each site
for site in 1 2 3 4 5; do
  echo "Testing SSO Site ${site}..."
  wabadmin auth test-saml --site bastion-site${site} --provider ClientAccessManager
done
```

**Deliverable**: Client AM team provided with routing parameters, SSO validated from all 5 sites.

---

### Step 8.3: Multi-Site Testing

**Action**: Comprehensive testing across all 5 sites.

**Reference**: [11-testing-validation.md](11-testing-validation.md)

**Test Scenarios**:

```bash
# 1. Load Testing
- [ ] 30 concurrent sessions per site (150 total across all 5 sites)
- [ ] Performance metrics (latency, throughput, CPU, memory)
- [ ] Session recording performance under load

# 2. Failover Testing
- [ ] HAProxy failover per site (VRRP, automatic)
- [ ] Bastion cluster failover per site (active sessions preserved)
- [ ] FortiAuthenticator HA failover per site (FAC-1 → FAC-2, RADIUS uninterrupted)
- [ ] Single site failure (notify client AM team to reroute sessions)

# 3. Integration Testing
- [ ] RADIUS MFA (TOTP) across all 5 sites — per-site FortiAuth VIP
- [ ] LDAP user sync from per-site AD DC at all 5 sites
- [ ] SAML SSO from all 5 sites (client AM team to confirm routing)
- [ ] OT access via WALLIX RDS (all 5 sites)

# 4. Security Testing
- [ ] TLS certificate validation
- [ ] Encrypted session recordings
- [ ] Audit log integrity
- [ ] Credential rotation
- [ ] Access control enforcement

# 5. Operational Testing
- [ ] Backup and restore (per site)
- [ ] Logging and monitoring (SIEM integration)
- [ ] Alerting (license threshold, cluster health)
- [ ] Performance dashboard (Grafana)
```

**Validation Criteria**:

```bash
# Performance SLAs
- Session connection time: < 3 seconds
- HAProxy/Bastion failover time: < 60 seconds
- FortiAuth RADIUS failover time: 0 seconds (automatic VIP)
- Session recording latency: < 100ms
- API response time: < 500ms

# Availability SLAs
- Single site: 99.9% (HA cluster + FortiAuth HA + HAProxy HA)
- Multi-site service: 99.99% (5-site redundancy)
```

**Deliverable**: Multi-site testing completed with all scenarios passing.

---

### Step 8.4: Performance Tuning

**Action**: Optimize configuration based on testing results.

**Tuning Areas**:

```bash
# 1. HAProxy Tuning
# Increase connection limits
cat >> /etc/haproxy/haproxy.cfg <<'EOF'
global
    maxconn 10000
    tune.ssl.default-dh-param 2048

defaults
    timeout connect 10s
    timeout client 300s
    timeout server 300s
EOF

# 2. Bastion Database Tuning (MariaDB)
wabadmin database tune --innodb-buffer-pool-size 8G \
                       --max-connections 1000 \
                       --query-cache-size 256M

# 3. Session Recording Optimization
wabadmin config set session.recording.compression gzip
wabadmin config set session.recording.buffer_size 10M

# 4. API Rate Limiting
wabadmin api configure --rate-limit 1000 \
                       --burst-limit 2000 \
                       --timeout 30

# 5. AM Health Check Optimization (coordinate with client AM team)
# Ask client AM team to verify their health check polling interval
# Recommended: 30s interval, 3 missed checks before marking site unhealthy
# Our role: ensure Bastion /health endpoint responds within 2s
```

**Deliverable**: Performance optimizations applied, benchmarks documented.

---

### Week 9 Deliverables Checklist

- [ ] License limits verified (30/site, 150 total), monitoring thresholds set
- [ ] Session brokering parameters provided to client AM team
- [ ] SAML SSO validated from all 5 sites
- [ ] Multi-site testing completed (100% pass rate)
- [ ] Performance tuning applied
- [ ] Monitoring and alerting configured
- [ ] Documentation updated with test results

---

## Phase 9: Go-Live (Week 10)

### Objectives

- Production cutover and go-live
- User training and documentation handoff
- Post-deployment support
- Project closeout

### Step 9.1: Pre-Production Validation

**Action**: Final validation before production cutover.

**Pre-Flight Checklist**:

```bash
# Infrastructure
- [ ] All 5 sites operational (HA clusters healthy)
- [ ] HAProxy load balancers operational (all 10 instances)
- [ ] WALLIX RDS jump hosts operational (all 5 instances)
- [ ] Access Manager HA cluster operational

# Integration
- [ ] SAML SSO authentication working (all 5 sites)
- [ ] RADIUS MFA (FortiToken TOTP) working at all 5 sites
- [ ] LDAP user sync operational (per-site AD DC)
- [ ] Client AM team confirms all 5 Bastions registered and routing correctly
- [ ] Bastion license limits verified (30/site, 150 total)

# Security
- [ ] SSL certificates valid (not expiring within 90 days)
- [ ] Encryption keys backed up (offsite)
- [ ] Audit logging enabled (all sites)
- [ ] SIEM integration working (syslog export)
- [ ] Backup strategy tested (restore validated)

# Performance
- [ ] Load testing passed (30 concurrent sessions per site, 150 total)
- [ ] Failover tested (HAProxy, Bastion cluster, FortiAuth HA per site)
- [ ] Performance metrics within SLAs
- [ ] Monitoring dashboards operational

# Documentation
- [ ] Deployment documentation completed
- [ ] Operational runbooks created
- [ ] User guides finalized
- [ ] API documentation updated
- [ ] Troubleshooting guides available
```

**Validation Sign-Off**: Obtain approval from:
- Infrastructure team
- Security team
- Client AM team (confirm all 5 sites visible and routing correctly in AM)
- Business stakeholders

**Deliverable**: Pre-production validation complete with sign-off.

---

### Step 9.2: Production Cutover

**Action**: Execute production cutover plan.

**Cutover Plan**:

```bash
# Phase 1: Pilot (2 days)
# - Onboard 10 pilot users (IT admins)
# - Test all access patterns (SSH, RDP, OT RemoteApp)
# - Monitor for issues
# - Collect feedback

# Phase 2: Early Adopters (3 days)
# - Onboard 50 early adopter users
# - Monitor performance and stability
# - Refine procedures based on feedback

# Phase 3: Full Rollout (5 days)
# - Onboard all users (phased by department)
# - Migrate all target systems
# - Decommission legacy PAM solution (if applicable)
```

**Cutover Schedule**:

| Date | Activity | Users | Status |
|------|----------|-------|--------|
| Day 1-2 | Pilot | 10 | In Progress |
| Day 3-5 | Early Adopters | 50 | Pending |
| Day 6-10 | Full Rollout | All | Pending |

**Emergency Procedures**: Ensure all teams have reviewed [13-contingency-plan.md](13-contingency-plan.md) and [14-break-glass-procedures.md](14-break-glass-procedures.md) before go-live. Break glass accounts must be created, tested, and sealed credentials stored securely.

**Rollback Plan**:

```bash
# If critical issues during cutover
# 1. Redirect users back to legacy PAM (if available)
# 2. Pause new user onboarding
# 3. Root cause analysis
# 4. Fix and retest
# 5. Resume cutover
```

**Deliverable**: Production cutover executed successfully.

---

### Step 9.3: User Training

**Action**: Train end users and administrators.

**Training Sessions**:

1. **End User Training** (1 hour)
   - How to access Bastion web UI
   - SSO login with FortiToken MFA
   - Connecting to target systems (SSH, RDP)
   - OT access via WALLIX RDS RemoteApp
   - Session recordings and audit

2. **Administrator Training** (4 hours)
   - Bastion administration (`wabadmin` CLI)
   - User and authorization management
   - Target system configuration
   - Credential management and rotation
   - Session monitoring and playback
   - Troubleshooting common issues
   - Backup and restore procedures

3. **Operations Training** (2 hours)
   - Monitoring and alerting
   - Performance dashboards (Grafana)
   - Incident response procedures
   - Failover and disaster recovery
   - License management

**Training Materials**:

```bash
# User guides
- End User Quick Start Guide
- Administrator Guide
- Operations Runbook
- Troubleshooting Guide

# Video tutorials
- "Connecting to Windows via Bastion"
- "Accessing Linux Servers via Bastion"
- "OT Access via WALLIX RDS"
- "Bastion Administration Basics"
```

**Deliverable**: Training sessions completed, materials distributed.

---

### Step 9.4: Documentation Handoff

**Action**: Transfer knowledge and documentation to operations team.

**Documentation Package**:

```bash
# 1. Architecture Documentation
- Network topology diagrams
- Component inventory (all 5 sites)
- Integration architecture (Access Manager, FortiAuthenticator)
- License allocation

# 2. Operational Documentation
- Deployment procedures (per site)
- Configuration standards
- Backup and restore procedures
- Disaster recovery runbook
- Incident response playbook

# 3. Troubleshooting Documentation
- Common issues and resolutions
- Log file locations
- Diagnostic commands
- Escalation procedures
- Vendor support contacts

# 4. User Documentation
- End user guides
- Administrator guides
- API reference
- FAQ

# 5. Compliance Documentation
- Audit logging configuration
- Compliance report templates (SOC2, ISO27001)
- Evidence collection procedures
```

**Handoff Meeting Agenda**:

```markdown
# Documentation Handoff Meeting (2 hours)

## 1. Architecture Overview (30 mins)
- Review network topology
- Access Manager integration
- License pooling

## 2. Operational Procedures (45 mins)
- Daily/weekly/monthly tasks
- Monitoring and alerting
- Backup and restore
- Failover procedures

## 3. Troubleshooting (30 mins)
- Common issues walkthrough
- Log analysis
- Escalation process

## 4. Q&A (15 mins)
- Address questions
- Schedule follow-up sessions
```

**Deliverable**: Documentation package delivered, handoff meeting completed.

---

### Step 9.5: Post-Deployment Support

**Action**: Provide support during stabilization period.

**Support Plan** (30 days):

```bash
# Week 1-2: High Touch Support
- Daily check-in meetings
- Real-time issue resolution
- Performance monitoring
- User feedback collection

# Week 3-4: Transition Support
- Weekly check-in meetings
- Issue tracking and resolution
- Knowledge transfer to operations team
- Optimization and tuning

# Week 5+: Standard Support
- Transition to BAU (Business As Usual)
- Issue escalation to vendor support
- Periodic health checks
```

**Support Metrics**:

| Metric | Target | Actual |
|--------|--------|--------|
| Uptime (per site) | 99.9% | TBD |
| Uptime (multi-site) | 99.99% | TBD |
| Mean Time to Resolution (MTTR) | < 4 hours | TBD |
| User satisfaction | > 90% | TBD |
| Support tickets | < 10/week | TBD |

**Deliverable**: Post-deployment support completed, metrics documented.

---

### Step 9.6: Project Closeout

**Action**: Complete project closeout activities.

**Closeout Activities**:

```bash
# 1. Lessons Learned Session
- What went well
- What could be improved
- Recommendations for future deployments

# 2. Final Documentation
- Update documentation with lessons learned
- Archive project artifacts
- Create deployment retrospective

# 3. Financial Closeout
- Final budget reconciliation
- Asset inventory and tracking
- License activation and tracking

# 4. Stakeholder Communication
- Project completion announcement
- Success metrics summary
- Thank you and recognition

# 5. Transition to BAU
- Hand off to operations team
- Close project
- Celebrate success!
```

**Project Metrics Summary**:

| Metric | Target | Actual |
|--------|--------|--------|
| Deployment timeline | 10 weeks | TBD |
| Budget | $XXX,XXX | TBD |
| Sites deployed | 5 | 5 |
| Bastion appliances deployed | 10 | 10 |
| FortiAuthenticator HA pairs | 5 (1 per site) | 5 |
| Licensed Bastion capacity | 150 sessions (30/site) | 150 |
| User satisfaction | > 90% | TBD |
| Uptime (first 30 days) | 99.9% | TBD |

**Deliverable**: Project closed successfully with documentation and metrics.

---

### Week 10 Deliverables Checklist

- [ ] Pre-production validation completed with sign-off
- [ ] Production cutover executed successfully (pilot, early adopters, full rollout)
- [ ] User training completed (end users, administrators, operations)
- [ ] Documentation handoff completed
- [ ] Post-deployment support plan activated (30 days)
- [ ] Project closeout activities completed
- [ ] Lessons learned documented
- [ ] Transition to BAU operations

---

## Quick Reference Commands

### Bastion Administration

```bash
# System Status
wabadmin status
wabadmin ha status
wabadmin license status

# User Management
wabadmin user list
wabadmin user create --username john.doe --email john.doe@company.com
wabadmin user grant-role --username john.doe --role admin

# Target Management
wabadmin target list
wabadmin target create --name server01 --host 10.10.1.50 --protocol ssh
wabadmin target delete --name server01

# Authorization Management
wabadmin authorization create --user john.doe --target server01 --account root
wabadmin authorization list --user john.doe

# Session Management
wabadmin session list --active
wabadmin session terminate --id <session_id>
wabadmin session replay --id <session_id>

# Credential Management
wabadmin credential create --target server01 --account root --password SecurePass123
wabadmin credential rotate --target server01 --account root

# Backup and Restore
wabadmin backup create --output /backup/bastion-$(date +%Y%m%d).tar.gz
wabadmin restore --input /backup/bastion-20260205.tar.gz

# Logs
wabadmin log view --tail 100
wabadmin log export --start "2026-02-05 00:00" --end "2026-02-05 23:59" --output audit.log
```

### HAProxy Management

```bash
# Service Management
systemctl status haproxy
systemctl restart haproxy
systemctl status keepalived

# Check VIP
ip addr show eth0 | grep <VIP>

# HAProxy Statistics
curl http://localhost:8404/stats

# Test Backend Health
haproxy -c -f /etc/haproxy/haproxy.cfg
```

### Access Manager Integration (Bastion-side only)

```bash
# Verify Bastion health check endpoint (AM polls this)
curl -sk https://bastion-site1.company.com/health

# Check SSO/SAML status
wabadmin sso status

# Verify SAML SP metadata is accessible
curl -sk https://bastion-site1.company.com/auth/saml/metadata | head -5

# Test SAML authentication
wabadmin auth test-saml --provider ClientAccessManager --user testuser

# Note: AM registration and session brokering management is done by client AM team
```

### Monitoring and Diagnostics

```bash
# HA Database Replication Health
sudo bastion-replication --monitoring

# System Resources
top
htop
iostat -x 5
vmstat 5

# Network Connectivity
ping <target>
traceroute <target>
nc -zv <host> <port>

# Firewall Rules
iptables -L -n
ss -tunlp
```

---

## Troubleshooting Quick Links

### Common Issues

#### Issue 1: HAProxy VIP Not Responding

**Symptoms**:
- Cannot connect to HAProxy VIP (10.10.X.100)
- Keepalived logs show VRRP errors

**Diagnosis**:

```bash
# Check Keepalived status
systemctl status keepalived
journalctl -u keepalived -f

# Check VIP assignment
ip addr show eth0 | grep 10.10.X.100

# Check VRRP packets
tcpdump -i eth0 vrrp
```

**Resolution**:

```bash
# Restart Keepalived
systemctl restart keepalived

# If VIP not moving, check firewall (VRRP uses multicast 224.0.0.18)
iptables -I INPUT -p vrrp -j ACCEPT
```

**Reference**: [06-haproxy-setup.md](06-haproxy-setup.md#troubleshooting)

---

#### Issue 2: Bastion Cluster Split-Brain

**Symptoms**:
- Both Bastion nodes think they are primary
- Data inconsistency between nodes

**Diagnosis**:

```bash
# Check cluster status
wabadmin ha status

# Check HA Database Replication
sudo bastion-replication --monitoring
```

**Resolution**:

```bash
# Stop replication
sudo bastion-replication --stop

# Resync and restart replication
sudo bastion-replication --dump-resync
sudo bastion-replication --start

# Verify replication status
sudo bastion-replication --monitoring
```

**Reference**: [08-bastion-active-passive.md](08-bastion-active-passive.md#split-brain-recovery)

---

#### Issue 3: SSO Authentication Failure

**Symptoms**:
- Users redirected to Access Manager but fail to return to Bastion
- SAML assertion errors in logs

**Diagnosis**:

```bash
# Check SSO configuration
wabadmin sso status

# Check SAML metadata
curl https://am.company.com/saml/metadata

# Check Bastion logs
wabadmin log view --filter sso
```

**Resolution**:

```bash
# Re-import SAML metadata
wabadmin sso configure --provider saml \
  --idp-metadata "https://am.company.com/saml/metadata"

# Verify certificate validity
openssl s_client -connect am.company.com:443 -showcerts

# Test SSO flow manually
# Browser: https://bastion-site1.company.com/auth/sso
```

**Reference**: [15-access-manager-integration.md](15-access-manager-integration.md#sso-troubleshooting)

---

#### Issue 4: RADIUS MFA Timeout

**Symptoms**:
- MFA authentication fails with timeout
- TOTP authentication (6-digit code) is rejected
- Bastion logs show RADIUS connection refused or timeout

**Note**: Each site has its own FortiAuthenticator HA pair (Primary at 10.10.X.50, Secondary at 10.10.X.51, VIP at 10.10.X.52). Replace X with the affected site number.

**Diagnosis**:

```bash
# Test RADIUS connectivity to per-site FortiAuth VIP
wabadmin auth test-radius --user john.doe@company.local --token 123456

# Check RADIUS port reachability (inter-VLAN via Fortigate)
nc -zvu 10.10.X.52 1812   # FortiAuth VIP
nc -zvu 10.10.X.50 1812   # Primary
nc -zvu 10.10.X.51 1812   # Secondary

# Check FortiAuthenticator logs (on FortiAuthenticator admin console)
# Log & Report > Log Access > Local Logs → filter by RADIUS
```

**Resolution**:

```bash
# Increase RADIUS timeout
wabadmin auth configure --method radius --timeout 10

# If VIP is down but secondary is up, test directly
nc -zvu 10.10.X.51 1812
wabadmin auth configure --method radius --primary-server 10.10.X.51

# Verify shared secret matches FortiAuth configuration
wabadmin auth test-radius --user john.doe@company.local --debug

# Check Fortigate inter-VLAN policy (DMZ → Cyber, UDP 1812/1813)
# Verify no firewall rule is blocking Bastion → FortiAuth traffic
```

**Reference**: [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md)

---

#### Issue 5: Session Recording Playback Failure

**Symptoms**:
- Session recordings not playable
- "Corrupted recording" error

**Diagnosis**:

```bash
# Check recording status
wabadmin session list --id <session_id>

# Check storage space
df -h /var/wab/recordings

# Verify recording file integrity
wabadmin session verify --id <session_id>
```

**Resolution**:

```bash
# Repair recording index
wabadmin session repair --id <session_id>

# Export recording to alternative format
wabadmin session export --id <session_id> --format mp4

# If storage full, clean old recordings
wabadmin recording cleanup --older-than 90
```

**Reference**: [../docs/pam/39-session-recording-playback/](../docs/pam/39-session-recording-playback/)

---

#### Issue 6: License Pool Exhaustion

**Symptoms**:
- New sessions rejected with "License limit reached"
- License pool shows 100% utilization

**Diagnosis**:

```bash
# Check license status on affected site
wabadmin license status
# Expected max: 30 concurrent sessions per site

# List active sessions
wabadmin session list --active --count

# Check across all sites
for site in 1 2 3 4 5; do
  echo "Site ${site}:"
  ssh bastion1-site${site}.company.com "wabadmin license status" 2>/dev/null || echo "UNREACHABLE"
done
```

**Resolution**:

```bash
# Terminate idle sessions (free up licenses)
wabadmin session cleanup --idle-timeout 1800

# If genuine capacity issue, request emergency license increase
# Contact WALLIX licensing: support@wallix.com
# Reference: Bastion license (150 concurrent sessions, 30/site)
```

**Reference**: [10-licensing.md](10-licensing.md#license-pool-exhaustion)

---

### Contingency and Emergency Access

For comprehensive recovery procedures and emergency access when normal channels are unavailable:

- **Disaster Recovery**: [13-contingency-plan.md](13-contingency-plan.md) - Failure scenarios, backup strategy, recovery procedures
- **Break Glass Access**: [14-break-glass-procedures.md](14-break-glass-procedures.md) - Emergency access when SSO, MFA, or PAM is down

---

### Escalation Procedures

#### Level 1: Internal Operations Team

**Contact**: operations@company.com
**Response Time**: 1 hour (business hours), 4 hours (after hours)
**Scope**: Common issues, restarts, configuration changes

---

#### Level 2: Infrastructure Team

**Contact**: infrastructure@company.com
**Response Time**: 4 hours
**Scope**: Network issues, hardware failures, clustering issues

---

#### Level 3: WALLIX Support

**Contact**: support@wallix.com
**Support Portal**: https://support.wallix.com
**Response Time**: 8 hours (Standard), 4 hours (Premium), 1 hour (Critical)
**Scope**: Product defects, complex configuration, vendor escalation

---

### Additional Resources

#### Documentation Links

| Resource | Location |
|----------|----------|
| **PAM Documentation** | [/docs/pam/](../docs/pam/) |
| **Installation Guides** | [/install/](../install/) |
| **Pre-Production Lab** | [/pre/](../pre/) |
| **Automation Examples** | [/examples/](../examples/) |
| **Architecture Diagrams** | [12-architecture-diagrams.md](12-architecture-diagrams.md) |
| **Testing Procedures** | [11-testing-validation.md](11-testing-validation.md) |

---

#### Official WALLIX Resources

| Resource | URL |
|----------|-----|
| **Documentation Portal** | https://pam.wallix.one/documentation |
| **Admin Guide** | https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf |
| **User Guide** | https://pam.wallix.one/documentation/user-doc/bastion_en_user_guide.pdf |
| **API Reference** | https://github.com/wallix/wbrest_samples |
| **Support Portal** | https://support.wallix.com |

---

## Summary

This HOWTO guide has walked you through the complete 10-week deployment process for a 5-site WALLIX Bastion infrastructure with Access Manager integration:

1. **Week 1**: Planning and prerequisites
2. **Week 2**: Access Manager integration
3. **Weeks 3-4**: Site 1 deployment (reference template)
4. **Weeks 5-8**: Sites 2-5 replication
5. **Week 9**: Final integration and testing
6. **Week 10**: Go-live and production support

**Key Success Factors**:
- Thorough planning and prerequisites validation
- Robust Site 1 deployment as template
- Effective collaboration with Access Manager team
- Comprehensive testing at each phase
- Proper documentation and knowledge transfer

**Next Steps**:
1. Review and complete Week 1 planning activities
2. Coordinate with Access Manager team for Week 2 integration
3. Begin Site 1 deployment in Week 3
4. Use this guide as your reference throughout the deployment

**Questions or Issues?**
- Reference troubleshooting section above
- Consult detailed installation guides linked throughout this document
- Contact WALLIX support for vendor escalation

---

*Good luck with your deployment!*
