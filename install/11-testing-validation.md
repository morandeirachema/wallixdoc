# Testing and Validation - 5-Site Multi-Datacenter Deployment

> Comprehensive testing procedures for validating WALLIX Bastion deployment across 5 sites

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | End-to-end testing and validation procedures |
| **Scope** | 5 Bastion sites + per-site FortiAuthenticator HA + per-site AD |
| **AM Testing** | Bastion-side connectivity only — AM itself is tested by client team |
| **Timeline** | Phase 8-9 testing (Week 9 of deployment) |
| **Version** | WALLIX Bastion 12.1.x |
| **Last Updated** | April 2026 |

---

## Table of Contents

1. [Testing Overview](#testing-overview)
2. [Component Testing](#component-testing)
3. [Integration Testing](#integration-testing)
4. [End-to-End User Workflow Testing](#end-to-end-user-workflow-testing)
5. [Failover Testing](#failover-testing)
6. [Performance Testing](#performance-testing)
7. [Security Testing](#security-testing)
8. [Acceptance Criteria](#acceptance-criteria)
9. [Sign-Off Checklist](#sign-off-checklist)

---

## Testing Overview

### Testing Strategy

```
+===============================================================================+
|  TESTING PYRAMID - 5-SITE DEPLOYMENT                                          |
+===============================================================================+
|                                                                               |
|                         +---------------------+                               |
|                         |   E2E Testing       |                               |
|                         |   (5-10% of tests)  |                               |
|                         |   User Workflows    |                               |
|                         +---------------------+                               |
|                                                                               |
|                  +---------------------------+                                |
|                  |   Integration Testing     |                                |
|                  |   (20-30% of tests)       |                                |
|                  |   Component Interactions  |                                |
|                  +---------------------------+                                |
|                                                                               |
|         +----------------------------------------+                            |
|         |        Component Testing               |                            |
|         |        (60-70% of tests)               |                            |
|         |        Individual Components           |                            |
|         +----------------------------------------+                            |
|                                                                               |
+===============================================================================+
```

### Testing Phases

| Phase | Focus | Duration | Dependencies |
|-------|-------|----------|--------------|
| **Phase 1: Component Testing** | Individual component validation | 1-2 days | All components installed |
| **Phase 2: Integration Testing** | Component interactions | 2-3 days | Phase 1 complete |
| **Phase 3: E2E User Workflows** | Complete user journeys | 2-3 days | Phase 2 complete |
| **Phase 4: Failover Testing** | HA and DR scenarios | 1-2 days | Phase 3 complete |
| **Phase 5: Performance Testing** | Load and scalability | 2-3 days | Phase 4 complete |
| **Phase 6: Security Testing** | Penetration and compliance | 2-3 days | Phase 5 complete |

**Total Testing Timeline**: 10-16 days (2-3 weeks)

### Test Environment

```
Testing Scope:
==============

Per-Site Components (5 sites):
- Site 1 (DC-1): 2x Bastion (HA) + 2x HAProxy (HA) + 1x RDS (DMZ VLAN)
                 + 2x FortiAuthenticator (HA Primary/Secondary, Cyber VLAN)
                 + 1x Active Directory DC (Cyber VLAN)
- Site 2 (DC-2): same architecture as Site 1
- Site 3 (DC-3): same architecture as Site 1
- Site 4 (DC-4): same architecture as Site 1
- Site 5 (DC-5): same architecture as Site 1

Client-Managed (NOT our scope to test):
- 2x Access Manager (HA pair, client's team manages and tests)

MPLS:
- Inter-site connectivity via MPLS (tested jointly with network team)

Target Systems per site (~100-200 total, representative sample for testing):
- 2x Windows Server 2022 (RDP targets)
- 2x RHEL 10 (SSH targets)
- 1x RHEL 9 (SSH legacy target)
```

---

## Component Testing

### 1.1 HAProxy Testing (Per Site)

#### Test 1.1.1: HAProxy Service Health

```bash
# Test on each site (Site 1-5)
ssh admin@haproxy1-site1.company.com

# Check HAProxy service status
systemctl status haproxy
# Expected: active (running)

# Check HAProxy configuration syntax
haproxy -c -f /etc/haproxy/haproxy.cfg
# Expected: Configuration file is valid

# Check HAProxy statistics
echo "show stat" | socat stdio /var/lib/haproxy/stats
# Expected: Backend servers showing UP status

# Test HAProxy API
curl -u admin:password http://localhost:8404/stats
# Expected: HTTP 200, statistics page displayed
```

**Expected Results:**
- [ ] HAProxy service running on both nodes (primary and backup)
- [ ] Configuration valid with no syntax errors
- [ ] Statistics socket accessible
- [ ] Web stats interface accessible on port 8404

#### Test 1.1.2: HAProxy VRRP Failover

```bash
# Test VRRP virtual IP assignment
ip addr show | grep 10.10.1.100
# Expected: VIP present on primary node

# Check Keepalived status
systemctl status keepalived
# Expected: active (running)

# Test VRRP failover
# On primary node:
systemctl stop keepalived

# Verify VIP migration (< 3 seconds)
# On backup node:
ip addr show | grep 10.10.1.100
# Expected: VIP migrated to backup

# Test user connectivity during failover
while true; do curl -k https://10.10.1.100/health; sleep 1; done
# Expected: Brief interruption (< 3s), then successful responses

# Restart primary Keepalived
systemctl start keepalived
```

**Expected Results:**
- [ ] VIP assigned to primary under normal conditions
- [ ] VIP fails over to backup within 3 seconds
- [ ] User traffic automatically routed to backup
- [ ] Primary can reclaim VIP after restoration

#### Test 1.1.3: HAProxy Load Balancing

```bash
# Test load distribution to Bastion backends
for i in {1..100}; do
  curl -k https://10.10.1.100/health 2>&1 | grep -o "bastion[12]"
done | sort | uniq -c

# Expected: Approximately 50/50 distribution
#   50 bastion1
#   50 bastion2

# Test session persistence (cookie-based)
curl -k -c cookies.txt https://10.10.1.100/login
curl -k -b cookies.txt https://10.10.1.100/dashboard

# Expected: Both requests routed to same backend

# Check HAProxy backend health
echo "show servers state" | socat stdio /var/lib/haproxy/stats
# Expected: Both bastion1 and bastion2 status UP
```

**Expected Results:**
- [ ] Traffic distributed evenly across both Bastion nodes
- [ ] Session persistence maintained via cookies
- [ ] Health checks detecting backend status correctly
- [ ] Failed backends automatically removed from rotation

### 1.2 WALLIX Bastion Testing (Per Site)

#### Test 1.2.1: Bastion Service Health

```bash
# SSH to primary Bastion node
ssh admin@bastion1-site1.company.com

# Check WALLIX service status
systemctl status wallix-bastion
# Expected: active (running)

# Check Bastion internal health
wabadmin status
# Expected: All services running

# Check database connectivity
wabadmin db-status
# Expected: Database accessible, replication active

# Check license status
wabadmin license-info
# Expected: Valid license, sessions available
```

**Expected Results:**
- [ ] WALLIX Bastion service running on both nodes
- [ ] All internal services (web, SSH, RDP) active
- [ ] Database reachable and synchronized
- [ ] License valid with available session slots

#### Test 1.2.2: Bastion HA Replication Status

```bash
# Check replication status on each Bastion node (run as root)

# For Master/Master:
# On primary Master node:
bastion-replication --monitoring
# Expected output:
#   Replication mode: master-master
#   Local role: master
#   Remote role: master
#   Replication status: OK
#   Seconds behind: 0

# On secondary Master node:
bastion-replication --monitoring
# Expected output:
#   Replication mode: master-master
#   Local role: master
#   Remote role: master
#   Replication status: OK
#   Seconds behind: 0

# For Master/Slave:
# On Master node:
bastion-replication --monitoring
# Expected output:
#   Replication mode: master-slave
#   Local role: master
#   Remote role: slave
#   Replication status: OK

# On Slave node:
bastion-replication --monitoring
# Expected output:
#   Replication mode: master-slave
#   Local role: slave
#   Remote role: master
#   Replication status: OK
#   Seconds behind: 0
```

**Expected Results:**
- [ ] `bastion-replication --monitoring` reports OK on both nodes
- [ ] Replication mode matches expected topology (master-master or master-slave)
- [ ] Seconds behind is 0 (no replication lag)
- [ ] No replication errors reported

#### Test 1.2.2b: Replication Exclusions Validation

```bash
# Verify that node-specific settings are NOT replicated
# These must be configured independently on each node:

# Check SMTP configuration on each node
# Node 1:
ssh admin@bastion1-site1.company.com
wabadmin smtp-status
# Expected: SMTP configured with node-specific relay

# Node 2:
ssh admin@bastion2-site1.company.com
wabadmin smtp-status
# Expected: SMTP configured independently (may differ from Node 1)

# Verify SIEM/syslog forwarding is configured per node
# Each node should send logs independently

# Verify network settings are node-specific
# (IP address, hostname, DNS — NOT replicated)
```

**Expected Results:**
- [ ] SMTP settings configured independently on each node
- [ ] SMTP delivery functional on each node separately
- [ ] SIEM/syslog forwarding configured per node
- [ ] Network settings (IP, hostname) are node-specific
- [ ] Audit tables are node-local (not replicated)

#### Test 1.2.3: Bastion Credential Vault

```bash
# Test credential storage and retrieval
wabadmin credential add \
  --device "test-server-01" \
  --account "testuser" \
  --password "TestP@ssw0rd123" \
  --domain "company.com"

# Verify credential stored
wabadmin credential list | grep test-server-01
# Expected: Credential listed

# Test credential retrieval (encrypted)
wabadmin credential get --device "test-server-01" --account "testuser"
# Expected: Credential details returned (password masked)

# Test credential checkout (for session use)
wabadmin credential checkout --device "test-server-01" --account "testuser"
# Expected: Password decrypted and provided
```

**Expected Results:**
- [ ] Credentials stored encrypted in vault
- [ ] Credentials retrievable by authorized users only
- [ ] Credential checkout audited in logs
- [ ] Credential rotation policies enforced

### 1.3 WALLIX RDS Testing (Per Site)

#### Test 1.3.1: RDS Service Health

```bash
# RDP to WALLIX RDS server
mstsc /v:rds-site1.company.com

# Login with admin credentials

# Check RDS role installed
Get-WindowsFeature -Name RDS-RD-Server
# Expected: Installed

# Check RemoteApp configuration
Get-RDRemoteApp
# Expected: Published RemoteApps listed

# Check RDS licensing
Get-RDLicenseConfiguration
# Expected: License server configured, mode PerUser
```

**Expected Results:**
- [ ] RDS service running and accessible
- [ ] RemoteApps published for OT access
- [ ] RDS licensing configured correctly
- [ ] Session collection active

#### Test 1.3.2: RDS Connection via Bastion

```bash
# Test OT access via RDS jump host
# User connects to Bastion → Bastion routes to RDS → RDS connects to OT target

# Login to Bastion web UI
https://bastion-site1.company.com

# Select OT target (via RDS RemoteApp)
# Target: ot-workstation-01.company.com
# Protocol: RDP (RemoteApp)

# Expected: RemoteApp session launched
# User sees only the published application, not full desktop

# Verify session recording
wabadmin sessions --active | grep rds
# Expected: RDS session listed with recording active
```

**Expected Results:**
- [ ] RDS jump host accessible via Bastion
- [ ] RemoteApp sessions launch successfully
- [ ] OT targets reachable via RDS
- [ ] Sessions recorded and audited

### 1.4 Access Manager Integration Verification (Bastion Side Only)

> The Access Manager is installed and tested by the client team. Our scope here is
> verifying that the Bastion-side integration (SAML SP, health check endpoint, API key)
> is correctly configured and reachable.

#### Test 1.4.1: Bastion Health Check Endpoint Accessible from AM

```bash
# Verify health check endpoint is accessible (client AM team runs this from AM)
# Test locally to confirm endpoint exists before handoff to client
curl -k https://bastion-site1.company.com/health
# Expected: {"status": "ok", "version": "12.1.x", "sessions_active": 0}

# Test on all 5 sites
for site in 1 2 3 4 5; do
  echo "Site $site:"
  curl -sk https://bastion-site${site}.company.com/health
done
```

**Expected Results:**
- [ ] Health check endpoint returns HTTP 200 on all 5 sites
- [ ] Response includes status, version, and session count

#### Test 1.4.2: SAML SP Metadata Accessible

```bash
# Verify SAML SP metadata endpoint (AM team uses this to configure IdP side)
curl -k https://bastion-site1.company.com/auth/saml/metadata
# Expected: XML document with SP metadata (EntityDescriptor)

# Verify CA certificate imported and AM HTTPS trusted
curl --cacert /etc/ssl/certs/am-ca.crt https://am1.client.com/health
# Expected: HTTP 200 without certificate error
```

**Expected Results:**
- [ ] SAML SP metadata accessible on all 5 sites
- [ ] AM CA certificate trusted on each Bastion node
- [ ] SAML IdP configured on each Bastion site

#### Test 1.4.3: SSO Login via AM (Joint Test with Client Team)

```bash
# Coordinate with client AM team for this test
# 1. Open browser: https://bastion-site1.company.com
# 2. Click "Login with SSO"
# 3. Browser redirects to AM SSO URL
# 4. Authenticate with AD credentials + FortiToken MFA
# 5. AM redirects back to Bastion with SAML assertion
# 6. Bastion grants access and shows dashboard

# Verify SAML authentication logged on Bastion
wabadmin audit --last 10 | grep -i saml
# Expected: SAML authentication event logged
```

**Expected Results:**
- [ ] SSO login redirects to AM login page
- [ ] Successful SAML assertion returns to Bastion
- [ ] User receives correct Bastion access profile
- [ ] Authentication event logged in Bastion audit

### 1.5 FortiAuthenticator Testing (Per Site)

#### Test 1.5.1: FortiAuth RADIUS Service (Per Site)

Run this test on each site's FortiAuthenticator HA pair. Replace X with site number (1-5).

```bash
# Test RADIUS service on FortiAuth-1 (Primary, Cyber VLAN)
ssh admin@10.10.X.50  # FortiAuth-1

# Check RADIUS service status
diagnose debug application radiusd -1
# Expected: RADIUS daemon running

# Test RADIUS authentication for test user (TOTP-only flow)
radtest testuser TestP@ss123 localhost 0 sharedsecret
# Expected: Access-Challenge (TOTP prompt) — TOTP is the only MFA method

# Check RADIUS accounting records from Bastion
tail -f /var/log/radius/radacct/bastion-site-X/detail
# Expected: Accounting records logged from Bastion RADIUS clients
```

**Expected Results (per site):**
- [ ] RADIUS service running on Primary (10.10.X.50) and Secondary (10.10.X.51)
- [ ] Bastion registered as a RADIUS client on FortiAuth
- [ ] RADIUS Access-Challenge returned for test user (TOTP flow)
- [ ] Accounting logs generated for authentication events

#### Test 1.5.2: FortiToken TOTP Authentication

FortiToken Mobile is configured for TOTP (time-based one-time password), not push notifications.

```bash
# Test FortiToken TOTP authentication
# Login to FortiAuthenticator web UI (Cyber VLAN)
# https://10.10.X.52  (VIP for per-site FortiAuth HA)

# Navigate to: Authentication > Test Authentication

# Test user:
Username: jsmith
Password: [User's AD password + TOTP code]
# Format: <ADpassword><6-digit TOTP>

# Expected: RADIUS Access-Accept returned

# Verify in FortiAuth logs
# Authentication > Authentication Log
# Expected: jsmith — TOTP authenticated — ACCEPT
```

**Expected Results:**
- [ ] TOTP authentication succeeds for enrolled test user
- [ ] Authentication fails for incorrect TOTP code
- [ ] Timeout after 30-second TOTP window (TOTP rotation)
- [ ] Authentication events logged in FortiAuth

#### Test 1.5.3: FortiAuth AD/LDAP Integration

```bash
# Verify FortiAuth can authenticate users against per-site AD (Cyber VLAN)
# FortiAuth admin panel: Authentication > LDAP > Test

# LDAP server: 10.10.X.60 (AD DC, Cyber VLAN)
# Test user: svc_fortiauth (service account bound to LDAP)

# Expected: LDAP bind successful, user group memberships returned
```

**Expected Results:**
- [ ] FortiAuth LDAP bind to 10.10.X.60 successful on all 5 sites
- [ ] User groups correctly retrieved from AD
- [ ] User authentication falls through to LDAP correctly

---

## Integration Testing

### 2.1 SSO Integration Testing

#### Test 2.1.1: SAML Authentication Flow (Bastion → AM)

This test requires the client AM team to participate. The Bastion acts as SAML SP; the AM acts as IdP.

```bash
# Test SAML SSO from user perspective (coordinate with client AM team)

# 1. Access Bastion portal
curl -v https://bastion-site1.company.com/login
# Expected: HTTP 302 redirect to AM SSO URL

# 2. Follow redirect to AM SSO
# Expected: AM login page displayed

# 3. User enters AD credentials + TOTP (FortiToken)
# Expected: AM verifies credentials and MFA

# 4. AM issues SAML assertion and redirects to Bastion ACS
# Expected: Bastion receives SAML assertion

# 5. Bastion grants access
# Expected: User sees Bastion dashboard

# Verify SAML assertion received
wabadmin audit --last 10 | grep -i saml
# Expected: SAML authentication event logged with username and groups
```

**Expected Results:**
- [ ] SAML redirect chain functions correctly (Bastion → AM → Bastion)
- [ ] User attributes mapped properly (username, email, groups)
- [ ] Session created after successful SAML authentication
- [ ] Group-to-profile mapping grants correct access level

### 2.2 MFA Integration Testing

#### Test 2.2.1: FortiToken TOTP via Bastion

```bash
# End-to-end MFA test: Bastion RADIUS client → FortiAuth per site

# Test from a Bastion node, using radtest against per-site FortiAuth
# (Replace X with site number)
ssh admin@bastion1-site1.company.com

# Simulate RADIUS request to FortiAuth-1 (Cyber VLAN)
radtest jsmith "CorrectADpass123456" 10.10.X.50 0 <RADIUS_SHARED_SECRET>
# Expected: Access-Challenge (Bastion must relay TOTP code)

# Monitor RADIUS traffic on Bastion
tcpdump -i any -n 'udp port 1812 or udp port 1813'
# Expected: RADIUS Access-Request to 10.10.X.50, Access-Challenge returned

# After user provides TOTP code:
radtest jsmith "CorrectADpass123456<TOTP>" 10.10.X.50 0 <RADIUS_SHARED_SECRET>
# Expected: Access-Accept

# Verify in Bastion logs
tail -f /var/log/wallix/auth.log | grep -i radius
# Expected: RADIUS authentication successful
```

**Expected Results:**
- [ ] RADIUS communication between Bastion and FortiAuth functional (per site)
- [ ] TOTP challenge-response flow completes within 30-second TOTP window
- [ ] Failed MFA attempts (wrong TOTP) return Access-Reject and logged
- [ ] Bastion sends RADIUS accounting correctly to FortiAuth

#### Test 2.2.2: FortiAuth HA RADIUS Failover (Per Site)

```bash
# Test per-site FortiAuth RADIUS failover
# Each Bastion has 2 RADIUS servers configured: Primary (X.50) and Secondary (X.51)

# Step 1: Verify Bastion RADIUS config
wabadmin auth radius-list
# Expected: FortiAuth-1 (10.10.X.50) and FortiAuth-2 (10.10.X.51) listed

# Step 2: Simulate primary FortiAuth failure
ssh admin@10.10.X.50
# Simulate failure (e.g., block RADIUS port or stop service for testing)

# Step 3: Attempt user authentication on Bastion
# Expected: Bastion RADIUS timeout on 10.10.X.50 (5s), fails over to 10.10.X.51

# Step 4: Monitor Bastion auth logs
tail -f /var/log/wallix/auth.log
# Expected: "RADIUS timeout on 10.10.X.50, trying 10.10.X.51"
# Expected: Authentication completes successfully via secondary

# Step 5: Restore primary FortiAuth
# Step 6: Verify new authentication requests prefer primary
```

**Expected Results:**
- [ ] Automatic RADIUS failover to secondary FortiAuth (10.10.X.51)
- [ ] Users complete authentication transparently
- [ ] Failover time < 10 seconds (RADIUS timeout 5s + retry)
- [ ] Primary used again after restoration

### 2.3 Bastion LDAP/AD Integration Testing

#### Test 2.3.1: AD LDAP Connectivity per Site

```bash
# Verify Bastion LDAP connection to per-site AD DC (Cyber VLAN)
# Replace X with site number

ssh admin@bastion1-site1.company.com

# Test LDAP connectivity to per-site DC
wabadmin auth ldap-test --server 10.10.X.60
# Expected: LDAP bind successful, server reachable

# Test user lookup
wabadmin auth ldap-user-lookup --server 10.10.X.60 --username jsmith
# Expected: User attributes returned (groups, email, etc.)

# Verify group-to-profile mapping
wabadmin auth ldap-groups --server 10.10.X.60 --username jsmith
# Expected: AD groups listed, PAM-Users or PAM-Admins group present
```

**Expected Results:**
- [ ] LDAP connection to 10.10.X.60 successful on all 5 sites
- [ ] User attributes correctly returned
- [ ] Group memberships map to correct Bastion profiles
- [ ] LDAP service account (svc_wallix_bastion) works on each site

---

## End-to-End User Workflow Testing

### 3.1 Native Access Workflow (SSH)

#### Test 3.1.1: SSH Proxy Session

```bash
# Complete SSH workflow via Bastion

# User: jsmith
# Target: prod-rhel-01.company.com (SSH)

# Step 1: User initiates SSH connection
ssh jsmith@bastion-site1.company.com

# Expected: Bastion prompts for username/password + TOTP
# (or redirects to SSO if AM is configured)

# Step 2: User enters credentials
Username: jsmith
Password: [AD password + FortiToken TOTP code]

# Expected: RADIUS request sent to FortiAuth (Cyber VLAN), TOTP validated

# Step 3: Authentication successful
# Expected: Authentication successful, Bastion target menu presented

# Step 4: Bastion presents target selection menu
Available targets:
  1. prod-rhel-01.company.com (SSH)
  2. prod-rhel-02.company.com (SSH)
  3. dev-rhel-03.company.com (SSH)

Select target: 1

# Expected: SSH session established to prod-rhel-01.company.com

# Step 5: User executes commands on target
whoami
# Expected: jsmith

# Step 6: Session recorded
wabadmin sessions --active | grep jsmith
# Expected: Active SSH session to prod-rhel-01 listed

# Step 7: User exits session
exit

# Verify session recording saved
wabadmin recordings --user jsmith --last 1
# Expected: SSH session recording available
```

**Expected Results:**
- [ ] User authenticated via AD credentials + FortiToken TOTP
- [ ] Target selection menu displayed
- [ ] SSH session proxied through Bastion
- [ ] Commands executed successfully on target
- [ ] Session recorded with keystroke logging
- [ ] Session audit log generated

### 3.2 Native Access Workflow (RDP)

#### Test 3.2.1: RDP Proxy Session

```bash
# Complete RDP workflow via Bastion

# User: jsmith
# Target: prod-win-01.company.com (RDP)

# Step 1: User opens RDP client
mstsc /v:bastion-site1.company.com:3389

# Expected: Bastion RDP gateway prompt

# Step 2: User enters credentials
Username: jsmith@company.com
Password: [AD password + FortiToken TOTP code]

# Expected: RADIUS authentication via FortiAuth (Cyber VLAN)
# (or SSO login if AM is configured)

# Step 3: User completes authentication
# Expected: Authenticated, target selection screen

# Step 4: User selects target
Target: prod-win-01.company.com
Protocol: RDP

# Expected: RDP session established, Windows desktop displayed

# Step 5: User works on Windows target
# (Opens applications, executes commands)

# Verify session recording active
wabadmin sessions --active --protocol rdp | grep jsmith
# Expected: Active RDP session listed

# Step 6: User closes RDP window
# Expected: Session terminated gracefully

# Verify recording
wabadmin recordings --user jsmith --protocol rdp --last 1
# Expected: RDP session video recording available
```

**Expected Results:**
- [ ] RDP gateway authentication via AD + TOTP (or SSO via AM)
- [ ] Full Windows desktop accessible
- [ ] Mouse and keyboard input captured
- [ ] Screen recording saved as video
- [ ] Session metadata (apps opened, files accessed) logged
- [ ] Graceful session termination

### 3.3 OT Access Workflow (RemoteApp)

#### Test 3.3.1: OT RemoteApp Session

```bash
# OT access via WALLIX RDS jump host

# User: ot-engineer
# Target: ot-workstation-01.company.com (via RDS RemoteApp)

# Step 1: User logs into Bastion web UI
https://bastion-site1.company.com

# Expected: Login page (or SSO redirect to AM if configured)

# Step 2: Complete authentication (AD + TOTP or SSO)
# Expected: Bastion dashboard displayed

# Step 3: User selects OT target
Navigation: Resources > OT Systems > ot-workstation-01.company.com
Protocol: RDP (RemoteApp)

# Expected: RemoteApp connection initiated via RDS jump host

# Step 4: RDS brokers connection to OT target
# Expected: Published RemoteApp window displayed (NOT full desktop)

# Step 5: User works within RemoteApp
# (Performs OT-specific tasks in isolated application)

# Verify two-hop session recording
# Bastion → RDS → OT Target

wabadmin sessions --active --via-rds | grep ot-engineer
# Expected: Two sessions listed (Bastion→RDS, RDS→OT)

# Step 6: User closes RemoteApp
# Expected: Both sessions terminated

# Verify recording includes both hops
wabadmin recordings --user ot-engineer --last 1 --detailed
# Expected: Recording shows full path (Bastion→RDS→OT)
```

**Expected Results:**
- [ ] OT access via RDS jump host functional
- [ ] RemoteApp isolation enforced (no full desktop)
- [ ] Two-hop session path recorded
- [ ] OT target accessible only via RDS
- [ ] Direct Bastion→OT access blocked (enforced)

---

## Failover Testing

### 4.1 HAProxy Failover

#### Test 4.1.1: HAProxy Node Failure

```bash
# Test HAProxy high availability

# Initial state: HAProxy-1 primary, HAProxy-2 standby

# Step 1: Verify VIP on primary
ssh admin@haproxy1-site1.company.com
ip addr show | grep 10.10.1.100
# Expected: VIP present on HAProxy-1

# Step 2: Initiate user sessions
# 5 concurrent users accessing Bastion via VIP

# Step 3: Simulate HAProxy-1 failure
systemctl stop haproxy keepalived

# Step 4: Monitor failover
# On HAProxy-2:
ip addr show | grep 10.10.1.100
# Expected: VIP migrated to HAProxy-2 within 3 seconds

# Step 5: Verify user sessions
# Expected: Existing sessions continue uninterrupted
# New sessions routed via HAProxy-2

# Step 6: Measure failover time
# Expected: < 3 seconds (VRRP timeout)

# Step 7: Restore HAProxy-1
systemctl start haproxy keepalived

# Expected: HAProxy-1 reclaims VIP (manual fallback or auto)
```

**Expected Results:**
- [ ] VRRP failover within 3 seconds
- [ ] Active sessions continue without interruption
- [ ] New connections automatically routed to backup
- [ ] Failback to primary after restoration
- [ ] No data loss during failover

### 4.2 Bastion HA Failover

#### Test 4.2.1: Bastion Replication Failover (Master/Master)

```bash
# Test Master/Master replication failover

# Initial state: Both Bastion nodes active as masters, load balanced

# Step 1: Verify replication status on both nodes (run as root)
ssh admin@bastion1-site1.company.com
bastion-replication --monitoring
# Expected: Replication mode: master-master, Status: OK

ssh admin@bastion2-site1.company.com
bastion-replication --monitoring
# Expected: Replication mode: master-master, Status: OK

# Step 2: Verify bidirectional replication
# Create a test object on Node 1 (via web UI or API)
# Expected: Object appears on Node 2 within seconds

# Create a test object on Node 2
# Expected: Object appears on Node 1 within seconds

# Step 3: Initiate user sessions
# 10 users connected, distributed across both nodes

# Step 4: Simulate Bastion Node 1 failure
ssh admin@bastion1-site1.company.com
systemctl stop wallix-bastion

# Step 5: Monitor failover via HAProxy
# HAProxy health check detects Node 1 down
# All traffic redirected to Node 2

echo "show servers state" | socat stdio /var/lib/haproxy/stats
# Expected: bastion1 DOWN, bastion2 UP

# Step 6: Verify user sessions
# Expected: Users on Node 1 experience brief interruption (< 5s)
#           Users on Node 2 unaffected
#           New sessions all routed to Node 2

# Step 7: Check Node 2 load
wabadmin sessions --count
# Expected: All sessions on Node 2 (100% load)

# Step 8: Restore Node 1
systemctl start wallix-bastion

# Step 9: Verify replication resync after restoration
bastion-replication --monitoring
# Expected: Replication status: OK, Seconds behind: 0

# HAProxy detects Node 1 UP, resumes load balancing
```

**Expected Results:**
- [ ] HAProxy health check detects failure within 5 seconds
- [ ] Failed node removed from rotation
- [ ] Surviving node handles 100% load
- [ ] Session interruption < 5 seconds for affected users
- [ ] Replication resynchronizes after node restoration
- [ ] Automatic rebalancing after restoration

#### Test 4.2.2: Bastion Replication Failover (Master/Slave)

```bash
# Test Master/Slave replication failover

# Initial state: Node 1 MASTER (active), Node 2 SLAVE (standby)

# Step 1: Verify replication status (run as root)
ssh admin@bastion1-site1.company.com
bastion-replication --monitoring
# Expected: Local role: master, Remote role: slave, Status: OK

ssh admin@bastion2-site1.company.com
bastion-replication --monitoring
# Expected: Local role: slave, Remote role: master, Status: OK

# Step 2: Initiate user sessions
# 10 users connected to Node 1 via VIP

# Step 3: Simulate Node 1 (Master) failure
ssh admin@bastion1-site1.company.com
systemctl stop wallix-bastion

# Step 4: Promote Slave to Master (run as root on Node 2)
ssh admin@bastion2-site1.company.com
bastion-replication --elevate-master
# Expected: Node 2 promoted from slave to master

# Step 5: Verify promotion
bastion-replication --monitoring
# Expected: Local role: master, Replication status: OK

# Step 6: Verify user access
# Users reconnect to Node 2 (now master)
# Expected: Full functionality available on promoted node

# Step 7: Restore original Node 1 and resync
# After Node 1 is repaired/restarted:
ssh admin@bastion1-site1.company.com
bastion-replication --dump-resync
# Expected: Node 1 resynchronizes data from Node 2 (current master)

# Step 8: Verify resync completion
bastion-replication --monitoring
# Expected: Replication status: OK, Seconds behind: 0
```

**Expected Results:**
- [ ] `bastion-replication --elevate-master` promotes slave successfully
- [ ] Promoted node has full master functionality
- [ ] Users can reconnect to promoted node
- [ ] `bastion-replication --dump-resync` resynchronizes restored node
- [ ] Replication fully operational after resync

### 4.3 Access Manager Failover (Client Team Test)

> AM failover testing is the client team's responsibility. They control the AM HA pair.
> Our role is to verify that the Bastion remains functional during AM failover.

#### Test 4.3.1: Bastion Behavior During AM Failover (Coordinate with Client)

```bash
# Coordinate with client AM team to run this test

# Step 1: Client AM team initiates AM1 failure (simulated or real)

# Step 2: Monitor Bastion authentication logs
tail -f /var/log/wallix/auth.log | grep -i "access manager\|saml\|am"
# Expected: SAML requests redirected to AM2 automatically

# Step 3: Attempt SSO login during AM1 failover
# Expected: SSO login continues working via AM2 (within 10-60 seconds)

# Step 4: Verify Bastion health check endpoint still responds
curl -k https://bastion-site1.company.com/health
# Expected: HTTP 200 (Bastion unaffected by AM failover)

# Step 5: After AM1 restored, verify normal operation
```

**Expected Results (from Bastion side):**
- [ ] Bastion health check endpoint unaffected during AM failover
- [ ] SAML login recovers within AM failover window
- [ ] Existing Bastion sessions unaffected (sessions not disrupted)
- [ ] New SSO logins succeed after AM2 becomes active

### 4.4 FortiAuthenticator HA Failover (Per Site)

#### Test 4.4.1: FortiAuth Primary Failure (Per Site)

Run this test for each site. Replace X with site number (1-5).

```bash
# Test per-site FortiAuth RADIUS failover
# FortiAuth-1: 10.10.X.50 (Primary)
# FortiAuth-2: 10.10.X.51 (Secondary)
# Bastion has both configured as RADIUS servers

# Step 1: Verify both FortiAuth nodes are operational
ping 10.10.X.50  # FortiAuth-1
ping 10.10.X.51  # FortiAuth-2

# Step 2: Initiate test user authentication (5 attempts in parallel)
# Expected: All RADIUS requests routed to FortiAuth-1 (primary)

# Step 3: Simulate FortiAuth-1 failure
# (Block RADIUS UDP port 1812 on FortiAuth-1, or stop service)
ssh admin@10.10.X.50
# Block port for testing: iptables -I INPUT -p udp --dport 1812 -j DROP

# Step 4: Attempt user authentication on Bastion
# Expected: 5-second RADIUS timeout on FortiAuth-1, then automatic failover to FortiAuth-2
# Expected: Authentication completes via FortiAuth-2 (10.10.X.51)

# Step 5: Monitor Bastion auth logs during failover
tail -f /var/log/wallix/auth.log
# Expected: "RADIUS server 10.10.X.50 timeout, trying 10.10.X.51"
# Expected: "RADIUS authentication successful via 10.10.X.51"

# Step 6: Restore FortiAuth-1
# (Remove iptables rule: iptables -D INPUT -p udp --dport 1812 -j DROP)

# Step 7: Verify RADIUS requests return to primary (FortiAuth-1)
```

**Expected Results (per site):**
- [ ] RADIUS failover from 10.10.X.50 to 10.10.X.51 within 10 seconds
- [ ] User authentication completes transparently
- [ ] No user-visible authentication failure during failover
- [ ] Bastion prefers primary (10.10.X.50) after restoration
- [ ] FortiAuth HA internal replication remains healthy during test

---

## Performance Testing

### 5.1 Concurrent Session Load Testing

#### Test 5.1.1: Load Test - 25 Concurrent Sessions (Per Site)

```bash
# Load test with 25 concurrent SSH sessions (matching ~25 users per site)

# Use load testing tool (JMeter, Locust, or custom script)

# Test script: concurrent-ssh-load.sh
#!/bin/bash
for i in {1..25}; do
  ssh -o StrictHostKeyChecking=no \
      jsmith$i@bastion-site1.company.com \
      "hostname; sleep 300; exit" &
done
wait

# Monitor system resources during test
ssh admin@bastion1-site1.company.com
htop

# Expected:
# - CPU usage < 60%
# - Memory usage < 70%
# - Load average < 4.0

# Check session count
wabadmin sessions --count
# Expected: 25 active sessions

# Measure session establishment time
wabadmin sessions --active --show-latency
# Expected: Average session start time < 2 seconds
```

**Expected Results:**
- [ ] 25 concurrent sessions established successfully
- [ ] CPU usage < 60% (headroom for burst)
- [ ] Memory usage < 70%
- [ ] Disk I/O < 80% (recording overhead)
- [ ] Network bandwidth < 200 Mbps
- [ ] Session establishment time < 2 seconds per session

#### Test 5.1.2: Load Test - 30 Concurrent Sessions (Active-Active, per site limit)

```bash
# Load test with 30 concurrent sessions (matches license pool of 30/site)

# Expected load distribution (Active-Active):
# - Node 1: 15 sessions
# - Node 2: 15 sessions

# Step 1: Initiate 30 concurrent SSH sessions
for i in {1..30}; do
  ssh jsmith$i@bastion-site1.company.com \
      "hostname; sleep 600; exit" &
done

# Step 2: Monitor load distribution via HAProxy
echo "show servers state" | socat stdio /var/lib/haproxy/stats
# Expected: Approximately 15 sessions per backend

# Step 3: Monitor system resources on both nodes
ssh admin@bastion1-site1.company.com "uptime; free -h"
ssh admin@bastion2-site1.company.com "uptime; free -h"

# Expected:
# - Load average < 4.0 on each node
# - Memory usage < 70% on each node

# Step 4: Measure session recording disk I/O
iostat -x 5 10
# Expected: Disk write throughput < 100 MB/s
```

**Expected Results:**
- [ ] 30 sessions distributed evenly (15/15)
- [ ] Both nodes handling load without degradation
- [ ] No session establishment failures
- [ ] Recording storage keeping up with write rate
- [ ] Network throughput < 500 Mbps

### 5.2 Bandwidth Testing

#### Test 5.2.1: High-Throughput File Transfer

```bash
# Test large file transfer via Bastion (SCP)

# User: jsmith
# Source: Local workstation
# Target: prod-rhel-01.company.com via Bastion

# Step 1: Transfer 1 GB file
time scp -o ProxyJump=bastion-site1.company.com \
  testfile-1gb.bin jsmith@prod-rhel-01.company.com:/tmp/

# Expected: Transfer completes without errors
# Transfer time: < 2 minutes (> 8 MB/s sustained)

# Step 2: Monitor network bandwidth on Bastion
ssh admin@bastion1-site1.company.com
iftop -i eth0

# Expected: Peak bandwidth < 1 Gbps (network limit)

# Step 3: Verify file integrity
ssh jsmith@prod-rhel-01.company.com "md5sum /tmp/testfile-1gb.bin"
# Expected: MD5 checksum matches source file
```

**Expected Results:**
- [ ] Large file transfers complete successfully
- [ ] Sustained throughput > 8 MB/s (64 Mbps)
- [ ] No packet loss during transfer
- [ ] File integrity preserved (checksums match)
- [ ] Session recording captures file transfer metadata

### 5.3 Session Recording Performance

#### Test 5.3.1: Recording Storage I/O

```bash
# Test session recording under load

# Step 1: Initiate 20 concurrent RDP sessions (video recording)
# RDP sessions generate more recording data than SSH

# Step 2: Monitor recording storage disk I/O
ssh admin@bastion1-site1.company.com
iostat -x 5 10

# Expected:
# - Disk write throughput < 200 MB/s
# - Disk utilization < 85%
# - Write latency < 20ms

# Step 3: Check recording queue depth
wabadmin recordings --queue-status
# Expected: Queue depth < 100 (backlog manageable)

# Step 4: Verify recording files written
ls -lh /var/wab/recorded/
# Expected: Recording files present, sizes growing
```

**Expected Results:**
- [ ] Recording storage handles write load
- [ ] No recording buffer overruns
- [ ] Recording files written without corruption
- [ ] Disk I/O does not impact session performance

---

## Security Testing

### 6.1 Firewall Rules Validation

#### Test 6.1.1: Allowed Traffic

```bash
# Verify firewall rules allow required traffic

# Test 1: User → HAProxy VIP (HTTPS 443)
curl -k https://bastion-site1.company.com
# Expected: HTTP 200 (login page)

# Test 2: User → HAProxy VIP (SSH 22)
nc -zv bastion-site1.company.com 22
# Expected: Connection succeeded

# Test 3: Bastion (DMZ VLAN) → Access Manager via MPLS (HTTPS 443)
ssh admin@bastion1-site1.company.com
curl -k https://am1.client.com/health
# Expected: HTTP 200 (client AM must be online)

# Test 4: Bastion (DMZ VLAN) → FortiAuth (Cyber VLAN, RADIUS 1812)
ssh admin@bastion1-site1.company.com
nc -uzv 10.10.1.50 1812  # FortiAuth-1 Cyber VLAN
nc -uzv 10.10.1.51 1812  # FortiAuth-2 Cyber VLAN
# Expected: Connection succeeded (inter-VLAN traffic allowed by Fortigate)

# Test 5: Bastion → Target (SSH 22, RDP 3389)
ssh admin@bastion1-site1.company.com
nc -zv prod-rhel-01.company.com 22
nc -zv prod-win-01.company.com 3389
# Expected: Both connections succeeded
```

**Expected Results:**
- [ ] All allowed traffic passes through firewall
- [ ] No connection timeouts for permitted flows
- [ ] Latency within acceptable range (< 50ms)

#### Test 6.1.2: Blocked Traffic

```bash
# Verify firewall rules block unauthorized traffic

# Test 1: Direct Bastion-to-Bastion (Site 1 → Site 2) should FAIL
ssh admin@bastion1-site1.company.com
ping -c 3 bastion1-site2.company.com
# Expected: Destination Host Unreachable (BLOCKED)

# Test 2: External access to Bastion database port should FAIL
nc -zv bastion1-site1.company.com 3306
# Expected: Connection refused (MariaDB port blocked)

# Test 3: Bastion → Internet (unless explicit proxy) should FAIL
ssh admin@bastion1-site1.company.com
curl http://www.google.com
# Expected: Connection timeout (no internet access)

# Test 4: User → Bastion Node IP (not via HAProxy VIP) may be BLOCKED
curl -k https://10.10.1.11:443
# Expected: Connection timeout or refused (depending on policy)
```

**Expected Results:**
- [ ] Inter-site Bastion traffic blocked
- [ ] Database ports not accessible externally
- [ ] Internet access blocked (unless approved)
- [ ] Direct node access restricted (VIP mandatory)

### 6.2 Authentication Security Testing

#### Test 6.2.1: Brute Force Protection

```bash
# Test account lockout after failed login attempts

# Step 1: Attempt 5 failed logins for user "jsmith"
for i in {1..5}; do
  curl -X POST https://bastion-site1.company.com/api/login \
    -d '{"username":"jsmith","password":"wrongpassword"}'
done

# Expected: After 5 attempts, account locked temporarily

# Step 2: Attempt valid login
curl -X POST https://bastion-site1.company.com/api/login \
  -d '{"username":"jsmith","password":"correctpassword"}'
# Expected: HTTP 403 Forbidden - Account locked

# Step 3: Verify lockout logged
wabadmin audit --event "account.locked" | grep jsmith
# Expected: Lockout event logged

# Step 4: Wait for lockout expiration (e.g., 15 minutes)
# OR manually unlock account:
wabadmin user unlock --username jsmith

# Step 5: Retry valid login
# Expected: HTTP 200 OK - Login successful
```

**Expected Results:**
- [ ] Account locked after 5 failed attempts
- [ ] Lockout duration configurable (default 15 minutes)
- [ ] Lockout events logged in audit trail
- [ ] Admin can manually unlock accounts

#### Test 6.2.2: Session Timeout

```bash
# Test session inactivity timeout

# Step 1: Login to Bastion web UI
# Step 2: Remain idle for configured timeout (e.g., 30 minutes)
# Step 3: Attempt action after timeout

# Expected: Session expired, redirect to login page

# Verify in logs
wabadmin audit --event "session.timeout" | tail -10
# Expected: Session timeout logged

# Test SSH session timeout
ssh jsmith@bastion-site1.company.com
# Remain idle for 30 minutes

# Expected: SSH session terminated with message:
# "Connection closed due to inactivity"
```

**Expected Results:**
- [ ] Web UI sessions timeout after inactivity
- [ ] SSH sessions timeout after inactivity
- [ ] RDP sessions timeout after inactivity
- [ ] Timeout configurable per protocol

### 6.3 Encryption Validation

#### Test 6.3.1: TLS/SSL Configuration

```bash
# Test TLS configuration on Bastion

# Step 1: Check TLS version support
nmap --script ssl-enum-ciphers -p 443 bastion-site1.company.com

# Expected:
# - TLS 1.2: Supported
# - TLS 1.3: Supported
# - TLS 1.0/1.1: NOT supported (deprecated)

# Step 2: Check cipher suites
openssl s_client -connect bastion-site1.company.com:443 -tls1_2
# Expected: Strong ciphers only (AES-GCM, ChaCha20)

# Step 3: Test for weak ciphers (should fail)
openssl s_client -connect bastion-site1.company.com:443 -cipher 'DES-CBC3-SHA'
# Expected: Connection refused (weak cipher not supported)

# Step 4: Check certificate configuration
echo | openssl s_client -connect bastion-site1.company.com:443 -showcerts
# Expected:
# - Certificate valid
# - Certificate chain complete
# - No expired certificates
# - Strong signature algorithm (SHA256 or higher)
```

**Expected Results:**
- [ ] TLS 1.2+ only (TLS 1.0/1.1 disabled)
- [ ] Strong cipher suites only
- [ ] Valid certificate with complete chain
- [ ] Perfect Forward Secrecy (PFS) enabled

#### Test 6.3.2: Database Replication Encryption

```bash
# Test database replication encryption

# Step 1: Verify replication is using encrypted transport
# Run as root on each Bastion node:
bastion-replication --monitoring
# Expected: Replication status OK (replication uses encrypted transport)

# Step 2: Verify Bastion version (confirms 12.1.x encryption defaults)
bastion-replication --version
# Expected: Version 12.1.x (or matching installed version)

# Step 3: Verify via web UI
# Navigate to: Configuration > Replication
# Expected: Replication status shows encrypted connection
```

**Expected Results:**
- [ ] Database replication encrypted in transit
- [ ] `bastion-replication --version` confirms expected version
- [ ] Replication monitoring shows no errors
- [ ] Encryption settings align with WALLIX Bastion 12.1.x defaults

---

## Acceptance Criteria

### 7.1 Functional Acceptance Criteria

| ID | Criteria | Status | Evidence |
|----|----------|--------|----------|
| **F-01** | All 5 Bastion sites accessible via HAProxy VIP | [ ] Pass | Health check results |
| **F-02** | FortiToken TOTP authentication functional (all 5 sites) | [ ] Pass | RADIUS test results |
| **F-03** | Per-site FortiAuth HA failover works (all 5 sites) | [ ] Pass | FortiAuth failover tests |
| **F-04** | Per-site AD LDAP integration working (all 5 sites) | [ ] Pass | LDAP connectivity tests |
| **F-05** | SSO via AM functional (Bastion-side SAML SP) | [ ] Pass | Joint test with AM team |
| **F-06** | SSH proxy sessions established successfully | [ ] Pass | 10 test sessions |
| **F-07** | RDP proxy sessions established successfully | [ ] Pass | 10 test sessions |
| **F-08** | OT access via RDS RemoteApp functional | [ ] Pass | 5 test sessions |
| **F-09** | Credential vault stores and retrieves passwords | [ ] Pass | Credential tests |
| **F-10** | Session recording captures all session activity | [ ] Pass | Recording review |
| **F-11** | Audit logs generated for all user actions | [ ] Pass | Audit log export |

### 7.2 Performance Acceptance Criteria

| ID | Criteria | Target | Actual | Status |
|----|----------|--------|--------|--------|
| **P-01** | Session establishment time | < 2 seconds | _____ s | [ ] Pass |
| **P-02** | HAProxy failover time | < 3 seconds | _____ s | [ ] Pass |
| **P-03** | Bastion HA failover time (Master/Master) | < 5 seconds | _____ s | [ ] Pass |
| **P-04** | Bastion HA failover time (Master/Slave) | < 60 seconds | _____ s | [ ] Pass |
| **P-05** | Concurrent sessions per site | >= 25 (tested to 30) | _____ | [ ] Pass |
| **P-06** | Session recording disk I/O | < 200 MB/s | _____ MB/s | [ ] Pass |
| **P-07** | CPU utilization (50 sessions) | < 60% | _____ % | [ ] Pass |
| **P-08** | Memory utilization (50 sessions) | < 70% | _____ % | [ ] Pass |
| **P-09** | Network throughput (file transfer) | > 8 MB/s | _____ MB/s | [ ] Pass |
| **P-10** | MPLS latency (Bastion → AM via MPLS) | < 50 ms | _____ ms | [ ] Pass |
| **P-11** | Inter-VLAN latency (DMZ → Cyber VLAN) | < 5 ms | _____ ms | [ ] Pass |

### 7.3 Security Acceptance Criteria

| ID | Criteria | Status | Evidence |
|----|----------|--------|----------|
| **S-01** | TLS 1.2+ only (TLS 1.0/1.1 disabled) | [ ] Pass | nmap scan results |
| **S-02** | Strong cipher suites enforced | [ ] Pass | SSL Labs report |
| **S-03** | Account lockout after failed logins | [ ] Pass | Brute force test |
| **S-04** | Session timeout enforced | [ ] Pass | Inactivity test |
| **S-05** | Inter-site Bastion traffic blocked | [ ] Pass | Connectivity test |
| **S-06** | Database ports not externally accessible | [ ] Pass | Port scan results |
| **S-07** | Database replication encrypted | [ ] Pass | bastion-replication check |
| **S-08** | All user actions audited | [ ] Pass | Audit log review |
| **S-09** | Session recordings encrypted at rest | [ ] Pass | Storage encryption check |
| **S-10** | MFA required for all user authentication | [ ] Pass | Authentication tests |

### 7.4 Availability Acceptance Criteria

| ID | Criteria | Target | Status |
|----|----------|--------|--------|
| **A-01** | HAProxy HA pair functional | 99.99% | [ ] Pass |
| **A-02** | Bastion HA replication functional | 99.9%+ | [ ] Pass |
| **A-03** | AM HA functional (client team validates) | 99.99% | [ ] Pass |
| **A-04** | Per-site FortiAuth HA failover functional (all 5 sites) | < 10s | [ ] Pass |
| **A-05** | Session data replicated across nodes | Real-time | [ ] Pass |
| **A-06** | Automatic failover tested | Working | [ ] Pass |
| **A-07** | Automatic failback tested (optional) | Working | [ ] Pass |

---

## Sign-Off Checklist

### 9.1 Pre-Production Sign-Off

#### Technical Sign-Off

| Area | Responsible | Status | Date | Signature |
|------|-------------|--------|------|-----------|
| **Component Testing** | Infrastructure Team | [ ] Complete | ______ | __________ |
| **Integration Testing** | Integration Team | [ ] Complete | ______ | __________ |
| **Performance Testing** | Performance Team | [ ] Complete | ______ | __________ |
| **Security Testing** | Security Team | [ ] Complete | ______ | __________ |
| **Failover Testing** | Operations Team | [ ] Complete | ______ | __________ |
| **Documentation Review** | Documentation Lead | [ ] Complete | ______ | __________ |

#### Stakeholder Sign-Off

| Stakeholder | Role | Status | Date | Signature |
|-------------|------|--------|------|-----------|
| **Project Manager** | Overall delivery | [ ] Approved | ______ | __________ |
| **Infrastructure Lead** | Infrastructure | [ ] Approved | ______ | __________ |
| **Security Lead** | Security compliance | [ ] Approved | ______ | __________ |
| **Operations Manager** | Operational readiness | [ ] Approved | ______ | __________ |
| **Business Owner** | Business acceptance | [ ] Approved | ______ | __________ |

### 9.2 Production Go-Live Checklist

#### Pre-Go-Live

- [ ] All testing phases completed successfully
- [ ] All acceptance criteria met
- [ ] Known issues documented and mitigated
- [ ] Operations team trained on new system
- [ ] Runbooks created and reviewed
- [ ] Monitoring dashboards configured
- [ ] Alerting rules configured and tested
- [ ] Backup and recovery tested
- [ ] Disaster recovery plan documented
- [ ] Communication plan for users created
- [ ] Rollback plan documented and tested
- [ ] Change management approval obtained

#### Go-Live Day

- [ ] Final configuration backup taken
- [ ] Maintenance window scheduled and communicated
- [ ] War room established with key personnel
- [ ] Production cutover performed
- [ ] Post-cutover smoke tests completed
- [ ] User acceptance testing (UAT) completed
- [ ] Performance monitoring active
- [ ] On-call team briefed and ready

#### Post-Go-Live (First 24 Hours)

- [ ] System health monitoring active
- [ ] User issues tracked and resolved
- [ ] Performance metrics within targets
- [ ] No critical issues reported
- [ ] Lessons learned documented

### 9.3 Conditional Acceptance

If testing reveals issues:

1. **Critical Issues** (must be resolved before go-live):
   - Authentication failures
   - Data loss scenarios
   - Security vulnerabilities
   - System instability

2. **Major Issues** (must have mitigation plan):
   - Performance degradation
   - Non-critical feature failures
   - Failover delays exceeding targets

3. **Minor Issues** (can be resolved post-go-live):
   - UI/UX improvements
   - Non-essential feature enhancements
   - Documentation updates

---

## Next Steps

After successful testing and validation:

1. **Production Cutover**: Proceed to [HOWTO.md](HOWTO.md) Phase 9 (Go-Live)
2. **Operations Handoff**: Transfer to operations team with runbooks
3. **Monitoring Setup**: Configure Prometheus, Grafana dashboards
4. **User Training**: Conduct end-user training sessions
5. **Post-Go-Live Support**: 24/7 support for first week

---

## Related Documentation

- [12-architecture-diagrams.md](12-architecture-diagrams.md) - Network topology and port reference
- [01-network-design.md](01-network-design.md) - MPLS connectivity and firewall rules
- [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md) - Per-site FortiAuth HA configuration
- [04-ad-per-site.md](04-ad-per-site.md) - Per-site Active Directory integration
- [15-access-manager-integration.md](15-access-manager-integration.md) - Bastion-side AM integration
- [HOWTO.md](HOWTO.md) - Main installation guide

---

**Document Version**: 2.0
**Last Updated**: April 2026
**Validated By**: QA Team
**Approval Status**: Ready for Production Validation
