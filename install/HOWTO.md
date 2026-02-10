# WALLIX Bastion - Master Installation Guide

> Step-by-step deployment instructions for 5-site enterprise PAM infrastructure with Access Manager integration

---

## Table of Contents

1. [Overview](#overview)
2. [Deployment Timeline](#deployment-timeline)
3. [Phase 1: Planning and Prerequisites (Week 1)](#phase-1-planning-and-prerequisites-week-1)
4. [Phase 2: Access Manager Integration (Week 2)](#phase-2-access-manager-integration-week-2)
5. [Phase 3: Site 1 Deployment (Weeks 3-4)](#phase-3-site-1-deployment-weeks-3-4)
6. [Phase 4-7: Sites 2-5 Deployment (Weeks 5-8)](#phase-4-7-sites-2-5-deployment-weeks-5-8)
7. [Phase 8: Final Integration (Week 9)](#phase-8-final-integration-week-9)
8. [Phase 9: Go-Live (Week 10)](#phase-9-go-live-week-10)
9. [Quick Reference Commands](#quick-reference-commands)
10. [Troubleshooting Quick Links](#troubleshooting-quick-links)

---

## Overview

This guide provides a comprehensive, step-by-step walkthrough for deploying a 5-site WALLIX Bastion infrastructure integrated with 2 WALLIX Access Managers in high availability configuration.

### Architecture Summary

```
+===============================================================================+
|  DEPLOYMENT ARCHITECTURE                                                      |
+===============================================================================+
|                                                                               |
|  Access Manager Layer (HA):                                                   |
|  +-------------------------+          +-------------------------+             |
|  | Access Manager 1 (DC-A) |  <---->  | Access Manager 2 (DC-B) |             |
|  | - SSO / MFA             |          | - SSO / MFA             |             |
|  | - Session Brokering     |          | - Session Brokering     |             |
|  | - License Pool (500)    |          | - License Pool (500)    |             |
|  +------------+------------+          +------------+------------+             |
|               |                                    |                          |
|               +------------------------------------+                          |
|                            MPLS Network                                       |
|       +----------------+--------+--------+--------+----------------+          |
|       |                |        |        |        |                |          |
|  +----v----+      +----v----+  ...  +----v----+  +----v----+  +----v----+     |
|  | Site 1  |      | Site 2  |       | Site 3  |  | Site 4  |  | Site 5  |     |
|  | (DC-1)  |      | (DC-2)  |       | (DC-3)  |  | (DC-4)  |  | (DC-5)  |     |
|  +---------+      +---------+       +---------+  +---------+  +---------+     |
|                                                                               |
|  Each Site:                                                                   |
|  - 2x HAProxy (Active-Passive)                                                |
|  - 2x WALLIX Bastion (Active-Active OR Active-Passive)                        |
|  - 1x WALLIX RDS (Jump host for OT RemoteApp)                                 |
|  - License Pool Share: 450 sessions across all 5 sites                        |
|                                                                               |
+===============================================================================+
```

### Key Deployment Facts

| Aspect | Details |
|--------|---------|
| **Total Sites** | 5 (all in datacenter site buildings) |
| **Access Managers** | 2 (HA, separate datacenters) |
| **HA Models** | Active-Active OR Active-Passive (per site choice) |
| **Network** | MPLS connectivity, no direct site-to-site Bastion communication |
| **Total Duration** | 10 weeks (Site 1: 3-4 weeks, Sites 2-5: 1 week each) |
| **Total Appliances** | 10 Bastion HW appliances, 10 HAProxy servers, 5 RDS servers |
| **Licensed Capacity** | 950 concurrent sessions (500 AM + 450 Bastion shared) |

---

## Deployment Timeline

### Overview Table

| Phase | Duration | Components | Key Deliverables |
|-------|----------|------------|------------------|
| **Phase 1: Planning** | Week 1 | Prerequisites, network design | Network ready, licenses confirmed |
| **Phase 2: Access Manager** | Week 2 | SSO, MFA, brokering | Integration tested, APIs documented |
| **Phase 3: Site 1** | Week 3-4 | HAProxy, Bastion HA, RDS | Fully functional site, template created |
| **Phase 4: Site 2** | Week 5 | Replicate Site 1 | Second site operational |
| **Phase 5: Site 3** | Week 6 | Replicate Site 1 | Third site operational |
| **Phase 6: Site 4** | Week 7 | Replicate Site 1 | Fourth site operational |
| **Phase 7: Site 5** | Week 8 | Replicate Site 1 | All sites deployed |
| **Phase 8: Integration** | Week 9 | License pooling, testing | Multi-site validated |
| **Phase 9: Go-Live** | Week 10 | Production cutover | Production operational |

### Critical Path Dependencies

```
Week 1 (Planning) → Week 2 (Access Manager) → Weeks 3-4 (Site 1)
                                                      ↓
                                           Weeks 5-8 (Sites 2-5 in parallel)
                                                      ↓
                                           Week 9 (Final Integration)
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
- [ ] IPMI/iLO access configured for all appliances

# Network readiness
- [ ] MPLS circuits installed (Access Manager ↔ all sites)
- [ ] DNS records created (all components)
- [ ] NTP servers configured and reachable
- [ ] SSL/TLS certificates obtained (wildcard or per-host)
- [ ] Firewall rules pre-approved

# Licensing
- [ ] Access Manager license pool confirmed (500 sessions)
- [ ] Bastion license pool purchased (450 sessions)
- [ ] License activation keys received

# Security
- [ ] AD/LDAP service accounts created
- [ ] FortiAuthenticator RADIUS shared secret obtained
- [ ] Backup storage configured (offsite)
- [ ] Encryption keys generated
```

**Deliverable**: Completed prerequisite checklist with sign-off.

---

### Step 1.2: Design Network Topology

**Action**: Read and document network design in [01-network-design.md](01-network-design.md)

**Key Decisions**:

1. **IP Address Allocation**

   ```
   Site 1 (DC-1):
   - HAProxy VIP:        10.10.1.100
   - HAProxy-1:          10.10.1.5
   - HAProxy-2:          10.10.1.6
   - Bastion-1:          10.10.1.11
   - Bastion-2:          10.10.1.12
   - WALLIX RDS:         10.10.1.30

   Site 2 (DC-2):
   - HAProxy VIP:        10.10.2.100
   - HAProxy-1:          10.10.2.5
   - HAProxy-2:          10.10.2.6
   - Bastion-1:          10.10.2.11
   - Bastion-2:          10.10.2.12
   - WALLIX RDS:         10.10.2.30

   (Pattern repeats for Sites 3-5)
   ```

2. **DNS Records**

   ```bash
   # Site 1 Example
   bastion-site1.company.com      A    10.10.1.100  (HAProxy VIP)
   bastion1-site1.company.com     A    10.10.1.11
   bastion2-site1.company.com     A    10.10.1.12
   rds-site1.company.com          A    10.10.1.30
   ```

3. **Firewall Rules**

   **Reference**: [01-network-design.md](01-network-design.md) for complete port matrix.

   **Critical Ports**:
   - Access Manager → Bastion: TCP 443 (HTTPS API)
   - Bastion → FortiAuthenticator: UDP 1812/1813 (RADIUS)
   - HAProxy → Bastion: TCP 443, TCP 3389, TCP 22
   - Users → HAProxy VIP: TCP 443 (Web UI), TCP 22 (SSH), TCP 3389 (RDP)

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
- Active-Active: [06-bastion-active-active.md](06-bastion-active-active.md)
- Active-Passive: [07-bastion-active-passive.md](07-bastion-active-passive.md)

**Deliverable**: HA model selection document with justification per site.

---

### Step 1.4: Prepare Installation Environment

**Actions**:

1. **Download Software**

   ```bash
   # WALLIX Bastion ISO
   wget https://download.wallix.com/bastion/12.1/wallix-bastion-12.1.x.iso

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
- [ ] Network design documented (IP, DNS, firewall rules)
- [ ] HA model selected per site with justification
- [ ] Installation environment prepared (software, media, templates)
- [ ] Access Manager team coordination meeting scheduled for Week 2

---

## Phase 2: Access Manager Integration (Week 2)

### Objectives

- Configure Access Manager for session brokering
- Integrate FortiAuthenticator for MFA
- Test SSO authentication flow
- Document API endpoints for Bastion integration

### Step 2.1: Review Access Manager Architecture

**Action**: Read [03-access-manager-integration.md](03-access-manager-integration.md)

**Coordination with Access Manager Team**:

The Access Manager infrastructure is managed by a separate team. This phase focuses on **Bastion-side integration** only.

**Information to Obtain from Access Manager Team**:

```yaml
# SSO Configuration
sso_method: "SAML" | "OIDC" | "LDAP"
idp_metadata_url: "https://am.company.com/saml/metadata"
entity_id: "https://am.company.com"
assertion_consumer_url: "https://bastion-siteX.company.com/auth/sso"

# Session Brokering API
brokering_api_url: "https://am.company.com/api/v1/sessions"
api_key: "AM_API_KEY_REDACTED"
api_secret: "AM_API_SECRET_REDACTED"

# MFA Configuration
fortiauth_radius_primary: "10.20.0.60"
fortiauth_radius_secondary: "10.20.0.61"
radius_shared_secret: "RADIUS_SECRET_REDACTED"
radius_timeout: 5

# License Integration (Optional)
license_pool_api: "https://am.company.com/api/v1/licenses"
license_pool_id: "bastion-pool-450"
```

**Deliverable**: Integration parameters document from Access Manager team.

---

### Step 2.2: Configure SSO Integration

**Action**: Configure SAML/OIDC on Access Manager side (handled by AM team).

**Bastion Configuration** (to be applied in Phase 3):

```bash
# On Bastion (Phase 3), configure SSO provider
wabadmin sso configure --provider saml \
  --idp-metadata "https://am.company.com/saml/metadata" \
  --entity-id "https://bastion-site1.company.com" \
  --assertion-consumer-url "https://bastion-site1.company.com/auth/sso"
```

**Test Plan**:
1. Verify metadata exchange between AM and Bastion
2. Test user login via SSO (redirect to AM, return to Bastion)
3. Validate user attributes mapping (username, groups, email)

**Deliverable**: SSO configuration tested between AM test environment and pre-prod lab.

---

### Step 2.3: Integrate FortiAuthenticator MFA

**Action**: Configure RADIUS authentication for MFA.

**FortiAuthenticator Configuration** (handled by Security team):

```yaml
# RADIUS Client Configuration (on FortiAuthenticator)
client_name: "WALLIX-Bastion-Site1"
client_ip: "10.10.1.11"  # Bastion-1
nas_id: "bastion-site1"
shared_secret: "RADIUS_SECRET_REDACTED"
token_type: "FortiToken"
```

**Bastion Configuration** (Phase 3):

```bash
# Configure RADIUS authentication
wabadmin auth configure --method radius \
  --primary-server 10.20.0.60 \
  --secondary-server 10.20.0.61 \
  --shared-secret "RADIUS_SECRET_REDACTED" \
  --timeout 5 \
  --retry 3
```

**Test Plan**:
1. Test RADIUS authentication with FortiToken (push notification)
2. Test fallback to secondary RADIUS server
3. Validate MFA for privileged accounts
4. Test MFA bypass for service accounts (if required)

**Deliverable**: FortiAuthenticator RADIUS integration tested and documented.

---

### Step 2.4: Configure Session Brokering

**Action**: Set up session routing between Access Manager and Bastion sites.

**Brokering Logic** (configured on Access Manager):

```yaml
# Session routing rules (example)
routing_rules:
  - name: "Route by AD Site"
    condition: "user.ad_site == 'Site-1'"
    target: "bastion-site1.company.com"

  - name: "Route by User Group"
    condition: "user.groups contains 'IT-Admins'"
    target: "bastion-site1.company.com"

  - name: "Load Balance"
    condition: "true"  # Default
    target: "round_robin([site1, site2, site3, site4, site5])"
```

**Bastion API Configuration** (Phase 3):

```bash
# Register Bastion with Access Manager
curl -X POST https://am.company.com/api/v1/bastions \
  -H "Authorization: Bearer AM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "bastion-site1",
    "url": "https://bastion-site1.company.com",
    "api_key": "BASTION_API_KEY",
    "capacity": 90,
    "health_check_url": "https://bastion-site1.company.com/health"
  }'
```

**Test Plan**:
1. Test session creation via Access Manager API
2. Verify session routing to correct Bastion site
3. Test failover when primary site unavailable
4. Validate session attributes passed from AM to Bastion

**Deliverable**: Session brokering tested with all 5 sites registered (Sites 2-5 in Phase 4-7).

---

### Step 2.5: Document API Integration

**Action**: Document all API endpoints and authentication methods.

**API Endpoints Summary**:

| Endpoint | Method | Purpose | Authentication |
|----------|--------|---------|----------------|
| `/api/v1/sessions` | POST | Create new session | API Key |
| `/api/v1/sessions/{id}` | GET | Get session status | API Key |
| `/api/v1/sessions/{id}` | DELETE | Terminate session | API Key |
| `/api/v1/bastions` | GET | List registered Bastions | API Key |
| `/api/v1/licenses/pool` | GET | Check license availability | API Key |
| `/auth/sso` | POST | SSO authentication | SAML assertion |
| `/health` | GET | Health check | None (public) |

**Example API Call**:

```bash
# Create session via Access Manager
curl -X POST https://am.company.com/api/v1/sessions \
  -H "Authorization: Bearer AM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "john.doe@company.com",
    "target": "server01.company.com",
    "protocol": "ssh",
    "bastion_hint": "site1"
  }'

# Response
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "bastion_url": "https://bastion-site1.company.com",
  "connection_string": "ssh://john.doe@bastion-site1.company.com:22",
  "expires_at": "2026-02-05T18:00:00Z"
}
```

**Deliverable**: API integration guide with examples and error codes.

---

### Week 2 Deliverables Checklist

- [ ] SSO integration tested (SAML/OIDC)
- [ ] FortiAuthenticator RADIUS integration validated
- [ ] Session brokering API documented and tested
- [ ] API endpoint reference created
- [ ] Integration credentials securely stored
- [ ] Test results documented and approved

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

**Action**: Follow [05-haproxy-setup.md](05-haproxy-setup.md)

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

Follow [07-bastion-active-passive.md](07-bastion-active-passive.md)

**Summary**:

```bash
# On Bastion-1 (Primary: 10.10.1.11)

# 1. Initial appliance setup
wabadmin setup --hostname bastion1-site1.company.com \
               --ip 10.10.1.11 \
               --netmask 255.255.255.0 \
               --gateway 10.10.1.1 \
               --dns 10.20.0.10 \
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
               --dns 10.20.0.10 \
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

Follow [06-bastion-active-active.md](06-bastion-active-active.md)

**Note**: Active-Active requires additional MariaDB multi-master replication configuration and Pacemaker/Corosync setup. Defer to later phase if complexity is a concern.

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

**Action**: Integrate with Access Manager SSO and FortiAuthenticator MFA.

```bash
# On primary Bastion (Bastion-1)

# 1. Configure SSO (SAML)
wabadmin sso configure --provider saml \
  --idp-metadata "https://am.company.com/saml/metadata" \
  --entity-id "https://bastion-site1.company.com" \
  --assertion-consumer-url "https://bastion-site1.company.com/auth/sso"

# 2. Configure RADIUS MFA
wabadmin auth configure --method radius \
  --primary-server 10.20.0.60 \
  --secondary-server 10.20.0.61 \
  --shared-secret "RADIUS_SECRET_REDACTED" \
  --timeout 5 \
  --retry 3

# 3. Configure LDAP/AD user sync
wabadmin ldap configure --server ldap.company.com \
  --port 636 \
  --use-ssl \
  --base-dn "DC=company,DC=local" \
  --bind-dn "CN=svc_wallix,OU=Service Accounts,DC=company,DC=local" \
  --bind-password "LDAP_PASSWORD_REDACTED" \
  --user-filter "(objectClass=user)" \
  --sync-interval 300

# 4. Test authentication
wabadmin auth test --user john.doe@company.com
```

**Validation**:

```bash
# Test SSO login via web UI
# 1. Open browser: https://bastion-site1.company.com
# 2. Click "Login with SSO"
# 3. Redirect to Access Manager
# 4. Authenticate with AD credentials + FortiToken MFA
# 5. Return to Bastion dashboard

# Test direct RADIUS authentication
wabadmin auth test-radius --user john.doe@company.com --token 123456
```

**Deliverable**: SSO and MFA authentication working end-to-end.

---

### Week 4: Services and Integration

#### Step 3.4: Deploy WALLIX RDS Jump Host

**Action**: Follow [08-rds-jump-host.md](08-rds-jump-host.md)

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

#### Step 3.5: Register Bastion with Access Manager

**Action**: Register Site 1 Bastion with Access Manager for session brokering.

```bash
# From Access Manager (or via API)
curl -X POST https://am.company.com/api/v1/bastions \
  -H "Authorization: Bearer AM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "bastion-site1",
    "url": "https://bastion-site1.company.com",
    "api_key": "BASTION1_API_KEY",
    "api_secret": "BASTION1_API_SECRET",
    "capacity": 90,
    "location": "Site 1 DC",
    "health_check_url": "https://bastion-site1.company.com/health",
    "health_check_interval": 30
  }'

# Verify registration
curl -X GET https://am.company.com/api/v1/bastions/bastion-site1 \
  -H "Authorization: Bearer AM_API_KEY"
```

**Validation**:

```bash
# Test session brokering
curl -X POST https://am.company.com/api/v1/sessions \
  -H "Authorization: Bearer AM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "john.doe@company.com",
    "target": "server01.company.com",
    "protocol": "ssh",
    "bastion_hint": "site1"
  }'

# Verify session routed to Site 1 Bastion
# Check session on Bastion
wabadmin session list --active
```

**Deliverable**: Site 1 Bastion registered with Access Manager, session brokering tested.

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
- [ ] SSO login via web UI (redirect to Access Manager)
- [ ] MFA with FortiToken (push notification)
- [ ] LDAP user sync (verify user groups)
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

# 6. Access Manager Integration
- [ ] Session brokering (AM routes session to Site 1)
- [ ] API health check (AM polls Bastion health)
- [ ] License check (verify license consumption)

# 7. Audit and Compliance
- [ ] Audit log generation
- [ ] Syslog export to SIEM
- [ ] Compliance report generation (SOC2, ISO27001)
```

**Reference**: [10-testing-validation.md](10-testing-validation.md) for detailed test procedures.

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
- [ ] SSO and MFA authentication working
- [ ] WALLIX RDS operational with RemoteApp
- [ ] Site 1 registered with Access Manager
- [ ] Target systems configured and accessible
- [ ] Comprehensive testing completed (100% pass rate)
- [ ] Deployment template created for Sites 2-5

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
HAProxy VIP:   10.10.2.100
HAProxy-1:     10.10.2.5
HAProxy-2:     10.10.2.6
Bastion-1:     10.10.2.11
Bastion-2:     10.10.2.12
WALLIX RDS:    10.10.2.30
```

**DNS Records**:

```bash
bastion-site2.company.com      A    10.10.2.100
bastion1-site2.company.com     A    10.10.2.11
bastion2-site2.company.com     A    10.10.2.12
rds-site2.company.com          A    10.10.2.30
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

# 3. Configure authentication (1 hour)
# - Import SSO config from Site 1
# - Configure RADIUS (same FortiAuthenticator)
# - Configure LDAP sync

# 4. Deploy WALLIX RDS (1 hour)
# - Install Windows Server 2022
# - Configure RemoteApp
# - Add as target in Bastion

# 5. Register with Access Manager (30 mins)
curl -X POST https://am.company.com/api/v1/bastions \
  -H "Authorization: Bearer AM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "bastion-site2",
    "url": "https://bastion-site2.company.com",
    "api_key": "BASTION2_API_KEY",
    "api_secret": "BASTION2_API_SECRET",
    "capacity": 90,
    "location": "Site 2 DC"
  }'

# 6. Add target systems (1 hour)
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
# Test multi-site routing
# From Access Manager, create session with no bastion_hint
curl -X POST https://am.company.com/api/v1/sessions \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{
    "user": "john.doe@company.com",
    "target": "server02.company.com",
    "protocol": "ssh"
  }'

# Verify Access Manager routes session to Site 1 or Site 2 (load balanced)
```

**Deliverable**: Site 2 operational and integrated with Access Manager.

---

### Step 4.2: Sites 3, 4, 5 Deployment (Weeks 6-8)

**Action**: Repeat Site 2 deployment process for remaining sites.

**IP Allocation Summary**:

| Site | HAProxy VIP | Bastion-1 | Bastion-2 | WALLIX RDS |
|------|-------------|-----------|-----------|------------|
| Site 3 | 10.10.3.100 | 10.10.3.11 | 10.10.3.12 | 10.10.3.30 |
| Site 4 | 10.10.4.100 | 10.10.4.11 | 10.10.4.12 | 10.10.4.30 |
| Site 5 | 10.10.5.100 | 10.10.5.11 | 10.10.5.12 | 10.10.5.30 |

**Parallel Deployment** (if resources permit):

```bash
# Week 6: Deploy Sites 3 and 4 in parallel (2 teams)
# Week 7: Deploy Site 5 and start integration testing

# Reduces 4 weeks to 2 weeks
```

**Registration with Access Manager**:

```bash
# Register all sites
for site in site3 site4 site5; do
  curl -X POST https://am.company.com/api/v1/bastions \
    -H "Authorization: Bearer AM_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"bastion-${site}\",
      \"url\": \"https://bastion-${site}.company.com\",
      \"api_key\": \"${site^^}_API_KEY\",
      \"capacity\": 90,
      \"location\": \"Site ${site#site} DC\"
    }"
done

# Verify all sites registered
curl -X GET https://am.company.com/api/v1/bastions \
  -H "Authorization: Bearer AM_API_KEY"
```

**Deliverable**: Sites 3, 4, 5 operational and integrated with Access Manager.

---

### Week 5-8 Deliverables Checklist

- [ ] Site 2 deployed and operational (Week 5)
- [ ] Site 3 deployed and operational (Week 6)
- [ ] Site 4 deployed and operational (Week 7)
- [ ] Site 5 deployed and operational (Week 8)
- [ ] All 5 sites registered with Access Manager
- [ ] Multi-site session brokering tested
- [ ] Deployment metrics collected (actual vs. estimated time)

---

## Phase 8: Final Integration (Week 9)

### Objectives

- Configure license pooling across all 5 sites
- Optimize session brokering rules
- Conduct comprehensive multi-site testing
- Performance tuning and optimization

### Step 8.1: Configure License Pooling

**Action**: Integrate Bastion license pool with Access Manager.

**Reference**: [09-licensing.md](09-licensing.md)

**Configuration**:

```bash
# On Access Manager
# Configure Bastion license pool (450 concurrent sessions shared)

curl -X POST https://am.company.com/api/v1/licenses/pools \
  -H "Authorization: Bearer AM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "bastion-pool-450",
    "type": "shared",
    "capacity": 450,
    "bastions": [
      "bastion-site1",
      "bastion-site2",
      "bastion-site3",
      "bastion-site4",
      "bastion-site5"
    ],
    "allocation_strategy": "dynamic",
    "warning_threshold": 90
  }'

# On each Bastion, configure license pool client
wabadmin license configure --pool-mode shared \
                           --pool-server "https://am.company.com/api/v1/licenses" \
                           --pool-id "bastion-pool-450" \
                           --pool-api-key "LICENSE_POOL_API_KEY"

# Verify license consumption
wabadmin license status
# Output:
# License Pool: bastion-pool-450
# Total Capacity: 450
# Currently Used: 45
# Available: 405
# Site 1: 15 sessions
# Site 2: 10 sessions
# Site 3: 8 sessions
# Site 4: 7 sessions
# Site 5: 5 sessions
```

**Validation**:

```bash
# Test license exhaustion behavior
# 1. Simulate 450 concurrent sessions
# 2. Verify new session requests queued or rejected gracefully
# 3. Verify license release when sessions end
# 4. Verify alerting at 90% threshold (405 sessions)

# Check license pool via API
curl -X GET https://am.company.com/api/v1/licenses/pool/bastion-pool-450 \
  -H "Authorization: Bearer AM_API_KEY"
```

**Deliverable**: License pooling operational, consumption monitoring configured.

---

### Step 8.2: Optimize Session Brokering

**Action**: Fine-tune session routing rules for optimal load distribution.

**Brokering Rules**:

```yaml
# On Access Manager
routing_rules:
  # Rule 1: Route by AD Site attribute
  - name: "Route by AD Site"
    priority: 1
    condition: "user.ad_site == 'Site-1'"
    target: "bastion-site1.company.com"
    enabled: true

  - name: "Route by AD Site"
    priority: 1
    condition: "user.ad_site == 'Site-2'"
    target: "bastion-site2.company.com"
    enabled: true

  # Rule 2: Route by user group
  - name: "IT Admins to Site 1"
    priority: 2
    condition: "user.groups contains 'IT-Admins'"
    target: "bastion-site1.company.com"
    enabled: true

  # Rule 3: OT users via RDS
  - name: "OT Users to Site 5"
    priority: 3
    condition: "user.groups contains 'OT-Operators'"
    target: "bastion-site5.company.com"
    enabled: true

  # Rule 4: Load balancing (default)
  - name: "Load Balance"
    priority: 99
    condition: "true"
    target: "weighted_round_robin([
      {site: 'bastion-site1', weight: 30},
      {site: 'bastion-site2', weight: 25},
      {site: 'bastion-site3', weight: 20},
      {site: 'bastion-site4', weight: 15},
      {site: 'bastion-site5', weight: 10}
    ])"
    enabled: true

  # Rule 5: Failover
  - name: "Failover to Available Sites"
    priority: 100
    condition: "primary_site.health == 'unhealthy'"
    target: "first_healthy([site1, site2, site3, site4, site5])"
    enabled: true
```

**Validation**:

```bash
# Test routing rules
# 1. Create sessions for users with different AD sites
# 2. Verify routing to correct site
# 3. Test load balancing (create 100 sessions, verify distribution)
# 4. Test failover (stop Site 1, verify sessions route to other sites)
```

**Deliverable**: Session brokering optimized for performance and reliability.

---

### Step 8.3: Multi-Site Testing

**Action**: Comprehensive testing across all 5 sites.

**Reference**: [10-testing-validation.md](10-testing-validation.md)

**Test Scenarios**:

```bash
# 1. Load Testing
- [ ] 450 concurrent sessions across all 5 sites
- [ ] Performance metrics (latency, throughput, CPU, memory)
- [ ] Session recording performance under load

# 2. Failover Testing
- [ ] Single site failure (Site 1 down, sessions route to Sites 2-5)
- [ ] Multiple site failure (Sites 1-2 down, sessions route to Sites 3-5)
- [ ] Access Manager failover (AM-1 down, AM-2 takes over)
- [ ] HAProxy failover per site
- [ ] Bastion cluster failover per site

# 3. Integration Testing
- [ ] SSO across all sites
- [ ] MFA with FortiAuthenticator
- [ ] LDAP user sync
- [ ] Session brokering via Access Manager
- [ ] License pool consumption
- [ ] OT access via WALLIX RDS

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
- Failover time: < 60 seconds
- Session recording latency: < 100ms
- API response time: < 500ms
- License pool query: < 100ms

# Availability SLAs
- Site uptime: 99.9% (HA cluster)
- Access Manager uptime: 99.95% (HA cluster)
- Multi-site availability: 99.99% (1 site can fail)
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

# 5. Caching (Access Manager)
# Enable session brokering cache (reduce API calls to Bastions)
curl -X PATCH https://am.company.com/api/v1/config/cache \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{
    "enabled": true,
    "ttl": 300,
    "max_entries": 10000
  }'
```

**Deliverable**: Performance optimizations applied, benchmarks documented.

---

### Week 9 Deliverables Checklist

- [ ] License pooling configured and validated
- [ ] Session brokering rules optimized
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
- [ ] SSO authentication working (all sites)
- [ ] MFA with FortiAuthenticator working
- [ ] LDAP user sync operational
- [ ] Session brokering via Access Manager working
- [ ] License pooling operational (450 sessions shared)

# Security
- [ ] SSL certificates valid (not expiring within 90 days)
- [ ] Encryption keys backed up (offsite)
- [ ] Audit logging enabled (all sites)
- [ ] SIEM integration working (syslog export)
- [ ] Backup strategy tested (restore validated)

# Performance
- [ ] Load testing passed (450 concurrent sessions)
- [ ] Failover tested (all scenarios)
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
- Access Manager team
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

**Emergency Procedures**: Ensure all teams have reviewed [12-contingency-plan.md](12-contingency-plan.md) and [13-break-glass-procedures.md](13-break-glass-procedures.md) before go-live. Break glass accounts must be created, tested, and sealed credentials stored securely.

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
| Appliances deployed | 10 | 10 |
| Licensed capacity | 450 sessions | 450 |
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

### Access Manager Integration

```bash
# Register Bastion
curl -X POST https://am.company.com/api/v1/bastions \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{"name": "bastion-site1", "url": "https://bastion-site1.company.com"}'

# Check Bastion Health
curl -X GET https://am.company.com/api/v1/bastions/bastion-site1/health \
  -H "Authorization: Bearer AM_API_KEY"

# Create Session via Access Manager
curl -X POST https://am.company.com/api/v1/sessions \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{"user": "john.doe", "target": "server01", "protocol": "ssh"}'

# Check License Pool
curl -X GET https://am.company.com/api/v1/licenses/pool/bastion-pool-450 \
  -H "Authorization: Bearer AM_API_KEY"
```

### Monitoring and Diagnostics

```bash
# Cluster Health (Pacemaker)
crm status
crm_mon -1

# Database Replication (MariaDB)
mysql -e "SHOW SLAVE STATUS\G"

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

**Reference**: [05-haproxy-setup.md](05-haproxy-setup.md#troubleshooting)

---

#### Issue 2: Bastion Cluster Split-Brain

**Symptoms**:
- Both Bastion nodes think they are primary
- Data inconsistency between nodes

**Diagnosis**:

```bash
# Check cluster status
wabadmin ha status

# Check Pacemaker/Corosync
crm status
corosync-quorumtool
```

**Resolution**:

```bash
# Stop secondary node
wabadmin ha demote --force

# Restart cluster services
systemctl restart pacemaker
systemctl restart corosync

# Verify primary/secondary roles
wabadmin ha status
```

**Reference**: [07-bastion-active-passive.md](07-bastion-active-passive.md#split-brain-recovery)

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

**Reference**: [03-access-manager-integration.md](03-access-manager-integration.md#sso-troubleshooting)

---

#### Issue 4: RADIUS MFA Timeout

**Symptoms**:
- MFA authentication fails with timeout
- FortiToken push notifications not received

**Diagnosis**:

```bash
# Test RADIUS connectivity
wabadmin auth test-radius --user john.doe --token 123456

# Check FortiAuthenticator logs
# (on FortiAuthenticator)
diag debug application radiusd -1
diag debug enable

# Check network connectivity
nc -zvu 10.20.0.60 1812
nc -zvu 10.20.0.60 1813
```

**Resolution**:

```bash
# Increase RADIUS timeout
wabadmin auth configure --method radius --timeout 10

# Test with secondary RADIUS server
wabadmin auth configure --method radius --primary-server 10.20.0.61

# Verify shared secret
wabadmin auth test-radius --user john.doe --debug
```

**Reference**: [03-access-manager-integration.md](03-access-manager-integration.md#radius-troubleshooting)

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
# Check license status
wabadmin license status

# Check license pool via Access Manager
curl -X GET https://am.company.com/api/v1/licenses/pool/bastion-pool-450 \
  -H "Authorization: Bearer AM_API_KEY"

# List active sessions
wabadmin session list --active --count
```

**Resolution**:

```bash
# Terminate idle sessions
wabadmin session cleanup --idle-timeout 3600

# Increase license pool (requires purchase)
# Contact WALLIX licensing team

# Temporary: Increase warning threshold
curl -X PATCH https://am.company.com/api/v1/licenses/pools/bastion-pool-450 \
  -d '{"warning_threshold": 95}'
```

**Reference**: [09-licensing.md](09-licensing.md#license-pool-exhaustion)

---

### Contingency and Emergency Access

For comprehensive recovery procedures and emergency access when normal channels are unavailable:

- **Disaster Recovery**: [12-contingency-plan.md](12-contingency-plan.md) - Failure scenarios, backup strategy, recovery procedures
- **Break Glass Access**: [13-break-glass-procedures.md](13-break-glass-procedures.md) - Emergency access when SSO, MFA, or PAM is down

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
| **Architecture Diagrams** | [11-architecture-diagrams.md](11-architecture-diagrams.md) |
| **Testing Procedures** | [10-testing-validation.md](10-testing-validation.md) |

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
